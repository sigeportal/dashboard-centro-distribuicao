unit UnitTransferencias.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json,
  System.Variants;

type
  TTransferenciasController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure AtualizarStatus(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);

    // Itens
    class procedure GetItens(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetItemForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure PostItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure PostItensEmLote(Req: THorseRequest; Res: THorseResponse);
    class procedure PutItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure DeleteItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TTransferenciasController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitTabela.Helpers,
  FireDAC.Comp.Client,
  UnitTransferencia.Model,
  UnitTransferenciaItem.Model,
  UnitHisPro.Controller;

class procedure TTransferenciasController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Transferencia: TTransferencia;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Transferencia := TTransferencia.Create(TDatabase.Connection);
    Transferencia.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Transferencia.DisposeOf;
  end;
end;

class procedure TTransferenciasController.DeleteItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var TransferenciaItem: TTransferenciaItem;
    id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    TransferenciaItem := TTransferenciaItem.Create(TDatabase.Connection);
    TransferenciaItem.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    TransferenciaItem.DisposeOf;
  end;
end;

class procedure TTransferenciasController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Transferencia: TTransferencia;
    aJson: TJSONArray;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
    Transferencia := TTransferencia.Create(TDatabase.Connection);
    try
      Transferencia.BuscaDadosTabela(GeraCodigo('TRANSFERENCIA', 'TR_ID')-1);
    except
      Transferencia.BuscaDadosTabela(1);
    end;
    Query.Open('SELECT TR_ID FROM TRANSFERENCIA ORDER BY TR_ID DESC');
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Transferencia.BuscaDadosTabela(Query.Dataset.FieldByName('TR_ID').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(Transferencia.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
    Transferencia.DisposeOf;
  end;
end;

class procedure TTransferenciasController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Transferencia: TTransferencia;
    id: Integer;
begin
  id := Req.Params.Items['id'].ToInteger();
  try
    Transferencia := TTransferencia.Create(TDatabase.Connection);
    Transferencia.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Transferencia.ToJson) as TJSONObject);
  finally
    Transferencia.DisposeOf;
  end;
end;

class procedure TTransferenciasController.GetItemForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var TransferenciaItem: TTransferenciaItem;
    id: Integer;
begin
  id := Req.Params.Items['id'].ToInteger();
  try
    TransferenciaItem := TTransferenciaItem.Create(TDatabase.Connection);
    TransferenciaItem.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(TransferenciaItem.ToJson) as TJSONObject);
  finally
    TransferenciaItem.DisposeOf;
  end;
end;

class procedure TTransferenciasController.GetItens(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
    aJson: TJSONArray;
    Query: iQuery;
    tr_id: string;
    itemObj: TJSONObject;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
    if Req.Params.ContainsKey('id') then
      tr_id := Req.Params.Items['id']
    else if Req.Query.ContainsKey('transferencia_id') then
      tr_id := Req.Query.Items['transferencia_id']
    else if Req.Query.ContainsKey('TR_ID') then
      tr_id := Req.Query.Items['TR_ID']
    else if Req.Query.ContainsKey('id') then
      tr_id := Req.Query.Items['id']
    else
      tr_id := '';

    if tr_id <> '' then
      Query.Open(
        'SELECT TI.TRI_ID, TI.TRI_TRANSFERENCIA_ID, TI.TRI_PRODUTO_ID, TI.TRI_QUANTIDADE, TI.TRI_VALOR, TI.TRI_QTD_CONFERIDA, TI.TRI_JUSTIFICATIVA, ' +
        '       P.PRO_NOME, P.PRO_CODBARRA, P.PRO_NCM, P.PRO_CFOP, P.PRO_CEST, P.PRO_EMBALAGEM, P.PRO_BALANCA, P.PRO_GRU, P.PRO_VALORC, ' +
        '       COALESCE(P.PRO_COD_FISCAL, 0) AS PRO_COD_FISCAL, COALESCE(P.PRO_FISCAL_GERAR, ''S'') AS PRO_FISCAL_GERAR, P.PRO_TIPO ' +
        'FROM TRANSFERENCIA_ITEM TI ' +
        'LEFT JOIN PRODUTOS P ON (P.PRO_CODIGO = TI.TRI_PRODUTO_ID) ' +
        'WHERE TI.TRI_TRANSFERENCIA_ID = ' + tr_id + ' ' +
        'ORDER BY TI.TRI_ID'
      )
    else
      Query.Open(
        'SELECT TI.TRI_ID, TI.TRI_TRANSFERENCIA_ID, TI.TRI_PRODUTO_ID, TI.TRI_QUANTIDADE, TI.TRI_VALOR, TI.TRI_QTD_CONFERIDA, TI.TRI_JUSTIFICATIVA, ' +
        '       P.PRO_NOME, P.PRO_CODBARRA, P.PRO_NCM, P.PRO_CFOP, P.PRO_CEST, P.PRO_EMBALAGEM, P.PRO_BALANCA, P.PRO_GRU, P.PRO_VALORC, ' +
        '       COALESCE(P.PRO_COD_FISCAL, 0) AS PRO_COD_FISCAL, COALESCE(P.PRO_FISCAL_GERAR, ''S'') AS PRO_FISCAL_GERAR, P.PRO_TIPO ' +
        'FROM TRANSFERENCIA_ITEM TI ' +
        'LEFT JOIN PRODUTOS P ON (P.PRO_CODIGO = TI.TRI_PRODUTO_ID) ' +
        'ORDER BY TI.TRI_ID'
      );
      
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      itemObj := TJSONObject.Create;
      itemObj.AddPair('id', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_ID').AsInteger));
      itemObj.AddPair('tri_id', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_ID').AsInteger));
      itemObj.AddPair('transferenciaId', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_TRANSFERENCIA_ID').AsInteger));
      itemObj.AddPair('tri_transferencia_id', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_TRANSFERENCIA_ID').AsInteger));
      itemObj.AddPair('produtoId', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_PRODUTO_ID').AsInteger));
      itemObj.AddPair('tri_produto_id', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_PRODUTO_ID').AsInteger));
      itemObj.AddPair('quantidade', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_QUANTIDADE').AsFloat));
      itemObj.AddPair('tri_quantidade', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_QUANTIDADE').AsFloat));
      itemObj.AddPair('valor', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_VALOR').AsFloat));
      itemObj.AddPair('tri_valor', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_VALOR').AsFloat));
      itemObj.AddPair('quantidadeConferida', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_QTD_CONFERIDA').AsFloat));
      itemObj.AddPair('tri_qtd_conferida', TJSONNumber.Create(Query.Dataset.FieldByName('TRI_QTD_CONFERIDA').AsFloat));
      itemObj.AddPair('justificativa', Query.Dataset.FieldByName('TRI_JUSTIFICATIVA').AsString);
      itemObj.AddPair('tri_justificativa', Query.Dataset.FieldByName('TRI_JUSTIFICATIVA').AsString);
      
      // Dados completos do produto e classificacao fiscal
      itemObj.AddPair('nome', Query.Dataset.FieldByName('PRO_NOME').AsString);
      itemObj.AddPair('PRO_NOME', Query.Dataset.FieldByName('PRO_NOME').AsString);
      itemObj.AddPair('codbarra', Query.Dataset.FieldByName('PRO_CODBARRA').AsString);
      itemObj.AddPair('PRO_CODBARRA', Query.Dataset.FieldByName('PRO_CODBARRA').AsString);
      itemObj.AddPair('ncm', Query.Dataset.FieldByName('PRO_NCM').AsString);
      itemObj.AddPair('PRO_NCM', Query.Dataset.FieldByName('PRO_NCM').AsString);
      itemObj.AddPair('cfop', Query.Dataset.FieldByName('PRO_CFOP').AsString);
      itemObj.AddPair('PRO_CFOP', Query.Dataset.FieldByName('PRO_CFOP').AsString);
      itemObj.AddPair('cest', Query.Dataset.FieldByName('PRO_CEST').AsString);
      itemObj.AddPair('embalagem', Query.Dataset.FieldByName('PRO_EMBALAGEM').AsString);
      itemObj.AddPair('balanca', Query.Dataset.FieldByName('PRO_BALANCA').AsString);
      itemObj.AddPair('custo', TJSONNumber.Create(Query.Dataset.FieldByName('PRO_VALORC').AsFloat));
      itemObj.AddPair('codFiscal', TJSONNumber.Create(Query.Dataset.FieldByName('PRO_COD_FISCAL').AsInteger));
      itemObj.AddPair('pro_cod_fiscal', TJSONNumber.Create(Query.Dataset.FieldByName('PRO_COD_FISCAL').AsInteger));
      itemObj.AddPair('fiscalGerar', Query.Dataset.FieldByName('PRO_FISCAL_GERAR').AsString);
      itemObj.AddPair('pro_fiscal_gerar', Query.Dataset.FieldByName('PRO_FISCAL_GERAR').AsString);
      itemObj.AddPair('pro_tipo', Query.Dataset.FieldByName('PRO_TIPO').AsString);
      
      aJson.Add(itemObj);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
  end;
end;

class procedure TTransferenciasController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Transferencia: TTransferencia;
  LResObj, LBodyObj, LItemObj: TJSONObject;
  LItensArr: TJSONArray;
  LItemVal: TJSONValue;
  LItem: TTransferenciaItem;
  i, LTrId: Integer;
begin
  try
    LBodyObj := Req.Body<TJSONObject>;
    Transferencia := TTransferencia.Create(TDatabase.Connection).fromJson<TTransferencia>(Req.Body);
    if Transferencia.Id <= 0 then
      Transferencia.Id := GeraCodigo('TRANSFERENCIA', 'TR_ID');
    if Transferencia.Status.IsEmpty then
      Transferencia.Status := 'Em Trânsito';
    if Transferencia.Data = 0 then
      Transferencia.Data := Date;
    Transferencia.SalvaNoBanco(1);
    LTrId := Transferencia.Id;

    // Se vierem itens no payload, salva automaticamente em lote
    if Assigned(LBodyObj) and (LBodyObj.TryGetValue<TJSONArray>('itens', LItensArr) or LBodyObj.TryGetValue<TJSONArray>('items', LItensArr)) then
    begin
      for i := 0 to Pred(LItensArr.Count) do
      begin
        LItemVal := LItensArr.Items[i];
        if LItemVal is TJSONObject then
        begin
          LItemObj := TJSONObject(LItemVal);
          LItem := TTransferenciaItem.Create(TDatabase.Connection);
          try
            LItem.Id := GeraCodigo('TRANSFERENCIA_ITEM', 'TRI_ID');
            LItem.TransferenciaId := LTrId;
            LItem.ProdutoId := LItemObj.GetValue<Integer>('produto_id', LItemObj.GetValue<Integer>('produtoId', 0));
            LItem.Quantidade := LItemObj.GetValue<Double>('quantidade', 1);
            LItem.Valor := LItemObj.GetValue<Double>('valor', 0);
            LItem.QuantidadeConferida := LItem.Quantidade;
            LItem.Justificativa := LItemObj.GetValue<string>('justificativa', '');
            LItem.SalvaNoBanco(1);
          finally
            LItem.DisposeOf;
          end;
        end;
      end;
    end;

    LResObj := TJSONObject.ParseJSONValue(Transferencia.ToJson) as TJSONObject;
    if Assigned(LResObj) then
    begin
      LResObj.RemovePair('id');
      LResObj.AddPair('id', TJSONNumber.Create(Transferencia.Id));
      LResObj.AddPair('tr_id', TJSONNumber.Create(Transferencia.Id));
    end;
    Res.Send<TJSONObject>(LResObj);
  finally
    Transferencia.DisposeOf;
  end;
end;

class procedure TTransferenciasController.PostEmLote(Req: THorseRequest; Res: THorseResponse);
var
  Itens     : TTransferencia;
  aJson     : TJSONArray;
  oJsonValue: TJSONValue;
  oJson     : TJSONObject;
  LQuery    : iQuery;
  FDQuery   : TFDQuery;
  i         : Integer;
  Transferencia: TTransferencia;
begin
  Transferencia := TTransferencia.Create(TDatabase.Connection);
  try
    try
      Transferencia.BuscaDadosTabela(GeraCodigo('TRANSFERENCIA', 'TR_ID')-1);
    except
      Transferencia.BuscaDadosTabela(1);
    end;    
    oJson   := Req.Body<TJSONObject>;
    aJson   := oJson.GetValue<TJSONArray>('itens');
    LQuery  := TDatabase.Query;
    FDQuery := TFDQuery(LQuery.Query);
    FDQuery.Close;
    FDQuery.SQL.Add('UPDATE OR INSERT INTO TRANSFERENCIA (TR_ID, TR_ORIGEM, TR_DESTINO, TR_DATA, TR_STATUS, TR_OBS, TR_USUARIO_RECEBIMENTO, TR_DATA_RECEBIMENTO, TR_TIPO_FISCAL, TR_NUMERO_NF, TR_CHAVE_NFE)');
    FDQuery.SQL.Add('VALUES (:TR_ID, :TR_ORIGEM, :TR_DESTINO, :TR_DATA, :TR_STATUS, :TR_OBS, :TR_USUARIO_RECEBIMENTO, :TR_DATA_RECEBIMENTO, :TR_TIPO_FISCAL, :TR_NUMERO_NF, :TR_CHAVE_NFE)');
    FDQuery.SQL.Add('MATCHING (TR_ID)');  
    // preparando para usar inserções via ArrayDML
    FDQuery.Params.ArraySize := aJson.Count;
    for i                    := 0 to Pred(aJson.Count) do
    begin
      oJsonValue := aJson.Items[i];
      Itens      := TTransferencia.Create(TDatabase.Connection).fromJson<TTransferencia>(oJsonValue.ToJson);
      try
        if Itens.Id <= 0 then
          FDQuery.ParamByName('TR_ID').AsIntegers[i] := GeraCodigo('TRANSFERENCIA', 'TR_ID')
        else
          FDQuery.ParamByName('TR_ID').AsIntegers[i] := Itens.Id;
        FDQuery.ParamByName('TR_ORIGEM').AsIntegers[i] := Itens.Origem;
        FDQuery.ParamByName('TR_DESTINO').AsIntegers[i] := Itens.Destino;
        FDQuery.ParamByName('TR_DATA').AsDateTimes[i] := Itens.Data;
        FDQuery.ParamByName('TR_STATUS').AsStrings[i] := Itens.Status;
        FDQuery.ParamByName('TR_OBS').AsStrings[i] := Itens.Obs;
        FDQuery.ParamByName('TR_USUARIO_RECEBIMENTO').AsStrings[i] := Itens.UsuarioRecebimento;
        FDQuery.ParamByName('TR_TIPO_FISCAL').AsStrings[i] := Itens.TipoFiscal;
        FDQuery.ParamByName('TR_NUMERO_NF').AsStrings[i] := Itens.NumeroNf;
        FDQuery.ParamByName('TR_CHAVE_NFE').AsStrings[i] := Itens.ChaveNfe;
        if Itens.DataRecebimento > 0 then
          FDQuery.ParamByName('TR_DATA_RECEBIMENTO').AsDateTimes[i] := Itens.DataRecebimento
        else
          FDQuery.ParamByName('TR_DATA_RECEBIMENTO').AsDateTimes[i] := Null;
      finally
        Itens.DisposeOf;
      end;
    end;
    // Executa as inserções em lote
    FDQuery.Execute(aJson.Count, 0);
    Res.Send<TJSONObject>(oJson);
  finally
    Transferencia.DisposeOf;
  end;
end;

class procedure TTransferenciasController.PostItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var TransferenciaItem: TTransferenciaItem;
begin
  try
    TransferenciaItem := TTransferenciaItem.Create(TDatabase.Connection).fromJson<TTransferenciaItem>(Req.Body);
    if TransferenciaItem.Id <= 0 then
      TransferenciaItem.Id := GeraCodigo('TRANSFERENCIA_ITEM', 'TRI_ID');
    TransferenciaItem.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(TransferenciaItem.ToJson) as TJSONObject);
  finally
    TransferenciaItem.DisposeOf;
  end;
end;

class procedure TTransferenciasController.PostItensEmLote(Req: THorseRequest; Res: THorseResponse);
var
  Itens     : TTransferenciaItem;
  aJson     : TJSONArray;
  oJsonValue: TJSONValue;
  oJson     : TJSONObject;
  LQuery    : iQuery;
  FDQuery   : TFDQuery;
  i         : Integer;
  TransferenciaItem: TTransferenciaItem;
  LQueryEst, LQueryCheck, LQueryUpsert, LQueryEmp: iQuery;
  LOrigemId, LDestinoId: Integer;
  LNomeOrigem, LNomeDestino: string;
  LQtdFinal: Double;
begin
  TransferenciaItem := TTransferenciaItem.Create(TDatabase.Connection);
  try
    try
      TransferenciaItem.BuscaDadosTabela(GeraCodigo('TRANSFERENCIA_ITEM', 'TRI_ID')-1);
    except
      TransferenciaItem.BuscaDadosTabela(1);
    end;    
    oJson   := Req.Body<TJSONObject>;
    aJson   := oJson.GetValue<TJSONArray>('itens');
    LQuery  := TDatabase.Query;
    FDQuery := TFDQuery(LQuery.Query);
    FDQuery.Close;
    FDQuery.SQL.Add('UPDATE OR INSERT INTO TRANSFERENCIA_ITEM (TRI_ID, TRI_TRANSFERENCIA_ID, TRI_PRODUTO_ID, TRI_QUANTIDADE, TRI_VALOR, TRI_QTD_CONFERIDA, TRI_JUSTIFICATIVA)');
    FDQuery.SQL.Add('VALUES (:TRI_ID, :TRI_TRANSFERENCIA_ID, :TRI_PRODUTO_ID, :TRI_QUANTIDADE, :TRI_VALOR, :TRI_QTD_CONFERIDA, :TRI_JUSTIFICATIVA)');
    FDQuery.SQL.Add('MATCHING (TRI_ID)');  
    // preparando para usar inserções via ArrayDML
    FDQuery.Params.ArraySize := aJson.Count;
    for i                    := 0 to Pred(aJson.Count) do
    begin
      oJsonValue := aJson.Items[i];
      Itens      := TTransferenciaItem.Create(TDatabase.Connection).fromJson<TTransferenciaItem>(oJsonValue.ToJson);
      try
        if Itens.Id <= 0 then
          FDQuery.ParamByName('TRI_ID').AsIntegers[i] := GeraCodigo('TRANSFERENCIA_ITEM', 'TRI_ID')
        else
          FDQuery.ParamByName('TRI_ID').AsIntegers[i] := Itens.Id;
        FDQuery.ParamByName('TRI_TRANSFERENCIA_ID').AsIntegers[i] := Itens.TransferenciaId;
        FDQuery.ParamByName('TRI_PRODUTO_ID').AsIntegers[i] := Itens.ProdutoId;
        FDQuery.ParamByName('TRI_QUANTIDADE').AsFloats[i] := Itens.Quantidade;
        FDQuery.ParamByName('TRI_VALOR').AsFloats[i] := Itens.Valor;
        FDQuery.ParamByName('TRI_QTD_CONFERIDA').AsFloats[i] := Itens.QuantidadeConferida;
        FDQuery.ParamByName('TRI_JUSTIFICATIVA').AsStrings[i] := Itens.Justificativa;

        // Movimentação de estoque e histórico
        try
          LQueryEst := TDatabase.Query;
          LQueryEst.Open(Format('SELECT TR_ORIGEM, TR_DESTINO FROM TRANSFERENCIA WHERE TR_ID = %d', [Itens.TransferenciaId]));
          if not LQueryEst.DataSet.Eof then
          begin
            LOrigemId  := LQueryEst.DataSet.FieldByName('TR_ORIGEM').AsInteger;
            LDestinoId := LQueryEst.DataSet.FieldByName('TR_DESTINO').AsInteger;

            LNomeOrigem  := 'UNIDADE #' + IntToStr(LOrigemId);
            LNomeDestino := 'UNIDADE #' + IntToStr(LDestinoId);

            try
              LQueryEmp := TDatabase.Query;
              LQueryEmp.Open(Format('SELECT EMP_CODIGO, EMP_FANTASIA, EMP_RAZAO_SOCIAL FROM EMPRESA WHERE EMP_CODIGO IN (%d, %d)', [LOrigemId, LDestinoId]));
              while not LQueryEmp.DataSet.Eof do
              begin
                if LQueryEmp.DataSet.FieldByName('EMP_CODIGO').AsInteger = LOrigemId then
                begin
                  LNomeOrigem := LQueryEmp.DataSet.FieldByName('EMP_FANTASIA').AsString;
                  if LNomeOrigem.IsEmpty then
                    LNomeOrigem := LQueryEmp.DataSet.FieldByName('EMP_RAZAO_SOCIAL').AsString;
                end
                else if LQueryEmp.DataSet.FieldByName('EMP_CODIGO').AsInteger = LDestinoId then
                begin
                  LNomeDestino := LQueryEmp.DataSet.FieldByName('EMP_FANTASIA').AsString;
                  if LNomeDestino.IsEmpty then
                    LNomeDestino := LQueryEmp.DataSet.FieldByName('EMP_RAZAO_SOCIAL').AsString;
                end;
                LQueryEmp.DataSet.Next;
              end;
            except
            end;

            // Usar SOMENTE a quantidade efetivamente conferida (ou se for 0, usa a solicitada)
            if Itens.QuantidadeConferida > 0 then
              LQtdFinal := Itens.QuantidadeConferida
            else
              LQtdFinal := Itens.Quantidade;

            // 1. Gravar Histórico de Estoque com o Nome da Unidade Origem e Destino
            THisProController.RegistrarMovimentacao(
              Itens.ProdutoId,
              Date,
              Copy('TRANSF: ' + LNomeOrigem + ' -> ' + LNomeDestino, 1, 30),
              IntToStr(Itens.TransferenciaId),
              LQtdFinal,
              Itens.Valor,
              Itens.Valor,
              Itens.Valor,
              0,
              Itens.Valor,
              'T',
              2,
              0
            );

            // 2. DAR BAIXA NA UNIDADE ORIGEM (ESTOQUE_EMPRESA)
            if LOrigemId > 0 then
            begin
              LQueryCheck := TDatabase.Query;
              LQueryCheck.Open(Format('SELECT EE_ID FROM ESTOQUE_EMPRESA WHERE EE_EMPRESA_ID = %d AND EE_PRO_CODIGO = %d', [LOrigemId, Itens.ProdutoId]));
              LQueryUpsert := TDatabase.Query;
              if not LQueryCheck.DataSet.Eof then
              begin
                LQueryUpsert.Add(Format(
                  'UPDATE ESTOQUE_EMPRESA SET EE_QUANTIDADE = EE_QUANTIDADE - %s, EE_DATA_ATUALIZACAO = CURRENT_TIMESTAMP WHERE EE_EMPRESA_ID = %d AND EE_PRO_CODIGO = %d',
                  [FloatToStr(LQtdFinal).Replace(',', '.'), LOrigemId, Itens.ProdutoId]
                ));
                LQueryUpsert.ExecSQL;
              end
              else
              begin
                LQueryUpsert.Add(Format(
                  'INSERT INTO ESTOQUE_EMPRESA (EE_ID, EE_EMPRESA_ID, EE_PRO_CODIGO, EE_QUANTIDADE, EE_DATA_ATUALIZACAO) ' +
                  'VALUES (%d, %d, %d, -%s, CURRENT_TIMESTAMP)',
                  [GeraCodigo('ESTOQUE_EMPRESA', 'EE_ID'), LOrigemId, Itens.ProdutoId, FloatToStr(LQtdFinal).Replace(',', '.')]
                ));
                LQueryUpsert.ExecSQL;
              end;

              // Se a origem for a Matriz (CD Douradina / Principal), também atualiza PRODUTOS
              if (LOrigemId = 1) or (LOrigemId = 5) then
              begin
                LQueryUpsert.Clear;
                LQueryUpsert.Add(Format(
                  'UPDATE PRODUTOS SET PRO_QUANTIDADE = PRO_QUANTIDADE - %s, PRO_CADASTRAR = ''S'' WHERE PRO_CODIGO = %d',
                  [FloatToStr(LQtdFinal).Replace(',', '.'), Itens.ProdutoId]
                ));
                LQueryUpsert.ExecSQL;
              end;
            end;

            // 3. INCREMENTAR NA UNIDADE DESTINO (ESTOQUE_EMPRESA)
            if LDestinoId > 0 then
            begin
              LQueryCheck := TDatabase.Query;
              LQueryCheck.Open(Format('SELECT EE_ID FROM ESTOQUE_EMPRESA WHERE EE_EMPRESA_ID = %d AND EE_PRO_CODIGO = %d', [LDestinoId, Itens.ProdutoId]));
              LQueryUpsert := TDatabase.Query;
              if not LQueryCheck.DataSet.Eof then
              begin
                LQueryUpsert.Add(Format(
                  'UPDATE ESTOQUE_EMPRESA SET EE_QUANTIDADE = EE_QUANTIDADE + %s, EE_DATA_ATUALIZACAO = CURRENT_TIMESTAMP WHERE EE_EMPRESA_ID = %d AND EE_PRO_CODIGO = %d',
                  [FloatToStr(LQtdFinal).Replace(',', '.'), LDestinoId, Itens.ProdutoId]
                ));
                LQueryUpsert.ExecSQL;
              end
              else
              begin
                LQueryUpsert.Add(Format(
                  'INSERT INTO ESTOQUE_EMPRESA (EE_ID, EE_EMPRESA_ID, EE_PRO_CODIGO, EE_QUANTIDADE, EE_DATA_ATUALIZACAO) ' +
                  'VALUES (%d, %d, %d, %s, CURRENT_TIMESTAMP)',
                  [GeraCodigo('ESTOQUE_EMPRESA', 'EE_ID'), LDestinoId, Itens.ProdutoId, FloatToStr(LQtdFinal).Replace(',', '.')]
                ));
                LQueryUpsert.ExecSQL;
              end;

              // Se o destino for a Matriz (CD Douradina / Principal), também incrementa em PRODUTOS
              if (LDestinoId = 1) or (LDestinoId = 5) then
              begin
                LQueryUpsert.Clear;
                LQueryUpsert.Add(Format(
                  'UPDATE PRODUTOS SET PRO_QUANTIDADE = PRO_QUANTIDADE + %s, PRO_CADASTRAR = ''S'' WHERE PRO_CODIGO = %d',
                  [FloatToStr(LQtdFinal).Replace(',', '.'), Itens.ProdutoId]
                ));
                LQueryUpsert.ExecSQL;
              end;
            end;

          end;
        except
          on E: Exception do
            Writeln('-> Erro ao atualizar ESTOQUE_EMPRESA em PostItensEmLote: ' + E.Message);
        end;
      finally
        Itens.DisposeOf;
      end;
    end;
    // Executa as inserções em lote
    FDQuery.Execute(aJson.Count, 0);
    Res.Send<TJSONObject>(oJson);
  finally
    TransferenciaItem.DisposeOf;
  end;
end;

class procedure TTransferenciasController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Transferencia: TTransferencia;
begin
  try
    Transferencia := TTransferencia.Create(TDatabase.Connection).fromJson<TTransferencia>(Req.Body);
    Transferencia.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Transferencia.ToJson) as TJSONObject);
  finally
    Transferencia.DisposeOf;
  end;
end;

class procedure TTransferenciasController.PutItem(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var TransferenciaItem: TTransferenciaItem;
begin
  try
    TransferenciaItem := TTransferenciaItem.Create(TDatabase.Connection).fromJson<TTransferenciaItem>(Req.Body);
    TransferenciaItem.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(TransferenciaItem.ToJson) as TJSONObject);
  finally
    TransferenciaItem.DisposeOf;
  end;
end;

class procedure TTransferenciasController.AtualizarStatus(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  id: string;
  oJson: TJSONObject;
  st, obs, usr: string;
  Query: iQuery;
begin
  id := Req.Params.Items['id'];
  st := 'RECEBIDO';
  obs := '';
  usr := 'OPERADOR';
  try
    oJson := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
    if oJson <> nil then
    begin
      if oJson.GetValue('status') <> nil then
        st := oJson.GetValue('status').Value
      else if oJson.GetValue('TR_STATUS') <> nil then
        st := oJson.GetValue('TR_STATUS').Value;

      if oJson.GetValue('obs') <> nil then
        obs := oJson.GetValue('obs').Value
      else if oJson.GetValue('TR_OBS') <> nil then
        obs := oJson.GetValue('TR_OBS').Value;

      if oJson.GetValue('usuario') <> nil then
        usr := oJson.GetValue('usuario').Value
      else if oJson.GetValue('usuarioRecebimento') <> nil then
        usr := oJson.GetValue('usuarioRecebimento').Value
      else if oJson.GetValue('TR_USUARIO_RECEBIMENTO') <> nil then
        usr := oJson.GetValue('TR_USUARIO_RECEBIMENTO').Value;
      oJson.DisposeOf;
    end;
  except
  end;

  try
    Query := TDatabase.Query;
    Query.Add('UPDATE TRANSFERENCIA SET TR_STATUS = ''' + st + ''', TR_USUARIO_RECEBIMENTO = ''' + usr + ''', TR_DATA_RECEBIMENTO = CURRENT_TIMESTAMP WHERE TR_ID = ' + id);
    Query.ExecSQL;
  except
  end;

  Res.Send<TJSONObject>(TJSONObject.Create.AddPair('sucesso', TJSONBool.Create(True)).AddPair('status', st));
end;

class procedure TTransferenciasController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/transferencias')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Prefix('/v1')
        .Route('/transferencias/:id')
          .Get(GetForID)
          .Put(Put)
          .Delete(Delete)
        .&End
        .Prefix('/v1')
        .Route('/transferencias/:id/status')
          .Put(AtualizarStatus)
          .Post(AtualizarStatus)
        .&End
        .Prefix('/v1')
        .Route('/transferencias/emLote')
          .Post(PostEmLote)
        .&End
        .Prefix('/v1')
        .Route('/transferenciaItens')
          .Get(GetItens)
          .Post(PostItem)
          .Put(PutItem)
        .&End
        .Prefix('/v1')
        .Route('/transferenciaItens/:id')
          .Get(GetItemForID)
          .Delete(DeleteItem)
        .&End
        .Prefix('/v1')
        .Route('/transferencias/itens')
          .Get(GetItens)
        .&End
        .Prefix('/v1')
        .Route('/transferencias/:id/itens')
          .Get(GetItens)
        .&End
        .Prefix('/v1')
        .Route('/transferenciaItens/emLote')
          .Post(PostItensEmLote)
        .&End
        .Prefix('/v1')
        .Route('/transferenciaItens/lote')
          .Post(PostItensEmLote)
        .&End
        .Prefix('/v1')
        .Route('/transferencias/itens/lote')
          .Post(PostItensEmLote)
        .&End
        .Prefix('/v1')
        .Route('/transferencias/lote')
          .Post(PostEmLote)
        .&End;
end;

initialization
  Swagger
    .BasePath('v1')
      .Path('transferencias')
        .Tag('Transferencias')
        .GET('Lista Transferencias', 'Lista todas as transferencias e romaneios de carga com filtros e status')
          .AddResponse(200, 'Operacao bem Sucedida')
            .Schema(TTransferencia)
            .IsArray(True)
          .&End
          .AddResponse(400, 'BadRequest').&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
        .POST('Criar Transferencia', 'Cria um novo envio / romaneio de transferencia entre o CD e filiais')
          .AddParamBody('Dados da Transferencia', 'Transferencias')
            .Required(True)
            .Schema(TTransferencia)
          .&End
          .AddResponse(201, 'Created')
            .Schema(TTransferencia)
          .&End
          .AddResponse(400, 'BadRequest').&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
        .PUT('Atualiza Transferencia', 'Atualiza os dados ou status de uma transferencia')
          .AddParamBody('Dados da Transferencia', 'Transferencias')
            .Required(True)
            .Schema(TTransferencia)
          .&End
          .AddResponse(200, 'Ok')
            .Schema(TTransferencia)
          .&End
          .AddResponse(400, 'BadRequest').&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
      .&End
    .&End
    .BasePath('v1')
      .Path('transferencias/{id}')
        .Tag('Transferencias')
        .GET('Obtem uma Transferencia', 'Busca dados da transferencia por ID')
          .AddParamPath('id', 'Id da Transferencia para buscar')
            .Required(True)
            .Schema(SWAG_INTEGER)
          .&End
          .AddResponse(200, 'Operacao bem Sucedida')
            .Schema(TTransferencia)
          .&End
          .AddResponse(404, 'Transferencia nao encontrada').&End
          .AddResponse(400, 'BadRequest').&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
        .DELETE('Apagar uma Transferencia', 'Remove ou cancela a transferencia')
          .AddParamPath('id', 'id da Transferencia para deletar')
            .Required(True)
            .Schema(SWAG_INTEGER)
          .&End
          .AddResponse(204, 'No Content').&End
          .AddResponse(404, 'Transferencia nao encontrada').&End
          .AddResponse(400, 'BadRequest').&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
      .&End
    .&End
    .BasePath('v1')
      .Path('transferenciaItens')
        .Tag('Transferencias')
        .GET('Lista Itens da Transferencia', 'Lista itens vinculados a uma transferencia')
          .AddResponse(200, 'Operacao bem Sucedida')
            .Schema(TTransferenciaItem)
            .IsArray(True)
          .&End
          .AddResponse(400, 'BadRequest').&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
        .POST('Adicionar Item', 'Adiciona item ao romaneio de transferencia')
          .AddParamBody('Item da Transferencia', 'TransferenciaItem')
            .Required(True)
            .Schema(TTransferenciaItem)
          .&End
          .AddResponse(201, 'Created')
            .Schema(TTransferenciaItem)
          .&End
          .AddResponse(400, 'BadRequest').&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
      .&End
    .&End;

end.
