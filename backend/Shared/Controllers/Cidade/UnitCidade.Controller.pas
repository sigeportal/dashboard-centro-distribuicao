unit UnitCidade.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  UnitConnection.Model.Interfaces;

type
  TCidadeController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TCidadeController }

uses
  UnitCidade.Model,
  UnitTabela.Helpers,
  UnitDatabase;

class procedure TCidadeController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Cidade: TCidade;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Cidade := TCidade.Create(TDatabase.Connection);
    Cidade.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Cidade.DisposeOf;
  end;
end;

class procedure TCidadeController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Cidade: TCidade;
    aJson: TJSONArray;
    UF: string;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  UF := Req.Query.Items['UF'];
  Query := TDatabase.Query;
  Query.Clear;
  Query.Add('SELECT CID_CODIGO FROM CIDADES');
  if not UF.IsEmpty then
  begin
    Query.Add('WHERE CID_UF = :UF');
    Query.AddParam('UF', UF);
  end;
  Query.Add('ORDER BY CID_NOME');
  Query.Open();
  Query.DataSet.First;
  while not Query.DataSet.Eof do
  begin
    Cidade := TCidade.Create(TDatabase.Connection);
    try
      Cidade.BuscaDadosTabela(Query.DataSet.FieldByName('CID_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(Cidade.ToJson) as TJSONObject);
    finally
      Cidade.DisposeOf;
    end;
    Query.DataSet.Next;
  end;
  Res.Send<TJSONArray>(aJson);
end;

class procedure TCidadeController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Cidade: TCidade;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    Cidade := TCidade.Create(TDatabase.Connection);
    Cidade.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Cidade.ToJson) as TJSONObject);
  finally
    Cidade.DisposeOf;
  end;
end;

class procedure TCidadeController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Cidade: TCidade;
begin
  try
    Cidade := TCidade.Create(TDatabase.Connection).fromJson<TCidade>(Req.Body);
    if Cidade.Codigo = 0 then
      Cidade.Codigo := Cidade.GeraCodigo('CID_CODIGO');
    Cidade.SalvaNoBanco(0);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Cidade.ToJson) as TJSONObject).Status(THTTPStatus.Created);
  finally
    Cidade.DisposeOf;
  end;
end;

class procedure TCidadeController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Cidade: TCidade;
begin
  try
    Cidade := TCidade.Create(TDatabase.Connection).fromJson<TCidade>(Req.Body);
    Cidade.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Cidade.ToJson) as TJSONObject);
  finally
    Cidade.DisposeOf;
  end;
end;

class procedure TCidadeController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/cidade')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Prefix('/v1')
        .Route('/cidade/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
        .Prefix('/v1')
        .Route('/cidades')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Prefix('/v1')
        .Route('/cidades/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End;
end;

end.
