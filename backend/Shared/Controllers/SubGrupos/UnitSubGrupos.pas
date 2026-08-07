unit UnitSubGrupos;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json;

type
  TSubGruposController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TSubGruposController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitSubGrupos.Model,
  UnitTabela.Helper.Json;

class procedure TSubGruposController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var SubGrupos: TSubGrupos;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    SubGrupos := TSubGrupos.Create(TDatabase.Connection);
    SubGrupos.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    SubGrupos.DisposeOf;
  end;
end;

class procedure TSubGruposController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var SubGrupos: TSubGrupos;
    aJson: TJSONArray;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
    SubGrupos := TSubGrupos.Create(TDatabase.Connection);
    try
      SubGrupos.BuscaDadosTabela(GeraCodigo('GRUPOS', 'GRU_CODIGO')-1);
    except
      SubGrupos.BuscaDadosTabela(1);
    end;
    Query.Open('SELECT GRU_CODIGO FROM GRUPOS ORDER BY GRU_CODIGO');
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      SubGrupos.BuscaDadosTabela(Query.Dataset.FieldByName('GRU_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(SubGrupos.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
    SubGrupos.DisposeOf;
  end;
end;

class procedure TSubGruposController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var SubGrupos: TSubGrupos;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    SubGrupos := TSubGrupos.Create(TDatabase.Connection);
    SubGrupos.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(SubGrupos.ToJson) as TJSONObject);
  finally
    SubGrupos.DisposeOf;
  end;
end;

class procedure TSubGruposController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var SubGrupos: TSubGrupos;
begin
  try
    SubGrupos := TSubGrupos.Create(TDatabase.Connection).fromJson<TSubGrupos>(Req.Body);
    SubGrupos.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(SubGrupos.ToJson) as TJSONObject);
  finally
    SubGrupos.DisposeOf;
  end;
end;

class procedure TSubGruposController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var SubGrupos: TSubGrupos;
begin
  try
    SubGrupos := TSubGrupos.Create(TDatabase.Connection).fromJson<TSubGrupos>(Req.Body);
    SubGrupos.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(SubGrupos.ToJson) as TJSONObject);
  finally
    SubGrupos.DisposeOf;
  end;
end;

class procedure TSubGruposController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/subgrupos')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/subgrupos/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
end;

end.
