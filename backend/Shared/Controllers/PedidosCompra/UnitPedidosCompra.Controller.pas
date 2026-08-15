unit UnitPedidosCompra.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  FireDAC.Comp.Client;

type
  TPedidosCompraController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure EnsureTables;
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitPedidosCompra.Model;

class procedure TPedidosCompraController.EnsureTables;
var
  LPedido: TPedidosCompra;
  LItens: TPedidosCompraItens;
begin
  try
    LPedido := TPedidosCompra.Create(TDatabase.Connection);
    try
      LPedido.CriaTabela;
    finally
      LPedido.DisposeOf;
    end;

    LItens := TPedidosCompraItens.Create(TDatabase.Connection);
    try
      LItens.CriaTabela;
    finally
      LItens.DisposeOf;
    end;
  except
    on E: Exception do
      Writeln('-> Erro ao verificar tabelas de pedidos de compra: ' + E.Message);
  end;
end;

class procedure TPedidosCompraController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LResponseObj, LMetaObj, LObj: TJSONObject;
  LDataArr: TJSONArray;
  QueryCount, QueryData: iQuery;
  LPage, LLimit, LOffset, LTotalRecords, LTotalPages: Integer;
  LBusca, LWhere: string;
begin
  EnsureTables;
  LDataArr := TJSONArray.Create;
  QueryCount := TDatabase.Query;
  QueryData := TDatabase.Query;
  try
    LPage := StrToIntDef(Req.Query.Items['page'], 1);
    if LPage < 1 then LPage := 1;

    LLimit := StrToIntDef(Req.Query.Items['limit'], 15);
    if LLimit < 1 then LLimit := 15;
    if LLimit > 100 then LLimit := 100;

    LOffset := (LPage - 1) * LLimit;

    LBusca := Trim(Req.Query.Items['termo']);
    if LBusca.IsEmpty then LBusca := Trim(Req.Query.Items['busca']);

    LWhere := '';
    if not LBusca.IsEmpty then
    begin
      LWhere := Format(' WHERE (NUMERO_ORDEM LIKE ''%%%s%%'' OR FORNECEDOR_NOME LIKE ''%%%s%%'' OR MARCA LIKE ''%%%s%%'' OR REPRESENTANTE LIKE ''%%%s%%'')',
        [LBusca, LBusca, LBusca, LBusca]);
    end;

    QueryCount.Open('SELECT COUNT(*) AS TOTAL FROM PEDIDOS_COMPRA' + LWhere);
    LTotalRecords := QueryCount.Dataset.FieldByName('TOTAL').AsInteger;

    if LLimit > 0 then
      LTotalPages := (LTotalRecords + LLimit - 1) div LLimit
    else
      LTotalPages := 1;

    QueryData.Open(Format('SELECT FIRST %d SKIP %d ID, NUMERO_ORDEM, FORNECEDOR_ID, FORNECEDOR_NOME, MARCA, REPRESENTANTE, CONTATO_REPRESENTANTE, EMPRESA_NOME, EMPRESA_CNPJ, LOCAL_PEDIDO, LOCAL_ENTREGA, DATA_PEDIDO, DATA_ENTREGA, PRAZO_PAGAMENTO, DESCONTO_PERC, DESCONTO_VALOR, IMPOSTO_ICMS, TOTAL_PECAS, VALOR_TOTAL, STATUS, OBSERVACAO FROM PEDIDOS_COMPRA %s ORDER BY ID DESC', [LLimit, LOffset, LWhere]));
    QueryData.Dataset.First;

    while not QueryData.Dataset.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', TJSONNumber.Create(QueryData.Dataset.FieldByName('ID').AsInteger));
      LObj.AddPair('numero_ordem', QueryData.Dataset.FieldByName('NUMERO_ORDEM').AsString);
      LObj.AddPair('fornecedor_id', TJSONNumber.Create(QueryData.Dataset.FieldByName('FORNECEDOR_ID').AsInteger));
      LObj.AddPair('fornecedor_nome', QueryData.Dataset.FieldByName('FORNECEDOR_NOME').AsString);
      LObj.AddPair('marca', QueryData.Dataset.FieldByName('MARCA').AsString);
      LObj.AddPair('representante', QueryData.Dataset.FieldByName('REPRESENTANTE').AsString);
      LObj.AddPair('contato_representante', QueryData.Dataset.FieldByName('CONTATO_REPRESENTANTE').AsString);
      LObj.AddPair('empresa_nome', QueryData.Dataset.FieldByName('EMPRESA_NOME').AsString);
      LObj.AddPair('empresa_cnpj', QueryData.Dataset.FieldByName('EMPRESA_CNPJ').AsString);
      LObj.AddPair('local_pedido', QueryData.Dataset.FieldByName('LOCAL_PEDIDO').AsString);
      LObj.AddPair('local_entrega', QueryData.Dataset.FieldByName('LOCAL_ENTREGA').AsString);
      LObj.AddPair('data_pedido', FormatDateTime('yyyy-mm-dd', QueryData.Dataset.FieldByName('DATA_PEDIDO').AsDateTime));
      LObj.AddPair('data_entrega', QueryData.Dataset.FieldByName('DATA_ENTREGA').AsString);
      LObj.AddPair('prazo_pagamento', QueryData.Dataset.FieldByName('PRAZO_PAGAMENTO').AsString);
      LObj.AddPair('desconto_perc', TJSONNumber.Create(QueryData.Dataset.FieldByName('DESCONTO_PERC').AsFloat));
      LObj.AddPair('desconto_valor', TJSONNumber.Create(QueryData.Dataset.FieldByName('DESCONTO_VALOR').AsFloat));
      LObj.AddPair('imposto_icms', TJSONNumber.Create(QueryData.Dataset.FieldByName('IMPOSTO_ICMS').AsFloat));
      LObj.AddPair('total_pecas', TJSONNumber.Create(QueryData.Dataset.FieldByName('TOTAL_PECAS').AsFloat));
      LObj.AddPair('valor_total', TJSONNumber.Create(QueryData.Dataset.FieldByName('VALOR_TOTAL').AsFloat));
      LObj.AddPair('status', QueryData.Dataset.FieldByName('STATUS').AsString);
      LObj.AddPair('observacao', QueryData.Dataset.FieldByName('OBSERVACAO').AsString);

      LDataArr.AddElement(LObj);
      QueryData.Dataset.Next;
    end;

    LResponseObj := TJSONObject.Create;
    LMetaObj := TJSONObject.Create;

    LMetaObj.AddPair('page', TJSONNumber.Create(LPage));
    LMetaObj.AddPair('limit', TJSONNumber.Create(LLimit));
    LMetaObj.AddPair('total', TJSONNumber.Create(LTotalRecords));
    LMetaObj.AddPair('pages', TJSONNumber.Create(LTotalPages));

    LResponseObj.AddPair('data', LDataArr);
    LResponseObj.AddPair('meta', LMetaObj);

    Res.Send<TJSONObject>(LResponseObj);
  except
    on E: Exception do
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
  end;
end;

class procedure TPedidosCompraController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LId: Integer;
  LResponseObj, LItemObj: TJSONObject;
  LItensArr: TJSONArray;
  QueryHeader, QueryItens: iQuery;
begin
  EnsureTables;
  LId := StrToIntDef(Req.Params.Items['id'], 0);
  if LId <= 0 then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "ID invalido"}');
    Exit;
  end;

  QueryHeader := TDatabase.Query;
  QueryItens := TDatabase.Query;

  QueryHeader.Open(Format('SELECT ID, NUMERO_ORDEM, FORNECEDOR_ID, FORNECEDOR_NOME, MARCA, REPRESENTANTE, CONTATO_REPRESENTANTE, EMPRESA_NOME, EMPRESA_CNPJ, LOCAL_PEDIDO, LOCAL_ENTREGA, DATA_PEDIDO, DATA_ENTREGA, PRAZO_PAGAMENTO, DESCONTO_PERC, DESCONTO_VALOR, IMPOSTO_ICMS, TOTAL_PECAS, VALOR_TOTAL, STATUS, OBSERVACAO FROM PEDIDOS_COMPRA WHERE ID = %d', [LId]));
  if QueryHeader.Dataset.IsEmpty then
  begin
    Res.Status(THTTPStatus.NotFound).Send('{"error": "Pedido de compra nao encontrado"}');
    Exit;
  end;

  LResponseObj := TJSONObject.Create;
  LResponseObj.AddPair('id', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('ID').AsInteger));
  LResponseObj.AddPair('numero_ordem', QueryHeader.Dataset.FieldByName('NUMERO_ORDEM').AsString);
  LResponseObj.AddPair('fornecedor_id', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('FORNECEDOR_ID').AsInteger));
  LResponseObj.AddPair('fornecedor_nome', QueryHeader.Dataset.FieldByName('FORNECEDOR_NOME').AsString);
  LResponseObj.AddPair('marca', QueryHeader.Dataset.FieldByName('MARCA').AsString);
  LResponseObj.AddPair('representante', QueryHeader.Dataset.FieldByName('REPRESENTANTE').AsString);
  LResponseObj.AddPair('contato_representante', QueryHeader.Dataset.FieldByName('CONTATO_REPRESENTANTE').AsString);
  LResponseObj.AddPair('empresa_nome', QueryHeader.Dataset.FieldByName('EMPRESA_NOME').AsString);
  LResponseObj.AddPair('empresa_cnpj', QueryHeader.Dataset.FieldByName('EMPRESA_CNPJ').AsString);
  LResponseObj.AddPair('local_pedido', QueryHeader.Dataset.FieldByName('LOCAL_PEDIDO').AsString);
  LResponseObj.AddPair('local_entrega', QueryHeader.Dataset.FieldByName('LOCAL_ENTREGA').AsString);
  LResponseObj.AddPair('data_pedido', FormatDateTime('yyyy-mm-dd', QueryHeader.Dataset.FieldByName('DATA_PEDIDO').AsDateTime));
  LResponseObj.AddPair('data_entrega', QueryHeader.Dataset.FieldByName('DATA_ENTREGA').AsString);
  LResponseObj.AddPair('prazo_pagamento', QueryHeader.Dataset.FieldByName('PRAZO_PAGAMENTO').AsString);
  LResponseObj.AddPair('desconto_perc', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('DESCONTO_PERC').AsFloat));
  LResponseObj.AddPair('desconto_valor', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('DESCONTO_VALOR').AsFloat));
  LResponseObj.AddPair('imposto_icms', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('IMPOSTO_ICMS').AsFloat));
  LResponseObj.AddPair('total_pecas', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('TOTAL_PECAS').AsFloat));
  LResponseObj.AddPair('valor_total', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('VALOR_TOTAL').AsFloat));
  LResponseObj.AddPair('status', QueryHeader.Dataset.FieldByName('STATUS').AsString);
  LResponseObj.AddPair('observacao', QueryHeader.Dataset.FieldByName('OBSERVACAO').AsString);

  LItensArr := TJSONArray.Create;
  QueryItens.Open(Format('SELECT ID, PRODUTO_CODIGO, PRODUTO_NOME, COR, REFERENCIA, VALOR_UNITARIO, VALOR_IMPOSTO, VALOR_DINHEIRO, VALOR_VISTA, VALOR_PRAZO, GRADE_TAMANHOS, TOTAL_PECAS, VALOR_TOTAL FROM PEDIDOS_COMPRA_ITENS WHERE PEDIDO_ID = %d ORDER BY ID ASC', [LId]));
  QueryItens.Dataset.First;
  while not QueryItens.Dataset.Eof do
  begin
    LItemObj := TJSONObject.Create;
    LItemObj.AddPair('id', TJSONNumber.Create(QueryItens.Dataset.FieldByName('ID').AsInteger));
    LItemObj.AddPair('produto_codigo', TJSONNumber.Create(QueryItens.Dataset.FieldByName('PRODUTO_CODIGO').AsInteger));
    LItemObj.AddPair('produto_nome', QueryItens.Dataset.FieldByName('PRODUTO_NOME').AsString);
    LItemObj.AddPair('cor', QueryItens.Dataset.FieldByName('COR').AsString);
    LItemObj.AddPair('referencia', QueryItens.Dataset.FieldByName('REFERENCIA').AsString);
    LItemObj.AddPair('valor_unitario', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_UNITARIO').AsFloat));
    LItemObj.AddPair('valor_imposto', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_IMPOSTO').AsFloat));
    LItemObj.AddPair('valor_dinheiro', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_DINHEIRO').AsFloat));
    LItemObj.AddPair('valor_vista', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_VISTA').AsFloat));
    LItemObj.AddPair('valor_prazo', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_PRAZO').AsFloat));
    LItemObj.AddPair('grade_tamanhos', QueryItens.Dataset.FieldByName('GRADE_TAMANHOS').AsString);
    LItemObj.AddPair('total_pecas', TJSONNumber.Create(QueryItens.Dataset.FieldByName('TOTAL_PECAS').AsFloat));
    LItemObj.AddPair('valor_total', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_TOTAL').AsFloat));

    LItensArr.AddElement(LItemObj);
    QueryItens.Dataset.Next;
  end;
  LResponseObj.AddPair('itens', LItensArr);

  Res.Send<TJSONObject>(LResponseObj);
end;

class procedure TPedidosCompraController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LBody, LItemObj, LResObj: TJSONObject;
  LItensArr: TJSONArray;
  LPedidoId, I, LNewItemId: Integer;
  LQuery: iQuery;
  LDataPedidoStr: string;
begin
  EnsureTables;
  LBody := Req.Body<TJSONObject>;
  if not Assigned(LBody) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "JSON body esperado"}');
    Exit;
  end;

  try
    LQuery := TDatabase.Query;
    LPedidoId := LBody.GetValue<Integer>('id', 0);
    if LPedidoId <= 0 then
      LPedidoId := GeraCodigo('PEDIDOS_COMPRA', 'ID');

    LDataPedidoStr := LBody.GetValue<string>('data_pedido', FormatDateTime('yyyy-mm-dd', Date));

    LQuery.Clear;
    LQuery.Add('UPDATE OR INSERT INTO PEDIDOS_COMPRA (ID, NUMERO_ORDEM, FORNECEDOR_ID, FORNECEDOR_NOME, MARCA, REPRESENTANTE, CONTATO_REPRESENTANTE, EMPRESA_NOME, EMPRESA_CNPJ, LOCAL_PEDIDO, LOCAL_ENTREGA, DATA_PEDIDO, DATA_ENTREGA, PRAZO_PAGAMENTO, DESCONTO_PERC, DESCONTO_VALOR, IMPOSTO_ICMS, TOTAL_PECAS, VALOR_TOTAL, STATUS, OBSERVACAO)');
    LQuery.Add('VALUES (:ID, :NUM_ORDEM, :FOR_ID, :FOR_NOME, :MARCA, :REP, :REP_TEL, :EMP_NOME, :EMP_CNPJ, :LOC_PED, :LOC_ENT, :D_PED, :D_ENT, :PRAZO, :DESC_P, :DESC_V, :IMP, :TOT_P, :V_TOT, :STAT, :OBS)');
    LQuery.Add('MATCHING (ID)');

    LQuery.AddParam('ID', LPedidoId);
    LQuery.AddParam('NUM_ORDEM', LBody.GetValue<string>('numero_ordem', Format('%.3d/%.4d', [LPedidoId, StrToIntDef(FormatDateTime('yyyy', Date), 2026)])));
    LQuery.AddParam('FOR_ID', LBody.GetValue<Integer>('fornecedor_id', 0));
    LQuery.AddParam('FOR_NOME', LBody.GetValue<string>('fornecedor_nome', ''));
    LQuery.AddParam('MARCA', LBody.GetValue<string>('marca', ''));
    LQuery.AddParam('REP', LBody.GetValue<string>('representante', ''));
    LQuery.AddParam('REP_TEL', LBody.GetValue<string>('contato_representante', ''));
    LQuery.AddParam('EMP_NOME', LBody.GetValue<string>('empresa_nome', ''));
    LQuery.AddParam('EMP_CNPJ', LBody.GetValue<string>('empresa_cnpj', ''));
    LQuery.AddParam('LOC_PED', LBody.GetValue<string>('local_pedido', ''));
    LQuery.AddParam('LOC_ENT', LBody.GetValue<string>('local_entrega', ''));
    LQuery.AddParam('D_PED', LDataPedidoStr);
    LQuery.AddParam('D_ENT', LBody.GetValue<string>('data_entrega', ''));
    LQuery.AddParam('PRAZO', LBody.GetValue<string>('prazo_pagamento', ''));
    LQuery.AddParam('DESC_P', LBody.GetValue<Double>('desconto_perc', 0));
    LQuery.AddParam('DESC_V', LBody.GetValue<Double>('desconto_valor', 0));
    LQuery.AddParam('IMP', LBody.GetValue<Double>('imposto_icms', 0));
    LQuery.AddParam('TOT_P', LBody.GetValue<Double>('total_pecas', 0));
    LQuery.AddParam('V_TOT', LBody.GetValue<Double>('valor_total', 0));
    LQuery.AddParam('STAT', LBody.GetValue<string>('status', 'RASCUNHO'));
    LQuery.AddParam('OBS', LBody.GetValue<string>('observacao', ''));
    LQuery.ExecSQL;

    // Processa Itens do Pedido
    LItensArr := LBody.GetValue<TJSONArray>('itens', nil);
    if Assigned(LItensArr) then
    begin
      // Limpa itens anteriores do pedido
      LQuery.Clear;
      LQuery.Add('DELETE FROM PEDIDOS_COMPRA_ITENS WHERE PEDIDO_ID = :PID');
      LQuery.AddParam('PID', LPedidoId);
      LQuery.ExecSQL;

      for I := 0 to LItensArr.Count - 1 do
      begin
        LItemObj := TJSONObject(LItensArr.Items[I]);
        LNewItemId := GeraCodigo('PEDIDOS_COMPRA_ITENS', 'ID');

        LQuery.Clear;
        LQuery.Add('INSERT INTO PEDIDOS_COMPRA_ITENS (ID, PEDIDO_ID, PRODUTO_CODIGO, PRODUTO_NOME, COR, REFERENCIA, VALOR_UNITARIO, VALOR_IMPOSTO, VALOR_DINHEIRO, VALOR_VISTA, VALOR_PRAZO, GRADE_TAMANHOS, TOTAL_PECAS, VALOR_TOTAL)');
        LQuery.Add('VALUES (:ID, :PID, :PCOD, :PNOME, :COR, :REF, :VUNIT, :VIMP, :VDIN, :VVISTA, :VPRAZO, :GRADE, :TOT_P, :VTOT)');

        LQuery.AddParam('ID', LNewItemId);
        LQuery.AddParam('PID', LPedidoId);
        LQuery.AddParam('PCOD', LItemObj.GetValue<Integer>('produto_codigo', 0));
        LQuery.AddParam('PNOME', LItemObj.GetValue<string>('produto_nome', ''));
        LQuery.AddParam('COR', LItemObj.GetValue<string>('cor', ''));
        LQuery.AddParam('REF', LItemObj.GetValue<string>('referencia', ''));
        LQuery.AddParam('VUNIT', LItemObj.GetValue<Double>('valor_unitario', 0));
        LQuery.AddParam('VIMP', LItemObj.GetValue<Double>('valor_imposto', 0));
        LQuery.AddParam('VDIN', LItemObj.GetValue<Double>('valor_dinheiro', 0));
        LQuery.AddParam('VVISTA', LItemObj.GetValue<Double>('valor_vista', 0));
        LQuery.AddParam('VPRAZO', LItemObj.GetValue<Double>('valor_prazo', 0));
        LQuery.AddParam('GRADE', LItemObj.GetValue<string>('grade_tamanhos', '{}'));
        LQuery.AddParam('TOT_P', LItemObj.GetValue<Double>('total_pecas', 0));
        LQuery.AddParam('VTOT', LItemObj.GetValue<Double>('valor_total', 0));
        LQuery.ExecSQL;
      end;
    end;

    LResObj := TJSONObject.Create;
    LResObj.AddPair('id', TJSONNumber.Create(LPedidoId));
    LResObj.AddPair('msg', 'Pedido de compra salvo com sucesso');
    Res.Status(THTTPStatus.OK).Send(LResObj);
  except
    on E: Exception do
    begin
      Writeln('-> Erro ao salvar pedido de compra: ' + E.Message);
      LResObj := TJSONObject.Create;
      LResObj.AddPair('error', E.Message);
      Res.Status(THTTPStatus.InternalServerError).Send(LResObj);
    end;
  end;
end;

class procedure TPedidosCompraController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LId: Integer;
  LQuery: iQuery;
begin
  EnsureTables;
  LId := StrToIntDef(Req.Params.Items['id'], 0);
  if LId <= 0 then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "ID invalido"}');
    Exit;
  end;

  try
    LQuery := TDatabase.Query;
    LQuery.Clear;
    LQuery.Add('DELETE FROM PEDIDOS_COMPRA_ITENS WHERE PEDIDO_ID = :PID');
    LQuery.AddParam('PID', LId);
    LQuery.ExecSQL;

    LQuery.Clear;
    LQuery.Add('DELETE FROM PEDIDOS_COMPRA WHERE ID = :ID');
    LQuery.AddParam('ID', LId);
    LQuery.ExecSQL;

    Res.Send('').Status(THTTPStatus.NoContent);
  except
    on E: Exception do
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
  end;
end;

class procedure TPedidosCompraController.Router;
begin
  THorse.Group.Prefix('/v1')
    .Route('/pedidos-compra')
      .Get(Get)
      .Post(Post)
    .&End;

  THorse.Group.Prefix('/v1')
    .Route('/pedidos-compra/:id')
      .Get(GetForID)
      .Delete(Delete)
    .&End;
end;

end.
