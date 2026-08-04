unit UnitEstado.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json, UnitConnection.Model.Interfaces;

type
  TEstadoController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TEstadoController }

uses
  UnitEstado.Model,
  UnitTabela.Helpers,
  UnitDatabase;

class procedure TEstadoController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Estado: TEstado;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Estado := TEstado.Create(TDatabase.Connection);
    Estado.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Estado.DisposeOf;
  end;
end;

class procedure TEstadoController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Estado: TEstado;
    aJson: TJSONArray;
    CodEstado: integer;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  Query.Clear;
  Query.Open('SELECT EST_CODIGO FROM ESTADOS ORDER BY EST_NOME');
  Query.DataSet.First;
  while not Query.DataSet.Eof do
  begin
    CodEstado := Query.DataSet.FieldByName('EST_CODIGO').AsInteger;
    Estado := TEstado.Create(TDatabase.Connection);
    try
      Estado.BuscaDadosTabela(CodEstado);
      aJson.Add(TJSONObject.ParseJSONValue(Estado.ToJson) as TJSONObject);
    finally
      Estado.DisposeOf;
    end;
    Query.DataSet.Next;
  end;
  Res.Send<TJSONArray>(aJson);
end;

class procedure TEstadoController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Estado: TEstado;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    Estado := TEstado.Create(TDatabase.Connection);
    Estado.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Estado.ToJson) as TJSONObject);
  finally
    Estado.DisposeOf;
  end;
end;

class procedure TEstadoController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Estado: TEstado;
begin
  try
    Estado := TEstado.Create(TDatabase.Connection).fromJson<TEstado>(Req.Body);
    if Estado.Codigo = 0 then
      Estado.Codigo := Estado.GeraCodigo('EST_CODIGO');
    Estado.SalvaNoBanco(0);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Estado.ToJson) as TJSONObject).Status(THTTPStatus.Created);
  finally
    Estado.DisposeOf;
  end;
end;

class procedure TEstadoController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Estado: TEstado;
begin
  try
    Estado := TEstado.Create(TDatabase.Connection).fromJson<TEstado>(Req.Body);
    Estado.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Estado.ToJson) as TJSONObject);
  finally
    Estado.DisposeOf;
  end;
end;

class procedure TEstadoController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/estado')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/estado/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
end;

end.
