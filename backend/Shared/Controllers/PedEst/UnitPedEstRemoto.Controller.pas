unit UnitPedEstRemoto.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json;

type
  TPedEstRemotoController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TPedEstRemotoController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitPedEstRemoto.Model,
  UnitTabela.Helpers;

class procedure TPedEstRemotoController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var PedEstRemoto: TPedEstRemoto;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    PedEstRemoto := TPedEstRemoto.Create(TDatabase.Connection);
    PedEstRemoto.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    PedEstRemoto.DisposeOf;
  end;
end;

class procedure TPedEstRemotoController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var PedEstRemoto: TPedEstRemoto;
    aJson: TJSONArray;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
    PedEstRemoto := TPedEstRemoto.Create(TDatabase.Connection);
    try
      PedEstRemoto.BuscaDadosTabela(GeraCodigo('PED_EST_REMOTO', 'PE_CODIGO')-1);
    except
      PedEstRemoto.BuscaDadosTabela(1);
    end;
    Query.Open('SELECT PE_CODIGO FROM PED_EST_REMOTO ORDER BY PE_CODIGO');
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      PedEstRemoto.BuscaDadosTabela(Query.Dataset.FieldByName('PE_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(PedEstRemoto.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
    PedEstRemoto.DisposeOf;
  end;
end;

class procedure TPedEstRemotoController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var PedEstRemoto: TPedEstRemoto;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    PedEstRemoto := TPedEstRemoto.Create(TDatabase.Connection);
    PedEstRemoto.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(PedEstRemoto.ToJson) as TJSONObject);
  finally
    PedEstRemoto.DisposeOf;
  end;
end;

class procedure TPedEstRemotoController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var PedEstRemoto: TPedEstRemoto;
begin
  try
    PedEstRemoto := TPedEstRemoto.Create(TDatabase.Connection).fromJson<TPedEstRemoto>(Req.Body);
    PedEstRemoto.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(PedEstRemoto.ToJson) as TJSONObject);
  finally
    PedEstRemoto.DisposeOf;
  end;
end;

class procedure TPedEstRemotoController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var PedEstRemoto: TPedEstRemoto;
begin
  try
    PedEstRemoto := TPedEstRemoto.Create(TDatabase.Connection).fromJson<TPedEstRemoto>(Req.Body);
    PedEstRemoto.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(PedEstRemoto.ToJson) as TJSONObject);
  finally
    PedEstRemoto.DisposeOf;
  end;
end;

class procedure TPedEstRemotoController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/ped_est')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/ped_est/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
end;

end.
