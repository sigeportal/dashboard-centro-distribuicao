unit UnitSync.Controller;

interface

uses
  Horse,
  Horse.Commons,
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.DateUtils;

type
  TSyncController = class
  private
    class function ObterEmpresaId(Req: THorseRequest): Integer; static;
    class function ISOToDate(const AStr: string): TDateTime; static;
  public
    class procedure Router;
    class procedure SyncDashboard(Req: THorseRequest; Res: THorseResponse);
    class procedure SyncPending(Req: THorseRequest; Res: THorseResponse);
    class procedure SyncAck(Req: THorseRequest; Res: THorseResponse);
    class procedure EnsureSyncControlColumns;

    // GET Dashboard handlers
    class procedure ClientesCidade(Req: THorseRequest; Res: THorseResponse);
    class procedure DespesasTipoPagamento(Req: THorseRequest; Res: THorseResponse);
    class procedure VendasMargemLucro(Req: THorseRequest; Res: THorseResponse);
    class procedure OsMargemLucro(Req: THorseRequest; Res: THorseResponse);
    class procedure VendasLucroGrupo(Req: THorseRequest; Res: THorseResponse);
    class procedure TiposPagamentosVendas(Req: THorseRequest; Res: THorseResponse);
    class procedure TiposPagamentosCompras(Req: THorseRequest; Res: THorseResponse);
    class procedure TiposPagamentosRecebimentos(Req: THorseRequest; Res: THorseResponse);
    class procedure TiposPagamentosPagamentos(Req: THorseRequest; Res: THorseResponse);
    class procedure Movimentacoes(Req: THorseRequest; Res: THorseResponse);
    class procedure VendasDiarias(Req: THorseRequest; Res: THorseResponse);
    class procedure VendasDiariasHora(Req: THorseRequest; Res: THorseResponse);
    class procedure OsDiarias(Req: THorseRequest; Res: THorseResponse);
    class procedure EstoquePosicao(Req: THorseRequest; Res: THorseResponse);
    class procedure EnsureEstoqueEmpresaTable;
    class procedure EnsureDashboardTables;
    class procedure SincronizaCadastroEmpresa(AEmpresaObj: TJSONObject; ADefaultEmpresaId: Integer);
  end;

implementation

uses
  FireDAC.Comp.Client,
  UnitDatabase,
  UnitConnection.Model.Interfaces,
  UnitDashboardSync.Model,
  UnitEstoqueEmpresa.Model, UnitFunctions;

{ TSyncController }

class procedure TSyncController.Router;
begin
  THorse.Group
    .Prefix('/v1')
    .Route('/sync/dashboard')
      .Post(SyncDashboard)
    .&End
    .Prefix('/v1')
    .Route('/sync/pending')
      .Get(SyncPending)
    .&End
    .Prefix('/v1')
    .Route('/sync/ack')
      .Post(SyncAck)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/clientes-cidade')
      .Get(ClientesCidade)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/despesas-tipo-pagamento')
      .Get(DespesasTipoPagamento)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/vendas-margem-lucro')
      .Get(VendasMargemLucro)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/os-margem-lucro')
      .Get(OsMargemLucro)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/vendas-lucro-grupo')
      .Get(VendasLucroGrupo)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-vendas')
      .Get(TiposPagamentosVendas)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-compras')
      .Get(TiposPagamentosCompras)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-recebimentos')
      .Get(TiposPagamentosRecebimentos)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-pagamentos')
      .Get(TiposPagamentosPagamentos)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/movimentacoes')
      .Get(Movimentacoes)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/vendas-diarias')
      .Get(VendasDiarias)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/vendas-diarias/hora')
      .Get(VendasDiariasHora)
    .&End
    .Prefix('/v1')
    .Route('/dashboard/os-diarias')
      .Get(OsDiarias)
    .&End
    .Prefix('/v1')
    .Route('/estoque/posicao')
      .Get(EstoquePosicao)
    .&End
    .Prefix('/v1')
    .Route('/posicao-estoque')
      .Get(EstoquePosicao)
    .&End;
end;

class procedure TSyncController.SyncDashboard(Req: THorseRequest; Res: THorseResponse);
var
  LBody, LObj, LEmpresaObj: TJSONObject;
  LArrDiario, LArrPag, LArrGrupo, LArrCidade, LArrHora, LArrEstoque: TJSONArray;
  LQuery: iQuery;
  LEmpresaId, I, cod: Integer;
  LValQtd: Double;
  LDataRefStr, LDataRefSql: string;
  LDeletedDates: TStringList;
begin
  EnsureEstoqueEmpresaTable;
  EnsureDashboardTables;

  LBody := Req.Body<TJSONObject>;
  if not Assigned(LBody) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "Corpo da requisição inválido"}');
    Exit;
  end;

  LEmpresaId := ObterEmpresaId(Req); 
  LQuery := TDatabase.Query;

  try
    // 1. Diarios
    LArrDiario := LBody.GetValue<TJSONArray>('diarios', nil);
    if Assigned(LArrDiario) then
    begin
      for I := 0 to LArrDiario.Count - 1 do
      begin
        LObj := TJSONObject(LArrDiario.Items[I]);
        try
          LDataRefStr := FormatDateTime('yyyy-mm-dd', ISOToDate(LObj.GetValue<string>('data_ref', '')));
          LDataRefSql := QuotedStr(LDataRefStr);

          LQuery.Clear;
          LQuery.Add(Format(
            'UPDATE DASHBOARD_DIARIO SET ' +
            'VENDAS_VALOR = %s, VENDAS_LUCRO = %s, VENDAS_MAIOR = %s, VENDAS_QTD = %d, ' +
            'OS_VALOR = %s, OS_LUCRO = %s, OS_MAIOR = %s, OS_QTD = %d, ' +
            'MOV_CREDITO = %s, MOV_DEBITO = %s ' +
            'WHERE EMPRESA_ID = %d AND DATA_REF = %s',
            [FloatToStr(LObj.GetValue<Double>('vendas_valor', 0)).Replace(',', '.'),
             FloatToStr(LObj.GetValue<Double>('vendas_lucro', 0)).Replace(',', '.'),
             FloatToStr(LObj.GetValue<Double>('vendas_maior', 0)).Replace(',', '.'),
             LObj.GetValue<Integer>('vendas_qtd', 0),
             FloatToStr(LObj.GetValue<Double>('os_valor', 0)).Replace(',', '.'),
             FloatToStr(LObj.GetValue<Double>('os_lucro', 0)).Replace(',', '.'),
             FloatToStr(LObj.GetValue<Double>('os_maior', 0)).Replace(',', '.'),
             LObj.GetValue<Integer>('os_qtd', 0),
             FloatToStr(LObj.GetValue<Double>('mov_credito', 0)).Replace(',', '.'),
             FloatToStr(LObj.GetValue<Double>('mov_debito', 0)).Replace(',', '.'),
             LEmpresaId, LDataRefSql]
          ));
          LQuery.ExecSQL;

          if TFDQuery(LQuery.Query).RowsAffected = 0 then
          begin
            LQuery.Clear;
            LQuery.Add(Format(
              'INSERT INTO DASHBOARD_DIARIO (ID, EMPRESA_ID, DATA_REF, VENDAS_VALOR, VENDAS_LUCRO, VENDAS_MAIOR, VENDAS_QTD, OS_VALOR, OS_LUCRO, OS_MAIOR, OS_QTD, MOV_CREDITO, MOV_DEBITO) ' +
              'VALUES (%d, %d, %s, %s, %s, %s, %d, %s, %s, %s, %d, %s, %s)',
              [GeraCodigo('DASHBOARD_DIARIO', 'ID'), LEmpresaId, LDataRefSql,
               FloatToStr(LObj.GetValue<Double>('vendas_valor', 0)).Replace(',', '.'),
               FloatToStr(LObj.GetValue<Double>('vendas_lucro', 0)).Replace(',', '.'),
               FloatToStr(LObj.GetValue<Double>('vendas_maior', 0)).Replace(',', '.'),
               LObj.GetValue<Integer>('vendas_qtd', 0),
               FloatToStr(LObj.GetValue<Double>('os_valor', 0)).Replace(',', '.'),
               FloatToStr(LObj.GetValue<Double>('os_lucro', 0)).Replace(',', '.'),
               FloatToStr(LObj.GetValue<Double>('os_maior', 0)).Replace(',', '.'),
               LObj.GetValue<Integer>('os_qtd', 0),
               FloatToStr(LObj.GetValue<Double>('mov_credito', 0)).Replace(',', '.'),
               FloatToStr(LObj.GetValue<Double>('mov_debito', 0)).Replace(',', '.')]
            ));
            LQuery.ExecSQL;
          end;
        except
          on E: Exception do Writeln('-> Erro ao salvar DASHBOARD_DIARIO: ' + E.Message);
        end;
      end;
    end;

    // 2. Pagamentos
    LArrPag := LBody.GetValue<TJSONArray>('pagamentos', nil);
    if Assigned(LArrPag) and (LArrPag.Count > 0) then
    begin
      LDeletedDates := TStringList.Create;
      try
        LDeletedDates.Sorted := True;
        LDeletedDates.Duplicates := dupIgnore;

        for I := 0 to LArrPag.Count - 1 do
        begin
          LObj := TJSONObject(LArrPag.Items[I]);
          try
            if (LObj.GetValue<string>('data_ref', '') <> '') then
              LDataRefStr := FormatDateTime('yyyy-mm-dd', ISOToDate(LObj.GetValue<string>('data_ref', '')))
            else
              LDataRefStr := FormatDateTime('yyyy-mm-dd', Date);
            LDataRefSql := QuotedStr(LDataRefStr);

            if LDeletedDates.IndexOf(LDataRefStr) < 0 then
            begin
              LDeletedDates.Add(LDataRefStr);
              LQuery.Clear;
              LQuery.Add(Format('DELETE FROM DASHBOARD_PAGAMENTOS WHERE EMPRESA_ID = %d AND (DATA_REF IS NULL OR DATA_REF = %s)', [LEmpresaId, LDataRefSql]));
              LQuery.ExecSQL;
            end;

            LQuery.Clear;
            LQuery.Add(Format(
              'INSERT INTO DASHBOARD_PAGAMENTOS (ID, EMPRESA_ID, TIPO_REGISTRO, TIPO_OPERACAO, TIPO_PAGAMENTO, VALOR, DATA_REF) VALUES (%d, %d, %s, %s, %s, %s, %s)',
              [GeraCodigo('DASHBOARD_PAGAMENTOS', 'ID'), LEmpresaId,
               QuotedStr(LObj.GetValue<string>('tipo_registro', '')),
               QuotedStr(LObj.GetValue<string>('tipo_operacao', '')),
               QuotedStr(LObj.GetValue<string>('tipo_pagamento', '')),
               FloatToStr(LObj.GetValue<Double>('valor', 0)).Replace(',', '.'),
               LDataRefSql]
            ));
            LQuery.ExecSQL;
          except
            on E: Exception do Writeln('-> Erro ao salvar DASHBOARD_PAGAMENTOS: ' + E.Message);
          end;
        end;
      finally
        LDeletedDates.Free;
      end;
    end;

    // 3. Grupos
    LArrGrupo := LBody.GetValue<TJSONArray>('vendas_grupo', nil);
    if Assigned(LArrGrupo) and (LArrGrupo.Count > 0) then
    begin
      LDeletedDates := TStringList.Create;
      try
        LDeletedDates.Sorted := True;
        LDeletedDates.Duplicates := dupIgnore;

        for I := 0 to LArrGrupo.Count - 1 do
        begin
          LObj := TJSONObject(LArrGrupo.Items[I]);
          try
            if (LObj.GetValue<string>('data_ref', '') <> '') then
              LDataRefStr := FormatDateTime('yyyy-mm-dd', ISOToDate(LObj.GetValue<string>('data_ref', '')))
            else
              LDataRefStr := FormatDateTime('yyyy-mm-dd', Date);
            LDataRefSql := QuotedStr(LDataRefStr);

            if LDeletedDates.IndexOf(LDataRefStr) < 0 then
            begin
              LDeletedDates.Add(LDataRefStr);
              LQuery.Clear;
              LQuery.Add(Format('DELETE FROM DASHBOARD_VENDAS_GRUPO WHERE EMPRESA_ID = %d AND (DATA_REF IS NULL OR DATA_REF = %s)', [LEmpresaId, LDataRefSql]));
              LQuery.ExecSQL;
            end;

            LQuery.Clear;
            LQuery.Add(Format(
              'INSERT INTO DASHBOARD_VENDAS_GRUPO (ID, EMPRESA_ID, NOME_GRUPO, VALOR, LUCRO, DATA_REF) VALUES (%d, %d, %s, %s, %s, %s)',
              [GeraCodigo('DASHBOARD_VENDAS_GRUPO', 'ID'), LEmpresaId,
               QuotedStr(LObj.GetValue<string>('nome_grupo', '')),
               FloatToStr(LObj.GetValue<Double>('valor', 0)).Replace(',', '.'),
               FloatToStr(LObj.GetValue<Double>('lucro', 0)).Replace(',', '.'),
               LDataRefSql]
            ));
            LQuery.ExecSQL;
          except
            on E: Exception do Writeln('-> Erro ao salvar DASHBOARD_VENDAS_GRUPO: ' + E.Message);
          end;
        end;
      finally
        LDeletedDates.Free;
      end;
    end;

    // 4. Clientes Cidade
    LArrCidade := LBody.GetValue<TJSONArray>('clientes_cidade', nil);
    if Assigned(LArrCidade) and (LArrCidade.Count > 0) then
    begin
      LDeletedDates := TStringList.Create;
      try
        LDeletedDates.Sorted := True;
        LDeletedDates.Duplicates := dupIgnore;

        for I := 0 to LArrCidade.Count - 1 do
        begin
          LObj := TJSONObject(LArrCidade.Items[I]);
          try
            if (LObj.GetValue<string>('data_ref', '') <> '') then
              LDataRefStr := FormatDateTime('yyyy-mm-dd', ISOToDate(LObj.GetValue<string>('data_ref', '')))
            else
              LDataRefStr := FormatDateTime('yyyy-mm-dd', Date);
            LDataRefSql := QuotedStr(LDataRefStr);

            if LDeletedDates.IndexOf(LDataRefStr) < 0 then
            begin
              LDeletedDates.Add(LDataRefStr);
              LQuery.Clear;
              LQuery.Add(Format('DELETE FROM DASHBOARD_CLIENTES_CIDADE WHERE EMPRESA_ID = %d AND (DATA_REF IS NULL OR DATA_REF = %s)', [LEmpresaId, LDataRefSql]));
              LQuery.ExecSQL;
            end;

            LQuery.Clear;
            LQuery.Add(Format(
              'INSERT INTO DASHBOARD_CLIENTES_CIDADE (ID, EMPRESA_ID, CIDADE, QUANTIDADE, DATA_REF) VALUES (%d, %d, %s, %d, %s)',
              [GeraCodigo('DASHBOARD_CLIENTES_CIDADE', 'ID'), LEmpresaId,
               QuotedStr(LObj.GetValue<string>('cidade', '')),
               LObj.GetValue<Integer>('quantidade', 0),
               LDataRefSql]
            ));
            LQuery.ExecSQL;
          except
            on E: Exception do Writeln('-> Erro ao salvar DASHBOARD_CLIENTES_CIDADE: ' + E.Message);
          end;
        end;
      finally
        LDeletedDates.Free;
      end;
    end;

    // 5. Vendas Hora
    LArrHora := LBody.GetValue<TJSONArray>('vendas_hora', nil);
    if Assigned(LArrHora) and (LArrHora.Count > 0) then
    begin
      LDeletedDates := TStringList.Create;
      try
        LDeletedDates.Sorted := True;
        LDeletedDates.Duplicates := dupIgnore;

        for I := 0 to LArrHora.Count - 1 do
        begin
          LObj := TJSONObject(LArrHora.Items[I]);
          try
            if (LObj.GetValue<string>('data_ref', '') <> '') then
              LDataRefStr := FormatDateTime('yyyy-mm-dd', ISOToDate(LObj.GetValue<string>('data_ref', '')))
            else
              LDataRefStr := FormatDateTime('yyyy-mm-dd', Date);
            LDataRefSql := QuotedStr(LDataRefStr);

            if LDeletedDates.IndexOf(LDataRefStr) < 0 then
            begin
              LDeletedDates.Add(LDataRefStr);
              LQuery.Clear;
              LQuery.Add(Format('DELETE FROM DASHBOARD_VENDAS_HORA WHERE EMPRESA_ID = %d AND (DATA_REF IS NULL OR DATA_REF = %s)', [LEmpresaId, LDataRefSql]));
              LQuery.ExecSQL;
            end;

            LQuery.Clear;
            LQuery.Add(Format(
              'INSERT INTO DASHBOARD_VENDAS_HORA (ID, EMPRESA_ID, HORA, VALOR, DATA_REF) VALUES (%d, %d, %s, %s, %s)',
              [GeraCodigo('DASHBOARD_VENDAS_HORA', 'ID'), LEmpresaId,
               QuotedStr(LObj.GetValue<string>('hora', '')),
               FloatToStr(LObj.GetValue<Double>('valor', 0)).Replace(',', '.'),
               LDataRefSql]
            ));
            LQuery.ExecSQL;
          except
            on E: Exception do Writeln('-> Erro ao salvar DASHBOARD_VENDAS_HORA: ' + E.Message);
          end;
        end;
      finally
        LDeletedDates.Free;
      end;
    end;

    // 6. Estoque por Empresa / Filial (Super Otimizado com UPDATE primario e INSERT fallback)
    EnsureEstoqueEmpresaTable;
    LArrEstoque := LBody.GetValue<TJSONArray>('estoque', nil);
    if Assigned(LArrEstoque) and (LArrEstoque.Count > 0) then
    begin
      for I := 0 to LArrEstoque.Count - 1 do
      begin
        LObj := TJSONObject(LArrEstoque.Items[I]);
        try
          if LObj.TryGetValue('pro_codigo', cod) then
          begin
            LQuery.Clear;
            LQuery.Add(Format(
              'UPDATE ESTOQUE_EMPRESA SET EE_QUANTIDADE = %s, EE_DATA_ATUALIZACAO = CURRENT_TIMESTAMP WHERE EE_EMPRESA_ID = %d AND EE_PRO_CODIGO = %d',
              [FloatToStr(LObj.GetValue<Double>('quantidade', 0)).Replace(',', '.'), LEmpresaId, LObj.GetValue<Integer>('pro_codigo')]
            ));
            LQuery.ExecSQL;

            if TFDQuery(LQuery.Query).RowsAffected = 0 then
            begin
              LQuery.Clear;
              LQuery.Add(Format(
                'INSERT INTO ESTOQUE_EMPRESA (EE_ID, EE_EMPRESA_ID, EE_PRO_CODIGO, EE_QUANTIDADE, EE_DATA_ATUALIZACAO) VALUES (%d, %d, %d, %s, CURRENT_TIMESTAMP)',
                [GeraCodigo('ESTOQUE_EMPRESA', 'EE_ID'), LEmpresaId, LObj.GetValue<Integer>('pro_codigo'), FloatToStr(LObj.GetValue<Double>('quantidade', 0)).Replace(',', '.')]
              ));
              LQuery.ExecSQL;
            end;
          end;
        except
          on E: Exception do
            Writeln('-> Erro ao salvar ESTOQUE_EMPRESA no sync: ' + E.Message);
        end;
      end;
    end;

    // 7. Dados Cadastrais da Empresa (Identificado e comparado pelo EMP_CNPJ)
    LEmpresaObj := LBody.GetValue<TJSONObject>('empresa', nil);
    if Assigned(LEmpresaObj) then
    begin
      try
        SincronizaCadastroEmpresa(LEmpresaObj, LEmpresaId);
      except
        on E: Exception do
          Writeln('-> Erro ao sincronizar dados da EMPRESA no CD: ' + E.Message);
      end;
    end;

    Writeln(Format('[CD Server] SyncDashboard: Dados do dashboard salvos com sucesso para a Empresa EMP_ID = %d.', [LEmpresaId]));
    Res.Status(THTTPStatus.OK).Send('{"status": "ok"}');
  except
    on E: Exception do
    begin
      Writeln('-> Erro no SyncDashboard: ' + E.Message);
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.SincronizaCadastroEmpresa(AEmpresaObj: TJSONObject; ADefaultEmpresaId: Integer);
var
  LQuery: iQuery;
  LCNPJ, LCNPJLimpo: string;
  LEmpCodigo: Integer;

  function ValStr(const AKey: string; const AMaxLen: Integer = 0): string;
  var
    S: string;
  begin
    S := '';
    if Assigned(AEmpresaObj.GetValue(AKey)) and not AEmpresaObj.GetValue(AKey).InheritsFrom(TJSONNull) then
      S := AEmpresaObj.GetValue<string>(AKey, '')
    else if Assigned(AEmpresaObj.GetValue(LowerCase(AKey))) and not AEmpresaObj.GetValue(LowerCase(AKey)).InheritsFrom(TJSONNull) then
      S := AEmpresaObj.GetValue<string>(LowerCase(AKey), '')
    else if Assigned(AEmpresaObj.GetValue(UpperCase(AKey))) and not AEmpresaObj.GetValue(UpperCase(AKey)).InheritsFrom(TJSONNull) then
      S := AEmpresaObj.GetValue<string>(UpperCase(AKey), '');

    if (AMaxLen > 0) and (Length(S) > AMaxLen) then
      S := Copy(S, 1, AMaxLen);
    Result := S;
  end;

  function ValInt(const AKey: string; ADefault: Integer = 0): Integer;
  begin
    Result := ADefault;
    if Assigned(AEmpresaObj.GetValue(AKey)) and not AEmpresaObj.GetValue(AKey).InheritsFrom(TJSONNull) then
      Result := AEmpresaObj.GetValue<Integer>(AKey, ADefault)
    else if Assigned(AEmpresaObj.GetValue(LowerCase(AKey))) and not AEmpresaObj.GetValue(LowerCase(AKey)).InheritsFrom(TJSONNull) then
      Result := AEmpresaObj.GetValue<Integer>(LowerCase(AKey), ADefault);
  end;

begin
  if not Assigned(AEmpresaObj) then Exit;

  LCNPJ := ValStr('emp_cnpj', 18);
  if LCNPJ.IsEmpty then
    LCNPJ := ValStr('cnpj', 18);

  if LCNPJ.IsEmpty then Exit;

  LCNPJLimpo := LCNPJ.Replace('.', '').Replace('/', '').Replace('-', '').Replace(' ', '');
  
  LQuery := TDatabase.Query;
  LEmpCodigo := 0;

  // Busca se a empresa já existe no CD pelo EMP_CNPJ (formatado ou limpo)
  LQuery.Clear;
  LQuery.Add(Format(
    'SELECT FIRST 1 EMP_CODIGO, EMP_CNPJ FROM EMPRESA ' +
    'WHERE EMP_CNPJ = %s OR REPLACE(REPLACE(REPLACE(REPLACE(EMP_CNPJ, ''.'', ''''), ''/'', ''''), ''-'', ''''), '' '', '''') = %s',
    [QuotedStr(LCNPJ), QuotedStr(LCNPJLimpo)]
  ));
  LQuery.Open;

  if not LQuery.DataSet.Eof then
    LEmpCodigo := LQuery.DataSet.FieldByName('EMP_CODIGO').AsInteger;

  if LEmpCodigo > 0 then
  begin
    // UPDATE por EMP_CODIGO / EMP_CNPJ
    LQuery.Clear;
    LQuery.Add('UPDATE EMPRESA SET ');
    LQuery.Add('  EMP_CNPJ = ' + QuotedStr(LCNPJ) + ', ');
    LQuery.Add('  EMP_INSCEST = ' + QuotedStr(ValStr('emp_inscest', 20)) + ', ');
    LQuery.Add('  EMP_RAZAO_SOCIAL = ' + QuotedStr(ValStr('emp_razao_social', 50)) + ', ');
    LQuery.Add('  EMP_MUNICIPIO = ' + QuotedStr(ValStr('emp_municipio', 50)) + ', ');
    LQuery.Add('  EMP_UF = ' + QuotedStr(ValStr('emp_uf', 2)) + ', ');
    LQuery.Add('  EMP_FONE = ' + QuotedStr(ValStr('emp_fone', 13)) + ', ');
    LQuery.Add('  EMP_FAX = ' + QuotedStr(ValStr('emp_fax', 13)) + ', ');
    LQuery.Add('  EMP_LOGRADOURO = ' + QuotedStr(ValStr('emp_logradouro', 50)) + ', ');
    LQuery.Add('  EMP_NUMERO = ' + QuotedStr(ValStr('emp_numero', 10)) + ', ');
    LQuery.Add('  EMP_COMPLEMENTO = ' + QuotedStr(ValStr('emp_complemento', 50)) + ', ');
    LQuery.Add('  EMP_BAIRRO = ' + QuotedStr(ValStr('emp_bairro', 30)) + ', ');
    LQuery.Add('  EMP_CEP = ' + QuotedStr(ValStr('emp_cep', 10)) + ', ');
    LQuery.Add('  EMP_CONTATO = ' + QuotedStr(ValStr('emp_contato', 30)) + ', ');
    LQuery.Add('  EMP_CODMUN_IBGE = ' + QuotedStr(ValStr('emp_codmun_ibge', 10)) + ', ');
    LQuery.Add('  EMP_CODUF_IBGE = ' + QuotedStr(ValStr('emp_coduf_ibge', 10)) + ', ');
    LQuery.Add('  EMP_FANTASIA = ' + QuotedStr(ValStr('emp_fantasia', 100)) + ', ');
    LQuery.Add('  EMP_CRT = ' + QuotedStr(ValStr('emp_crt', 1)) + ', ');
    LQuery.Add('  EMP_SUFRAMA = ' + QuotedStr(ValStr('emp_suframa', 9)) + ', ');
    LQuery.Add('  EMP_PERFIL = ' + QuotedStr(ValStr('emp_perfil', 1)) + ', ');
    LQuery.Add('  EMP_ATIVIDADE = ' + QuotedStr(ValStr('emp_atividade', 1)) + ', ');
    LQuery.Add('  EMP_EMAIL = ' + QuotedStr(ValStr('emp_email', 50)) + ', ');
    LQuery.Add('  EMP_TITULO1 = ' + QuotedStr(ValStr('emp_titulo1', 100)) + ', ');
    LQuery.Add('  EMP_TITULO2 = ' + QuotedStr(ValStr('emp_titulo2', 100)) + ', ');
    LQuery.Add('  EMP_TITULO3 = ' + QuotedStr(ValStr('emp_titulo3', 100)) + ', ');
    LQuery.Add('  EMP_MD5 = ' + QuotedStr(ValStr('emp_md5', 50)) + ', ');
    LQuery.Add('  EMP_LICENCA = ' + QuotedStr(ValStr('emp_licenca', 20)) + ', ');
    LQuery.Add('  EMP_LICENCA_DLL_NFE = ' + QuotedStr(ValStr('emp_licenca_dll_nfe', 200)) + ', ');
    LQuery.Add('  EMP_ID_CSC = ' + QuotedStr(ValStr('emp_id_csc', 10)) + ', ');
    LQuery.Add('  EMP_CSC = ' + QuotedStr(ValStr('emp_csc', 50)) + ', ');
    LQuery.Add('  EMP_INSCMUN = ' + QuotedStr(ValStr('emp_inscmun', 20)) + ', ');
    LQuery.Add('  EMP_RNTRC = ' + QuotedStr(ValStr('emp_rntrc', 10)) + ', ');
    LQuery.Add('  EMP_LICENCA_DLL_MDF = ' + QuotedStr(ValStr('emp_licenca_dll_mdf', 200)) + ', ');
    LQuery.Add('  EMP_TIPO_ATIVIDADE = ' + QuotedStr(ValStr('emp_tipo_atividade', 2)) + ', ');
    LQuery.Add('  EMP_IND_NAT_PJ = ' + QuotedStr(ValStr('emp_ind_nat_pj', 2)) + ', ');
    LQuery.Add('  EMP_LOGO = ' + QuotedStr(ValStr('emp_logo', 1000)) + ', ');
    LQuery.Add('  EMP_CNAE = ' + QuotedStr(ValStr('emp_cnae', 10)) + ', ');
    LQuery.Add('  EMP_CC_CODIGO = ' + ValInt('emp_cc_codigo', 0).ToString + ' ');
    LQuery.Add('WHERE EMP_CODIGO = ' + LEmpCodigo.ToString);
    LQuery.ExecSQL;
    Writeln(Format('[CD Server] Empresa CNPJ %s atualizada com sucesso no CD (EMP_CODIGO = %d).', [LCNPJ, LEmpCodigo]));
  end
  else
  begin
    // INSERT novo registro
    if ADefaultEmpresaId > 0 then
      LEmpCodigo := ADefaultEmpresaId
    else
      LEmpCodigo := GeraCodigo('EMPRESA', 'EMP_CODIGO');

    LQuery.Clear;
    LQuery.Add('INSERT INTO EMPRESA (');
    LQuery.Add('  EMP_CODIGO, EMP_CNPJ, EMP_INSCEST, EMP_RAZAO_SOCIAL, EMP_MUNICIPIO, EMP_UF, ');
    LQuery.Add('  EMP_FONE, EMP_FAX, EMP_LOGRADOURO, EMP_NUMERO, EMP_COMPLEMENTO, EMP_BAIRRO, ');
    LQuery.Add('  EMP_CEP, EMP_CONTATO, EMP_CODMUN_IBGE, EMP_CODUF_IBGE, EMP_FANTASIA, EMP_CRT, ');
    LQuery.Add('  EMP_SUFRAMA, EMP_PERFIL, EMP_ATIVIDADE, EMP_EMAIL, EMP_TITULO1, EMP_TITULO2, ');
    LQuery.Add('  EMP_TITULO3, EMP_MD5, EMP_LICENCA, EMP_LICENCA_DLL_NFE, EMP_ID_CSC, EMP_CSC, ');
    LQuery.Add('  EMP_INSCMUN, EMP_RNTRC, EMP_LICENCA_DLL_MDF, EMP_TIPO_ATIVIDADE, EMP_IND_NAT_PJ, ');
    LQuery.Add('  EMP_LOGO, EMP_CNAE, EMP_CC_CODIGO');
    LQuery.Add(') VALUES (');
    LQuery.Add(Format(
      '  %d, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %d',
      [LEmpCodigo,
       QuotedStr(LCNPJ),
       QuotedStr(ValStr('emp_inscest', 20)),
       QuotedStr(ValStr('emp_razao_social', 50)),
       QuotedStr(ValStr('emp_municipio', 50)),
       QuotedStr(ValStr('emp_uf', 2)),
       QuotedStr(ValStr('emp_fone', 13)),
       QuotedStr(ValStr('emp_fax', 13)),
       QuotedStr(ValStr('emp_logradouro', 50)),
       QuotedStr(ValStr('emp_numero', 10)),
       QuotedStr(ValStr('emp_complemento', 50)),
       QuotedStr(ValStr('emp_bairro', 30)),
       QuotedStr(ValStr('emp_cep', 10)),
       QuotedStr(ValStr('emp_contato', 30)),
       QuotedStr(ValStr('emp_codmun_ibge', 10)),
       QuotedStr(ValStr('emp_coduf_ibge', 10)),
       QuotedStr(ValStr('emp_fantasia', 100)),
       QuotedStr(ValStr('emp_crt', 1)),
       QuotedStr(ValStr('emp_suframa', 9)),
       QuotedStr(ValStr('emp_perfil', 1)),
       QuotedStr(ValStr('emp_atividade', 1)),
       QuotedStr(ValStr('emp_email', 50)),
       QuotedStr(ValStr('emp_titulo1', 100)),
       QuotedStr(ValStr('emp_titulo2', 100)),
       QuotedStr(ValStr('emp_titulo3', 100)),
       QuotedStr(ValStr('emp_md5', 50)),
       QuotedStr(ValStr('emp_licenca', 20)),
       QuotedStr(ValStr('emp_licenca_dll_nfe', 200)),
       QuotedStr(ValStr('emp_id_csc', 10)),
       QuotedStr(ValStr('emp_csc', 50)),
       QuotedStr(ValStr('emp_inscmun', 20)),
       QuotedStr(ValStr('emp_rntrc', 10)),
       QuotedStr(ValStr('emp_licenca_dll_mdf', 200)),
       QuotedStr(ValStr('emp_tipo_atividade', 2)),
       QuotedStr(ValStr('emp_ind_nat_pj', 2)),
       QuotedStr(ValStr('emp_logo', 1000)),
       QuotedStr(ValStr('emp_cnae', 10)),
       ValInt('emp_cc_codigo', 0)]
    ));
    LQuery.Add(')');
    LQuery.ExecSQL;
    Writeln(Format('[CD Server] Nova empresa cadastrada no CD via sync CNPJ %s (EMP_CODIGO = %d).', [LCNPJ, LEmpCodigo]));
  end;
end;

class procedure TSyncController.EnsureSyncControlColumns;
begin
  // O PortalORM gerencia automaticamente a criação de campos e colunas no banco de dados através dos modelos TTabela.
end;

class procedure TSyncController.SyncAck(Req: THorseRequest; Res: THorseResponse);
var
  LQueryExec: iQuery;
begin
  EnsureSyncControlColumns;
  LQueryExec := TDatabase.Query;
  try LQueryExec.Clear; LQueryExec.Add('UPDATE PRODUTOS SET PRO_CADASTRAR = ''N'' WHERE PRO_CADASTRAR = ''S'' OR PRO_CADASTRAR IS NULL'); LQueryExec.ExecSQL; except end;
  try LQueryExec.Clear; LQueryExec.Add('UPDATE GRUPO_1 SET G1_CADASTRAR = ''N'' WHERE G1_CADASTRAR = ''S'' OR G1_CADASTRAR IS NULL'); LQueryExec.ExecSQL; except end;
  try LQueryExec.Clear; LQueryExec.Add('UPDATE GRUPOS SET GRU_CADASTRAR = ''N'' WHERE GRU_CADASTRAR = ''S'' OR GRU_CADASTRAR IS NULL'); LQueryExec.ExecSQL; except end;
  try LQueryExec.Clear; LQueryExec.Add('UPDATE FORNECEDORES SET FOR_CADASTRAR = ''N'' WHERE FOR_CADASTRAR = ''S'' OR FOR_CADASTRAR IS NULL'); LQueryExec.ExecSQL; except end;
  try LQueryExec.Clear; LQueryExec.Add('UPDATE GRADES SET GRA_CADASTRAR = ''N'' WHERE GRA_CADASTRAR = ''S'' OR GRA_CADASTRAR IS NULL'); LQueryExec.ExecSQL; except end;
  try LQueryExec.Clear; LQueryExec.Add('UPDATE TAMANHOS SET TAM_CADASTRAR = ''N'' WHERE TAM_CADASTRAR = ''S'' OR TAM_CADASTRAR IS NULL'); LQueryExec.ExecSQL; except end;
  try LQueryExec.Clear; LQueryExec.Add('UPDATE TRANSFERENCIA SET TR_CADASTRAR = ''N'' WHERE TR_CADASTRAR = ''S'' OR TR_CADASTRAR IS NULL'); LQueryExec.ExecSQL; except end;
  try LQueryExec.Clear; LQueryExec.Add('UPDATE CLIENTES SET CLI_CADASTRAR = ''N'' WHERE CLI_CADASTRAR = ''S'' OR CLI_CADASTRAR IS NULL'); LQueryExec.ExecSQL; except end;

  Res.Status(THTTPStatus.OK).Send('{"status": "acknowledged"}');
end;

class procedure TSyncController.SyncPending(Req: THorseRequest; Res: THorseResponse);
var
  LResponse: TJSONObject;
  LGrupos: TJSONArray;
  LFornecedores: TJSONArray;
  LProdutos: TJSONArray;
  LTransferencias: TJSONArray;
  LQuery, LQueryItens: iQuery;
  LObj, LItemObj: TJSONObject;
  LArrItens: TJSONArray;
  LTransfId, LEmpresaId: Integer;
  LSubgrupos, LGrades, LTamanhos, LModelos: TJSONArray;
  LCargaInicial, LLastSync: string;
  LIsCargaInicial: Boolean;
begin
  EnsureSyncControlColumns;
  LEmpresaId := ObterEmpresaId(Req);
  
  LCargaInicial := '';
  if Req.Query.ContainsKey('carga_inicial') then
    LCargaInicial := Req.Query.Items['carga_inicial'];
    
  LLastSync := '';
  if Req.Query.ContainsKey('last_sync') then
    LLastSync := Req.Query.Items['last_sync'];

  LIsCargaInicial := (LCargaInicial = 'S') or (LCargaInicial = 's') or (LCargaInicial = '1') or (LLastSync = '') or (Req.Query.ContainsKey('full') and (Req.Query.Items['full'] = 'S'));

  Writeln(Format('[CD Server] SyncPending: Pendencias enviadas para Empresa EMP_ID = %d (CargaInicial = %s).', [LEmpresaId, BoolToStr(LIsCargaInicial, True)]));
  
  LResponse := TJSONObject.Create;
  LGrupos := TJSONArray.Create;
  LFornecedores := TJSONArray.Create;
  LProdutos := TJSONArray.Create;
  LTransferencias := TJSONArray.Create;
  LModelos := TJSONArray.Create;

  LQuery := TDatabase.Query;
  try
    // 1. Grupos (GRUPO_1)
    LQuery.Clear;
    if LIsCargaInicial then
      LQuery.Open('SELECT G1_CODIGO, G1_NOME FROM GRUPO_1 ORDER BY G1_CODIGO')
    else
      LQuery.Open('SELECT G1_CODIGO, G1_NOME FROM GRUPO_1 WHERE G1_CADASTRAR IS NULL OR G1_CADASTRAR = ''S'' ORDER BY G1_CODIGO');
    while not LQuery.DataSet.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('gru_codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('G1_CODIGO').AsInteger));
      LObj.AddPair('gru_nome', LQuery.DataSet.FieldByName('G1_NOME').AsString);
      LGrupos.AddElement(LObj);
      LQuery.DataSet.Next;
    end;

    // 2. Fornecedores
    LQuery.Clear;
    if LIsCargaInicial then
      LQuery.Open('SELECT FOR_CODIGO, FOR_NOME, FOR_FANTASIA, FOR_CNPJ_CPF, FOR_INSC_ESTADUAL, FOR_FONE, FOR_EMAIL, FOR_ENDERECO, FOR_BAIRRO, FOR_CID, FOR_UF, FOR_CONTATO FROM FORNECEDORES ORDER BY FOR_CODIGO')
    else
      LQuery.Open('SELECT FOR_CODIGO, FOR_NOME, FOR_FANTASIA, FOR_CNPJ_CPF, FOR_INSC_ESTADUAL, FOR_FONE, FOR_EMAIL, FOR_ENDERECO, FOR_BAIRRO, FOR_CID, FOR_UF, FOR_CONTATO FROM FORNECEDORES WHERE FOR_CADASTRAR IS NULL OR FOR_CADASTRAR = ''S'' ORDER BY FOR_CODIGO');
    while not LQuery.DataSet.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('for_codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('FOR_CODIGO').AsInteger));
      LObj.AddPair('for_nome', LQuery.DataSet.FieldByName('FOR_NOME').AsString);
      LObj.AddPair('for_nomefantasia', LQuery.DataSet.FieldByName('FOR_FANTASIA').AsString);
      LObj.AddPair('for_cnpj_cpf', LQuery.DataSet.FieldByName('FOR_CNPJ_CPF').AsString);
      LObj.AddPair('for_insc_estadual', LQuery.DataSet.FieldByName('FOR_INSC_ESTADUAL').AsString);
      LObj.AddPair('for_fone', LQuery.DataSet.FieldByName('FOR_FONE').AsString);
      LObj.AddPair('for_email', LQuery.DataSet.FieldByName('FOR_EMAIL').AsString);
      LObj.AddPair('for_endereco', LQuery.DataSet.FieldByName('FOR_ENDERECO').AsString);
      LObj.AddPair('for_bairro', LQuery.DataSet.FieldByName('FOR_BAIRRO').AsString);
      LObj.AddPair('for_cid', TJSONNumber.Create(LQuery.DataSet.FieldByName('FOR_CID').AsInteger));
      LObj.AddPair('for_uf', LQuery.DataSet.FieldByName('FOR_UF').AsString);
      LObj.AddPair('for_contato', LQuery.DataSet.FieldByName('FOR_CONTATO').AsString);
      LFornecedores.AddElement(LObj);
      LQuery.DataSet.Next;
    end;

    // 3. Modelos
    LQuery.Clear;
    try
      if LIsCargaInicial then
        LQuery.Open('SELECT MOD_CODIGO, MOD_NOME FROM MODELOS ORDER BY MOD_CODIGO')
      else
        LQuery.Open('SELECT MOD_CODIGO, MOD_NOME FROM MODELOS WHERE MOD_CADASTRAR IS NULL OR MOD_CADASTRAR = ''S'' ORDER BY MOD_CODIGO');
      while not LQuery.DataSet.Eof do
      begin
        LObj := TJSONObject.Create;
        LObj.AddPair('codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('MOD_CODIGO').AsInteger));
        LObj.AddPair('nome', LQuery.DataSet.FieldByName('MOD_NOME').AsString);
        LModelos.AddElement(LObj);
        LQuery.DataSet.Next;
      end;
    except
      // Se tabela modelos não existir no momento
    end;

    // 4. Produtos
    LQuery.Clear;
    LQuery.Add('SELECT P.PRO_CODIGO, P.PRO_NOME, P.PRO_DESCRICAO, P.PRO_CODBARRA, P.PRO_VALORV, P.PRO_VALOR_DINHEIRO, P.PRO_VALORV_PRAZO, P.PRO_VALORC, P.PRO_EMBALAGEM, P.PRO_FABRICANTE, P.PRO_GRU, P.PRO_FOR,');
    LQuery.Add('P.PRO_EMP, P.PRO_TOTALIZADOR, P.PRO_NCM, P.PRO_UM, COALESCE((SELECT SUM(G.GRA_QUANTIDADE) FROM GRADES G WHERE G.GRA_PRO = P.PRO_CODIGO), P.PRO_QUANTIDADE, 0) AS PRO_QUANTIDADE, P.PRO_DATAUA FROM PRODUTOS P ');
    if LIsCargaInicial then
      LQuery.Add('WHERE P.PRO_ESTADO = ''ATIVO'' OR P.PRO_ESTADO IS NULL ORDER BY P.PRO_CODIGO')
    else
      LQuery.Add('WHERE P.PRO_CADASTRAR IS NULL OR P.PRO_CADASTRAR = ''S'' ORDER BY P.PRO_CODIGO');
    LQuery.Open();
    while not LQuery.DataSet.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('pro_codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_CODIGO').AsInteger));
      LObj.AddPair('pro_emp', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_EMP').AsInteger));
      LObj.AddPair('pro_nome', LQuery.DataSet.FieldByName('PRO_NOME').AsString);
      LObj.AddPair('pro_descricao', LQuery.DataSet.FieldByName('PRO_DESCRICAO').AsString);
      LObj.AddPair('pro_codbarra', LQuery.DataSet.FieldByName('PRO_CODBARRA').AsString);
      LObj.AddPair('pro_valorv', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_VALORV').AsFloat));
      LObj.AddPair('pro_valor_dinheiro', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_VALOR_DINHEIRO').AsFloat));
      LObj.AddPair('pro_valorv_prazo', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_VALORV_PRAZO').AsFloat));
      LObj.AddPair('pro_valorc', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_VALORC').AsFloat));
      LObj.AddPair('pro_embalagem', LQuery.DataSet.FieldByName('PRO_EMBALAGEM').AsString);
      LObj.AddPair('pro_fabricante', LQuery.DataSet.FieldByName('PRO_FABRICANTE').AsString);
      LObj.AddPair('pro_gru', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_GRU').AsInteger));
      LObj.AddPair('pro_for', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_FOR').AsInteger));
      LObj.AddPair('pro_totalizador', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_TOTALIZADOR').AsInteger));
      LObj.AddPair('codTotalizador', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_TOTALIZADOR').AsInteger));
      LObj.AddPair('pro_ncm', LQuery.DataSet.FieldByName('PRO_NCM').AsString);
      LObj.AddPair('ncm', LQuery.DataSet.FieldByName('PRO_NCM').AsString);
      LObj.AddPair('pro_um', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_UM').AsInteger));
      LObj.AddPair('um', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_UM').AsInteger));
      LObj.AddPair('pro_quantidade', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_QUANTIDADE').AsFloat));
      LObj.AddPair('preservar_estoque_local', TJSONBool.Create(not LIsCargaInicial));
      if LQuery.DataSet.FieldByName('PRO_DATAUA').IsNull then
        LObj.AddPair('pro_dataua', '')
      else
        LObj.AddPair('pro_dataua', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('PRO_DATAUA').AsDateTime));
      LProdutos.AddElement(LObj);
      LQuery.DataSet.Next;
    end;

    // 5. Transferencias
    LQuery.Clear;
    if LIsCargaInicial then
      LQuery.Open('SELECT TR_ID, TR_STATUS, TR_DATA, TR_DATA_RECEBIMENTO, TR_OBS FROM TRANSFERENCIA ORDER BY TR_ID')
    else
      LQuery.Open('SELECT TR_ID, TR_STATUS, TR_DATA, TR_DATA_RECEBIMENTO, TR_OBS FROM TRANSFERENCIA WHERE TR_CADASTRAR IS NULL OR TR_CADASTRAR = ''S'' ORDER BY TR_ID');
    LQueryItens := TDatabase.Query;
    try
      while not LQuery.DataSet.Eof do
      begin
        LTransfId := LQuery.DataSet.FieldByName('TR_ID').AsInteger;
        LObj := TJSONObject.Create;
        LObj.AddPair('id', TJSONNumber.Create(LTransfId));
        LObj.AddPair('codigo', LTransfId.ToString);
        LObj.AddPair('status', LQuery.DataSet.FieldByName('TR_STATUS').AsString);
        
        if LQuery.DataSet.FieldByName('TR_DATA').IsNull then
          LObj.AddPair('data_criacao', '')
        else
          LObj.AddPair('data_criacao', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('TR_DATA').AsDateTime));

        LObj.AddPair('data_xml', '');

        if LQuery.DataSet.FieldByName('TR_DATA_RECEBIMENTO').IsNull then
          LObj.AddPair('data_recebimento', '')
        else
          LObj.AddPair('data_recebimento', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('TR_DATA_RECEBIMENTO').AsDateTime));

        LObj.AddPair('data_cancelamento', '');
        LObj.AddPair('conteudo_xml', TJSONNull.Create);

        // Itens da transferencia
        LArrItens := TJSONArray.Create;
        LQueryItens.Clear;
        LQueryItens.Open('SELECT TRI_PRODUTO_ID, TRI_QUANTIDADE FROM TRANSFERENCIA_ITEM WHERE TRI_TRANSFERENCIA_ID = ' + LTransfId.ToString);
        while not LQueryItens.DataSet.Eof do
        begin
          LItemObj := TJSONObject.Create;
          LItemObj.AddPair('pro_codigo', TJSONNumber.Create(LQueryItens.DataSet.FieldByName('TRI_PRODUTO_ID').AsInteger));
          LItemObj.AddPair('quantidade', TJSONNumber.Create(LQueryItens.DataSet.FieldByName('TRI_QUANTIDADE').AsFloat));
          LArrItens.AddElement(LItemObj);
          LQueryItens.DataSet.Next;
        end;
        LObj.AddPair('itens', LArrItens);

        LTransferencias.AddElement(LObj);
        LQuery.DataSet.Next;
      end;
    finally
      // LQueryItens is interface managed
    end;

    LResponse.AddPair('grupos', LGrupos);
    LResponse.AddPair('fornecedores', LFornecedores);
    LResponse.AddPair('modelos', LModelos);
    LResponse.AddPair('produtos', LProdutos);
    LResponse.AddPair('transferencias', LTransferencias);

    // 6. Subgrupos
    LQuery.Clear;
    if LIsCargaInicial then
      LQuery.Open('SELECT GRU_CODIGO, GRU_NOME, GRU_G1, GRU_TR FROM GRUPOS ORDER BY GRU_CODIGO')
    else
      LQuery.Open('SELECT GRU_CODIGO, GRU_NOME, GRU_G1, GRU_TR FROM GRUPOS WHERE GRU_CADASTRAR IS NULL OR GRU_CADASTRAR = ''S'' ORDER BY GRU_CODIGO');
    LSubgrupos := TJSONArray.Create;
    while not LQuery.DataSet.Eof do
    begin
      LItemObj := TJSONObject.Create;
      LItemObj.AddPair('codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRU_CODIGO').AsInteger));
      LItemObj.AddPair('nome', LQuery.DataSet.FieldByName('GRU_NOME').AsString);
      LItemObj.AddPair('g1', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRU_G1').AsInteger));
      LItemObj.AddPair('tr', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRU_TR').AsInteger));
      LSubgrupos.AddElement(LItemObj);
      LQuery.DataSet.Next;
    end;
    LResponse.AddPair('subgrupos', LSubgrupos);

    // 7. Grades
    LQuery.Clear;
    if LIsCargaInicial then
      LQuery.Open('SELECT GRA_CODIGO, GRA_PRO, GRA_VALOR, GRA_VALOR_DINHEIRO, GRA_VALOR_PRAZO, GRA_TAM, GRA_QUANTIDADE, GRA_CODBARRA, GRA_COR FROM GRADES ORDER BY GRA_CODIGO')
    else
      LQuery.Open('SELECT GRA_CODIGO, GRA_PRO, GRA_VALOR, GRA_VALOR_DINHEIRO, GRA_VALOR_PRAZO, GRA_TAM, GRA_QUANTIDADE, GRA_CODBARRA, GRA_COR FROM GRADES WHERE GRA_CADASTRAR IS NULL OR GRA_CADASTRAR = ''S'' ORDER BY GRA_CODIGO');
    LGrades := TJSONArray.Create;
    while not LQuery.DataSet.Eof do
    begin
      LItemObj := TJSONObject.Create;
      LItemObj.AddPair('codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_CODIGO').AsInteger));
      LItemObj.AddPair('pro', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_PRO').AsInteger));
      LItemObj.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_VALOR').AsFloat));
      LItemObj.AddPair('valor_dinheiro', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_VALOR_DINHEIRO').AsFloat));
      LItemObj.AddPair('valor_prazo', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_VALOR_PRAZO').AsFloat));
      LItemObj.AddPair('tam', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_TAM').AsInteger));
      LItemObj.AddPair('quantidade', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_QUANTIDADE').AsFloat));
      LItemObj.AddPair('codbarra', LQuery.DataSet.FieldByName('GRA_CODBARRA').AsString);
      LItemObj.AddPair('cor', LQuery.DataSet.FieldByName('GRA_COR').AsString);
      LGrades.AddElement(LItemObj);
      LQuery.DataSet.Next;
    end;
    LResponse.AddPair('grades', LGrades);

    // 8. Tamanhos
    LQuery.Clear;
    if LIsCargaInicial then
      LQuery.Open('SELECT TAM_CODIGO, TAM_PRO, TAM_TAMANHO, TAM_SIGLA, TAM_VALOR FROM TAMANHOS ORDER BY TAM_CODIGO')
    else
      LQuery.Open('SELECT TAM_CODIGO, TAM_PRO, TAM_TAMANHO, TAM_SIGLA, TAM_VALOR FROM TAMANHOS WHERE TAM_CADASTRAR IS NULL OR TAM_CADASTRAR = ''S'' ORDER BY TAM_CODIGO');
    LTamanhos := TJSONArray.Create;
    while not LQuery.DataSet.Eof do
    begin
      LItemObj := TJSONObject.Create;
      LItemObj.AddPair('codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('TAM_CODIGO').AsInteger));
      LItemObj.AddPair('pro', TJSONNumber.Create(LQuery.DataSet.FieldByName('TAM_PRO').AsInteger));
      LItemObj.AddPair('tamanho', LQuery.DataSet.FieldByName('TAM_TAMANHO').AsString);
      LItemObj.AddPair('sigla', LQuery.DataSet.FieldByName('TAM_SIGLA').AsString);
      LItemObj.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('TAM_VALOR').AsFloat));
      LTamanhos.AddElement(LItemObj);
      LQuery.DataSet.Next;
    end;
    LResponse.AddPair('tamanhos', LTamanhos);

    // 9. Clientes
    LQuery.Clear;
    if LIsCargaInicial then
      LQuery.Open('SELECT CLI_CODIGO, CLI_NOME, CLI_CELULAR, CLI_FONE, CLI_EMAIL, CLI_CIDADE, CLI_UF, CLI_ENDERECO, CLI_BAIRRO, CLI_CEP, CLI_CNPJ_CPF, CLI_RG, CLI_LIMITE FROM CLIENTES ORDER BY CLI_CODIGO')
    else
      LQuery.Open('SELECT CLI_CODIGO, CLI_NOME, CLI_CELULAR, CLI_FONE, CLI_EMAIL, CLI_CIDADE, CLI_UF, CLI_ENDERECO, CLI_BAIRRO, CLI_CEP, CLI_CNPJ_CPF, CLI_RG, CLI_LIMITE FROM CLIENTES WHERE CLI_CADASTRAR IS NULL OR CLI_CADASTRAR = ''S'' ORDER BY CLI_CODIGO');
    LSubgrupos := TJSONArray.Create;
    while not LQuery.DataSet.Eof do
    begin
      LItemObj := TJSONObject.Create;
      LItemObj.AddPair('codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('CLI_CODIGO').AsInteger));
      LItemObj.AddPair('nome', LQuery.DataSet.FieldByName('CLI_NOME').AsString);
      LItemObj.AddPair('celular', LQuery.DataSet.FieldByName('CLI_CELULAR').AsString);
      LItemObj.AddPair('telefone', LQuery.DataSet.FieldByName('CLI_FONE').AsString);
      LItemObj.AddPair('email', LQuery.DataSet.FieldByName('CLI_EMAIL').AsString);
      LItemObj.AddPair('cidade', LQuery.DataSet.FieldByName('CLI_CIDADE').AsString);
      LItemObj.AddPair('uf', LQuery.DataSet.FieldByName('CLI_UF').AsString);
      LItemObj.AddPair('endereco', LQuery.DataSet.FieldByName('CLI_ENDERECO').AsString);
      LItemObj.AddPair('bairro', LQuery.DataSet.FieldByName('CLI_BAIRRO').AsString);
      LItemObj.AddPair('cep', LQuery.DataSet.FieldByName('CLI_CEP').AsString);
      LItemObj.AddPair('cnpj_cpf', LQuery.DataSet.FieldByName('CLI_CNPJ_CPF').AsString);
      LItemObj.AddPair('rg', LQuery.DataSet.FieldByName('CLI_RG').AsString);
      LItemObj.AddPair('limite', TJSONNumber.Create(LQuery.DataSet.FieldByName('CLI_LIMITE').AsFloat));
      LSubgrupos.AddElement(LItemObj);
      LQuery.DataSet.Next;
    end;
    LResponse.AddPair('clientes', LSubgrupos);

    LResponse.AddPair('timestamp', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));

    // Apenas baixa/limpa a flag se NÃO for carga inicial
    if not LIsCargaInicial then
    begin
      try
        LQuery.Clear; LQuery.Add('UPDATE PRODUTOS SET PRO_CADASTRAR = ''N'' WHERE PRO_CADASTRAR = ''S'' OR PRO_CADASTRAR IS NULL'); LQuery.ExecSQL;
        LQuery.Clear; LQuery.Add('UPDATE GRUPO_1 SET G1_CADASTRAR = ''N'' WHERE G1_CADASTRAR = ''S'' OR G1_CADASTRAR IS NULL'); LQuery.ExecSQL;
        LQuery.Clear; LQuery.Add('UPDATE GRUPOS SET GRU_CADASTRAR = ''N'' WHERE GRU_CADASTRAR = ''S'' OR GRU_CADASTRAR IS NULL'); LQuery.ExecSQL;
        LQuery.Clear; LQuery.Add('UPDATE FORNECEDORES SET FOR_CADASTRAR = ''N'' WHERE FOR_CADASTRAR = ''S'' OR FOR_CADASTRAR IS NULL'); LQuery.ExecSQL;
        LQuery.Clear; LQuery.Add('UPDATE MODELOS SET MOD_CADASTRAR = ''N'' WHERE MOD_CADASTRAR = ''S'' OR MOD_CADASTRAR IS NULL'); LQuery.ExecSQL;
        LQuery.Clear; LQuery.Add('UPDATE GRADES SET GRA_CADASTRAR = ''N'' WHERE GRA_CADASTRAR = ''S'' OR GRA_CADASTRAR IS NULL'); LQuery.ExecSQL;
        LQuery.Clear; LQuery.Add('UPDATE TAMANHOS SET TAM_CADASTRAR = ''N'' WHERE TAM_CADASTRAR = ''S'' OR TAM_CADASTRAR IS NULL'); LQuery.ExecSQL;
        LQuery.Clear; LQuery.Add('UPDATE TRANSFERENCIA SET TR_CADASTRAR = ''N'' WHERE TR_CADASTRAR = ''S'' OR TR_CADASTRAR IS NULL'); LQuery.ExecSQL;
        LQuery.Clear; LQuery.Add('UPDATE CLIENTES SET CLI_CADASTRAR = ''N'' WHERE CLI_CADASTRAR = ''S'' OR CLI_CADASTRAR IS NULL'); LQuery.ExecSQL;
      except end;
    end;

    Res.Status(THTTPStatus.OK).Send<TJSONObject>(LResponse);
  except
    on E: Exception do
    begin
      LResponse.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class function TSyncController.ObterEmpresaId(Req: THorseRequest): Integer;
var
  LEmpresaIdStr: string;
begin
  if Req.Query.ContainsKey('emp_id') then
    Result := StrToIntDef(Req.Query.Items['emp_id'], 1)
  else if Req.Query.ContainsKey('empresa_id') then
    Result := StrToIntDef(Req.Query.Items['empresa_id'], 1)
  else if Req.Query.ContainsKey('emp') then
    Result := StrToIntDef(Req.Query.Items['emp'], 1)
  else if Req.Headers.TryGetValue('X-Empresa-Id', LEmpresaIdStr) or Req.Headers.TryGetValue('x-empresa-id', LEmpresaIdStr) then
    Result := StrToIntDef(LEmpresaIdStr, 1)
  else
    Result := 1;
end;

class function TSyncController.ISOToDate(const AStr: string): TDateTime;
var
  LFormatSettings: TFormatSettings;
begin
  if Trim(AStr) = '' then
    Exit(Date);
  LFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  LFormatSettings.DateSeparator := '-';
  if not TryStrToDate(AStr, Result, LFormatSettings) then
  begin
    LFormatSettings.ShortDateFormat := 'dd/mm/yyyy';
    LFormatSettings.DateSeparator := '/';
    if not TryStrToDate(AStr, Result, LFormatSettings) then
      Result := Date;
  end;
end;

class procedure TSyncController.ClientesCidade(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d)', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF >= %s)', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF <= %s)', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT CIDADE, SUM(QUANTIDADE) AS QUANTIDADE FROM DASHBOARD_CLIENTES_CIDADE ' + LWhere + ' GROUP BY CIDADE ORDER BY SUM(QUANTIDADE) DESC';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('cidade', LQuery.DataSet.FieldByName('CIDADE').AsString);
      LItem.AddPair('clientes', TJSONNumber.Create(LQuery.DataSet.FieldByName('QUANTIDADE').AsInteger));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.DespesasTipoPagamento(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d) AND TIPO_REGISTRO = ''DESPESA''', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF >= %s)', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF <= %s)', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT TIPO_OPERACAO, TIPO_PAGAMENTO, SUM(VALOR) AS VALOR FROM DASHBOARD_PAGAMENTOS ' + LWhere + ' GROUP BY TIPO_OPERACAO, TIPO_PAGAMENTO';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('tipo_operacao', LQuery.DataSet.FieldByName('TIPO_OPERACAO').AsString);
      LItem.AddPair('tipo_pagamento', LQuery.DataSet.FieldByName('TIPO_PAGAMENTO').AsString);
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VALOR').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.VendasMargemLucro(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d)', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF >= %s', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF <= %s', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT DATA_REF, SUM(VENDAS_VALOR) AS VENDAS_VALOR, SUM(VENDAS_LUCRO) AS VENDAS_LUCRO FROM DASHBOARD_DIARIO ' + LWhere + ' GROUP BY DATA_REF ORDER BY DATA_REF';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('data', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('DATA_REF').AsDateTime));
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VENDAS_VALOR').AsFloat));
      LItem.AddPair('margem_lucro', TJSONNumber.Create(LQuery.DataSet.FieldByName('VENDAS_LUCRO').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.OsMargemLucro(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d)', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF >= %s', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF <= %s', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT DATA_REF, SUM(OS_VALOR) AS OS_VALOR, SUM(OS_LUCRO) AS OS_LUCRO FROM DASHBOARD_DIARIO ' + LWhere + ' GROUP BY DATA_REF ORDER BY DATA_REF';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('data', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('DATA_REF').AsDateTime));
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('OS_VALOR').AsFloat));
      LItem.AddPair('margem_lucro', TJSONNumber.Create(LQuery.DataSet.FieldByName('OS_LUCRO').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.VendasLucroGrupo(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d)', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF >= %s)', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF <= %s)', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT NOME_GRUPO, SUM(VALOR) AS VALOR, SUM(LUCRO) AS LUCRO FROM DASHBOARD_VENDAS_GRUPO ' + LWhere + ' GROUP BY NOME_GRUPO ORDER BY SUM(VALOR) DESC';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('nome', LQuery.DataSet.FieldByName('NOME_GRUPO').AsString);
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VALOR').AsFloat));
      LItem.AddPair('lucro', TJSONNumber.Create(LQuery.DataSet.FieldByName('LUCRO').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.TiposPagamentosVendas(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d) AND TIPO_REGISTRO = ''VENDA''', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF >= %s)', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF <= %s)', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT TIPO_PAGAMENTO, SUM(VALOR) AS VALOR FROM DASHBOARD_PAGAMENTOS ' + LWhere + ' GROUP BY TIPO_PAGAMENTO ORDER BY SUM(VALOR) DESC';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('tipo_pagamento', LQuery.DataSet.FieldByName('TIPO_PAGAMENTO').AsString);
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VALOR').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.TiposPagamentosCompras(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d) AND TIPO_REGISTRO = ''COMPRA''', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF >= %s)', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF <= %s)', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT TIPO_PAGAMENTO, SUM(VALOR) AS VALOR FROM DASHBOARD_PAGAMENTOS ' + LWhere + ' GROUP BY TIPO_PAGAMENTO ORDER BY SUM(VALOR) DESC';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('tipo_pagamento', LQuery.DataSet.FieldByName('TIPO_PAGAMENTO').AsString);
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VALOR').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.TiposPagamentosRecebimentos(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d) AND TIPO_REGISTRO = ''RECEBIMENTO''', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF >= %s)', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF <= %s)', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT TIPO_PAGAMENTO, SUM(VALOR) AS VALOR FROM DASHBOARD_PAGAMENTOS ' + LWhere + ' GROUP BY TIPO_PAGAMENTO ORDER BY SUM(VALOR) DESC';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('tipo_pagamento', LQuery.DataSet.FieldByName('TIPO_PAGAMENTO').AsString);
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VALOR').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.TiposPagamentosPagamentos(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d) AND TIPO_REGISTRO = ''PAGAMENTO''', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF >= %s)', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF <= %s)', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT TIPO_PAGAMENTO, SUM(VALOR) AS VALOR FROM DASHBOARD_PAGAMENTOS ' + LWhere + ' GROUP BY TIPO_PAGAMENTO ORDER BY SUM(VALOR) DESC';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('tipo_pagamento', LQuery.DataSet.FieldByName('TIPO_PAGAMENTO').AsString);
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VALOR').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.Movimentacoes(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d)', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF >= %s', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF <= %s', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT DATA_REF, SUM(MOV_CREDITO) AS MOV_CREDITO, SUM(MOV_DEBITO) AS MOV_DEBITO FROM DASHBOARD_DIARIO ' + LWhere + ' GROUP BY DATA_REF ORDER BY DATA_REF';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('data', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('DATA_REF').AsDateTime));
      LItem.AddPair('credito', TJSONNumber.Create(LQuery.DataSet.FieldByName('MOV_CREDITO').AsFloat));
      LItem.AddPair('debito', TJSONNumber.Create(LQuery.DataSet.FieldByName('MOV_DEBITO').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.VendasDiarias(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d)', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF >= %s', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF <= %s', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT DATA_REF, SUM(VENDAS_VALOR) AS VENDAS_VALOR, MAX(VENDAS_MAIOR) AS VENDAS_MAIOR, SUM(VENDAS_QTD) AS VENDAS_QTD FROM DASHBOARD_DIARIO ' + LWhere + ' GROUP BY DATA_REF ORDER BY DATA_REF';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('data', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('DATA_REF').AsDateTime));
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VENDAS_VALOR').AsFloat));
      LItem.AddPair('maior_venda', TJSONNumber.Create(LQuery.DataSet.FieldByName('VENDAS_MAIOR').AsFloat));
      LItem.AddPair('quantidade', TJSONNumber.Create(LQuery.DataSet.FieldByName('VENDAS_QTD').AsInteger));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.VendasDiariasHora(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d)', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF >= %s)', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND (DATA_REF IS NULL OR DATA_REF <= %s)', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT HORA, SUM(VALOR) AS VALOR FROM DASHBOARD_VENDAS_HORA ' + LWhere + ' GROUP BY HORA ORDER BY HORA';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('hora', LQuery.DataSet.FieldByName('HORA').AsString);
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('VALOR').AsFloat));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.OsDiarias(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LEmpresaId: Integer;
  LSQL, LWhere: string;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  LEmpresaId := ObterEmpresaId(Req);
  try
    LWhere := Format('WHERE (%d = 0 OR EMPRESA_ID = %d)', [LEmpresaId, LEmpresaId]);
    if Req.Query.ContainsKey('startDate') and not Req.Query.Items['startDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF >= %s', [QuotedStr(Req.Query.Items['startDate'])]);
    if Req.Query.ContainsKey('endDate') and not Req.Query.Items['endDate'].IsEmpty then
      LWhere := LWhere + Format(' AND DATA_REF <= %s', [QuotedStr(Req.Query.Items['endDate'])]);

    LSQL := 'SELECT DATA_REF, SUM(OS_VALOR) AS OS_VALOR, MAX(OS_MAIOR) AS OS_MAIOR, SUM(OS_QTD) AS OS_QTD FROM DASHBOARD_DIARIO ' + LWhere + ' GROUP BY DATA_REF ORDER BY DATA_REF';
    LQuery.Clear;
    LQuery.Add(LSQL);
    LQuery.Open;

    while not LQuery.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('data', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('DATA_REF').AsDateTime));
      LItem.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('OS_VALOR').AsFloat));
      LItem.AddPair('maior_os', TJSONNumber.Create(LQuery.DataSet.FieldByName('OS_MAIOR').AsFloat));
      LItem.AddPair('quantidade', TJSONNumber.Create(LQuery.DataSet.FieldByName('OS_QTD').AsInteger));
      LArr.AddElement(LItem);
      LQuery.DataSet.Next;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TSyncController.EnsureDashboardTables;
var
  LDiario: TDashboardDiario;
  LPag: TDashboardPagamento;
  LGrupo: TDashboardVendasGrupo;
  LCidade: TDashboardClientesCidade;
  LHora: TDashboardVendasHora;
begin
  try
    LDiario := TDashboardDiario.Create(TDatabase.Connection);
    try LDiario.CriaTabela; finally LDiario.DisposeOf; end;

    LPag := TDashboardPagamento.Create(TDatabase.Connection);
    try LPag.CriaTabela; finally LPag.DisposeOf; end;

    LGrupo := TDashboardVendasGrupo.Create(TDatabase.Connection);
    try LGrupo.CriaTabela; finally LGrupo.DisposeOf; end;

    LCidade := TDashboardClientesCidade.Create(TDatabase.Connection);
    try LCidade.CriaTabela; finally LCidade.DisposeOf; end;

    LHora := TDashboardVendasHora.Create(TDatabase.Connection);
    try LHora.CriaTabela; finally LHora.DisposeOf; end;
  except
    on E: Exception do
      Writeln('-> Erro ao verificar/criar tabelas de dashboard: ' + E.Message);
  end;
end;

class procedure TSyncController.EnsureEstoqueEmpresaTable;
var
  LEstoqueEmpresa: TEstoqueEmpresa;
  LQuery: iQuery;
begin
  try
    LEstoqueEmpresa := TEstoqueEmpresa.Create(TDatabase.Connection);
    try
      LEstoqueEmpresa.CriaTabela;
    finally
      LEstoqueEmpresa.DisposeOf;
    end;

    // Limpa registro fantasma/duplicado de EMP_CODIGO = 1 caso exista a empresa real sincronizada (EMP_CODIGO = 5)
    try
      LQuery := TDatabase.Query;
      LQuery.Clear;
      LQuery.Add('DELETE FROM EMPRESA WHERE EMP_CODIGO = 1 AND EXISTS (SELECT 1 FROM EMPRESA E5 WHERE E5.EMP_CODIGO = 5)');
      LQuery.ExecSQL;
    except
    end;
  except
    on E: Exception do
      Writeln('-> Erro ao verificar/criar tabela ESTOQUE_EMPRESA: ' + E.Message);
  end;
end;

class procedure TSyncController.EstoquePosicao(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
  LSQL, LEmpNome: string;
  LProCodigo, LEmpId: Integer;
begin
  EnsureEstoqueEmpresaTable;
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LProCodigo := 0;
    if Req.Query.ContainsKey('pro_codigo') then
      LProCodigo := StrToIntDef(Req.Query.Items['pro_codigo'], 0)
    else if Req.Query.ContainsKey('pro') then
      LProCodigo := StrToIntDef(Req.Query.Items['pro'], 0)
    else if Req.Query.ContainsKey('codigo') then
      LProCodigo := StrToIntDef(Req.Query.Items['codigo'], 0);

    if (LProCodigo = 0) and Req.Params.ContainsKey('pro_codigo') then
      LProCodigo := StrToIntDef(Req.Params.Items['pro_codigo'], 0);

    try
      if LProCodigo > 0 then
      begin
        LSQL := Format(
          'SELECT ' +
          '  EMP.EMP_CODIGO AS EE_EMPRESA_ID, ' +
          '  COALESCE(NULLIF(TRIM(EMP.EMP_FANTASIA), ''''), NULLIF(TRIM(EMP.EMP_RAZAO_SOCIAL), ''''), ''Unidade #'' || EMP.EMP_CODIGO) AS EMP_NOME, ' +
          '  EMP.EMP_FANTASIA, ' +
          '  EMP.EMP_RAZAO_SOCIAL, ' +
          '  EMP.EMP_MUNICIPIO, ' +
          '  EMP.EMP_UF, ' +
          '  EMP.EMP_CNPJ, ' +
          '  %d AS EE_PRO_CODIGO, ' +
          '  P.PRO_NOME AS PRO_NOME, ' +
          '  COALESCE( ' +
          '    E.EE_QUANTIDADE, ' +
          '    CASE WHEN (EMP.EMP_CODIGO = 5 OR EMP.EMP_CODIGO = 1 OR ' +
          '               UPPER(COALESCE(EMP.EMP_FANTASIA, EMP.EMP_RAZAO_SOCIAL, '''')) LIKE ''%%CD%%'' OR ' +
          '               UPPER(COALESCE(EMP.EMP_FANTASIA, EMP.EMP_RAZAO_SOCIAL, '''')) LIKE ''%%DOURADINA%%'' OR ' +
          '               UPPER(COALESCE(EMP.EMP_FANTASIA, EMP.EMP_RAZAO_SOCIAL, '''')) LIKE ''%%MATRIZ%%'') THEN ' +
          '      COALESCE((SELECT SUM(G.GRA_QUANTIDADE) FROM GRADES G WHERE G.GRA_PRO = %d), P.PRO_QUANTIDADE, 0) ' +
          '    ELSE 0 END, ' +
          '    0) AS EE_QUANTIDADE, ' +
          '  E.EE_DATA_ATUALIZACAO AS EE_DATA_ATUALIZACAO ' +
          'FROM EMPRESA EMP ' +
          'LEFT JOIN PRODUTOS P ON P.PRO_CODIGO = %d ' +
          'LEFT JOIN ESTOQUE_EMPRESA E ON E.EE_EMPRESA_ID = EMP.EMP_CODIGO AND E.EE_PRO_CODIGO = %d ' +
          'WHERE EMP.EMP_CODIGO IS NOT NULL AND (EMP.EMP_CODIGO <> 1 OR NOT EXISTS (SELECT 1 FROM EMPRESA E5 WHERE E5.EMP_CODIGO = 5)) ' +
          'ORDER BY EMP.EMP_CODIGO',
          [LProCodigo, LProCodigo, LProCodigo, LProCodigo]
        );
      end
      else
      begin
        LSQL := 
          'SELECT ' +
          '  EMP.EMP_CODIGO AS EE_EMPRESA_ID, ' +
          '  COALESCE(NULLIF(TRIM(EMP.EMP_FANTASIA), ''''), NULLIF(TRIM(EMP.EMP_RAZAO_SOCIAL), ''''), ''Unidade #'' || EMP.EMP_CODIGO) AS EMP_NOME, ' +
          '  EMP.EMP_FANTASIA, ' +
          '  EMP.EMP_RAZAO_SOCIAL, ' +
          '  EMP.EMP_MUNICIPIO, ' +
          '  EMP.EMP_UF, ' +
          '  EMP.EMP_CNPJ, ' +
          '  P.PRO_CODIGO AS EE_PRO_CODIGO, ' +
          '  P.PRO_NOME, ' +
          '  COALESCE( ' +
          '    E.EE_QUANTIDADE, ' +
          '    CASE WHEN (EMP.EMP_CODIGO = 5 OR EMP.EMP_CODIGO = 1 OR ' +
          '               UPPER(COALESCE(EMP.EMP_FANTASIA, EMP.EMP_RAZAO_SOCIAL, '''')) LIKE ''%%CD%%'' OR ' +
          '               UPPER(COALESCE(EMP.EMP_FANTASIA, EMP.EMP_RAZAO_SOCIAL, '''')) LIKE ''%%DOURADINA%%'' OR ' +
          '               UPPER(COALESCE(EMP.EMP_FANTASIA, EMP.EMP_RAZAO_SOCIAL, '''')) LIKE ''%%MATRIZ%%'') THEN ' +
          '      COALESCE((SELECT SUM(G.GRA_QUANTIDADE) FROM GRADES G WHERE G.GRA_PRO = P.PRO_CODIGO), P.PRO_QUANTIDADE, 0) ' +
          '    ELSE 0 END, ' +
          '    0) AS EE_QUANTIDADE, ' +
          '  E.EE_DATA_ATUALIZACAO ' +
          'FROM EMPRESA EMP ' +
          'CROSS JOIN PRODUTOS P ' +
          'LEFT JOIN ESTOQUE_EMPRESA E ON E.EE_EMPRESA_ID = EMP.EMP_CODIGO AND E.EE_PRO_CODIGO = P.PRO_CODIGO ' +
          'WHERE EMP.EMP_CODIGO IS NOT NULL AND (EMP.EMP_CODIGO <> 1 OR NOT EXISTS (SELECT 1 FROM EMPRESA E5 WHERE E5.EMP_CODIGO = 5)) ' +
          'ORDER BY P.PRO_CODIGO, EMP.EMP_CODIGO';
      end;

      LQuery.Open(LSQL);
      while not LQuery.DataSet.Eof do
      begin
        LItem := TJSONObject.Create;
        LEmpId := LQuery.DataSet.FieldByName('EE_EMPRESA_ID').AsInteger;
        LEmpNome := LQuery.DataSet.FieldByName('EMP_NOME').AsString;
        if LEmpNome.Trim.IsEmpty then
          LEmpNome := 'Unidade #' + IntToStr(LEmpId);

        LItem.AddPair('empresa_id', TJSONNumber.Create(LEmpId));
        LItem.AddPair('empresa_nome', LEmpNome);
        LItem.AddPair('empresa_fantasia', LQuery.DataSet.FieldByName('EMP_FANTASIA').AsString);
        LItem.AddPair('empresa_razao_social', LQuery.DataSet.FieldByName('EMP_RAZAO_SOCIAL').AsString);
        LItem.AddPair('empresa_municipio', LQuery.DataSet.FieldByName('EMP_MUNICIPIO').AsString);
        LItem.AddPair('empresa_uf', LQuery.DataSet.FieldByName('EMP_UF').AsString);
        LItem.AddPair('municipio', LQuery.DataSet.FieldByName('EMP_MUNICIPIO').AsString);
        LItem.AddPair('uf', LQuery.DataSet.FieldByName('EMP_UF').AsString);
        LItem.AddPair('pro_codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('EE_PRO_CODIGO').AsInteger));
        if not LQuery.DataSet.FieldByName('PRO_NOME').IsNull then
          LItem.AddPair('pro_nome', LQuery.DataSet.FieldByName('PRO_NOME').AsString)
        else
          LItem.AddPair('pro_nome', '');
        LItem.AddPair('quantidade', TJSONNumber.Create(LQuery.DataSet.FieldByName('EE_QUANTIDADE').AsFloat));
        if not LQuery.DataSet.FieldByName('EE_DATA_ATUALIZACAO').IsNull then
          LItem.AddPair('data_atualizacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', LQuery.DataSet.FieldByName('EE_DATA_ATUALIZACAO').AsDateTime))
        else
          LItem.AddPair('data_atualizacao', '');
        LArr.AddElement(LItem);
        LQuery.DataSet.Next;
      end;
    except
      on E: Exception do
      begin
        Writeln('-> Fallback EstoquePosicao: ' + E.Message);
        try
          LQuery.Clear;
          LQuery.Add('SELECT EMP_CODIGO, COALESCE(EMP_FANTASIA, EMP_RAZAO_SOCIAL) AS EMP_NOME, EMP_FANTASIA, EMP_RAZAO_SOCIAL, EMP_MUNICIPIO, EMP_UF FROM EMPRESA WHERE EMP_CODIGO IS NOT NULL ORDER BY EMP_CODIGO');
          LQuery.Open;
          while not LQuery.DataSet.Eof do
          begin
            LItem := TJSONObject.Create;
            LEmpId := LQuery.DataSet.FieldByName('EMP_CODIGO').AsInteger;
            LEmpNome := LQuery.DataSet.FieldByName('EMP_NOME').AsString;
            if LEmpNome.Trim.IsEmpty then
              LEmpNome := 'Unidade #' + IntToStr(LEmpId);
            LItem.AddPair('empresa_id', TJSONNumber.Create(LEmpId));
            LItem.AddPair('empresa_nome', LEmpNome);
            LItem.AddPair('empresa_fantasia', LQuery.DataSet.FieldByName('EMP_FANTASIA').AsString);
            LItem.AddPair('empresa_razao_social', LQuery.DataSet.FieldByName('EMP_RAZAO_SOCIAL').AsString);
            LItem.AddPair('empresa_municipio', LQuery.DataSet.FieldByName('EMP_MUNICIPIO').AsString);
            LItem.AddPair('empresa_uf', LQuery.DataSet.FieldByName('EMP_UF').AsString);
            LItem.AddPair('municipio', LQuery.DataSet.FieldByName('EMP_MUNICIPIO').AsString);
            LItem.AddPair('uf', LQuery.DataSet.FieldByName('EMP_UF').AsString);
            LItem.AddPair('pro_codigo', TJSONNumber.Create(LProCodigo));
            LItem.AddPair('pro_nome', '');
            LItem.AddPair('quantidade', TJSONNumber.Create(0));
            LItem.AddPair('data_atualizacao', '');
            LArr.AddElement(LItem);
            LQuery.DataSet.Next;
          end;
        except
        end;
      end;
    end;
    Res.Status(THTTPStatus.OK).Send<TJSONArray>(LArr);
  except
    on E: Exception do
    begin
      LArr.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

end.
