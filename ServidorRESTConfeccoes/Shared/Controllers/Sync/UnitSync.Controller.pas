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
  LBody: TJSONObject;
  LArrDiario, LArrPag, LArrGrupo, LArrCidade, LArrHora, LArrEstoque: TJSONArray;
  LObj: TJSONObject;
  I, LEmpresaId, cod: Integer;
  LQuery: iQuery;
begin
  LBody := Req.Body<TJSONObject>;
  if not Assigned(LBody) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "JSON body expected"}');
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
          LQuery.Clear;
          LQuery.Add('UPDATE OR INSERT INTO DASHBOARD_DIARIO (EMPRESA_ID, DATA_REF, VENDAS_VALOR, VENDAS_LUCRO, VENDAS_MAIOR, VENDAS_QTD, OS_VALOR, OS_LUCRO, OS_MAIOR, OS_QTD, MOV_CREDITO, MOV_DEBITO)');
          LQuery.Add('VALUES (:EMP, :DREF, :VVAL, :VLUC, :VMAI, :VQTD, :OVAL, :OLUC, :OMAI, :OQTD, :MCRE, :MDEB)');
          LQuery.Add('MATCHING (EMPRESA_ID, DATA_REF)');
          LQuery.AddParam('EMP', LEmpresaId);
          LQuery.AddParam('DREF', ISOToDate(LObj.GetValue<string>('data_ref', '')));
          LQuery.AddParam('VVAL', LObj.GetValue<Double>('vendas_valor', 0));
          LQuery.AddParam('VLUC', LObj.GetValue<Double>('vendas_lucro', 0));
          LQuery.AddParam('VMAI', LObj.GetValue<Double>('vendas_maior', 0));
          LQuery.AddParam('VQTD', LObj.GetValue<Integer>('vendas_qtd', 0));
          LQuery.AddParam('OVAL', LObj.GetValue<Double>('os_valor', 0));
          LQuery.AddParam('OLUC', LObj.GetValue<Double>('os_lucro', 0));
          LQuery.AddParam('OMAI', LObj.GetValue<Double>('os_maior', 0));
          LQuery.AddParam('OQTD', LObj.GetValue<Integer>('os_qtd', 0));
          LQuery.AddParam('MCRE', LObj.GetValue<Double>('mov_credito', 0));
          LQuery.AddParam('MDEB', LObj.GetValue<Double>('mov_debito', 0));
          LQuery.ExecSQL;
        except end;
      end;
    end;

    // 2. Pagamentos (Limpa registros anteriores da empresa para evitar duplicidades)
    LArrPag := LBody.GetValue<TJSONArray>('pagamentos', nil);
    if Assigned(LArrPag) then
    begin
      try
        LQuery.Clear;
        LQuery.Add('DELETE FROM DASHBOARD_PAGAMENTOS WHERE EMPRESA_ID = :EMP');
        LQuery.AddParam('EMP', LEmpresaId);
        LQuery.ExecSQL;
      except end;

      for I := 0 to LArrPag.Count - 1 do
      begin
        LObj := TJSONObject(LArrPag.Items[I]);
        try
          LQuery.Clear;
          LQuery.Add('INSERT INTO DASHBOARD_PAGAMENTOS (ID, EMPRESA_ID, TIPO_REGISTRO, TIPO_OPERACAO, TIPO_PAGAMENTO, VALOR) VALUES (:ID, :EMP, :TREG, :TOPE, :TPAG, :VAL)');
          LQuery.AddParam('ID', GeraCodigo('DASHBOARD_PAGAMENTOS', 'ID'));
          LQuery.AddParam('EMP', LEmpresaId);
          LQuery.AddParam('TREG', LObj.GetValue<string>('tipo_registro', ''));
          LQuery.AddParam('TOPE', LObj.GetValue<string>('tipo_operacao', ''));
          LQuery.AddParam('TPAG', LObj.GetValue<string>('tipo_pagamento', ''));
          LQuery.AddParam('VAL', LObj.GetValue<Double>('valor', 0));
          LQuery.ExecSQL;
        except end;
      end;
    end;

    // 3. Grupos (Limpa registros anteriores da empresa para evitar duplicidades)
    LArrGrupo := LBody.GetValue<TJSONArray>('vendas_grupo', nil);
    if Assigned(LArrGrupo) then
    begin
      try
        LQuery.Clear;
        LQuery.Add('DELETE FROM DASHBOARD_VENDAS_GRUPO WHERE EMPRESA_ID = :EMP');
        LQuery.AddParam('EMP', LEmpresaId);
        LQuery.ExecSQL;
      except end;

      for I := 0 to LArrGrupo.Count - 1 do
      begin
        LObj := TJSONObject(LArrGrupo.Items[I]);
        try
          LQuery.Clear;
          LQuery.Add('INSERT INTO DASHBOARD_VENDAS_GRUPO (ID, EMPRESA_ID, NOME_GRUPO, VALOR, LUCRO) VALUES (:ID, :EMP, :NOME, :VAL, :LUC)');
          LQuery.AddParam('ID', GeraCodigo('DASHBOARD_VENDAS_GRUPO', 'ID'));
          LQuery.AddParam('EMP', LEmpresaId);
          LQuery.AddParam('NOME', LObj.GetValue<string>('nome_grupo', ''));
          LQuery.AddParam('VAL', LObj.GetValue<Double>('valor', 0));
          LQuery.AddParam('LUC', LObj.GetValue<Double>('lucro', 0));
          LQuery.ExecSQL;
        except end;
      end;
    end;

    // 4. Clientes Cidade (Limpa registros anteriores da empresa para evitar duplicidades)
    LArrCidade := LBody.GetValue<TJSONArray>('clientes_cidade', nil);
    if Assigned(LArrCidade) then
    begin
      try
        LQuery.Clear;
        LQuery.Add('DELETE FROM DASHBOARD_CLIENTES_CIDADE WHERE EMPRESA_ID = :EMP');
        LQuery.AddParam('EMP', LEmpresaId);
        LQuery.ExecSQL;
      except end;

      for I := 0 to LArrCidade.Count - 1 do
      begin
        LObj := TJSONObject(LArrCidade.Items[I]);
        try
          LQuery.Clear;
          LQuery.Add('INSERT INTO DASHBOARD_CLIENTES_CIDADE (ID, EMPRESA_ID, CIDADE, QUANTIDADE) VALUES (:ID, :EMP, :CID, :QTD)');
          LQuery.AddParam('ID', GeraCodigo('DASHBOARD_CLIENTES_CIDADE', 'ID'));
          LQuery.AddParam('EMP', LEmpresaId);
          LQuery.AddParam('CID', LObj.GetValue<string>('cidade', ''));
          LQuery.AddParam('QTD', LObj.GetValue<Integer>('quantidade', 0));
          LQuery.ExecSQL;
        except end;
      end;
    end;

    // 5. Vendas Hora (Limpa registros anteriores da empresa para evitar duplicidades)
    LArrHora := LBody.GetValue<TJSONArray>('vendas_hora', nil);
    if Assigned(LArrHora) then
    begin
      try
        LQuery.Clear;
        LQuery.Add('DELETE FROM DASHBOARD_VENDAS_HORA WHERE EMPRESA_ID = :EMP');
        LQuery.AddParam('EMP', LEmpresaId);
        LQuery.ExecSQL;
      except end;

      for I := 0 to LArrHora.Count - 1 do
      begin
        LObj := TJSONObject(LArrHora.Items[I]);
        try
          LQuery.Clear;
          LQuery.Add('INSERT INTO DASHBOARD_VENDAS_HORA (ID, EMPRESA_ID, HORA, VALOR) VALUES (:ID, :EMP, :HORA, :VAL)');
          LQuery.AddParam('ID', GeraCodigo('DASHBOARD_VENDAS_HORA', 'ID'));
          LQuery.AddParam('EMP', LEmpresaId);
          LQuery.AddParam('HORA', LObj.GetValue<string>('hora', ''));
          LQuery.AddParam('VAL', LObj.GetValue<Double>('valor', 0));
          LQuery.ExecSQL;
        except end;
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
            LQuery.Add('UPDATE ESTOQUE_EMPRESA SET EE_QUANTIDADE = :QTD, EE_DATA_ATUALIZACAO = CURRENT_TIMESTAMP WHERE EE_EMPRESA_ID = :EMP AND EE_PRO_CODIGO = :PRO');
            LQuery.AddParam('QTD', LObj.GetValue<Double>('quantidade', 0));
            LQuery.AddParam('EMP', LEmpresaId);
            LQuery.AddParam('PRO', LObj.GetValue<Integer>('pro_codigo'));
            LQuery.ExecSQL;

            if TFDQuery(LQuery.Query).RowsAffected = 0 then
            begin
              LQuery.Clear;
              LQuery.Add('INSERT INTO ESTOQUE_EMPRESA (EE_ID, EE_EMPRESA_ID, EE_PRO_CODIGO, EE_QUANTIDADE, EE_DATA_ATUALIZACAO) VALUES (:ID, :EMP, :PRO, :QTD, CURRENT_TIMESTAMP)');
              LQuery.AddParam('ID', GeraCodigo('ESTOQUE_EMPRESA', 'EE_ID'));
              LQuery.AddParam('EMP', LEmpresaId);
              LQuery.AddParam('PRO', LObj.GetValue<Integer>('pro_codigo'));
              LQuery.AddParam('QTD', LObj.GetValue<Double>('quantidade', 0));
              LQuery.ExecSQL;
            end;
          end;
        except end;
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
  if Req.Headers.TryGetValue('X-Empresa-Id', LEmpresaIdStr) or Req.Headers.TryGetValue('x-empresa-id', LEmpresaIdStr) then
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add(
      'SELECT CIDADE, SUM(QUANTIDADE) AS QUANTIDADE ' +
      'FROM DASHBOARD_CLIENTES_CIDADE ' +
      'WHERE (:EMPRESA_ID = 0 OR EMPRESA_ID = :EMPRESA_ID) ' +
      'GROUP BY CIDADE ' +
      'ORDER BY SUM(QUANTIDADE) DESC'
    ).Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add('SELECT TIPO_OPERACAO, TIPO_PAGAMENTO, VALOR FROM DASHBOARD_PAGAMENTOS WHERE EMPRESA_ID = :EMPRESA_ID AND TIPO_REGISTRO = ''DESPESA''').Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add('SELECT DATA_REF, VENDAS_VALOR, VENDAS_LUCRO FROM DASHBOARD_DIARIO WHERE EMPRESA_ID = :EMPRESA_ID ORDER BY DATA_REF').Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add('SELECT DATA_REF, OS_VALOR, OS_LUCRO FROM DASHBOARD_DIARIO WHERE EMPRESA_ID = :EMPRESA_ID ORDER BY DATA_REF').Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add(
      'SELECT NOME_GRUPO, SUM(VALOR) AS VALOR, SUM(LUCRO) AS LUCRO ' +
      'FROM DASHBOARD_VENDAS_GRUPO ' +
      'WHERE (:EMPRESA_ID = 0 OR EMPRESA_ID = :EMPRESA_ID) ' +
      'GROUP BY NOME_GRUPO ' +
      'ORDER BY SUM(VALOR) DESC'
    ).Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add(
      'SELECT TIPO_PAGAMENTO, SUM(VALOR) AS VALOR ' +
      'FROM DASHBOARD_PAGAMENTOS ' +
      'WHERE (:EMPRESA_ID = 0 OR EMPRESA_ID = :EMPRESA_ID) AND TIPO_REGISTRO = ''VENDA'' ' +
      'GROUP BY TIPO_PAGAMENTO ' +
      'ORDER BY SUM(VALOR) DESC'
    ).Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add(
      'SELECT TIPO_PAGAMENTO, SUM(VALOR) AS VALOR ' +
      'FROM DASHBOARD_PAGAMENTOS ' +
      'WHERE (:EMPRESA_ID = 0 OR EMPRESA_ID = :EMPRESA_ID) AND TIPO_REGISTRO = ''COMPRA'' ' +
      'GROUP BY TIPO_PAGAMENTO ' +
      'ORDER BY SUM(VALOR) DESC'
    ).Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add(
      'SELECT TIPO_PAGAMENTO, SUM(VALOR) AS VALOR ' +
      'FROM DASHBOARD_PAGAMENTOS ' +
      'WHERE (:EMPRESA_ID = 0 OR EMPRESA_ID = :EMPRESA_ID) AND TIPO_REGISTRO = ''RECEBIMENTO'' ' +
      'GROUP BY TIPO_PAGAMENTO ' +
      'ORDER BY SUM(VALOR) DESC'
    ).Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add(
      'SELECT TIPO_PAGAMENTO, SUM(VALOR) AS VALOR ' +
      'FROM DASHBOARD_PAGAMENTOS ' +
      'WHERE (:EMPRESA_ID = 0 OR EMPRESA_ID = :EMPRESA_ID) AND TIPO_REGISTRO = ''PAGAMENTO'' ' +
      'GROUP BY TIPO_PAGAMENTO ' +
      'ORDER BY SUM(VALOR) DESC'
    ).Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add('SELECT DATA_REF, MOV_CREDITO, MOV_DEBITO FROM DASHBOARD_DIARIO WHERE EMPRESA_ID = :EMPRESA_ID ORDER BY DATA_REF').Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add('SELECT DATA_REF, VENDAS_VALOR, VENDAS_MAIOR, VENDAS_QTD FROM DASHBOARD_DIARIO WHERE EMPRESA_ID = :EMPRESA_ID ORDER BY DATA_REF').Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add('SELECT HORA, VALOR FROM DASHBOARD_VENDAS_HORA WHERE EMPRESA_ID = :EMPRESA_ID ORDER BY HORA').Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add('SELECT DATA_REF, OS_VALOR, OS_MAIOR, OS_QTD FROM DASHBOARD_DIARIO WHERE EMPRESA_ID = :EMPRESA_ID ORDER BY DATA_REF').Open;
    LQuery.AddParam('EMPRESA_ID', ObterEmpresaId(Req));
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
          '    MAX(E.EE_QUANTIDADE), ' +
          '    (SELECT SUM(TRI.TRI_QUANTIDADE) ' +
          '     FROM TRANSFERENCIA_ITEM TRI ' +
          '     JOIN TRANSFERENCIA TR ON TR.TR_ID = TRI.TRI_TRANSFERENCIA_ID ' +
          '     WHERE TRI.TRI_PRODUTO_ID = %d AND TR.TR_DESTINO = U.EMP_ID), ' +
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
