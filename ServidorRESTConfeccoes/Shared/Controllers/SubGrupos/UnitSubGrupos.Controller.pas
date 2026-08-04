unit UnitSubGrupos.Controller;

interface

uses
	Horse,
	Horse.Commons,
	Classes,
	SysUtils,
	System.Json, FireDAC.Comp.Client;

type
	TSubGruposController = class
		class procedure Router;
		class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
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
	UnitTabela.Helpers;

class procedure TSubGruposController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	SubGrupos: TSubGrupos;
	id       : Integer;
begin
	try
		id        := Req.Params.Items['id'].ToInteger();
		SubGrupos := TSubGrupos.Create(TDatabase.Connection);
		SubGrupos.Apagar(id);
		Res.Send('').Status(THTTPStatus.NoContent);
	finally
		SubGrupos.DisposeOf;
	end;
end;

class procedure TSubGruposController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	SubGrupos: TSubGrupos;
	aJson    : TJSONArray;
	Query    : iQuery;
begin
	aJson := TJSONArray.Create;
	Query := TDatabase.Query;
	try
		SubGrupos := TSubGrupos.Create(TDatabase.Connection);
		try
			SubGrupos.BuscaDadosTabela(GeraCodigo('GRUPOS', 'GRU_CODIGO') - 1);
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
var
	SubGrupos: TSubGrupos;
	aJson    : TJSONArray;
	id       : Integer;
begin
	aJson := TJSONArray.Create;
	id    := Req.Params.Items['id'].ToInteger();
	try
		SubGrupos := TSubGrupos.Create(TDatabase.Connection);
		SubGrupos.BuscaDadosTabela(id);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(SubGrupos.ToJson) as TJSONObject);
	finally
		SubGrupos.DisposeOf;
	end;
end;

class procedure TSubGruposController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	SubGrupos: TSubGrupos;
begin
	try
		SubGrupos := TSubGrupos.Create(TDatabase.Connection).fromJson<TSubGrupos>(Req.Body);
		if SubGrupos.Codigo = 0 then
			SubGrupos.Codigo := SubGrupos.GeraCodigo('GRU_CODIGO');
		SubGrupos.Cadastrar := 'S';
		SubGrupos.SalvaNoBanco(0);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(SubGrupos.ToJson) as TJSONObject).Status(THTTPStatus.Created);
	finally
		SubGrupos.DisposeOf;
	end;
end;

class procedure TSubGruposController.PostEmLote(Req: THorseRequest; Res: THorseResponse);
var
	Itens     : TSubGrupos;
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
	FDQuery.SQL.Add('UPDATE OR INSERT INTO GRUPOS (GRU_CODIGO, GRU_NOME, GRU_G1, GRU_TR, GRU_CADASTRAR)');
	FDQuery.SQL.Add('VALUES (:GRU_CODIGO, :GRU_NOME, :GRU_G1, :GRU_TR, :GRU_CADASTRAR)');
	FDQuery.SQL.Add('MATCHING (GRU_CODIGO)');
	// preparando para usar inserções via ArrayDML
	FDQuery.Params.ArraySize := aJson.Count;
	for i                    := 0 to Pred(aJson.Count) do
	begin
		oJsonValue := aJson.Items[i];
		Itens      := TSubGrupos.Create(TDatabase.Connection).fromJson<TSubGrupos>(oJsonValue.ToJson);
		try
			FDQuery.ParamByName('GRU_CODIGO').AsIntegers[i] := Itens.Codigo;
			FDQuery.ParamByName('GRU_NOME').AsStrings[i]    := Itens.Nome;
			FDQuery.ParamByName('GRU_G1').AsIntegers[i]     := Itens.G1;
			FDQuery.ParamByName('GRU_TR').AsIntegers[i]     := Itens.Tr;
			FDQuery.ParamByName('GRU_CADASTRAR').AsStrings[i] := 'S';
		finally
			Itens.DisposeOf;
		end;
	end;
	// Executa as inserções em lote
	FDQuery.Execute(aJson.Count, 0);
	Res.Send<TJSONObject>(oJson);
end;

class procedure TSubGruposController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	SubGrupos: TSubGrupos;
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
	THorse.Group.Prefix('/v1')
  	.Route('/subgrupos')
    	.Get(Get)
      .Post(Post)
      .Put(Put)
    .&End;
  THorse.Group.Prefix('/v1')
  	.Route('/subgrupos/:id')
    	.Get(GetForID)
      .Delete(Delete)
    .&End;
  THorse.Group.Prefix('/v1')
  	.Route('/subgrupos/emLote')
    	.Post(PostEmLote)
	  .&End;
end;

end.
