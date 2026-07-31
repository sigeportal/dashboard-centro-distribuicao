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
    .Group
    .Prefix('/v1')
    .Route('/sync/pending')
      .Get(SyncPending)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/sync/ack')
      .Post(SyncAck)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/clientes-cidade')
      .Get(ClientesCidade)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/despesas-tipo-pagamento')
      .Get(DespesasTipoPagamento)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/vendas-margem-lucro')
      .Get(VendasMargemLucro)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/os-margem-lucro')
      .Get(OsMargemLucro)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/vendas-lucro-grupo')
      .Get(VendasLucroGrupo)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-vendas')
      .Get(TiposPagamentosVendas)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-compras')
      .Get(TiposPagamentosCompras)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-recebimentos')
      .Get(TiposPagamentosRecebimentos)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-pagamentos')
      .Get(TiposPagamentosPagamentos)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/movimentacoes')
      .Get(Movimentacoes)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/vendas-diarias')
      .Get(VendasDiarias)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/vendas-diarias/hora')
      .Get(VendasDiariasHora)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/dashboard/os-diarias')
      .Get(OsDiarias)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/estoque/posicao')
      .Get(EstoquePosicao)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/posicao-estoque')
      .Get(EstoquePosicao)
    .&End;
end;

class procedure TSyncController.SyncDashboard(Req: THorseRequest; Res: THorseResponse);
var
  LBody, LObj: TJSONObject;
  LArrDiario, LArrPag, LArrGrupo, LArrCidade, LArrHora, LArrEstoque: TJSONArray;
  LQuery: iQuery;
  LEmpresaId, I, cod: Integer;
  LDataRefStr, LDataRefSql: string;
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
            'UPDATE OR INSERT INTO DASHBOARD_DIARIO (EMPRESA_ID, DATA_REF, VENDAS_VALOR, VENDAS_LUCRO, VENDAS_MAIOR, VENDAS_QTD, OS_VALOR, OS_LUCRO, OS_MAIOR, OS_QTD, MOV_CREDITO, MOV_DEBITO) ' +
            'VALUES (%d, %s, %s, %s, %s, %d, %s, %s, %s, %d, %s, %s) MATCHING (EMPRESA_ID, DATA_REF)',
            [LEmpresaId, LDataRefSql,
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
        except
          on E: Exception do Writeln('-> Erro ao salvar DASHBOARD_DIARIO: ' + E.Message);
        end;
      end;
    end;

    // 2. Pagamentos
    LArrPag := LBody.GetValue<TJSONArray>('pagamentos', nil);
    if Assigned(LArrPag) and (LArrPag.Count > 0) then
    begin
      for I := 0 to LArrPag.Count - 1 do
      begin
        LObj := TJSONObject(LArrPag.Items[I]);
        try
          if (LObj.GetValue<string>('data_ref', '') <> '') then
            LDataRefStr := FormatDateTime('yyyy-mm-dd', ISOToDate(LObj.GetValue<string>('data_ref', '')))
          else
            LDataRefStr := FormatDateTime('yyyy-mm-dd', Date);
          LDataRefSql := QuotedStr(LDataRefStr);

          if I = 0 then
          begin
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
    end;

    // 3. Grupos
    LArrGrupo := LBody.GetValue<TJSONArray>('vendas_grupo', nil);
    if Assigned(LArrGrupo) and (LArrGrupo.Count > 0) then
    begin
      for I := 0 to LArrGrupo.Count - 1 do
      begin
        LObj := TJSONObject(LArrGrupo.Items[I]);
        try
          if (LObj.GetValue<string>('data_ref', '') <> '') then
            LDataRefStr := FormatDateTime('yyyy-mm-dd', ISOToDate(LObj.GetValue<string>('data_ref', '')))
          else
            LDataRefStr := FormatDateTime('yyyy-mm-dd', Date);
          LDataRefSql := QuotedStr(LDataRefStr);

          if I = 0 then
          begin
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
    end;

    // 4. Clientes Cidade
    LArrCidade := LBody.GetValue<TJSONArray>('clientes_cidade', nil);
    if Assigned(LArrCidade) and (LArrCidade.Count > 0) then
    begin
      for I := 0 to LArrCidade.Count - 1 do
      begin
        LObj := TJSONObject(LArrCidade.Items[I]);
        try
          if (LObj.GetValue<string>('data_ref', '') <> '') then
            LDataRefStr := FormatDateTime('yyyy-mm-dd', ISOToDate(LObj.GetValue<string>('data_ref', '')))
          else
            LDataRefStr := FormatDateTime('yyyy-mm-dd', Date);
          LDataRefSql := QuotedStr(LDataRefStr);

          if I = 0 then
          begin
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
    end;

    // 5. Vendas Hora
    LArrHora := LBody.GetValue<TJSONArray>('vendas_hora', nil);
    if Assigned(LArrHora) and (LArrHora.Count > 0) then
    begin
      for I := 0 to LArrHora.Count - 1 do
      begin
        LObj := TJSONObject(LArrHora.Items[I]);
        try
          if (LObj.GetValue<string>('data_ref', '') <> '') then
            LDataRefStr := FormatDateTime('yyyy-mm-dd', ISOToDate(LObj.GetValue<string>('data_ref', '')))
          else
            LDataRefStr := FormatDateTime('yyyy-mm-dd', Date);
          LDataRefSql := QuotedStr(LDataRefStr);

          if I = 0 then
          begin
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
  LSubgrupos, LGrades, LTamanhos: TJSONArray;
begin
  EnsureSyncControlColumns;
  LEmpresaId := ObterEmpresaId(Req);
  Writeln(Format('[CD Server] SyncPending: Pendencias enviadas para a Empresa EMP_ID = %d.', [LEmpresaId]));
  LResponse := TJSONObject.Create;
  LGrupos := TJSONArray.Create;
  LFornecedores := TJSONArray.Create;
  LProdutos := TJSONArray.Create;
  LTransferencias := TJSONArray.Create;

  LQuery := TDatabase.Query;
  try
    // 1. Grupos (GRUPO_1) - Apenas pendentes (CADASTRAR = 'S')
    LQuery.Open('SELECT G1_CODIGO, G1_NOME FROM GRUPO_1 WHERE G1_CADASTRAR IS NULL OR G1_CADASTRAR = ''S'' ORDER BY G1_CODIGO');
    while not LQuery.DataSet.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('gru_codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('G1_CODIGO').AsInteger));
      LObj.AddPair('gru_nome', LQuery.DataSet.FieldByName('G1_NOME').AsString);
      LGrupos.AddElement(LObj);
      LQuery.DataSet.Next;
    end;

    // 2. Fornecedores - Apenas pendentes (CADASTRAR = 'S')
    LQuery.Clear;
    LQuery.Open('SELECT FOR_CODIGO, FOR_NOME, FOR_FANTASIA, FOR_CNPJ_CPF, FOR_INSC_ESTADUAL FROM FORNECEDORES WHERE FOR_CADASTRAR IS NULL OR FOR_CADASTRAR = ''S'' ORDER BY FOR_CODIGO');
    while not LQuery.DataSet.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('for_codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('FOR_CODIGO').AsInteger));
      LObj.AddPair('for_nome', LQuery.DataSet.FieldByName('FOR_NOME').AsString);
      LObj.AddPair('for_nomefantasia', LQuery.DataSet.FieldByName('FOR_FANTASIA').AsString);
      LObj.AddPair('for_cnpj_cpf', LQuery.DataSet.FieldByName('FOR_CNPJ_CPF').AsString);
      LObj.AddPair('for_insc_estadual', LQuery.DataSet.FieldByName('FOR_INSC_ESTADUAL').AsString);
      LFornecedores.AddElement(LObj);
      LQuery.DataSet.Next;
    end;

    // 3. Produtos - Apenas pendentes (CADASTRAR = 'S')
    LQuery.Clear;
    LQuery.Add('SELECT PRO_CODIGO, PRO_NOME, PRO_DESCRICAO, PRO_CODBARRA, PRO_VALORV, PRO_VALORC, PRO_EMBALAGEM, PRO_FABRICANTE, PRO_GRU, PRO_FOR,');
    LQuery.Add('PRO_EMP, PRO_TOTALIZADOR, PRO_NCM, PRO_UM, PRO_DATAUA FROM PRODUTOS WHERE PRO_CADASTRAR IS NULL OR PRO_CADASTRAR = ''S'' ORDER BY PRO_CODIGO');
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
      LObj.AddPair('preservar_estoque_local', TJSONBool.Create(True)); // Regra: Mudanças cadastrais do CD não alteram o estoque físico local das filiais
      if LQuery.DataSet.FieldByName('PRO_DATAUA').IsNull then
        LObj.AddPair('pro_dataua', '')
      else
        LObj.AddPair('pro_dataua', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('PRO_DATAUA').AsDateTime));
      LProdutos.AddElement(LObj);
      LQuery.DataSet.Next;
    end;

    // 4. Transferencias - Apenas pendentes (CADASTRAR = 'S')
    LQuery.Clear;
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
    LResponse.AddPair('produtos', LProdutos);
    LResponse.AddPair('transferencias', LTransferencias);

    // 5. Subgrupos - Apenas pendentes (CADASTRAR = 'S')
    LQuery.Clear;
    LQuery.Open('SELECT GRU_CODIGO, GRU_NOME, GRU_G1, GRU_TR FROM GRUPOS WHERE GRU_CADASTRAR IS NULL OR GRU_CADASTRAR = ''S'' ORDER BY GRU_CODIGO');
    LObj := TJSONObject.Create;
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

    // 6. Grades - Apenas pendentes (CADASTRAR = 'S')
    LQuery.Clear;
    LQuery.Open('SELECT GRA_CODIGO, GRA_PRO, GRA_VALOR, GRA_TAM, GRA_QUANTIDADE, GRA_CODBARRA, GRA_COR FROM GRADES WHERE GRA_CADASTRAR IS NULL OR GRA_CADASTRAR = ''S'' ORDER BY GRA_CODIGO');
    LGrades := TJSONArray.Create;
    while not LQuery.DataSet.Eof do
    begin
      LItemObj := TJSONObject.Create;
      LItemObj.AddPair('codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_CODIGO').AsInteger));
      LItemObj.AddPair('pro', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_PRO').AsInteger));
      LItemObj.AddPair('valor', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_VALOR').AsFloat));
      LItemObj.AddPair('tam', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_TAM').AsInteger));
      LItemObj.AddPair('quantidade', TJSONNumber.Create(LQuery.DataSet.FieldByName('GRA_QUANTIDADE').AsFloat));
      LItemObj.AddPair('codbarra', LQuery.DataSet.FieldByName('GRA_CODBARRA').AsString);
      LItemObj.AddPair('cor', LQuery.DataSet.FieldByName('GRA_COR').AsString);
      LGrades.AddElement(LItemObj);
      LQuery.DataSet.Next;
    end;
    LResponse.AddPair('grades', LGrades);

    // 7. Tamanhos - Apenas pendentes (CADASTRAR = 'S')
    LQuery.Clear;
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

    LResponse.AddPair('timestamp', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));

    // Baixa/limpa a flag de pendência (marcando 'N') para que na próxima chamada retorne 0 itens duplicados
    try
      LQuery.Clear; LQuery.Add('UPDATE PRODUTOS SET PRO_CADASTRAR = ''N'' WHERE PRO_CADASTRAR = ''S'' OR PRO_CADASTRAR IS NULL'); LQuery.ExecSQL;
      LQuery.Clear; LQuery.Add('UPDATE GRUPO_1 SET G1_CADASTRAR = ''N'' WHERE G1_CADASTRAR = ''S'' OR G1_CADASTRAR IS NULL'); LQuery.ExecSQL;
      LQuery.Clear; LQuery.Add('UPDATE GRUPOS SET GRU_CADASTRAR = ''N'' WHERE GRU_CADASTRAR = ''S'' OR GRU_CADASTRAR IS NULL'); LQuery.ExecSQL;
      LQuery.Clear; LQuery.Add('UPDATE FORNECEDORES SET FOR_CADASTRAR = ''N'' WHERE FOR_CADASTRAR = ''S'' OR FOR_CADASTRAR IS NULL'); LQuery.ExecSQL;
      LQuery.Clear; LQuery.Add('UPDATE GRADES SET GRA_CADASTRAR = ''N'' WHERE GRA_CADASTRAR = ''S'' OR GRA_CADASTRAR IS NULL'); LQuery.ExecSQL;
      LQuery.Clear; LQuery.Add('UPDATE TAMANHOS SET TAM_CADASTRAR = ''N'' WHERE TAM_CADASTRAR = ''S'' OR TAM_CADASTRAR IS NULL'); LQuery.ExecSQL;
      LQuery.Clear; LQuery.Add('UPDATE TRANSFERENCIA SET TR_CADASTRAR = ''N'' WHERE TR_CADASTRAR = ''S'' OR TR_CADASTRAR IS NULL'); LQuery.ExecSQL;
    except end;

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
begin
  try
    LEstoqueEmpresa := TEstoqueEmpresa.Create(TDatabase.Connection);
    try
      LEstoqueEmpresa.CriaTabela;
    finally
      LEstoqueEmpresa.DisposeOf;
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
          '  U.EMP_ID AS EE_EMPRESA_ID, ' +
          '  MAX(COALESCE(EMP.EMP_FANTASIA, EMP.EMP_RAZAO_SOCIAL)) AS EMP_NOME, ' +
          '  %d AS EE_PRO_CODIGO, ' +
          '  MAX(P.PRO_NOME) AS PRO_NOME, ' +
          '  COALESCE( ' +
          '    NULLIF(MAX(E.EE_QUANTIDADE), 0), ' +
          '    CASE WHEN U.EMP_ID IN (1, 5) THEN MAX(P.PRO_QUANTIDADE) ELSE NULL END, ' +
          '    (SELECT COALESCE(SUM(TRI.TRI_QUANTIDADE), 0) ' +
          '     FROM TRANSFERENCIA_ITEM TRI ' +
          '     JOIN TRANSFERENCIA TR ON TR.TR_ID = TRI.TRI_TRANSFERENCIA_ID ' +
          '     WHERE TRI.TRI_PRODUTO_ID = %d AND TR.TR_DESTINO = U.EMP_ID AND (TR.TR_STATUS = ''Conferido/Aprovado'' OR TR.TR_STATUS = ''Em Trânsito'')), ' +
          '    MAX(E.EE_QUANTIDADE), ' +
          '    0) AS EE_QUANTIDADE, ' +
          '  MAX(E.EE_DATA_ATUALIZACAO) AS EE_DATA_ATUALIZACAO ' +
          'FROM (' +
          '  SELECT 1 AS EMP_ID FROM RDB$DATABASE ' +
          '  UNION SELECT 2 FROM RDB$DATABASE ' +
          '  UNION SELECT 3 FROM RDB$DATABASE ' +
          '  UNION SELECT 4 FROM RDB$DATABASE ' +
          '  UNION SELECT 5 FROM RDB$DATABASE ' +
          ') U ' +
          'LEFT JOIN EMPRESA EMP ON EMP.EMP_CODIGO = U.EMP_ID ' +
          'LEFT JOIN PRODUTOS P ON P.PRO_CODIGO = %d ' +
          'LEFT JOIN ESTOQUE_EMPRESA E ON E.EE_EMPRESA_ID = U.EMP_ID AND E.EE_PRO_CODIGO = %d ' +
          'GROUP BY U.EMP_ID ' +
          'ORDER BY U.EMP_ID',
          [LProCodigo, LProCodigo, LProCodigo, LProCodigo]
        );
      end
      else
      begin
        LSQL := 
          'SELECT ' +
          '  E.EE_EMPRESA_ID, ' +
          '  COALESCE(EMP.EMP_FANTASIA, EMP.EMP_RAZAO_SOCIAL) AS EMP_NOME, ' +
          '  E.EE_PRO_CODIGO, ' +
          '  P.PRO_NOME, ' +
          '  E.EE_QUANTIDADE, ' +
          '  E.EE_DATA_ATUALIZACAO ' +
          'FROM ESTOQUE_EMPRESA E ' +
          'LEFT JOIN PRODUTOS P ON P.PRO_CODIGO = E.EE_PRO_CODIGO ' +
          'LEFT JOIN EMPRESA EMP ON EMP.EMP_CODIGO = E.EE_EMPRESA_ID ' +
          'ORDER BY E.EE_PRO_CODIGO, E.EE_EMPRESA_ID';
      end;

      LQuery.Open(LSQL);
      while not LQuery.DataSet.Eof do
      begin
        LItem := TJSONObject.Create;
        LEmpId := LQuery.DataSet.FieldByName('EE_EMPRESA_ID').AsInteger;
        LEmpNome := LQuery.DataSet.FieldByName('EMP_NOME').AsString;
        if LEmpNome.Trim.IsEmpty then
        begin
          case LEmpId of
            1: LEmpNome := 'CD DOURADINA';
            2: LEmpNome := 'ITAPORA';
            3: LEmpNome := 'MARACAJU';
            4: LEmpNome := 'NOVA ALVORADA';
            5: LEmpNome := 'RIO BRILHANTE';
          else
            LEmpNome := 'Unidade #' + IntToStr(LEmpId);
          end;
        end;

        LItem.AddPair('empresa_id', TJSONNumber.Create(LEmpId));
        LItem.AddPair('empresa_nome', LEmpNome);
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
        for LEmpId := 1 to 5 do
        begin
          LItem := TJSONObject.Create;
          case LEmpId of
            1: LEmpNome := 'CD DOURADINA';
            2: LEmpNome := 'ITAPORA';
            3: LEmpNome := 'MARACAJU';
            4: LEmpNome := 'NOVA ALVORADA';
            5: LEmpNome := 'RIO BRILHANTE';
          end;
          LItem.AddPair('empresa_id', TJSONNumber.Create(LEmpId));
          LItem.AddPair('empresa_nome', LEmpNome);
          LItem.AddPair('pro_codigo', TJSONNumber.Create(LProCodigo));
          LItem.AddPair('pro_nome', '');
          LItem.AddPair('quantidade', TJSONNumber.Create(0));
          LItem.AddPair('data_atualizacao', '');
          LArr.AddElement(LItem);
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
