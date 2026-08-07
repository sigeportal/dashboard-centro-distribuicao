unit UnitCompras.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  FireDAC.Comp.Client;

type
  TComprasController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure BuscarPorNfOuChave(Req: THorseRequest; Res: THorseResponse);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure EnsureComprasTables;
    class function ObterEmpresaId(Req: THorseRequest): Integer;
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitCompras.Model,
  UnitHisPro.Controller;

class function TComprasController.ObterEmpresaId(Req: THorseRequest): Integer;
var
  LEmpIdStr: string;
begin
  if Req.Headers.TryGetValue('X-Empresa-Id', LEmpIdStr) or
     Req.Headers.TryGetValue('x-empresa-id', LEmpIdStr) or
     Req.Headers.TryGetValue('X-Empresa-CC', LEmpIdStr) or
     Req.Headers.TryGetValue('x-empresa-cc', LEmpIdStr) then
    Result := StrToIntDef(LEmpIdStr, 1)
  else
    Result := StrToIntDef(Req.Query.Items['emp_id'], StrToIntDef(Req.Query.Items['emp_cc'], 1));
end;

class procedure TComprasController.EnsureComprasTables;
var
  LCompras: TCompras;
  LItens: TComprasItens;
begin
  try
    LCompras := TCompras.Create(TDatabase.Connection);
    try
      LCompras.CriaTabela;
    finally
      LCompras.DisposeOf;
    end;

    LItens := TComprasItens.Create(TDatabase.Connection);
    try
      LItens.CriaTabela;
    finally
      LItens.DisposeOf;
    end;
  except
    on E: Exception do
      Writeln('-> Erro ao verificar/criar tabelas de compras: ' + E.Message);
  end;
end;

class procedure TComprasController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LResponseObj, LMetaObj, LObj: TJSONObject;
  LDataArr: TJSONArray;
  QueryCount, QueryData: iQuery;
  LPage, LLimit, LOffset, LTotalRecords, LTotalPages, LEmpresaId: Integer;
begin
  EnsureComprasTables;
  LDataArr := TJSONArray.Create;
  QueryCount := TDatabase.Query;
  QueryData := TDatabase.Query;
  try
    LEmpresaId := ObterEmpresaId(Req);
    LPage := StrToIntDef(Req.Query.Items['page'], 1);
    if LPage < 1 then LPage := 1;

    LLimit := StrToIntDef(Req.Query.Items['limit'], 10);
    if LLimit < 1 then LLimit := 10;
    if LLimit > 100 then LLimit := 100;

    LOffset := (LPage - 1) * LLimit;

    if (LEmpresaId = 1) or (LEmpresaId = 5) then
    begin
      QueryCount.Open('SELECT COUNT(*) AS TOTAL FROM COMPRAS');
      LTotalRecords := QueryCount.Dataset.FieldByName('TOTAL').AsInteger;

      if LLimit > 0 then
        LTotalPages := (LTotalRecords + LLimit - 1) div LLimit
      else
        LTotalPages := 1;

      QueryData.Open(Format('SELECT FIRST %d SKIP %d ID, FORNECEDOR_ID, FORNECEDOR_NOME, NUMERO_NF, CHAVE_NFE, DATA_EMISSAO, DATA_ENTRADA, VALOR_TOTAL, VALOR_FRETE, VALOR_OUTROS, OBSERVACAO FROM COMPRAS ORDER BY ID DESC', [LLimit, LOffset]));
    end
    else
    begin
      QueryCount.Open(Format('SELECT COUNT(*) AS TOTAL FROM COMPRAS WHERE FORNECEDOR_ID = %d', [LEmpresaId]));
      LTotalRecords := QueryCount.Dataset.FieldByName('TOTAL').AsInteger;

      if LLimit > 0 then
        LTotalPages := (LTotalRecords + LLimit - 1) div LLimit
      else
        LTotalPages := 1;

      QueryData.Open(Format('SELECT FIRST %d SKIP %d ID, FORNECEDOR_ID, FORNECEDOR_NOME, NUMERO_NF, CHAVE_NFE, DATA_EMISSAO, DATA_ENTRADA, VALOR_TOTAL, VALOR_FRETE, VALOR_OUTROS, OBSERVACAO FROM COMPRAS WHERE FORNECEDOR_ID = %d ORDER BY ID DESC', [LLimit, LOffset, LEmpresaId]));
    end;
    QueryData.Dataset.First;

    while not QueryData.Dataset.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', TJSONNumber.Create(QueryData.Dataset.FieldByName('ID').AsInteger));
      LObj.AddPair('fornecedor_id', TJSONNumber.Create(QueryData.Dataset.FieldByName('FORNECEDOR_ID').AsInteger));
      LObj.AddPair('fornecedor_nome', QueryData.Dataset.FieldByName('FORNECEDOR_NOME').AsString);
      LObj.AddPair('numero_nf', QueryData.Dataset.FieldByName('NUMERO_NF').AsString);
      LObj.AddPair('chave_nfe', QueryData.Dataset.FieldByName('CHAVE_NFE').AsString);
      LObj.AddPair('data_emissao', FormatDateTime('yyyy-mm-dd', QueryData.Dataset.FieldByName('DATA_EMISSAO').AsDateTime));
      LObj.AddPair('data_entrada', FormatDateTime('yyyy-mm-dd', QueryData.Dataset.FieldByName('DATA_ENTRADA').AsDateTime));
      LObj.AddPair('valor_total', TJSONNumber.Create(QueryData.Dataset.FieldByName('VALOR_TOTAL').AsFloat));
      LObj.AddPair('valor_frete', TJSONNumber.Create(QueryData.Dataset.FieldByName('VALOR_FRETE').AsFloat));
      LObj.AddPair('valor_outros', TJSONNumber.Create(QueryData.Dataset.FieldByName('VALOR_OUTROS').AsFloat));
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
    begin
      LResponseObj := TJSONObject.Create;
      LMetaObj := TJSONObject.Create;
      LMetaObj.AddPair('page', TJSONNumber.Create(1));
      LMetaObj.AddPair('limit', TJSONNumber.Create(10));
      LMetaObj.AddPair('total', TJSONNumber.Create(0));
      LMetaObj.AddPair('pages', TJSONNumber.Create(1));

      LResponseObj.AddPair('data', TJSONArray.Create);
      LResponseObj.AddPair('meta', LMetaObj);
      Res.Send<TJSONObject>(LResponseObj);
    end;
  end;
end;

class procedure TComprasController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LId: Integer;
  LResponseObj, LItemObj: TJSONObject;
  LItensArr: TJSONArray;
  QueryHeader, QueryItens: iQuery;
begin
  EnsureComprasTables;
  LId := StrToIntDef(Req.Params.Items['id'], 0);
  if LId <= 0 then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "ID invalido"}');
    Exit;
  end;

  QueryHeader := TDatabase.Query;
  QueryItens := TDatabase.Query;

  QueryHeader.Open(Format('SELECT ID, FORNECEDOR_ID, FORNECEDOR_NOME, NUMERO_NF, CHAVE_NFE, DATA_EMISSAO, DATA_ENTRADA, VALOR_TOTAL, VALOR_FRETE, VALOR_OUTROS, OBSERVACAO FROM COMPRAS WHERE ID = %d', [LId]));
  if QueryHeader.Dataset.IsEmpty then
  begin
    Res.Status(THTTPStatus.NotFound).Send('{"error": "Compra nao encontrada"}');
    Exit;
  end;

  LResponseObj := TJSONObject.Create;
  LResponseObj.AddPair('id', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('ID').AsInteger));
  LResponseObj.AddPair('fornecedor_id', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('FORNECEDOR_ID').AsInteger));
  LResponseObj.AddPair('fornecedor_nome', QueryHeader.Dataset.FieldByName('FORNECEDOR_NOME').AsString);
  LResponseObj.AddPair('numero_nf', QueryHeader.Dataset.FieldByName('NUMERO_NF').AsString);
  LResponseObj.AddPair('chave_nfe', QueryHeader.Dataset.FieldByName('CHAVE_NFE').AsString);
  LResponseObj.AddPair('data_emissao', FormatDateTime('yyyy-mm-dd', QueryHeader.Dataset.FieldByName('DATA_EMISSAO').AsDateTime));
  LResponseObj.AddPair('data_entrada', FormatDateTime('yyyy-mm-dd', QueryHeader.Dataset.FieldByName('DATA_ENTRADA').AsDateTime));
  LResponseObj.AddPair('valor_total', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('VALOR_TOTAL').AsFloat));
  LResponseObj.AddPair('valor_frete', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('VALOR_FRETE').AsFloat));
  LResponseObj.AddPair('valor_outros', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('VALOR_OUTROS').AsFloat));
  LResponseObj.AddPair('observacao', QueryHeader.Dataset.FieldByName('OBSERVACAO').AsString);

  LItensArr := TJSONArray.Create;
  QueryItens.Open(Format('SELECT ID, COMPRA_ID, PRODUTO_CODIGO, PRODUTO_NOME, QUANTIDADE, VALOR_UNITARIO, VALOR_FRETE, VALOR_IPI, VALOR_ST, VALOR_OUTROS, CUSTO_MERCADORIA, CUSTO_MEDIO, CUSTO_OPERACIONAL FROM COMPRAS_ITENS WHERE COMPRA_ID = %d', [LId]));
  QueryItens.Dataset.First;

  while not QueryItens.Dataset.Eof do
  begin
    LItemObj := TJSONObject.Create;
    LItemObj.AddPair('id', TJSONNumber.Create(QueryItens.Dataset.FieldByName('ID').AsInteger));
    LItemObj.AddPair('produto_codigo', TJSONNumber.Create(QueryItens.Dataset.FieldByName('PRODUTO_CODIGO').AsInteger));
    LItemObj.AddPair('produto_nome', QueryItens.Dataset.FieldByName('PRODUTO_NOME').AsString);
    LItemObj.AddPair('quantidade', TJSONNumber.Create(QueryItens.Dataset.FieldByName('QUANTIDADE').AsFloat));
    LItemObj.AddPair('valor_unitario', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_UNITARIO').AsFloat));
    LItemObj.AddPair('valor_frete', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_FRETE').AsFloat));
    LItemObj.AddPair('valor_ipi', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_IPI').AsFloat));
    LItemObj.AddPair('valor_st', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_ST').AsFloat));
    LItemObj.AddPair('valor_outros', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_OUTROS').AsFloat));
    LItemObj.AddPair('custo_mercadoria', TJSONNumber.Create(QueryItens.Dataset.FieldByName('CUSTO_MERCADORIA').AsFloat));
    LItemObj.AddPair('custo_medio', TJSONNumber.Create(QueryItens.Dataset.FieldByName('CUSTO_MEDIO').AsFloat));
    LItemObj.AddPair('custo_operacional', TJSONNumber.Create(QueryItens.Dataset.FieldByName('CUSTO_OPERACIONAL').AsFloat));

    LItensArr.AddElement(LItemObj);
    QueryItens.Dataset.Next;
  end;

  LResponseObj.AddPair('itens', LItensArr);
  Res.Send<TJSONObject>(LResponseObj);
end;

class procedure TComprasController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LBody, LItemObj, LResObj: TJSONObject;
  LItensArr: TJSONArray;
  LCompraId, I, LProCodigo, LNewItemId: Integer;
  LQuery, LQueryPro: iQuery;
  LQtd, LValUnit, LValFrete, LValIpi, LValSt, LValOutros: Double;
  LCustoEntrada, LRateio, LCustoMercadoria, LCustoOperacional, LCustoMedio: Double;
  LQtdAtual, LCustoMedioAtual: Double;
begin
  EnsureComprasTables;
  LBody := Req.Body<TJSONObject>;
  if not Assigned(LBody) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "JSON body esperado"}');
    Exit;
  end;

  try
    LQuery := TDatabase.Query;

    LCompraId := LBody.GetValue<Integer>('id', 0);
    if LCompraId <= 0 then
      LCompraId := GeraCodigo('COMPRAS', 'ID');

    LQuery.Clear;
    LQuery.Add('UPDATE OR INSERT INTO COMPRAS (ID, FORNECEDOR_ID, FORNECEDOR_NOME, NUMERO_NF, CHAVE_NFE, DATA_EMISSAO, DATA_ENTRADA, VALOR_TOTAL, VALOR_FRETE, VALOR_OUTROS, OBSERVACAO)');
    LQuery.Add('VALUES (:ID, :FOR_ID, :FOR_NOME, :NUM_NF, :CHAVE, :D_EMIS, :D_ENTR, :V_TOT, :V_FRETE, :V_OUTROS, :OBS)');
    LQuery.Add('MATCHING (ID)');

    LQuery.AddParam('ID', LCompraId);
    LQuery.AddParam('FOR_ID', LBody.GetValue<Integer>('fornecedor_id', 0));
    LQuery.AddParam('FOR_NOME', LBody.GetValue<string>('fornecedor_nome', ''));
    LQuery.AddParam('NUM_NF', LBody.GetValue<string>('numero_nf', ''));
    LQuery.AddParam('CHAVE', LBody.GetValue<string>('chave_nfe', ''));
    LQuery.AddParam('D_EMIS', FormatDateTime('yyyy-mm-dd', Date));
    LQuery.AddParam('D_ENTR', FormatDateTime('yyyy-mm-dd', Date));
    LQuery.AddParam('V_TOT', LBody.GetValue<Double>('valor_total', 0));
    LQuery.AddParam('V_FRETE', LBody.GetValue<Double>('valor_frete', 0));
    LQuery.AddParam('V_OUTROS', LBody.GetValue<Double>('valor_outros', 0));
    LQuery.AddParam('OBS', LBody.GetValue<string>('observacao', ''));
    LQuery.ExecSQL;

    // Processa Itens e Recalcula Custos dos Produtos
    LItensArr := LBody.GetValue<TJSONArray>('itens', nil);
    if Assigned(LItensArr) then
    begin
      for I := 0 to LItensArr.Count - 1 do
      begin
        LItemObj := TJSONObject(LItensArr.Items[I]);
        LProCodigo := LItemObj.GetValue<Integer>('produto_codigo', 0);
        if LProCodigo <= 0 then Continue;

        LQtd := LItemObj.GetValue<Double>('quantidade', 0);
        LValUnit := LItemObj.GetValue<Double>('valor_unitario', 0);
        LValFrete := LItemObj.GetValue<Double>('valor_frete', 0);
        LValIpi := LItemObj.GetValue<Double>('valor_ipi', 0);
        LValSt := LItemObj.GetValue<Double>('valor_st', 0);
        LValOutros := LItemObj.GetValue<Double>('valor_outros', 0);

        LCustoEntrada := LValUnit;
        LRateio := 0;
        if LQtd > 0 then
          LRateio := (LValFrete + LValIpi + LValSt + LValOutros) / LQtd;

        LCustoMercadoria := LCustoEntrada + LRateio; // PRO_VALORF
        LCustoOperacional := LCustoMercadoria * 1.10; // PRO_VALORL (10% desp. operacional padrao)

        // Busca estoque e custo medio atual no produto
        LQueryPro := TDatabase.Query;
        LQueryPro.Open(Format('SELECT PRO_QUANTIDADE, PRO_VALORCM FROM PRODUTOS WHERE PRO_CODIGO = %d', [LProCodigo]));

        LQtdAtual := 0;
        LCustoMedioAtual := 0;
        if not LQueryPro.Dataset.IsEmpty then
        begin
          LQtdAtual := LQueryPro.Dataset.FieldByName('PRO_QUANTIDADE').AsFloat;
          LCustoMedioAtual := LQueryPro.Dataset.FieldByName('PRO_VALORCM').AsFloat;
        end;

        // Formula de Custo Medio Ponderado (UnitRegraCustoNF.Model.pas):
        // CustoMedio = ((QtdAnterior * CustoMedioAnterior) + (QtdNova * CustoEntradaNovo)) / (QtdAnterior + QtdNova)
        if (LQtdAtual + LQtd) > 0 then
          LCustoMedio := ((LQtdAtual * LCustoMedioAtual) + (LQtd * LCustoMercadoria)) / (LQtdAtual + LQtd)
        else
          LCustoMedio := LCustoMercadoria;

        // Grava os novos custos e estoque atualizado no produto
        LQuery.Clear;
        LQuery.Add('UPDATE PRODUTOS SET ');
        LQuery.Add('  PRO_QUANTIDADE = COALESCE(PRO_QUANTIDADE, 0) + :QTD,');
        LQuery.Add('  PRO_VALORC = :CUSTO_ENTRADA,');
        LQuery.Add('  PRO_VALORCM = :CUSTO_MEDIO,');
        LQuery.Add('  PRO_VALORF = :CUSTO_MERCADORIA,');
        LQuery.Add('  PRO_VALORL = :CUSTO_OPERACIONAL');
        LQuery.Add('WHERE PRO_CODIGO = :PRO_COD');

        LQuery.AddParam('QTD', LQtd);
        LQuery.AddParam('CUSTO_ENTRADA', LCustoEntrada);
        LQuery.AddParam('CUSTO_MEDIO', LCustoMedio);
        LQuery.AddParam('CUSTO_MERCADORIA', LCustoMercadoria);
        LQuery.AddParam('CUSTO_OPERACIONAL', LCustoOperacional);
        LQuery.AddParam('PRO_COD', LProCodigo);
        LQuery.ExecSQL;

        // Insere o Item da Compra
        LNewItemId := GeraCodigo('COMPRAS_ITENS', 'ID');
        LQuery.Clear;
        LQuery.Add('INSERT INTO COMPRAS_ITENS (ID, COMPRA_ID, PRODUTO_CODIGO, PRODUTO_NOME, QUANTIDADE, VALOR_UNITARIO, VALOR_FRETE, VALOR_IPI, VALOR_ST, VALOR_OUTROS, CUSTO_MERCADORIA, CUSTO_MEDIO, CUSTO_OPERACIONAL)');
        LQuery.Add('VALUES (:ID, :CID, :PCOD, :PNOME, :QTD, :VUNIT, :VFRETE, :VIPI, :VST, :VOUTROS, :CMERC, :CMED, :COPER)');

        LQuery.AddParam('ID', LNewItemId);
        LQuery.AddParam('CID', LCompraId);
        LQuery.AddParam('PCOD', LProCodigo);
        LQuery.AddParam('PNOME', LItemObj.GetValue<string>('produto_nome', ''));
        LQuery.AddParam('QTD', LQtd);
        LQuery.AddParam('VUNIT', LValUnit);
        LQuery.AddParam('VFRETE', LValFrete);
        LQuery.AddParam('VIPI', LValIpi);
        LQuery.AddParam('VST', LValSt);
        LQuery.AddParam('VOUTROS', LValOutros);
        LQuery.AddParam('CMERC', LCustoMercadoria);
        LQuery.AddParam('CMED', LCustoMedio);
        LQuery.AddParam('COPER', LCustoOperacional);
        LQuery.ExecSQL;

        // Grava no Histórico de Estoque (HIS_PRO)
        THisProController.RegistrarMovimentacao(
          LProCodigo,
          Date,
          'ENTRADA COMPRA/NF',
          LBody.GetValue<string>('numero_nf', IntToStr(LCompraId)),
          LQtd,
          LCustoEntrada,
          LValUnit,
          LCustoMedio,
          LCustoOperacional,
          LCustoMercadoria,
          'E',
          1,
          LQtdAtual
        );
      end;
    end;

    LResObj := TJSONObject.Create;
    LResObj.AddPair('id', TJSONNumber.Create(LCompraId));
    LResObj.AddPair('msg', 'Compra lançada e custos atualizados com sucesso');
    Res.Status(THTTPStatus.OK).Send(LResObj);
  except
    on E: Exception do
    begin
      Writeln('-> Erro ao salvar compra: ' + E.Message);
      LResObj := TJSONObject.Create;
      LResObj.AddPair('error', E.Message);
      Res.Status(THTTPStatus.InternalServerError).Send(LResObj);
    end;
  end;
end;

class procedure TComprasController.Router;
begin
  THorse.Group.Prefix('/v1')
    .Route('/compras')
      .Get(Get)
      .Post(Post)
    .&End;

  THorse.Group.Prefix('/v1')
    .Route('/compras/buscar-nf')
      .Get(BuscarPorNfOuChave)
    .&End;

  THorse.Group.Prefix('/v1')
    .Route('/compras/:id')
      .Get(GetForID)
    .&End;
end;

class procedure TComprasController.BuscarPorNfOuChave(Req: THorseRequest; Res: THorseResponse);
var
  LTermo: string;
  LResponseObj, LItemObj: TJSONObject;
  LItensArr: TJSONArray;
  QueryHeader, QueryItens: iQuery;
  LCompraId: Integer;
begin
  EnsureComprasTables;
  LTermo := Trim(Req.Query.Items['termo']);
  if LTermo.IsEmpty then LTermo := Trim(Req.Query.Items['busca']);
  if LTermo.IsEmpty then LTermo := Trim(Req.Query.Items['chave']);
  if LTermo.IsEmpty then LTermo := Trim(Req.Query.Items['numero']);

  if LTermo.IsEmpty then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "Termo de busca nao informado"}');
    Exit;
  end;

  QueryHeader := TDatabase.Query;
  QueryItens := TDatabase.Query;

  QueryHeader.Open(Format(
    'SELECT FIRST 1 ID, FORNECEDOR_ID, FORNECEDOR_NOME, NUMERO_NF, CHAVE_NFE, DATA_EMISSAO, DATA_ENTRADA, VALOR_TOTAL, VALOR_FRETE, VALOR_OUTROS, OBSERVACAO ' +
    'FROM COMPRAS WHERE CHAVE_NFE = %s OR NUMERO_NF = %s OR ID = %s',
    [QuotedStr(LTermo), QuotedStr(LTermo), QuotedStr(LTermo)]
  ));

  if QueryHeader.Dataset.IsEmpty then
  begin
    Res.Status(THTTPStatus.NotFound).Send('{"error": "Compra nao encontrada"}');
    Exit;
  end;

  LCompraId := QueryHeader.Dataset.FieldByName('ID').AsInteger;

  LResponseObj := TJSONObject.Create;
  LResponseObj.AddPair('id', TJSONNumber.Create(LCompraId));
  LResponseObj.AddPair('fornecedor_id', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('FORNECEDOR_ID').AsInteger));
  LResponseObj.AddPair('fornecedor_nome', QueryHeader.Dataset.FieldByName('FORNECEDOR_NOME').AsString);
  LResponseObj.AddPair('numero_nf', QueryHeader.Dataset.FieldByName('NUMERO_NF').AsString);
  LResponseObj.AddPair('chave_nfe', QueryHeader.Dataset.FieldByName('CHAVE_NFE').AsString);
  LResponseObj.AddPair('data_emissao', FormatDateTime('yyyy-mm-dd', QueryHeader.Dataset.FieldByName('DATA_EMISSAO').AsDateTime));
  LResponseObj.AddPair('data_entrada', FormatDateTime('yyyy-mm-dd', QueryHeader.Dataset.FieldByName('DATA_ENTRADA').AsDateTime));
  LResponseObj.AddPair('valor_total', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('VALOR_TOTAL').AsFloat));

  LItensArr := TJSONArray.Create;
  QueryItens.Open(Format(
    'SELECT ID, COMPRA_ID, PRODUTO_CODIGO, PRODUTO_NOME, QUANTIDADE, VALOR_UNITARIO, CUSTO_MEDIO ' +
    'FROM COMPRAS_ITENS WHERE COMPRA_ID = %d',
    [LCompraId]
  ));
  QueryItens.Dataset.First;

  while not QueryItens.Dataset.Eof do
  begin
    LItemObj := TJSONObject.Create;
    LItemObj.AddPair('id', TJSONNumber.Create(QueryItens.Dataset.FieldByName('ID').AsInteger));
    LItemObj.AddPair('produto_codigo', TJSONNumber.Create(QueryItens.Dataset.FieldByName('PRODUTO_CODIGO').AsInteger));
    LItemObj.AddPair('produto_nome', QueryItens.Dataset.FieldByName('PRODUTO_NOME').AsString);
    LItemObj.AddPair('quantidade', TJSONNumber.Create(QueryItens.Dataset.FieldByName('QUANTIDADE').AsFloat));
    LItemObj.AddPair('valor_unitario', TJSONNumber.Create(QueryItens.Dataset.FieldByName('VALOR_UNITARIO').AsFloat));

    LItensArr.AddElement(LItemObj);
    QueryItens.Dataset.Next;
  end;

  LResponseObj.AddPair('itens', LItensArr);
  Res.Send<TJSONObject>(LResponseObj);
end;

end.
