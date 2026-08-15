unit UnitFuncionarios.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json;

type
  TFuncionariosController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TFuncionariosController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
	UnitFuncionarios.Model,
  UnitTabela.Helpers;

class procedure TFuncionariosController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Funcionarios: TFuncionarios;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
		Funcionarios := TFuncionarios.Create(TDatabase.Connection);
		Funcionarios.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
		Funcionarios.DisposeOf;
  end;
end;

class procedure TFuncionariosController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Funcionarios: TFuncionarios;
    aJson: TJSONArray;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
		Funcionarios := TFuncionarios.Create(TDatabase.Connection);
    try
			Funcionarios.BuscaDadosTabela(GeraCodigo('FUNCIONARIOS', 'FUN_CODIGO')-1);
    except
			Funcionarios.BuscaDadosTabela(1);
    end;
    Query.Open('SELECT FUN_CODIGO FROM FUNCIONARIOS ORDER BY FUN_CODIGO');
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
			Funcionarios.BuscaDadosTabela(Query.Dataset.FieldByName('FUN_CODIGO').AsInteger);
			aJson.Add(TJSONObject.ParseJSONValue(Funcionarios.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
		Funcionarios.DisposeOf;
  end;
end;

class procedure TFuncionariosController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Funcionarios: TFuncionarios;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
		Funcionarios := TFuncionarios.Create(TDatabase.Connection);
		Funcionarios.BuscaDadosTabela(id);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Funcionarios.ToJson) as TJSONObject);
  finally
		Funcionarios.DisposeOf;
  end;
end;

class procedure TFuncionariosController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Funcionarios: TFuncionarios;
begin
  try
		Funcionarios := TFuncionarios.Create(TDatabase.Connection).fromJson<TFuncionarios>(Req.Body);
		if Funcionarios.Codigo = 0 then
			Funcionarios.Codigo := Funcionarios.GeraCodigo('FUN_CODIGO');
		Funcionarios.SalvaNoBanco(0);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Funcionarios.ToJson) as TJSONObject).Status(THTTPStatus.Created);
  finally
		Funcionarios.DisposeOf;
  end;
end;

class procedure TFuncionariosController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Funcionarios: TFuncionarios;
begin
  try
		Funcionarios := TFuncionarios.Create(TDatabase.Connection).fromJson<TFuncionarios>(Req.Body);
		Funcionarios.SalvaNoBanco(1);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Funcionarios.ToJson) as TJSONObject);
  finally
		Funcionarios.DisposeOf;
  end;
end;

class procedure TFuncionariosController.Router;
begin
  THorse.Group
        .Prefix('/v1')
				.Route('/funcionarios')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Prefix('/v1')
        .Route('/funcionarios/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
end;

end.
