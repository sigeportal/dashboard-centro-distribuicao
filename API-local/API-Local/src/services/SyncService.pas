unit SyncService;

interface

uses
  System.Classes,
  System.SysUtils,
  System.IniFiles,
  System.JSON,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  System.DateUtils,
  System.Variants,
  UnitDatabase,
  UnitConnection.Model.Interfaces,
  UnitConstants,
  UnitEmpresa.Model,
  UnitOrdens.Model,
  UnitOrdEst.Model,
  UnitGrades.Model,
  UnitTamanho.Model,
  UnitCddTransferencia.Model,
  UnitFunctions,
  JOSE.Core.JWT,
  JOSE.Core.Builder;

type
  TSyncThread = class(TThread)
  private
    FIniFile: TIniFile;
    FClient: TNetHTTPClient;
    FCNPJ: string;
    FToken: string;
    FEmpresaId: Integer;
    function ObterCpfAuth: string;
    function ObterSenhaAuth: string;
    function AutenticaUsuarioAUTH: Boolean;
    procedure LoadConfig;
    procedure IdentificaEmpresaPorCNPJ;
    function GenerateJWT: string;
    procedure EnsureLocalTables;
    procedure SyncDashboard;
    procedure SyncDownCD;
    function QueryDiariosJson(StartDate, EndDate: string): TJSONArray;
    function QueryPagamentosJson(StartDate, EndDate: string): TJSONArray;
    function QueryVendasGrupoJson(StartDate, EndDate: string): TJSONArray;
    function QueryClientesCidadeJson: TJSONArray;
    function QueryVendasHoraJson(StartDate, EndDate: string): TJSONArray;
    function QueryEstoqueJson: TJSONArray;
    function SafeGetInt(const AObj: TJSONObject; const AKey: string; ADefault: Integer = 0): Integer;
    function SafeGetFloat(const AObj: TJSONObject; const AKey: string; ADefault: Double = 0): Double;
    function SafeGetString(const AObj: TJSONObject; const AKey: string; const ADefault: string = ''): string;
    function SafeGetDateParam(const AObj: TJSONObject; const AKey: string): Variant;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TSyncService = class
  private
    class var FThread: TSyncThread;
  public
    class procedure Start;
    class procedure Stop;
  end;

implementation

{ TSyncThread }

constructor TSyncThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FClient := TNetHTTPClient.Create(nil);
  FClient.ContentType := 'application/json';
  FClient.ConnectionTimeout := 15000;
  FClient.ResponseTimeout := 30000;
  FIniFile := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'sinc_config.ini');
end;

destructor TSyncThread.Destroy;
begin
  FClient.Free;
  FIniFile.Free;
  inherited;
end;

function TSyncThread.ObterCpfAuth: string;
begin
  Result := GetEnvironmentVariable('AUTH_CPF').Trim;
  if Result.IsEmpty then
    Result := GetEnvironmentVariable('CPF_AUTH').Trim;
  if Result.IsEmpty then
    Result := FIniFile.ReadString('Sincronia', 'AUTH_CPF', FIniFile.ReadString('Auth', 'CPF', '123.456.789-09'));
end;

function TSyncThread.ObterSenhaAuth: string;
begin
  Result := GetEnvironmentVariable('AUTH_PASSWORD').Trim;
  if Result.IsEmpty then
    Result := GetEnvironmentVariable('AUTH_PASW').Trim;
  if Result.IsEmpty then
    Result := GetEnvironmentVariable('PASW_AUTH').Trim;
  if Result.IsEmpty then
    Result := FIniFile.ReadString('Sincronia', 'AUTH_PASSWORD', FIniFile.ReadString('Auth', 'PASSWORD', 'senha123'));
end;

function TSyncThread.AutenticaUsuarioAUTH: Boolean;
var
  LURL, LCpf, LSenha, LResponseStr: string;
  LBodyJSON, LResponseJSON: TJSONObject;
  LStream: TStringStream;
  LResponse: IHTTPResponse;
begin
  Result := False;
  LCpf := ObterCpfAuth;
  LSenha := ObterSenhaAuth;

  if LCpf.IsEmpty or LSenha.IsEmpty then
    Exit;

  LURL := TConstants.URL_AUTH + '/v1/login';
  LBodyJSON := TJSONObject.Create;
  try
    LBodyJSON.AddPair('cpf', LCpf);
    LBodyJSON.AddPair('password', LSenha);
    LStream := TStringStream.Create(LBodyJSON.ToString, TEncoding.UTF8);
    try
      FClient.CustomHeaders['Authorization'] := '';
      LResponse := FClient.Post(LURL, LStream);

      if (LResponse.StatusCode <> 200) then
      begin
        LURL := TConstants.URL_CD + '/v1/login';
        LResponse := FClient.Post(LURL, LStream);
      end;

      if LResponse.StatusCode = 200 then
      begin
        LResponseStr := LResponse.ContentAsString(TEncoding.UTF8);
        LResponseJSON := TJSONObject.ParseJSONValue(LResponseStr) as TJSONObject;
        if Assigned(LResponseJSON) then
        begin
          try
            FToken := SafeGetString(LResponseJSON, 'access_token');
            Result := not FToken.IsEmpty;
          finally
            LResponseJSON.Free;
          end;
        end;
      end
      else
      begin
        Writeln('-> Falha no login AUTH /v1/login (HTTP ' + LResponse.StatusCode.ToString + ') com CPF ' + LCpf);
      end;
    finally
      LStream.Free;
    end;
  finally
    LBodyJSON.Free;
  end;
end;

procedure TSyncThread.LoadConfig;
var
  LEmpresa: TEmpresa;
begin
  if FCNPJ.IsEmpty then
  begin
    LEmpresa := TEmpresa.Create(TDataBase.Connection);
    try
      LEmpresa.BuscaPorCampo('EMP_CODIGO', 1);
      FCNPJ := NormalizaCNPJ(LEmpresa.CNPJ);
    finally
      LEmpresa.Free;
    end;
  end;

  IdentificaEmpresaPorCNPJ;
end;

procedure TSyncThread.IdentificaEmpresaPorCNPJ;
var
  LURL, LResponseStr, LCnpjItem, LIdItem: string;
  LResponse: IHTTPResponse;
  LJSONVal, LObjItem: TJSONObject;
  LArrCompanies: TJSONArray;
  I: Integer;
  LFound: Boolean;
  LNomeItem: string;
begin
  FEmpresaId := 1;
  if FCNPJ.IsEmpty then
    Exit;

  LFound := False;

  // 1. Tenta autenticar via CPF e Password no AUTH server (/v1/login)
  if not AutenticaUsuarioAUTH then
  begin
    if FToken.IsEmpty then
      FToken := GenerateJWT;
  end;

  // 2. Consulta as empresas vinculadas ao usuario em /v1/companies/linked
  LURL := TConstants.URL_AUTH + '/v1/companies/linked';

  try
    FClient.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
    LResponse := FClient.Get(LURL);

    if (LResponse.StatusCode <> 200) then
    begin
      LURL := TConstants.URL_CD + '/v1/companies/linked';
      LResponse := FClient.Get(LURL);
    end;

    if LResponse.StatusCode = 200 then
    begin
      LResponseStr := LResponse.ContentAsString(TEncoding.UTF8);
      LJSONVal := TJSONObject.ParseJSONValue(LResponseStr) as TJSONObject;
      if Assigned(LJSONVal) then
      begin
        try
          LArrCompanies := LJSONVal.GetValue<TJSONArray>('companies', nil);
          if Assigned(LArrCompanies) then
          begin
            for I := 0 to LArrCompanies.Count - 1 do
            begin
              LObjItem := TJSONObject(LArrCompanies.Items[I]);
              LCnpjItem := NormalizaCNPJ(SafeGetString(LObjItem, 'cnpj'));
              LIdItem := SafeGetString(LObjItem, 'id');
              LNomeItem := SafeGetString(LObjItem, 'nome');
              if (not LCnpjItem.IsEmpty) and (LCnpjItem = FCNPJ) then
              begin
                FEmpresaId := StrToIntDef(LIdItem, 1);
                LFound := True;
                Break;
              end;
            end;
          end;
        finally
          LJSONVal.Free;
        end;
      end;
    end;

    if LFound then
      Writeln('-> Empresa identificada pelo CNPJ (' + FCNPJ + ') - (' + LNomeItem +') em /v1/companies/linked: EMP_ID = ' + FEmpresaId.ToString)
    else
      Writeln('-> CNPJ local (' + FCNPJ + ') nao localizado em /v1/companies/linked. Usando EMP_ID padrao = ' + FEmpresaId.ToString);

  except
    on E: Exception do
      Writeln('-> Erro ao consultar /v1/companies/linked: ' + E.Message);
  end;
end;

function TSyncThread.GenerateJWT: string;
var
  LToken: TJWT;
begin
  LToken := TJWT.Create;
  try
    LToken.Claims.Issuer := 'Portal.com';
    LToken.Claims.Subject := FCNPJ;
    LToken.Claims.IssuedAt := Now;
    LToken.Claims.Expiration := Now + 1.0;
    Result := TJOSE.SHA256CompactToken(TConstants.JWT_SECRET, LToken);
  finally
    LToken.Free;
  end;
end;

procedure TSyncThread.EnsureLocalTables;
var
  OrdEst: TOrdEst;
  Ordens: TOrdens;
  CddTransf: TCddTransferencia;
  CddTransfItem: TCddTransferenciaItem;
  Tamanhos: TTamanho;
  Grades: TGrades;
begin
  try
    OrdEst := TOrdEst.Create(TDatabase.Connection);
    try
      OrdEst.CriaTabela;
    finally
      OrdEst.DisposeOf;
    end;

    Ordens := TOrdens.Create(TDatabase.Connection);
    try
      Ordens.CriaTabela;
    finally
      Ordens.DisposeOf;
    end;

    CddTransf := TCddTransferencia.Create(TDatabase.Connection);
    try
      CddTransf.CriaTabela;
    finally
      CddTransf.DisposeOf;
    end;

    CddTransfItem := TCddTransferenciaItem.Create(TDatabase.Connection);
    try
      CddTransfItem.CriaTabela;
    finally
      CddTransfItem.DisposeOf;
    end;

    Tamanhos := TTamanho.Create(TDatabase.Connection);
    try
      Tamanhos.CriaTabela;
    finally
      Tamanhos.DisposeOf;
    end;

    Grades := TGrades.Create(TDatabase.Connection);
    try
      Grades.CriaTabela;
    finally
      Grades.DisposeOf;
    end;
  except
    on E: Exception do
      Writeln('-> Erro ao verificar/criar tabelas locais: ' + E.Message);
  end;
end;

function TSyncThread.QueryDiariosJson(StartDate, EndDate: string): TJSONArray;
var
  LQuery: iQuery;
  LQ2: iQuery;
  LItem: TJSONObject;
  LDataStr: string;
begin
  Result := TJSONArray.Create;
  LQuery := TDatabase.Query;
  // Get sales and OS daily totals, plus credit/debts from movimentacoes
  // Grouped daily for last 30 days
  LQuery.Add('SELECT DISTINCT CAST(v.VEN_DATA AS DATE) AS DATA_REF FROM VENDAS v WHERE v.VEN_DATA BETWEEN :D1 AND :D2');
  LQuery.Add('UNION DISTINCT');
  LQuery.Add('SELECT DISTINCT CAST(o.ORD_DATA AS DATE) AS DATA_REF FROM ORDENS o WHERE o.ORD_DATA BETWEEN :D1 AND :D2');
  LQuery.Add('UNION DISTINCT');
  LQuery.Add('SELECT DISTINCT CAST(m.MOV_DATA AS DATE) AS DATA_REF FROM MOVIMENTACOES m WHERE m.MOV_DATA BETWEEN :D1 AND :D2');
  LQuery.AddParam('D1', StartDate);
  LQuery.AddParam('D2', EndDate);
  LQuery.Open;

  while not LQuery.DataSet.Eof do
  begin
    if not LQuery.DataSet.FieldByName('DATA_REF').IsNull then
    begin
      LDataStr := FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('DATA_REF').AsDateTime);
      LItem := TJSONObject.Create;
      LItem.AddPair('data_ref', LDataStr);

      // We will perform fast individual aggregates for each day
      // 1. Sales
      LQ2 := TDatabase.Query;
      LQ2.Add('SELECT SUM(COALESCE(ve.VE_VALOR, 0)) as valor, MAX(COALESCE(ve.VE_VALOR, 0)) as maior_venda, COUNT(DISTINCT(v.VEN_CODIGO)) as quantidade, ');
      LQ2.Add('SUM(COALESCE(ve.VE_VALOR, 0) - COALESCE(ve.VE_VALORR, 0)) as lucro ');
      LQ2.Add('FROM VENDAS v JOIN VEN_EST ve ON ve.VE_VEN = v.VEN_CODIGO ');
      LQ2.Add('WHERE CAST(v.VEN_DATA AS DATE) = :DREF AND v.VEN_DATAC = ''01.01.1900''');
      LQ2.AddParam('DREF', LDataStr).Open;
      LItem.AddPair('vendas_valor', TJSONNumber.Create(LQ2.DataSet.FieldByName('valor').AsFloat));
      LItem.AddPair('vendas_lucro', TJSONNumber.Create(LQ2.DataSet.FieldByName('lucro').AsFloat));
      LItem.AddPair('vendas_maior', TJSONNumber.Create(LQ2.DataSet.FieldByName('maior_venda').AsFloat));
      LItem.AddPair('vendas_qtd', TJSONNumber.Create(LQ2.DataSet.FieldByName('quantidade').AsInteger));

      // 2. OS
      LQ2.Clear;
      LQ2.Add('SELECT SUM(COALESCE(ORD_VALOR, 0)) as valor, MAX(COALESCE(ORD_VALOR, 0)) as maior_os, COUNT(DISTINCT(ORD_CODIGO)) as quantidade ');
      LQ2.Add('FROM ORDENS ');
      LQ2.Add('WHERE CAST(ORD_DATA AS DATE) = :DREF');
      LQ2.AddParam('DREF', LDataStr).Open;
      LItem.AddPair('os_valor', TJSONNumber.Create(LQ2.DataSet.FieldByName('valor').AsFloat));
      LItem.AddPair('os_lucro', TJSONNumber.Create(LQ2.DataSet.FieldByName('valor').AsFloat * 0.35)); // Estimate 35% margin on OS service/parts
      LItem.AddPair('os_maior', TJSONNumber.Create(LQ2.DataSet.FieldByName('maior_os').AsFloat));
      LItem.AddPair('os_qtd', TJSONNumber.Create(LQ2.DataSet.FieldByName('quantidade').AsInteger));

      // 3. Movements
      LQ2.Clear;
      LQ2.Add('SELECT SUM(COALESCE(MOV_CREDITO, 0)) as credito, SUM(COALESCE(MOV_DEBITO, 0)) as debito ');
      LQ2.Add('FROM MOVIMENTACOES ');
      LQ2.Add('WHERE CAST(MOV_DATA AS DATE) = :DREF');
      LQ2.AddParam('DREF', LDataStr).Open;
      LItem.AddPair('mov_credito', TJSONNumber.Create(LQ2.DataSet.FieldByName('credito').AsFloat));
      LItem.AddPair('mov_debito', TJSONNumber.Create(LQ2.DataSet.FieldByName('debito').AsFloat));

      Result.AddElement(LItem);
    end;
    LQuery.DataSet.Next;
  end;
end;

function TSyncThread.QueryPagamentosJson(StartDate, EndDate: string): TJSONArray;
var
  LQuery: iQuery;
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;
  LQuery := TDatabase.Query;
  // Let's aggregate main payment types
  LQuery.Add('SELECT PF_TABELA AS TIPO_REGISTRO, TP_DESCRICAO AS TIPO_PAGAMENTO, SUM(PP_VALOR) AS VALOR');
  LQuery.Add('FROM TIPO_PGM, PED_FAT, PF_PARCELA');
  LQuery.Add('WHERE PF_CODIGO = PP_PF AND PP_TP = TP_CODIGO');
  LQuery.Add('AND PF_DATA BETWEEN :D1 AND :D2 AND PF_DATAC = ''01.01.1900'' AND PF_TIPO = 2');
  LQuery.Add('GROUP BY PF_TABELA, TP_DESCRICAO');
  LQuery.AddParam('D1', StartDate);
  LQuery.AddParam('D2', EndDate);
  LQuery.Open;

  while not LQuery.DataSet.Eof do
  begin
    LItem := TJSONObject.Create;
    LItem.AddPair('tipo_registro', LQuery.DataSet.FieldByName('TIPO_REGISTRO').AsString);
    LItem.AddPair('tipo_operacao', '');
    LItem.AddPair('tipo_pagamento', LQuery.DataSet.FieldByName('TIPO_PAGAMENTO').AsString);
    LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VALOR').AsFloat));
    Result.AddElement(LItem);
    LQuery.DataSet.Next;
  end;
end;

function TSyncThread.QueryVendasGrupoJson(StartDate, EndDate: string): TJSONArray;
var
  LQuery: iQuery;
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LQuery.Add('SELECT g.GRU_NOME AS nome_grupo, SUM(COALESCE(ve.VE_VALOR, 0)) AS valor, SUM(COALESCE(ve.VE_VALOR, 0) - COALESCE(ve.VE_VALORR, 0)) AS lucro');
  LQuery.Add('FROM GRUPOS g JOIN PRODUTOS p ON p.PRO_GRU = g.GRU_CODIGO');
  LQuery.Add('JOIN VEN_EST ve ON ve.VE_PRO = p.PRO_CODIGO JOIN VENDAS v ON v.VEN_CODIGO = ve.VE_VEN');
  LQuery.Add('WHERE v.VEN_DATA BETWEEN :D1 AND :D2 AND v.VEN_DATAC = ''01.01.1900''');
  LQuery.Add('GROUP BY g.GRU_NOME');
  LQuery.AddParam('D1', StartDate);
  LQuery.AddParam('D2', EndDate);
  LQuery.Open;

  while not LQuery.DataSet.Eof do
  begin
    LItem := TJSONObject.Create;
    LItem.AddPair('nome_grupo', LQuery.DataSet.FieldByName('nome_grupo').AsString);
    LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('valor').AsFloat));
    LItem.AddPair('lucro', TJSONNumber.Create(LQuery.DataSet.FieldByName('lucro').AsFloat));
    Result.AddElement(LItem);
    LQuery.DataSet.Next;
  end;
end;

function TSyncThread.QueryClientesCidadeJson: TJSONArray;
var
  LQuery: iQuery;
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LQuery.Add('SELECT c.CID_NOME as CIDADE, COUNT(cl.CLI_CODIGO) as QUANTIDADE');
  LQuery.Add('FROM CLIENTES cl LEFT JOIN CIDADES c ON c.CID_CODIGO = cl.CLI_CID');
  LQuery.Add('GROUP BY c.CID_NOME');
  LQuery.Open;

  while not LQuery.DataSet.Eof do
  begin
    LItem := TJSONObject.Create;
    LItem.AddPair('cidade', LQuery.DataSet.FieldByName('CIDADE').AsString);
    LItem.AddPair('quantidade', TJSONNumber.Create(LQuery.DataSet.FieldByName('QUANTIDADE').AsInteger));
    Result.AddElement(LItem);
    LQuery.DataSet.Next;
  end;
end;

function TSyncThread.QueryVendasHoraJson(StartDate, EndDate: string): TJSONArray;
var
  LQuery: iQuery;
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LQuery.Add('SELECT SUBSTRING(v.VEN_HORA FROM 1 FOR 2) AS hora, SUM(COALESCE(ve.VE_VALOR, 0)) AS valor');
  LQuery.Add('FROM VENDAS v JOIN VEN_EST ve ON ve.VE_VEN = v.VEN_CODIGO');
  LQuery.Add('WHERE v.VEN_DATA BETWEEN :D1 AND :D2 AND v.VEN_DATAC = ''01.01.1900''');
  LQuery.Add('GROUP BY 1');
  LQuery.AddParam('D1', StartDate);
  LQuery.AddParam('D2', EndDate);
  LQuery.Open;

  while not LQuery.DataSet.Eof do
  begin
    LItem := TJSONObject.Create;
    LItem.AddPair('hora', LQuery.DataSet.FieldByName('hora').AsString);
    LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('valor').AsFloat));
    Result.AddElement(LItem);
    LQuery.DataSet.Next;
  end;
end;

function TSyncThread.QueryEstoqueJson: TJSONArray;
var
  LQuery: iQuery;
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LQuery.Add('SELECT PRO_CODIGO, COALESCE(PRO_QUANTIDADE, 0) AS QTD FROM PRODUTOS WHERE PRO_CODIGO IS NOT NULL');
  LQuery.Open;

  while not LQuery.DataSet.Eof do
  begin
    LItem := TJSONObject.Create;
    LItem.AddPair('pro_codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_CODIGO').AsInteger));
    LItem.AddPair('quantidade', TJSONNumber.Create(LQuery.DataSet.FieldByName('QTD').AsFloat));
    Result.AddElement(LItem);
    LQuery.DataSet.Next;
  end;
end;

function TSyncThread.SafeGetInt(const AObj: TJSONObject; const AKey: string; ADefault: Integer): Integer;
var
  LVal: TJSONValue;
begin
  Result := ADefault;
  if not Assigned(AObj) then Exit;
  LVal := AObj.GetValue(AKey);
  if not Assigned(LVal) or LVal.InheritsFrom(TJSONNull) then Exit;

  if LVal is TJSONNumber then
    Result := TJSONNumber(LVal).AsInt
  else if LVal is TJSONString then
    Result := StrToIntDef(TJSONString(LVal).Value, ADefault);
end;

function TSyncThread.SafeGetFloat(const AObj: TJSONObject; const AKey: string; ADefault: Double): Double;
var
  LVal: TJSONValue;
  LStr: string;
  LSettings: TFormatSettings;
begin
  Result := ADefault;
  if not Assigned(AObj) then Exit;
  LVal := AObj.GetValue(AKey);
  if not Assigned(LVal) or LVal.InheritsFrom(TJSONNull) then Exit;

  if LVal is TJSONNumber then
    Result := TJSONNumber(LVal).AsDouble
  else if LVal is TJSONString then
  begin
    LStr := TJSONString(LVal).Value;
    LSettings.DecimalSeparator := '.';
    if not TryStrToFloat(LStr, Result, LSettings) then
    begin
      LSettings.DecimalSeparator := ',';
      if not TryStrToFloat(LStr, Result, LSettings) then
        Result := ADefault;
    end;
  end;
end;

function TSyncThread.SafeGetString(const AObj: TJSONObject; const AKey, ADefault: string): string;
var
  LVal: TJSONValue;
begin
  Result := ADefault;
  if not Assigned(AObj) then Exit;
  LVal := AObj.GetValue(AKey);
  if not Assigned(LVal) or LVal.InheritsFrom(TJSONNull) then Exit;
  Result := LVal.Value;
end;

function TSyncThread.SafeGetDateParam(const AObj: TJSONObject; const AKey: string): Variant;
var
  LStr: string;
begin
  LStr := SafeGetString(AObj, AKey, '');
  if (Trim(LStr) = '') or (LStr = '1899-12-30') or (LStr = '30/12/1899') then
    Result := Null
  else
    Result := LStr;
end;

procedure TSyncThread.SyncDashboard;
var
  LPayload: TJSONObject;
  LURL, LStartDate, LEndDate: string;
  LBody: TStringStream;
  LResponse: IHTTPResponse;
begin
  LStartDate := FormatDateTime('yyyy-mm-dd', Now - 30);
  LEndDate := FormatDateTime('yyyy-mm-dd', Now);

  LPayload := TJSONObject.Create;
  try
    LPayload.AddPair('diarios', QueryDiariosJson(LStartDate, LEndDate));
    LPayload.AddPair('pagamentos', QueryPagamentosJson(LStartDate, LEndDate));
    LPayload.AddPair('vendas_grupo', QueryVendasGrupoJson(LStartDate, LEndDate));
    LPayload.AddPair('clientes_cidade', QueryClientesCidadeJson);
    LPayload.AddPair('vendas_hora', QueryVendasHoraJson(LStartDate, LEndDate));
    LPayload.AddPair('estoque', QueryEstoqueJson);

    LURL := TConstants.URL_CD + '/v1/sync/dashboard';
    LBody := TStringStream.Create(LPayload.ToString, TEncoding.UTF8);
    try
      FClient.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
      FClient.CustomHeaders['X-Empresa-Id'] := FEmpresaId.ToString;
      LResponse := FClient.Post(LURL, LBody);
      if (LResponse.StatusCode = 200) or (LResponse.StatusCode = 201) then
        Writeln('-> Dashboard enviado com sucesso para o CD.')
      else
        Writeln('-> Erro ao enviar Dashboard para o CD: ' + LResponse.StatusCode.ToString);
    except
      on E: Exception do
        Writeln('-> Exception no push de Dashboard: ' + E.Message);
    end;
  finally
    LPayload.Free;
  end;
end;

procedure TSyncThread.SyncDownCD;
var
  LLastSync, LURL, LResponseStr, LNewSync: string;
  LResponse: IHTTPResponse;
  LJSON, LObj: TJSONObject;
  LArrGrupos, LArrSubgrupos, LArrGrades, LArrTamanhos, LArrFornecedores, LArrProdutos, LArrTransf, LArrItens: TJSONArray;
  I, J, LTransfId, LGru, LFor: Integer;
  LXmlVal: TJSONValue;
  LObjItem: TJSONObject;
  LQuery: iQuery;
  Null: Variant;
  LArrClientes: TJSONArray;
begin
  LLastSync := FIniFile.ReadString('Sincronia', 'CD_LastSync', '');
  LURL := TConstants.URL_CD + '/v1/sync/pending?last_sync=' + LLastSync;

  try
    FClient.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
    FClient.CustomHeaders['X-Empresa-Id'] := FEmpresaId.ToString;
    LResponse := FClient.Get(LURL);
    if LResponse.StatusCode <> 200 then
    begin
      Writeln('-> Erro ao buscar pendencias do CD: ' + LResponse.StatusCode.ToString);
      Exit;
    end;

    LResponseStr := LResponse.ContentAsString(TEncoding.UTF8);
    LJSON := TJSONObject.ParseJSONValue(LResponseStr) as TJSONObject;
    if not Assigned(LJSON) then
      Exit;

    try
      // 1. Grupos
      try
        LArrGrupos := LJSON.GetValue<TJSONArray>('grupos', nil);
        if Assigned(LArrGrupos) and (LArrGrupos.Count > 0) then
        begin
          LQuery := TDatabase.Query;
          for I := 0 to LArrGrupos.Count - 1 do
          begin
            LObj := TJSONObject(LArrGrupos.Items[I]);
            LQuery.Clear;
            LQuery.Add('UPDATE OR INSERT INTO GRUPOS (GRU_CODIGO, GRU_NOME) VALUES (:COD, :NOME) MATCHING (GRU_CODIGO)');
            LQuery.AddParam('COD', SafeGetInt(LObj, 'gru_codigo', 0));
            LQuery.AddParam('NOME', SafeGetString(LObj, 'gru_nome'));
            LQuery.ExecSQL;
          end;
          Writeln('-> Sincronizados ' + LArrGrupos.Count.ToString + ' grupos da matriz.');
        end;
      except
        on E: Exception do Writeln('-> Erro ao sincronizar grupos: ' + E.Message);
      end;

      // 2. Fornecedores
      try
        LArrFornecedores := LJSON.GetValue<TJSONArray>('fornecedores', nil);
        if Assigned(LArrFornecedores) and (LArrFornecedores.Count > 0) then
        begin
          LQuery := TDatabase.Query;
          for I := 0 to LArrFornecedores.Count - 1 do
          begin
            LObj := TJSONObject(LArrFornecedores.Items[I]);
            LQuery.Clear;
            LQuery.Add('UPDATE OR INSERT INTO FORNECEDORES (FOR_CODIGO, FOR_NOME, FOR_NOMEFANTASIA, FOR_CNPJ_CPF, FOR_INSC_ESTADUAL)');
            LQuery.Add('VALUES (:COD, :NOME, :FANTASIA, :CNPJ, :IE) MATCHING (FOR_CODIGO)');
            LQuery.AddParam('COD', SafeGetInt(LObj, 'for_codigo', 0));
            LQuery.AddParam('NOME', SafeGetString(LObj, 'for_nome'));
            LQuery.AddParam('FANTASIA', SafeGetString(LObj, 'for_nomefantasia'));
            LQuery.AddParam('CNPJ', SafeGetString(LObj, 'for_cnpj_cpf'));
            LQuery.AddParam('IE', SafeGetString(LObj, 'for_insc_estadual'));
            LQuery.ExecSQL;
          end;
          Writeln('-> Sincronizados ' + LArrFornecedores.Count.ToString + ' fornecedores da matriz.');
        end;
      except
        on E: Exception do Writeln('-> Erro ao sincronizar fornecedores: ' + E.Message);
      end;

      // 3. Produtos
      try
        LArrProdutos := LJSON.GetValue<TJSONArray>('produtos', nil);
        if Assigned(LArrProdutos) and (LArrProdutos.Count > 0) then
        begin
          LQuery := TDatabase.Query;
          for I := 0 to LArrProdutos.Count - 1 do
          begin
            LObj := TJSONObject(LArrProdutos.Items[I]);
            LGru := SafeGetInt(LObj, 'pro_gru', 0);
            LFor := SafeGetInt(LObj, 'pro_for', 0);

            LQuery.Clear;
            LQuery.Add('UPDATE OR INSERT INTO PRODUTOS (PRO_CODIGO, PRO_NOME, PRO_DESCRICAO, PRO_CODBARRA, PRO_VALORV, PRO_VALOR_DINHEIRO, PRO_VALORV_PRAZO, PRO_VALORC, PRO_EMBALAGEM, PRO_FABRICANTE, PRO_GRU, PRO_FOR, PRO_DATAUA)');
            LQuery.Add('VALUES (:COD, :NOME, :DESC, :BARRA, :VALORV, :VALORD, :VALORP, :VALORC, :EMB, :FAB, :GRU, :FOR, :DATAUA) MATCHING (PRO_CODIGO)');
            LQuery.AddParam('COD', SafeGetInt(LObj, 'pro_codigo', 0));
            LQuery.AddParam('NOME', SafeGetString(LObj, 'pro_nome'));
            LQuery.AddParam('DESC', SafeGetString(LObj, 'pro_descricao'));
            LQuery.AddParam('BARRA', SafeGetString(LObj, 'pro_codbarra'));
            LQuery.AddParam('VALORV', SafeGetFloat(LObj, 'pro_valorv', 0));
            LQuery.AddParam('VALORD', SafeGetFloat(LObj, 'pro_valor_dinheiro', 0));
            LQuery.AddParam('VALORP', SafeGetFloat(LObj, 'pro_valorv_prazo', 0));
            LQuery.AddParam('VALORC', SafeGetFloat(LObj, 'pro_valorc', 0));
            LQuery.AddParam('EMB', SafeGetString(LObj, 'pro_embalagem'));
            LQuery.AddParam('FAB', SafeGetString(LObj, 'pro_fabricante'));

            if LGru > 0 then
              LQuery.AddParam('GRU', LGru)
            else
              LQuery.AddParam('GRU', Null);

            if LFor > 0 then
              LQuery.AddParam('FOR', LFor)
            else
              LQuery.AddParam('FOR', Null);

            LQuery.AddParam('DATAUA', SafeGetDateParam(LObj, 'pro_dataua'));
            LQuery.ExecSQL;
          end;
          Writeln('-> Sincronizados ' + LArrProdutos.Count.ToString + ' produtos da matriz.');
        end;
      except
        on E: Exception do Writeln('-> Erro ao sincronizar produtos: ' + E.Message);
      end;

      // 4. Transferencias
      try
        LArrTransf := LJSON.GetValue<TJSONArray>('transferencias', nil);
        if Assigned(LArrTransf) and (LArrTransf.Count > 0) then
        begin
          LQuery := TDatabase.Query;
          for I := 0 to LArrTransf.Count - 1 do
          begin
            LObj := TJSONObject(LArrTransf.Items[I]);
            LTransfId := SafeGetInt(LObj, 'id', 0);

            LQuery.Clear;
            LQuery.Add('UPDATE OR INSERT INTO CDD_TRANSFERENCIAS (ID, CODIGO, STATUS, DATA_CRIACAO, DATA_XML, DATA_RECEBIMENTO, DATA_CANCELAMENTO, CONTEUDO_XML)');
            LQuery.Add('VALUES (:ID, :CODIGO, :STATUS, :DATA_CRIACAO, :DATA_XML, :DATA_RECEBIMENTO, :DATA_CANCELAMENTO, :CONTEUDO_XML) MATCHING (ID)');
            LQuery.AddParam('ID', LTransfId);
            LQuery.AddParam('CODIGO', SafeGetString(LObj, 'codigo'));
            LQuery.AddParam('STATUS', SafeGetString(LObj, 'status'));
            LQuery.AddParam('DATA_CRIACAO', SafeGetString(LObj, 'data_criacao'));
            LQuery.AddParam('DATA_XML', SafeGetString(LObj, 'data_xml'));
            LQuery.AddParam('DATA_RECEBIMENTO', SafeGetString(LObj, 'data_recebimento'));
            LQuery.AddParam('DATA_CANCELAMENTO', SafeGetString(LObj, 'data_cancelamento'));

            LXmlVal := LObj.GetValue('conteudo_xml');
            if Assigned(LXmlVal) and not LXmlVal.InheritsFrom(TJSONNull) then
              LQuery.AddParam('CONTEUDO_XML', LXmlVal.Value)
            else
              LQuery.AddParam('CONTEUDO_XML', '');
            LQuery.ExecSQL;

            // Clear items
            LQuery.Clear;
            LQuery.Add('DELETE FROM CDD_TRANSFERENCIAS_ITENS WHERE TRANSFERENCIA_ID = :TID');
            LQuery.AddParam('TID', LTransfId).ExecSQL;

            // Insert items
            LArrItens := LObj.GetValue<TJSONArray>('itens', nil);
            if Assigned(LArrItens) then
            begin
              for J := 0 to LArrItens.Count - 1 do
              begin
                LObjItem := TJSONObject(LArrItens.Items[J]);
                LQuery.Clear;
                LQuery.Add('INSERT INTO CDD_TRANSFERENCIAS_ITENS (ID, TRANSFERENCIA_ID, PRO_CODIGO, QUANTIDADE)');
                LQuery.Add('VALUES ((SELECT COALESCE(MAX(ID), 0) + 1 FROM CDD_TRANSFERENCIAS_ITENS), :TID, :PRO_CODIGO, :QUANTIDADE)');
                LQuery.AddParam('TID', LTransfId);
                LQuery.AddParam('PRO_CODIGO', SafeGetInt(LObjItem, 'pro_codigo', 0));
                LQuery.AddParam('QUANTIDADE', SafeGetFloat(LObjItem, 'quantidade', 0));
                LQuery.ExecSQL;
              end;
            end;
          end;
          Writeln('-> Sincronizadas ' + LArrTransf.Count.ToString + ' transferencias da matriz.');
        end;
      except
        on E: Exception do Writeln('-> Erro ao sincronizar transferencias: ' + E.Message);
      end;

      // 5. Subgrupos
      try
        LArrSubgrupos := LJSON.GetValue<TJSONArray>('subgrupos', nil);
        if Assigned(LArrSubgrupos) and (LArrSubgrupos.Count > 0) then
        begin
          LQuery := TDatabase.Query;
          for I := 0 to LArrSubgrupos.Count - 1 do
          begin
            LObj := TJSONObject(LArrSubgrupos.Items[I]);
            LQuery.Clear;
            LQuery.Add('UPDATE OR INSERT INTO GRUPOS (GRU_CODIGO, GRU_NOME, GRU_G1, GRU_TR) VALUES (:COD, :NOME, :G1, :TR) MATCHING (GRU_CODIGO)');
            LQuery.AddParam('COD', SafeGetInt(LObj, 'codigo', 0));
            LQuery.AddParam('NOME', SafeGetString(LObj, 'nome'));
            LQuery.AddParam('G1', SafeGetInt(LObj, 'g1', 0));
            LQuery.AddParam('TR', SafeGetInt(LObj, 'tr', 0));
            LQuery.ExecSQL;
          end;
          Writeln('-> Sincronizados ' + LArrSubgrupos.Count.ToString + ' subgrupos da matriz.');
        end;
      except
        on E: Exception do Writeln('-> Erro ao sincronizar subgrupos: ' + E.Message);
      end;

      // 6. Grades
      try
        LArrGrades := LJSON.GetValue<TJSONArray>('grades', nil);
        if Assigned(LArrGrades) and (LArrGrades.Count > 0) then
        begin
          LQuery := TDatabase.Query;
          for I := 0 to LArrGrades.Count - 1 do
          begin
            LObj := TJSONObject(LArrGrades.Items[I]);
            LQuery.Clear;
            LQuery.Add('UPDATE OR INSERT INTO GRADES (GRA_CODIGO, GRA_PRO, GRA_VALOR, GRA_VALOR_DINHEIRO, GRA_VALOR_PRAZO, GRA_TAM, GRA_QUANTIDADE, GRA_CODBARRA, GRA_COR) VALUES (:COD, :PRO, :VALOR, :VALORD, :VALORP, :TAM, :QTD, :BARRA, :COR) MATCHING (GRA_CODIGO)');
            LQuery.AddParam('COD', SafeGetInt(LObj, 'codigo', 0));
            LQuery.AddParam('PRO', SafeGetInt(LObj, 'pro', 0));
            LQuery.AddParam('VALOR', SafeGetFloat(LObj, 'valor', 0));
            LQuery.AddParam('VALORD', SafeGetFloat(LObj, 'valor_dinheiro', 0));
            LQuery.AddParam('VALORP', SafeGetFloat(LObj, 'valor_prazo', 0));
            LQuery.AddParam('TAM', SafeGetInt(LObj, 'tam', 0));
            LQuery.AddParam('QTD', SafeGetFloat(LObj, 'quantidade', 0));
            LQuery.AddParam('BARRA', SafeGetString(LObj, 'codbarra'));
            LQuery.AddParam('COR', SafeGetString(LObj, 'cor'));
            LQuery.ExecSQL;
          end;
          Writeln('-> Sincronizadas ' + LArrGrades.Count.ToString + ' grades da matriz.');
        end;
      except
        on E: Exception do Writeln('-> Erro ao sincronizar grades: ' + E.Message);
      end;

      // 7. Tamanhos
      try
        LArrTamanhos := LJSON.GetValue<TJSONArray>('tamanhos', nil);
        if Assigned(LArrTamanhos) and (LArrTamanhos.Count > 0) then
        begin
          LQuery := TDatabase.Query;
          for I := 0 to LArrTamanhos.Count - 1 do
          begin
            LObj := TJSONObject(LArrTamanhos.Items[I]);
            LQuery.Clear;
            LQuery.Add('UPDATE OR INSERT INTO TAMANHOS (TAM_CODIGO, TAM_PRO, TAM_TAMANHO, TAM_SIGLA, TAM_VALOR) VALUES (:COD, :PRO, :TAM, :SIGLA, :VALOR) MATCHING (TAM_CODIGO)');
            LQuery.AddParam('COD', SafeGetInt(LObj, 'codigo', 0));
            LQuery.AddParam('PRO', SafeGetInt(LObj, 'pro', 0));
            LQuery.AddParam('TAM', SafeGetString(LObj, 'tamanho'));
            LQuery.AddParam('SIGLA', SafeGetString(LObj, 'sigla'));
            LQuery.AddParam('VALOR', SafeGetFloat(LObj, 'valor', 0));
            LQuery.ExecSQL;
          end;
          Writeln('-> Sincronizados ' + LArrTamanhos.Count.ToString + ' tamanhos da matriz.');
        end;
      except
        on E: Exception do Writeln('-> Erro ao sincronizar tamanhos: ' + E.Message);
      end;

      // 8. Clientes
      try
        LArrClientes := LJSON.GetValue<TJSONArray>('clientes', nil);
        if Assigned(LArrClientes) and (LArrClientes.Count > 0) then
        begin
          LQuery := TDatabase.Query;
          for I := 0 to LArrClientes.Count - 1 do
          begin
            LObj := TJSONObject(LArrClientes.Items[I]);
            LQuery.Clear;
            LQuery.Add('UPDATE OR INSERT INTO CLIENTES (CLI_CODIGO, CLI_NOME, CLI_CELULAR, CLI_FONE, CLI_EMAIL, CLI_CIDADE, ');
            LQuery.Add('CLI_UF, CLI_ENDERECO, CLI_BAIRRO, CLI_CEP, CLI_CNPJ_CPF, CLI_RG, CLI_LIMITE) VALUES (:COD, :NOME, :CEL, ');
            LQuery.Add(':TEL, :EMAIL, :CID, :UF, :END, :BAI, :CEP, :CNPJ, :RG, :LIM) MATCHING (CLI_CODIGO)');
            LQuery.AddParam('COD', SafeGetInt(LObj, 'codigo', 0));
            LQuery.AddParam('NOME', SafeGetString(LObj, 'nome'));
            LQuery.AddParam('CEL', SafeGetString(LObj, 'celular'));
            LQuery.AddParam('TEL', SafeGetString(LObj, 'telefone'));
            LQuery.AddParam('EMAIL', SafeGetString(LObj, 'email'));
            LQuery.AddParam('CID', SafeGetString(LObj, 'cidade'));
            LQuery.AddParam('UF', SafeGetString(LObj, 'uf'));
            LQuery.AddParam('END', SafeGetString(LObj, 'endereco'));
            LQuery.AddParam('BAI', SafeGetString(LObj, 'bairro'));
            LQuery.AddParam('CEP', SafeGetString(LObj, 'cep'));
            LQuery.AddParam('CNPJ', SafeGetString(LObj, 'cnpj_cpf'));
            LQuery.AddParam('RG', SafeGetString(LObj, 'rg'));
            LQuery.AddParam('LIM', SafeGetFloat(LObj, 'limite', 0));
            LQuery.ExecSQL;
          end;
          Writeln('-> Sincronizados ' + LArrClientes.Count.ToString + ' clientes da matriz.');
        end;
      except
        on E: Exception do Writeln('-> Erro ao sincronizar clientes: ' + E.Message);
      end;

      LNewSync := LJSON.GetValue<string>('timestamp', '');
      if not LNewSync.IsEmpty then
        FIniFile.WriteString('Sincronia', 'CD_LastSync', LNewSync);

      // Envia confirmacao (ACK) ao CD para baixar os flags CADASTRAR = 'N'
      try
        LURL := TConstants.URL_CD + '/v1/sync/ack';
        FClient.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
        FClient.CustomHeaders['X-Empresa-Id'] := FEmpresaId.ToString;
        FClient.Post(LURL, TStringStream.Create('{}', TEncoding.UTF8));
        Writeln('-> Confirmacao de sincronizacao (ACK) enviada ao CD.');
      except
        on E: Exception do
          Writeln('-> Falha ao enviar ACK ao CD: ' + E.Message);
      end;

    finally
      LJSON.Free;
    end;

  except
    on E: Exception do
      Writeln('-> Exception no pull de pendencias do CD: ' + E.Message);
  end;
end;

procedure TSyncThread.Execute;
var
  LInterval: Integer;
  ICount: Integer;
begin
  LInterval := 10 * 60 * 1000; // 10 minutos
  Sleep(10000); // 10 segundos iniciais

  while not Terminated do
  begin
    try
      LoadConfig;
      if not FCNPJ.IsEmpty then
      begin
        FToken := GenerateJWT;
        Writeln('*** Iniciando Sincronizacao Centralizada (CD) ***');
        EnsureLocalTables;
        
        Writeln('- Enviando dados do Dashboard...');
        SyncDashboard;

        Writeln('- Buscando pendencias da Matriz...');
        SyncDownCD;

        Writeln('*** Sincronizacao Concluida! ***');
      end;
    except
      on E: Exception do
        Writeln('Erros capturados na sincronia: ' + sLineBreak + E.Message);
    end;

    ICount := 0;
    while (ICount < (LInterval div 1000)) and (not Terminated) do
    begin
      Sleep(1000);
      Inc(ICount);
    end;
  end;
end;

{ TSyncService }

class procedure TSyncService.Start;
begin
  if not Assigned(FThread) then
  begin
    FThread := TSyncThread.Create;
    FThread.Start;
    Writeln('* Servico de Sincronia de Dados Inicializado com Sucesso!');
  end;
end;

class procedure TSyncService.Stop;
begin
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FThread.WaitFor;
    FreeAndNil(FThread);
    Writeln('* Servico de Sincronia de Dados Paralisado!');
  end;
end;

initialization

finalization
  TSyncService.Stop;

end.
