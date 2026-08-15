unit UnitEmpresa.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  UnitConnection.Model.Interfaces;

type
  TEmpresaController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TEmpresaController }

uses
  UnitEmpresa.Model,
  UnitTabela.Helpers,
  UnitDatabase;

class procedure TEmpresaController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Empresa: TEmpresa;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Empresa := TEmpresa.Create();
    Empresa.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Empresa.DisposeOf;
  end;
end;

class procedure TEmpresaController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Empresa: TEmpresa;
    aJson: TJSONArray;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  Query.Clear;
  Query.Open('SELECT EMP_CODIGO FROM EMPRESA');
  while not Query.DataSet.Eof do
  begin
    Empresa := TEmpresa.Create(TDatabase.Connection);
    try
      Empresa.BuscaDadosTabela(Query.DataSet.FieldByName('EMP_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(Empresa.ToJson) as TJSONObject);
    finally
      Empresa.DisposeOf;
    end;
    Query.DataSet.Next;
  end;
  if aJson.Count > 0 then
    Res.Send<TJSONArray>(aJson)
  else
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('msg', 'nada encontrado')).Status(THTTPStatus.NotFound);
end;

class procedure TEmpresaController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Empresa: TEmpresa;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    Empresa := TEmpresa.Create(TDatabase.Connection);
    Empresa.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Empresa.ToJson) as TJSONObject);
  finally
    Empresa.DisposeOf;
  end;
end;

class procedure TEmpresaController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Empresa: TEmpresa;
begin
  try
    Empresa := TEmpresa.Create(TDatabase.Connection).fromJson<TEmpresa>(Req.Body);
    if Empresa.Codigo = 0 then
      Empresa.Codigo := Empresa.GeraCodigo('EMP_CODIGO');
    Empresa.SalvaNoBanco(0);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Empresa.ToJson) as TJSONObject).Status(THTTPStatus.Created);
  finally
    Empresa.DisposeOf;
  end;
end;

class procedure TEmpresaController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Empresa: TEmpresa;
begin
  try
    Empresa := TEmpresa.Create(TDatabase.Connection).fromJson<TEmpresa>(Req.Body);
    Empresa.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Empresa.ToJson) as TJSONObject);
  finally
    Empresa.DisposeOf;
  end;
end;

class procedure TEmpresaController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/empresa')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Prefix('/v1')
        .Route('/empresa/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
end;

end.
