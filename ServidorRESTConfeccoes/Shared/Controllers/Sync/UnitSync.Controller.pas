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
  public
    class procedure Router;
    class procedure SyncDashboard(Req: THorseRequest; Res: THorseResponse);
    class procedure SyncPending(Req: THorseRequest; Res: THorseResponse);

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
  end;

implementation

uses
  UnitDatabase,
  UnitConnection.Model.Interfaces,
  UnitDashboardSync.Model;

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
    .&End;
end;

class procedure TSyncController.SyncDashboard(Req: THorseRequest; Res: THorseResponse);
var
  LBody: TJSONObject;
  LArrDiario, LArrPag, LArrGrupo, LArrCidade, LArrHora: TJSONArray;
  LObj: TJSONObject;
  I, LEmpresaId: Integer;
  LModelDiario: TDashboardDiario;
  LModelPag: TDashboardPagamento;
  LModelGrupo: TDashboardVendasGrupo;
  LModelCidade: TDashboardClientesCidade;
  LModelHora: TDashboardVendasHora;
  LQuery: iQuery;
begin
  LBody := Req.Body<TJSONObject>;
  if not Assigned(LBody) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "JSON body expected"}');
    Exit;
  end;

  // Em um cenario real, obtem o ID via Token JWT ou Header. 
  // O dashboard vai consultar na mesma base com as tabelas de dashboard
  LEmpresaId := ObterEmpresaId(Req); 

  LQuery := TDatabase.Query;
  
  try
    LQuery.Clear;
    LQuery.Add('DELETE FROM DASHBOARD_DIARIO WHERE EMPRESA_ID = :EMPRESA_ID');
    LQuery.AddParam('EMPRESA_ID', LEmpresaId).ExecSQL;
  except end;

  try
    LQuery.Clear;
    LQuery.Add('DELETE FROM DASHBOARD_PAGAMENTOS WHERE EMPRESA_ID = :EMPRESA_ID');
    LQuery.AddParam('EMPRESA_ID', LEmpresaId).ExecSQL;
  except end;

  try
    LQuery.Clear;
    LQuery.Add('DELETE FROM DASHBOARD_VENDAS_GRUPO WHERE EMPRESA_ID = :EMPRESA_ID');
    LQuery.AddParam('EMPRESA_ID', LEmpresaId).ExecSQL;
  except end;

  try
    LQuery.Clear;
    LQuery.Add('DELETE FROM DASHBOARD_CLIENTES_CIDADE WHERE EMPRESA_ID = :EMPRESA_ID');
    LQuery.AddParam('EMPRESA_ID', LEmpresaId).ExecSQL;
  except end;

  try
    LQuery.Clear;
    LQuery.Add('DELETE FROM DASHBOARD_VENDAS_HORA WHERE EMPRESA_ID = :EMPRESA_ID');
    LQuery.AddParam('EMPRESA_ID', LEmpresaId).ExecSQL;
  except end;

  // 1. Diarios
  LArrDiario := LBody.GetValue<TJSONArray>('diarios', nil);
  if Assigned(LArrDiario) then
  begin
    LModelDiario := TDashboardDiario.Create(TDatabase.Connection);
    try
      LModelDiario.CriaTabela;
      for I := 0 to LArrDiario.Count - 1 do
      begin
        LObj := TJSONObject(LArrDiario.Items[I]);
        LModelDiario.Id := LModelDiario.GeraCodigo('ID');
        LModelDiario.EmpresaId := LEmpresaId;
        LModelDiario.DataRef := StrToDateDef(LObj.GetValue<string>('data_ref', ''), Date);
        LModelDiario.VendasValor := LObj.GetValue<Double>('vendas_valor', 0);
        LModelDiario.VendasLucro := LObj.GetValue<Double>('vendas_lucro', 0);
        LModelDiario.VendasMaior := LObj.GetValue<Double>('vendas_maior', 0);
        LModelDiario.VendasQtd := LObj.GetValue<Integer>('vendas_qtd', 0);
        LModelDiario.OsValor := LObj.GetValue<Double>('os_valor', 0);
        LModelDiario.OsLucro := LObj.GetValue<Double>('os_lucro', 0);
        LModelDiario.OsMaior := LObj.GetValue<Double>('os_maior', 0);
        LModelDiario.OsQtd := LObj.GetValue<Integer>('os_qtd', 0);
        LModelDiario.MovCredito := LObj.GetValue<Double>('mov_credito', 0);
        LModelDiario.MovDebito := LObj.GetValue<Double>('mov_debito', 0);
        LModelDiario.SalvaNoBanco(1);
      end;
    finally
      LModelDiario.Free;
    end;
  end;

  // 2. Pagamentos
  LArrPag := LBody.GetValue<TJSONArray>('pagamentos', nil);
  if Assigned(LArrPag) then
  begin
    LModelPag := TDashboardPagamento.Create(TDatabase.Connection);
    try
      LModelPag.CriaTabela;
      for I := 0 to LArrPag.Count - 1 do
      begin
        LObj := TJSONObject(LArrPag.Items[I]);
        LModelPag.Id := LModelPag.GeraCodigo('ID');
        LModelPag.EmpresaId := LEmpresaId;
        LModelPag.TipoRegistro := LObj.GetValue<string>('tipo_registro', '');
        LModelPag.TipoOperacao := LObj.GetValue<string>('tipo_operacao', '');
        LModelPag.TipoPagamento := LObj.GetValue<string>('tipo_pagamento', '');
        LModelPag.Valor := LObj.GetValue<Double>('valor', 0);
        LModelPag.SalvaNoBanco(1);
      end;
    finally
      LModelPag.Free;
    end;
  end;

  // 3. Grupos
  LArrGrupo := LBody.GetValue<TJSONArray>('vendas_grupo', nil);
  if Assigned(LArrGrupo) then
  begin
    LModelGrupo := TDashboardVendasGrupo.Create(TDatabase.Connection);
    try
      LModelGrupo.CriaTabela;
      for I := 0 to LArrGrupo.Count - 1 do
      begin
        LObj := TJSONObject(LArrGrupo.Items[I]);
        LModelGrupo.Id := LModelGrupo.GeraCodigo('ID');
        LModelGrupo.EmpresaId := LEmpresaId;
        LModelGrupo.NomeGrupo := LObj.GetValue<string>('nome_grupo', '');
        LModelGrupo.Valor := LObj.GetValue<Double>('valor', 0);
        LModelGrupo.Lucro := LObj.GetValue<Double>('lucro', 0);
        LModelGrupo.SalvaNoBanco(1);
      end;
    finally
      LModelGrupo.Free;
    end;
  end;

  // 4. Clientes Cidade
  LArrCidade := LBody.GetValue<TJSONArray>('clientes_cidade', nil);
  if Assigned(LArrCidade) then
  begin
    LModelCidade := TDashboardClientesCidade.Create(TDatabase.Connection);
    try
      LModelCidade.CriaTabela;
      for I := 0 to LArrCidade.Count - 1 do
      begin
        LObj := TJSONObject(LArrCidade.Items[I]);
        LModelCidade.Id := LModelCidade.GeraCodigo('ID');
        LModelCidade.EmpresaId := LEmpresaId;
        LModelCidade.Cidade := LObj.GetValue<string>('cidade', '');
        LModelCidade.Quantidade := LObj.GetValue<Integer>('quantidade', 0);
        LModelCidade.SalvaNoBanco(1);
      end;
    finally
      LModelCidade.Free;
    end;
  end;

  // 5. Vendas Hora
  LArrHora := LBody.GetValue<TJSONArray>('vendas_hora', nil);
  if Assigned(LArrHora) then
  begin
    LModelHora := TDashboardVendasHora.Create(TDatabase.Connection);
    try
      LModelHora.CriaTabela;
      for I := 0 to LArrHora.Count - 1 do
      begin
        LObj := TJSONObject(LArrHora.Items[I]);
        LModelHora.Id := LModelHora.GeraCodigo('ID');
        LModelHora.EmpresaId := LEmpresaId;
        LModelHora.Hora := LObj.GetValue<string>('hora', '');
        LModelHora.Valor := LObj.GetValue<Double>('valor', 0);
        LModelHora.SalvaNoBanco(1);
      end;
    finally
      LModelHora.Free;
    end;
  end;

  Writeln('SyncDashboard: Dados do dashboard recebidos e salvos com sucesso.');
  Res.Status(THTTPStatus.OK).Send('{"status": "ok"}');
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
  LTransfId: Integer;
begin
  LResponse := TJSONObject.Create;
  LGrupos := TJSONArray.Create;
  LFornecedores := TJSONArray.Create;
  LProdutos := TJSONArray.Create;
  LTransferencias := TJSONArray.Create;

  LQuery := TDatabase.Query;
  try
    // 1. Grupos (GRUPO_1)
    LQuery.Open('SELECT G1_CODIGO, G1_NOME FROM GRUPO_1 ORDER BY G1_CODIGO');
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
    LQuery.Open('SELECT FOR_CODIGO, FOR_NOME, FOR_FANTASIA, FOR_CNPJ_CPF, FOR_INSC_ESTADUAL FROM FORNECEDORES ORDER BY FOR_CODIGO');
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

    // 3. Produtos
    LQuery.Clear;
    LQuery.Open('SELECT PRO_CODIGO, PRO_NOME, PRO_DESCRICAO, PRO_CODBARRA, PRO_VALORV, PRO_VALORC, PRO_EMBALAGEM, PRO_FABRICANTE, PRO_GRU, PRO_FOR, PRO_DATAUA FROM PRODUTOS ORDER BY PRO_CODIGO');
    while not LQuery.DataSet.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('pro_codigo', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_CODIGO').AsInteger));
      LObj.AddPair('pro_nome', LQuery.DataSet.FieldByName('PRO_NOME').AsString);
      LObj.AddPair('pro_descricao', LQuery.DataSet.FieldByName('PRO_DESCRICAO').AsString);
      LObj.AddPair('pro_codbarra', LQuery.DataSet.FieldByName('PRO_CODBARRA').AsString);
      LObj.AddPair('pro_valorv', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_VALORV').AsFloat));
      LObj.AddPair('pro_valorc', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_VALORC').AsFloat));
      LObj.AddPair('pro_embalagem', LQuery.DataSet.FieldByName('PRO_EMBALAGEM').AsString);
      LObj.AddPair('pro_fabricante', LQuery.DataSet.FieldByName('PRO_FABRICANTE').AsString);
      LObj.AddPair('pro_gru', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_GRU').AsInteger));
      LObj.AddPair('pro_for', TJSONNumber.Create(LQuery.DataSet.FieldByName('PRO_FOR').AsInteger));
      if LQuery.DataSet.FieldByName('PRO_DATAUA').IsNull then
        LObj.AddPair('pro_dataua', '')
      else
        LObj.AddPair('pro_dataua', FormatDateTime('yyyy-mm-dd', LQuery.DataSet.FieldByName('PRO_DATAUA').AsDateTime));
      LProdutos.AddElement(LObj);
      LQuery.DataSet.Next;
    end;

    // 4. Transferencias
    LQuery.Clear;
    LQuery.Open('SELECT TR_ID, TR_STATUS, TR_DATA, TR_DATA_RECEBIMENTO, TR_OBS FROM TRANSFERENCIA ORDER BY TR_ID');
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
        LQueryItens.Open('SELECT TRI_PRO_CODIGO, TRI_QUANTIDADE FROM TRANSFERENCIA_ITEM WHERE TRI_TR_ID = ' + LTransfId.ToString);
        while not LQueryItens.DataSet.Eof do
        begin
          LItemObj := TJSONObject.Create;
          LItemObj.AddPair('pro_codigo', TJSONNumber.Create(LQueryItens.DataSet.FieldByName('TRI_PRO_CODIGO').AsInteger));
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
    LResponse.AddPair('timestamp', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));

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

class procedure TSyncController.ClientesCidade(Req: THorseRequest; Res: THorseResponse);
var
  LQuery: iQuery;
  LArr: TJSONArray;
  LItem: TJSONObject;
begin
  LArr := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Add('SELECT CIDADE, QUANTIDADE FROM DASHBOARD_CLIENTES_CIDADE WHERE EMPRESA_ID = :EMPRESA_ID ORDER BY QUANTIDADE DESC').Open;
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
    LQuery.Add('SELECT NOME_GRUPO, VALOR, LUCRO FROM DASHBOARD_VENDAS_GRUPO WHERE EMPRESA_ID = :EMPRESA_ID ORDER BY VALOR DESC').Open;
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
    LQuery.Add('SELECT TIPO_PAGAMENTO, VALOR FROM DASHBOARD_PAGAMENTOS WHERE EMPRESA_ID = :EMPRESA_ID AND TIPO_REGISTRO = ''VENDA'' ORDER BY VALOR DESC').Open;
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
    LQuery.Add('SELECT TIPO_PAGAMENTO, VALOR FROM DASHBOARD_PAGAMENTOS WHERE EMPRESA_ID = :EMPRESA_ID AND TIPO_REGISTRO = ''COMPRA'' ORDER BY VALOR DESC').Open;
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
    LQuery.Add('SELECT TIPO_PAGAMENTO, VALOR FROM DASHBOARD_PAGAMENTOS WHERE EMPRESA_ID = :EMPRESA_ID AND TIPO_REGISTRO = ''RECEBIMENTO'' ORDER BY VALOR DESC').Open;
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
    LQuery.Add('SELECT TIPO_PAGAMENTO, VALOR FROM DASHBOARD_PAGAMENTOS WHERE EMPRESA_ID = :EMPRESA_ID AND TIPO_REGISTRO = ''PAGAMENTO'' ORDER BY VALOR DESC').Open;
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

end.
