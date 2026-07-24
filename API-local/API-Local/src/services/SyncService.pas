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
  UnitDatabase,
  UnitConnection.Model.Interfaces,
  UnitConstants,
  UnitEmpresa.Model,
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
    procedure LoadConfig;
    function GenerateJWT: string;
    procedure EnsureLocalTables;
    procedure SyncDashboard;
    procedure SyncDownCD;
    function QueryDiariosJson(StartDate, EndDate: string): TJSONArray;
    function QueryPagamentosJson(StartDate, EndDate: string): TJSONArray;
    function QueryVendasGrupoJson(StartDate, EndDate: string): TJSONArray;
    function QueryClientesCidadeJson: TJSONArray;
    function QueryVendasHoraJson(StartDate, EndDate: string): TJSONArray;
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

uses UnitOrdens.Model, UnitOrdEst.Model;

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
  LQuery: iQuery;
  Ordens: TOrdens;
  OrdEst: TOrdEst;
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
  except

  end;
  try
    LQuery := TDatabase.Query;
    LQuery.Add('CREATE TABLE CDD_TRANSFERENCIAS (');
    LQuery.Add('  ID INTEGER NOT NULL PRIMARY KEY,');
    LQuery.Add('  CODIGO VARCHAR(40) NOT NULL,');
    LQuery.Add('  STATUS VARCHAR(30) NOT NULL,');
    LQuery.Add('  DATA_CRIACAO VARCHAR(30),');
    LQuery.Add('  DATA_XML VARCHAR(30),');
    LQuery.Add('  DATA_RECEBIMENTO VARCHAR(30),');
    LQuery.Add('  DATA_CANCELAMENTO VARCHAR(30),');
    LQuery.Add('  CONTEUDO_XML BLOB SUB_TYPE TEXT');
    LQuery.Add(')');
    LQuery.ExecSQL;
  except
    // ignore if already exists
  end;

  try
    LQuery := TDatabase.Query;
    LQuery.Clear;
    LQuery.Add('CREATE TABLE CDD_TRANSFERENCIAS_ITENS (');
    LQuery.Add('  ID INTEGER NOT NULL PRIMARY KEY,');
    LQuery.Add('  TRANSFERENCIA_ID INTEGER NOT NULL,');
    LQuery.Add('  PRO_CODIGO INTEGER NOT NULL,');
    LQuery.Add('  QUANTIDADE NUMERIC(15,4) NOT NULL');
    LQuery.Add(')');
    LQuery.ExecSQL;
  except
    // ignore if already exists
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

    LURL := TConstants.URL_CD + '/v1/sync/dashboard';
    LBody := TStringStream.Create(LPayload.ToString, TEncoding.UTF8);
    try
      FClient.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
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
  LArrGrupos, LArrFornecedores, LArrProdutos, LArrTransf, LArrItens: TJSONArray;
  I, J: Integer;
  LQuery: iQuery;
  LTransfId: Integer;
  LXmlVal: TJSONValue;
  LObjItem: TJSONObject;
begin
  LLastSync := FIniFile.ReadString('Sincronia', 'CD_LastSync', '');
  LURL := TConstants.URL_CD + '/v1/sync/pending?last_sync=' + LLastSync;

  try
    FClient.CustomHeaders['Authorization'] := 'Bearer ' + FToken;
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
      LArrGrupos := LJSON.GetValue<TJSONArray>('grupos', nil);
      if Assigned(LArrGrupos) and (LArrGrupos.Count > 0) then
      begin
        LQuery := TDatabase.Query;
        for I := 0 to LArrGrupos.Count - 1 do
        begin
          LObj := TJSONObject(LArrGrupos.Items[I]);
          LQuery.Clear;
          LQuery.Add('UPDATE OR INSERT INTO GRUPOS (GRU_CODIGO, GRU_NOME) VALUES (:COD, :NOME) MATCHING (GRU_CODIGO)');
          LQuery.AddParam('COD', LObj.GetValue<Integer>('gru_codigo'));
          LQuery.AddParam('NOME', LObj.GetValue<string>('gru_nome'));
          LQuery.ExecSQL;
        end;
        Writeln('-> Sincronizados ' + LArrGrupos.Count.ToString + ' grupos da matriz.');
      end;

      // 2. Fornecedores
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
          LQuery.AddParam('COD', LObj.GetValue<Integer>('for_codigo'));
          LQuery.AddParam('NOME', LObj.GetValue<string>('for_nome'));
          LQuery.AddParam('FANTASIA', LObj.GetValue<string>('for_nomefantasia'));
          LQuery.AddParam('CNPJ', LObj.GetValue<string>('for_cnpj_cpf'));
          LQuery.AddParam('IE', LObj.GetValue<string>('for_insc_estadual'));
          LQuery.ExecSQL;
        end;
        Writeln('-> Sincronizados ' + LArrFornecedores.Count.ToString + ' fornecedores da matriz.');
      end;

      // 3. Produtos
      LArrProdutos := LJSON.GetValue<TJSONArray>('produtos', nil);
      if Assigned(LArrProdutos) and (LArrProdutos.Count > 0) then
      begin
        LQuery := TDatabase.Query;
        for I := 0 to LArrProdutos.Count - 1 do
        begin
          LObj := TJSONObject(LArrProdutos.Items[I]);
          LQuery.Clear;
          LQuery.Add('UPDATE OR INSERT INTO PRODUTOS (PRO_CODIGO, PRO_NOME, PRO_DESCRICAO, PRO_CODBARRA, PRO_VALORV, PRO_VALORC, PRO_EMBALAGEM, PRO_FABRICANTE, PRO_GRU, PRO_FOR, PRO_DATAUA)');
          LQuery.Add('VALUES (:COD, :NOME, :DESC, :BARRA, :VALORV, :VALORC, :EMB, :FAB, :GRU, :FOR, :DATAUA) MATCHING (PRO_CODIGO)');
          LQuery.AddParam('COD', LObj.GetValue<Integer>('pro_codigo'));
          LQuery.AddParam('NOME', LObj.GetValue<string>('pro_nome'));
          LQuery.AddParam('DESC', LObj.GetValue<string>('pro_descricao'));
          LQuery.AddParam('BARRA', LObj.GetValue<string>('pro_codbarra'));
          LQuery.AddParam('VALORV', LObj.GetValue<Double>('pro_valorv'));
          LQuery.AddParam('VALORC', LObj.GetValue<Double>('pro_valorc'));
          LQuery.AddParam('EMB', LObj.GetValue<string>('pro_embalagem'));
          LQuery.AddParam('FAB', LObj.GetValue<string>('pro_fabricante'));
          LQuery.AddParam('GRU', LObj.GetValue<Integer>('pro_gru'));
          LQuery.AddParam('FOR', LObj.GetValue<Integer>('pro_for'));
          LQuery.AddParam('DATAUA', LObj.GetValue<string>('pro_dataua'));
          LQuery.ExecSQL;
        end;
        Writeln('-> Sincronizados ' + LArrProdutos.Count.ToString + ' produtos da matriz.');
      end;

      // 4. Transferencias
      LArrTransf := LJSON.GetValue<TJSONArray>('transferencias', nil);
      if Assigned(LArrTransf) and (LArrTransf.Count > 0) then
      begin
        LQuery := TDatabase.Query;
        for I := 0 to LArrTransf.Count - 1 do
        begin
          LObj := TJSONObject(LArrTransf.Items[I]);
          LTransfId := LObj.GetValue<Integer>('id');

          LQuery.Clear;
          LQuery.Add('UPDATE OR INSERT INTO CDD_TRANSFERENCIAS (ID, CODIGO, STATUS, DATA_CRIACAO, DATA_XML, DATA_RECEBIMENTO, DATA_CANCELAMENTO, CONTEUDO_XML)');
          LQuery.Add('VALUES (:ID, :CODIGO, :STATUS, :DATA_CRIACAO, :DATA_XML, :DATA_RECEBIMENTO, :DATA_CANCELAMENTO, :CONTEUDO_XML) MATCHING (ID)');
          LQuery.AddParam('ID', LTransfId);
          LQuery.AddParam('CODIGO', LObj.GetValue<string>('codigo'));
          LQuery.AddParam('STATUS', LObj.GetValue<string>('status'));
          LQuery.AddParam('DATA_CRIACAO', LObj.GetValue<string>('data_criacao'));
          LQuery.AddParam('DATA_XML', LObj.GetValue<string>('data_xml'));
          LQuery.AddParam('DATA_RECEBIMENTO', LObj.GetValue<string>('data_recebimento'));
          LQuery.AddParam('DATA_CANCELAMENTO', LObj.GetValue<string>('data_cancelamento'));

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
              // Simple sequential sub-id generation for items locally
              LQuery.Add('VALUES ((SELECT COALESCE(MAX(ID), 0) + 1 FROM CDD_TRANSFERENCIAS_ITENS), :TID, :PRO_CODIGO, :QUANTIDADE)');
              LQuery.AddParam('TID', LTransfId);
              LQuery.AddParam('PRO_CODIGO', LObjItem.GetValue<Integer>('pro_codigo'));
              LQuery.AddParam('QUANTIDADE', LObjItem.GetValue<Double>('quantidade'));
              LQuery.ExecSQL;
            end;
          end;
        end;
        Writeln('-> Sincronizadas ' + LArrTransf.Count.ToString + ' transferencias da matriz.');
      end;

      LNewSync := LJSON.GetValue<string>('timestamp', '');
      if not LNewSync.IsEmpty then
        FIniFile.WriteString('Sincronia', 'CD_LastSync', LNewSync);

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
