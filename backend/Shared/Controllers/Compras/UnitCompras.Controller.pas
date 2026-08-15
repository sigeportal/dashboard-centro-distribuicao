unit UnitCompras.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Math,
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
	System.StrUtils,
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitCompras.Model,
  UnitFaturamento2.Model,
  UnitPagamentos.Model,
  UnitPagPgm.Model,
  UnitMovimentacoes.Model,
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
  LFat2: TFaturamento2;
  LPag: TPagamentos;
  LPagPgm: TPagPgm;
begin
  try
    // O PortalORM gerencia a verificacao e criacao das tabelas estruturais
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

    LFat2 := TFaturamento2.Create(TDatabase.Connection);
    try
      LFat2.CriaTabela;
    finally
      LFat2.DisposeOf;
    end;

    LPag := TPagamentos.Create(TDatabase.Connection);
    try
      LPag.CriaTabela;
    finally
      LPag.DisposeOf;
    end;

    LPagPgm := TPagPgm.Create(TDatabase.Connection);
    try
      LPagPgm.CriaTabela;
    finally
      LPagPgm.DisposeOf;
    end;
  except
    on E: Exception do
      Writeln('-> Verificacao tabelas ORM: ' + E.Message);
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
      Writeln('-> Erro ao buscar compras: ' + E.Message);
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TComprasController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LId, LFaturaId: Integer;
  LResponseObj, LItemObj, LParcObj: TJSONObject;
  LItensArr, LParcArr: TJSONArray;
  QueryHeader, QueryItens, QueryParc: iQuery;
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
  QueryParc := TDatabase.Query;

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
  QueryItens.Open(Format('SELECT ID, PRODUTO_CODIGO, PRODUTO_NOME, QUANTIDADE, VALOR_UNITARIO, VALOR_FRETE, VALOR_IPI, VALOR_ST, VALOR_OUTROS, CUSTO_MERCADORIA, CUSTO_MEDIO, CUSTO_OPERACIONAL FROM COMPRAS_ITENS WHERE COMPRA_ID = %d', [LId]));
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

  // Busca parcelas do Faturamento em PAGAMENTOS via FATURAMENTO2
  LParcArr := TJSONArray.Create;
  try
    QueryParc.Open(Format(
      'SELECT P.PAG_CODIGO, P.PAG_VALOR, P.PAG_VENCIMENTO, P.PAG_DUPLICATA, P.PAG_ESTADO, P.PAG_TIPO ' +
      'FROM PAGAMENTOS P ' +
      'INNER JOIN FATURAMENTO2 F ON (F.FAT2_CODIGO = P.PAG_FAT2) ' +
      'WHERE F.FAT2_DESCRICAO = %d ORDER BY P.PAG_CODIGO ASC',
      [LId]
    ));
    QueryParc.Dataset.First;
    while not QueryParc.Dataset.Eof do
    begin
      LParcObj := TJSONObject.Create;
      LParcObj.AddPair('id', TJSONNumber.Create(QueryParc.Dataset.FieldByName('PAG_CODIGO').AsInteger));
      LParcObj.AddPair('parcela', QueryParc.Dataset.FieldByName('PAG_DUPLICATA').AsString);
      LParcObj.AddPair('data_vencimento', FormatDateTime('yyyy-mm-dd', QueryParc.Dataset.FieldByName('PAG_VENCIMENTO').AsDateTime));
      LParcObj.AddPair('valor_parcela', TJSONNumber.Create(QueryParc.Dataset.FieldByName('PAG_VALOR').AsFloat));
      LParcObj.AddPair('forma_pagamento', QueryParc.Dataset.FieldByName('PAG_TIPO').AsString);
      LParcObj.AddPair('status', IfThen(QueryParc.Dataset.FieldByName('PAG_ESTADO').AsInteger = 3, 'PAGO', 'ABERTO'));

      LParcArr.AddElement(LParcObj);
      QueryParc.Dataset.Next;
    end;
  except
    // Caso ainda nao tenha faturamento associado
  end;
  LResponseObj.AddPair('parcelas', LParcArr);

  Res.Send<TJSONObject>(LResponseObj);
end;

class procedure TComprasController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LBody, LItemObj, LParcObj, LResObj: TJSONObject;
  LItensArr, LParcArr: TJSONArray;
  LCompraId, I, LProCodigo, LNewItemId, LFornId: Integer;
  LQuery, LQueryPro: iQuery;
  LQtd, LValUnit, LValFrete, LValIpi, LValSt, LValOutros: Double;
  LCustoEntrada, LRateio, LCustoMercadoria, LCustoOperacional, LCustoMedio: Double;
  LQtdAtual, LCustoMedioAtual: Double;
  LVendaDinheiro, LVendaVista, LVendaPrazo, LTotalCompra: Double;
  LNumDoc, LFornNome: string;
  // Models oficiais do sistema para Faturamento
  LFaturamento2: TFaturamento2;
  LPagamento: TPagamentos;
  LCodFat2, LCodPag: Integer;
  LDataVencStr: string;
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

    LNumDoc := LBody.GetValue<string>('numero_nf', '');
    LFornNome := LBody.GetValue<string>('fornecedor_nome', '');
    LFornId := LBody.GetValue<Integer>('fornecedor_id', 0);
    LTotalCompra := LBody.GetValue<Double>('valor_total', 0);

    LQuery.Clear;
    LQuery.Add('UPDATE OR INSERT INTO COMPRAS (ID, FORNECEDOR_ID, FORNECEDOR_NOME, NUMERO_NF, CHAVE_NFE, DATA_EMISSAO, DATA_ENTRADA, VALOR_TOTAL, VALOR_FRETE, VALOR_OUTROS, OBSERVACAO)');
    LQuery.Add('VALUES (:ID, :FOR_ID, :FOR_NOME, :NUM_NF, :CHAVE, :D_EMIS, :D_ENTR, :V_TOT, :V_FRETE, :V_OUTROS, :OBS)');
    LQuery.Add('MATCHING (ID)');

    LQuery.AddParam('ID', LCompraId);
    LQuery.AddParam('FOR_ID', LFornId);
    LQuery.AddParam('FOR_NOME', LFornNome);
    LQuery.AddParam('NUM_NF', LNumDoc);
    LQuery.AddParam('CHAVE', LBody.GetValue<string>('chave_nfe', ''));
    LQuery.AddParam('D_EMIS', FormatDateTime('yyyy-mm-dd', Date));
    LQuery.AddParam('D_ENTR', FormatDateTime('yyyy-mm-dd', Date));
    LQuery.AddParam('V_TOT', LTotalCompra);
    LQuery.AddParam('V_FRETE', LBody.GetValue<Double>('valor_frete', 0));
    LQuery.AddParam('V_OUTROS', LBody.GetValue<Double>('valor_outros', 0));
    LQuery.AddParam('OBS', LBody.GetValue<string>('observacao', ''));
    LQuery.ExecSQL;

    // Processa Itens e Recalcula Custos e Precos dos Produtos
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

        LCustoMercadoria := LCustoEntrada + LRateio;
        LCustoOperacional := LCustoMercadoria * 1.10;

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

        if (LQtdAtual + LQtd) > 0 then
          LCustoMedio := ((LQtdAtual * LCustoMedioAtual) + (LQtd * LCustoMercadoria)) / (LQtdAtual + LQtd)
        else
          LCustoMedio := LCustoMercadoria;

        // Precos de Venda Atualizados (da Analise de Custos F5)
        LVendaDinheiro := LItemObj.GetValue<Double>('valor_dinheiro', 0);
        LVendaVista := LItemObj.GetValue<Double>('valor_vista', 0);
        LVendaPrazo := LItemObj.GetValue<Double>('valor_prazo', 0);

        // Grava os novos custos, estoque e precos no produto
        LQuery.Clear;
        LQuery.Add('UPDATE PRODUTOS SET ');
        LQuery.Add('  PRO_QUANTIDADE = COALESCE(PRO_QUANTIDADE, 0) + :QTD,');
        LQuery.Add('  PRO_VALORC = :CUSTO_ENTRADA,');
        LQuery.Add('  PRO_VALORCM = :CUSTO_MEDIO,');
        LQuery.Add('  PRO_VALORF = :CUSTO_MERCADORIA,');
        LQuery.Add('  PRO_VALORL = :CUSTO_OPERACIONAL');

        if LVendaVista > 0 then
        begin
          LQuery.Add('  , PRO_VALORV = :V_VISTA');
          if LVendaDinheiro > 0 then
            LQuery.Add('  , PRO_VALOR_DINHEIRO = :V_DIN');
          if LVendaPrazo > 0 then
            LQuery.Add('  , PRO_VALORV_PRAZO = :V_PRAZO');
        end;

        LQuery.Add('WHERE PRO_CODIGO = :PRO_COD');

        LQuery.AddParam('QTD', LQtd);
        LQuery.AddParam('CUSTO_ENTRADA', LCustoEntrada);
        LQuery.AddParam('CUSTO_MEDIO', LCustoMedio);
        LQuery.AddParam('CUSTO_MERCADORIA', LCustoMercadoria);
        LQuery.AddParam('CUSTO_OPERACIONAL', LCustoOperacional);
        if LVendaVista > 0 then
        begin
          LQuery.AddParam('V_VISTA', LVendaVista);
          if LVendaDinheiro > 0 then
            LQuery.AddParam('V_DIN', LVendaDinheiro);
          if LVendaPrazo > 0 then
            LQuery.AddParam('V_PRAZO', LVendaPrazo);
        end;
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

        // Grava no Historico de Estoque (HIS_PRO)
        THisProController.RegistrarMovimentacao(
          LProCodigo,
          Date,
          'ENTRADA COMPRA/NF',
          LNumDoc,
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

    // Faturamento Oficial via FATURAMENTO2 e PAGAMENTOS (FormsComuns)
    LParcArr := LBody.GetValue<TJSONArray>('parcelas', nil);
    if Assigned(LParcArr) and (LParcArr.Count > 0) then
    begin
      // Cria/Atualiza Registro em FATURAMENTO2
      LCodFat2 := GeraCodigo('FATURAMENTO2', 'FAT2_CODIGO');
      LFaturamento2 := TFaturamento2.Create(TDatabase.Connection);
      try
        LFaturamento2.Codigo := LCodFat2;
        LFaturamento2.Tipo := 1; // Compra = 1
        LFaturamento2.Valor := LTotalCompra;
        LFaturamento2.Descricao := LCompraId; // Vinculo com ID da Compra
        LFaturamento2.TipoPgm := IfThen(LParcArr.Count = 1, 1, 2); // 1 = A Vista, 2 = A Prazo
        LFaturamento2.Parcelas := LParcArr.Count;
        LFaturamento2.Juros := 0;
        LFaturamento2.Data := Date;
        LFaturamento2.Cod_FDTF := LFornId;
        LFaturamento2.SalvaNoBanco(0);
      finally
        LFaturamento2.DisposeOf;
      end;

      // Cria os registros individuais de parcelas em PAGAMENTOS
      for I := 0 to LParcArr.Count - 1 do
      begin
        LParcObj := TJSONObject(LParcArr.Items[I]);
        LCodPag := GeraCodigo('PAGAMENTOS', 'PAG_CODIGO');
        LDataVencStr := LParcObj.GetValue<string>('data_vencimento', FormatDateTime('yyyy-mm-dd', Date + (30 * (I + 1))));

        LPagamento := TPagamentos.Create(TDatabase.Connection);
        try
          LPagamento.Codigo := LCodPag;
          LPagamento.Valor := LParcObj.GetValue<Double>('valor_parcela', 0);
          LPagamento.Vencimento := StrToDateDef(LDataVencStr, Date + (30 * (I + 1)));
          LPagamento.Juros := 0;
          LPagamento.Estado := 1; // 1 = Aberto / A Pagar, 3 = Quitado
          LPagamento.Duplicata := Format('%d-%d/%d', [LCodFat2, I + 1, LParcArr.Count]);
          LPagamento.Fpg := 1;
          LPagamento.Fat2 := LCodFat2;
          LPagamento.Descontos := 0;
          LPagamento.Tipo := LParcObj.GetValue<string>('forma_pagamento', 'BOLETO');
          LPagamento.Situacao := 0;
          LPagamento.Datac := Date;
          LPagamento.SalvaNoBanco(0);
        finally
          LPagamento.DisposeOf;
        end;
      end;
    end;

    LResObj := TJSONObject.Create;
    LResObj.AddPair('id', TJSONNumber.Create(LCompraId));
    LResObj.AddPair('msg', 'Compra lançada, custos atualizados e faturamento gravado com sucesso');
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
  LResponseObj.AddPair('valor_frete', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('VALOR_FRETE').AsFloat));
  LResponseObj.AddPair('valor_outros', TJSONNumber.Create(QueryHeader.Dataset.FieldByName('VALOR_OUTROS').AsFloat));
  LResponseObj.AddPair('observacao', QueryHeader.Dataset.FieldByName('OBSERVACAO').AsString);

  LItensArr := TJSONArray.Create;
  QueryItens.Open(Format('SELECT ID, PRODUTO_CODIGO, PRODUTO_NOME, QUANTIDADE, VALOR_UNITARIO, VALOR_FRETE, VALOR_IPI, VALOR_ST, VALOR_OUTROS, CUSTO_MERCADORIA, CUSTO_MEDIO, CUSTO_OPERACIONAL FROM COMPRAS_ITENS WHERE COMPRA_ID = %d', [LCompraId]));
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

end.
