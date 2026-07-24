unit UnitProdutosServidor.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json;

type
  TProdutosServidorController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TProdutosServidorController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitProdutosServidor.Model,
  UnitTabela.Helper.Json;

class procedure TProdutosServidorController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var ProdutosServidor: TProdutosServidor;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    ProdutosServidor := TProdutosServidor.Create(TDatabase.Connection);
    ProdutosServidor.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    ProdutosServidor.DisposeOf;
  end;
end;

class procedure TProdutosServidorController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var ProdutosServidor: TProdutosServidor;
    aJson: TJSONArray;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
    ProdutosServidor := TProdutosServidor.Create(TDatabase.Connection);
    try
      ProdutosServidor.BuscaDadosTabela(GeraCodigo('PRODUTOS_SERVIDOR', 'PS_CODIGO')-1);
    except
      ProdutosServidor.BuscaDadosTabela(1);
    end;
    Query.Open('SELECT PS_CODIGO FROM PRODUTOS_SERVIDOR ORDER BY PS_CODIGO');
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      ProdutosServidor.BuscaDadosTabela(Query.Dataset.FieldByName('PS_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(ProdutosServidor.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
    ProdutosServidor.DisposeOf;
  end;
end;

class procedure TProdutosServidorController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var ProdutosServidor: TProdutosServidor;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    ProdutosServidor := TProdutosServidor.Create(TDatabase.Connection);
    ProdutosServidor.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(ProdutosServidor.ToJson) as TJSONObject);
  finally
    ProdutosServidor.DisposeOf;
  end;
end;

class procedure TProdutosServidorController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var ProdutosServidor: TProdutosServidor;
begin
  try
    ProdutosServidor := TProdutosServidor.Create(TDatabase.Connection).fromJson<TProdutosServidor>(Req.Body);
    ProdutosServidor.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(ProdutosServidor.ToJson) as TJSONObject);
  finally
    ProdutosServidor.DisposeOf;
  end;
end;

class procedure TProdutosServidorController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var ProdutosServidor: TProdutosServidor;
begin
  try
    ProdutosServidor := TProdutosServidor.Create(TDatabase.Connection).fromJson<TProdutosServidor>(Req.Body);
    ProdutosServidor.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(ProdutosServidor.ToJson) as TJSONObject);
  finally
    ProdutosServidor.DisposeOf;
  end;
end;

class procedure TProdutosServidorController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/produtos_servidor')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/produtos_servidor/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
end;

end.
