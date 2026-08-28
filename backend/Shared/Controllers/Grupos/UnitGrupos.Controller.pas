unit UnitGrupos.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  FireDAC.Comp.Client;

type
  TGruposController = class
  public
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

{ TGruposController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitGrupos.Model,
  UnitTabela.Helpers;

class procedure TGruposController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupos: TGrupos;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Grupos := TGrupos.Create(TDatabase.Connection);
    Grupos.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Grupos.DisposeOf;
  end;
end;

class procedure TGruposController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupos: TGrupos;
    aJson: TJSONArray;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
    Grupos := TGrupos.Create(TDatabase.Connection);
    try
      Grupos.BuscaDadosTabela(GeraCodigo('GRUPO_1', 'G1_CODIGO')-1);
    except
      Grupos.BuscaDadosTabela(1);
    end;
    Query.Open('SELECT G1_CODIGO FROM GRUPO_1 ORDER BY G1_CODIGO');
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Grupos.BuscaDadosTabela(Query.Dataset.FieldByName('G1_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(Grupos.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
    Grupos.DisposeOf;
  end;
end;

class procedure TGruposController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupos: TGrupos;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    Grupos := TGrupos.Create(TDatabase.Connection);
    Grupos.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Grupos.ToJson) as TJSONObject);
  finally
    Grupos.DisposeOf;
  end;
end;

class procedure TGruposController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupos: TGrupos;
begin
  try
    Grupos := TGrupos.Create(TDatabase.Connection).fromJson<TGrupos>(Req.Body);
    if Grupos.Codigo = 0 then
      Grupos.Codigo := Grupos.GeraCodigo('G1_CODIGO');
    Grupos.Cadastrar := 'S';
    Grupos.SalvaNoBanco(0);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Grupos.ToJson) as TJSONObject).Status(THTTPStatus.Created);
  finally
    Grupos.DisposeOf;
  end;
end;

class procedure TGruposController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Grupos: TGrupos;
begin
  try
    Grupos := TGrupos.Create(TDatabase.Connection).fromJson<TGrupos>(Req.Body);
    Grupos.Cadastrar := 'S';
    Grupos.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Grupos.ToJson) as TJSONObject);
  finally
    Grupos.DisposeOf;
  end;
end;

class procedure TGruposController.PostEmLote(Req: THorseRequest; Res: THorseResponse);
var
	Itens     : TGrupos;
	aJson     : TJSONArray;
	oJsonValue: TJSONValue;
	oJson     : TJSONObject;
	LQuery    : iQuery;
	FDQuery   : TFDQuery;
	i         : Integer;
begin
	oJson   := Req.Body<TJSONObject>;
	aJson   := oJson.GetValue<TJSONArray>('itens');
	LQuery  := TDatabase.Query;
	FDQuery := TFDQuery(LQuery.Query);
	FDQuery.Close;
	FDQuery.SQL.Clear;
	FDQuery.SQL.Add('UPDATE OR INSERT INTO GRUPO_1 (G1_CODIGO, G1_NOME, G1_CADASTRAR)');
	FDQuery.SQL.Add('VALUES (:G1_CODIGO, :G1_NOME, :G1_CADASTRAR)');
	FDQuery.SQL.Add('MATCHING (G1_CODIGO)');
	// preparando para usar inserções via ArrayDML
	FDQuery.Params.ArraySize := aJson.Count;
	for i                    := 0 to Pred(aJson.Count) do
	begin
		oJsonValue := aJson.Items[i];
		Itens      := TGrupos.Create(TDatabase.Connection).fromJson<TGrupos>(oJsonValue.ToJson);
		try
			FDQuery.ParamByName('G1_CODIGO').AsIntegers[i] := Itens.Codigo;
			FDQuery.ParamByName('G1_NOME').AsStrings[i]    := Itens.Nome;
			FDQuery.ParamByName('G1_CADASTRAR').AsStrings[i] := 'S';
		finally
			Itens.DisposeOf;
		end;
	end;
	// Executa as inseres em lote
	FDQuery.Execute(aJson.Count, 0);
	Res.Send<TJSONObject>(oJson);
end;

class procedure TGruposController.Router;
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
        .&End;
  THorse.Group.Prefix('/v1')
  	.Route('/grupos/emLote')
    	.Post(PostEmLote)
	  .&End;
end;

end.
