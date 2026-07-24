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
  UnitTransferenciaItem.Model;

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
    FDQuery.SQL.Add('UPDATE OR INSERT INTO TRANSFERENCIA (TR_ID, TR_ORIGEM, TR_DESTINO, TR_DATA, TR_STATUS, TR_OBS, TR_USUARIO_RECEBIMENTO, TR_DATA_RECEBIMENTO)');
    FDQuery.SQL.Add('VALUES (:TR_ID, :TR_ORIGEM, :TR_DESTINO, :TR_DATA, :TR_STATUS, :TR_OBS, :TR_USUARIO_RECEBIMENTO, :TR_DATA_RECEBIMENTO)');
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
    FDQuery.SQL.Add('UPDATE OR INSERT INTO TRANSFERENCIA_ITEM (TRI_ID, TRI_TRANSFERENCIA_ID, TRI_PRODUTO_ID, TRI_QUANTIDADE, TRI_VALOR, TRI_QTD_CONFERIDA)');
    FDQuery.SQL.Add('VALUES (:TRI_ID, :TRI_TRANSFERENCIA_ID, :TRI_PRODUTO_ID, :TRI_QUANTIDADE, :TRI_VALOR, :TRI_QTD_CONFERIDA)');
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
