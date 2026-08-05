unit UnitTransferencias.Controller;

interface

uses
  Horse,
  Horse.Commons,
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
var TransferenciaItem: TTransferenciaItem;
    aJson: TJSONArray;
    Query: iQuery;
    tr_id: string;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
    TransferenciaItem := TTransferenciaItem.Create(TDatabase.Connection);
    try
      TransferenciaItem.BuscaDadosTabela(GeraCodigo('TRANSFERENCIA_ITEM', 'TRI_ID')-1);
    except
      TransferenciaItem.BuscaDadosTabela(1);
    end;
    
    if Req.Query.ContainsKey('transferencia_id') then
    begin
      tr_id := Req.Query.Items['transferencia_id'];
      Query.Open('SELECT TRI_ID FROM TRANSFERENCIA_ITEM WHERE TRI_TRANSFERENCIA_ID = ' + tr_id + ' ORDER BY TRI_ID');
    end
    else
      Query.Open('SELECT TRI_ID FROM TRANSFERENCIA_ITEM ORDER BY TRI_ID');
      
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      TransferenciaItem.BuscaDadosTabela(Query.Dataset.FieldByName('TRI_ID').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(TransferenciaItem.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
    TransferenciaItem.DisposeOf;
  end;
end;

class procedure TTransferenciasController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
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

              // Se a origem for a Matriz (PRODUTOS principal), também atualiza PRODUTOS
              if LOrigemId = 1 then
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

              // Se o destino for a Matriz (1), também incrementa em PRODUTOS
              if LDestinoId = 1 then
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

class procedure TTransferenciasController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/transferencias')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/transferencias/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/transferencias/emLote')
          .Post(PostEmLote)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/transferenciaItens')
          .Get(GetItens)
          .Post(PostItem)
          .Put(PutItem)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/transferenciaItens/:id')
          .Get(GetItemForID)
          .Delete(DeleteItem)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/transferenciaItens/emLote')
          .Post(PostItensEmLote)
        .&End;
end;

end.
