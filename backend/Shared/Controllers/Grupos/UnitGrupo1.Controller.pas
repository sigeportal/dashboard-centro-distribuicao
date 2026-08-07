unit UnitGrupo1.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json;

type
  TGrupo1Controller = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TGrupo1Controller }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitGrupo1.Model,
  UnitTabela.Helper.Json;

class procedure TGrupo1Controller.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupo1: TGrupo1;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Grupo1 := TGrupo1.Create(TDatabase.Connection);
    Grupo1.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Grupo1.DisposeOf;
  end;
end;

class procedure TGrupo1Controller.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupo1: TGrupo1;
    aJson: TJSONArray;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
    Grupo1 := TGrupo1.Create(TDatabase.Connection);
    try
      Grupo1.BuscaDadosTabela(GeraCodigo('GRUPO_1', 'G1_CODIGO')-1);
    except
      Grupo1.BuscaDadosTabela(1);
    end;
    Query.Open('SELECT G1_CODIGO FROM GRUPO_1 ORDER BY G1_CODIGO');
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Grupo1.BuscaDadosTabela(Query.Dataset.FieldByName('G1_CODIGO').AsInteger);
      aJson.Add(Grupo1.ToJsonObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
    Grupo1.DisposeOf;
  end;
end;

class procedure TGrupo1Controller.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupo1: TGrupo1;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    Grupo1 := TGrupo1.Create(TDatabase.Connection);
    Grupo1.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(Grupo1.ToJsonObject);
  finally
    Grupo1.DisposeOf;
  end;
end;

class procedure TGrupo1Controller.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupo1: TGrupo1;
begin
  try
    Grupo1 := TGrupo1.Create(TDatabase.Connection).fromJson<TGrupo1>(Req.Body);
    Grupo1.SalvaNoBanco(1);
    Res.Send<TJSONObject>(Grupo1.ToJsonObject);
  finally
    Grupo1.DisposeOf;
  end;
end;

class procedure TGrupo1Controller.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupo1: TGrupo1;
begin
  try
    Grupo1 := TGrupo1.Create(TDatabase.Connection).fromJson<TGrupo1>(Req.Body);
    Grupo1.SalvaNoBanco(1);
    Res.Send<TJSONObject>(Grupo1.ToJsonObject);
  finally
    Grupo1.DisposeOf;
  end;
end;

class procedure TGrupo1Controller.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/grupos')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/grupos/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
end;

end.
