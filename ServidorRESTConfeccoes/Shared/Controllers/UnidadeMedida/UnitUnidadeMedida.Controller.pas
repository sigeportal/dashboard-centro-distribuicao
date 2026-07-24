unit UnitUnidadeMedida.Controller;

interface

uses
	Horse,
	Horse.Commons,
	Classes,
	SysUtils,
	System.Json;

type
	TUnidadeMedidaController = class
		class procedure Router;
		class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
		class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
	end;

implementation

{ TUnidadeMedidaController }

uses
	UnitConnection.Model.Interfaces,
	UnitDatabase,
	UnitFunctions,
	UnitUnidadeMedida.Model,
	UnitTabela.Helpers, FireDAC.Comp.Client;

class procedure TUnidadeMedidaController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	UnidadeMedida: TUnidadeMedida;
	id           : Integer;
begin
	try
		id            := Req.Params.Items['id'].ToInteger();
		UnidadeMedida := TUnidadeMedida.Create(TDatabase.Connection);
		UnidadeMedida.Apagar(id);
		Res.Send('').Status(THTTPStatus.NoContent);
	finally
		UnidadeMedida.DisposeOf;
	end;
end;

class procedure TUnidadeMedidaController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	UnidadeMedida: TUnidadeMedida;
	aJson        : TJSONArray;
	Query        : iQuery;
begin
	aJson := TJSONArray.Create;
	Query := TDatabase.Query;
	try
		UnidadeMedida := TUnidadeMedida.Create(TDatabase.Connection);
		try
			UnidadeMedida.BuscaDadosTabela(GeraCodigo('UNIDADE_MED', 'UM_CODIGO') - 1);
		except
			UnidadeMedida.BuscaDadosTabela(1);
		end;
		Query.Open('SELECT UM_CODIGO FROM UNIDADE_MED ORDER BY UM_CODIGO');
		Query.Dataset.First;
		while not Query.Dataset.Eof do
		begin
			UnidadeMedida.BuscaDadosTabela(Query.Dataset.FieldByName('UM_CODIGO').AsInteger);
			aJson.Add(TJSONObject.ParseJSONValue(UnidadeMedida.ToJson) as TJSONObject);
			Query.Dataset.Next;
		end;
		Res.Send<TJSONArray>(aJson);
	finally
		UnidadeMedida.DisposeOf;
	end;
end;

class procedure TUnidadeMedidaController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	UnidadeMedida: TUnidadeMedida;
	aJson        : TJSONArray;
	id           : Integer;
begin
	aJson := TJSONArray.Create;
	id    := Req.Params.Items['id'].ToInteger();
	try
		UnidadeMedida := TUnidadeMedida.Create(TDatabase.Connection);
		UnidadeMedida.BuscaDadosTabela(id);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(UnidadeMedida.ToJson) as TJSONObject);
	finally
		UnidadeMedida.DisposeOf;
	end;
end;

class procedure TUnidadeMedidaController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	UnidadeMedida: TUnidadeMedida;
begin
	try
		UnidadeMedida := TUnidadeMedida.Create(TDatabase.Connection).fromJson<TUnidadeMedida>(Req.Body);
		UnidadeMedida.SalvaNoBanco(1);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(UnidadeMedida.ToJson) as TJSONObject);
	finally
		UnidadeMedida.DisposeOf;
	end;
end;

class procedure TUnidadeMedidaController.PostEmLote(Req: THorseRequest; Res: THorseResponse);
var
	Itens     : TUnidadeMedida;
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
	FDQuery.SQL.Add('UPDATE OR INSERT INTO UNIDADE_MED (UM_CODIGO, UM_UNIDADE, UM_DESCRICAO)');
	FDQuery.SQL.Add('VALUES (:UM_CODIGO, :UM_UNIDADE, :UM_DESCRICAO)');
	FDQuery.SQL.Add('MATCHING (UM_CODIGO)');
	// preparando para usar inser��es via ArrayDML
	FDQuery.Params.ArraySize := aJson.Count;
	for i                    := 0 to Pred(aJson.Count) do
	begin
		oJsonValue := aJson.Items[i];
		Itens      := TUnidadeMedida.Create(TDatabase.Connection).fromJson<TUnidadeMedida>(oJsonValue.ToJson);
		try
			FDQuery.ParamByName('UM_CODIGO').AsIntegers[i]   := Itens.Codigo;
			FDQuery.ParamByName('UM_UNIDADE').AsStrings[i]   := Itens.Unidade;
			FDQuery.ParamByName('UM_DESCRICAO').AsStrings[i] := Itens.Descricao;
		finally
			Itens.DisposeOf;
		end;
	end;
	// Executa as inser��es em lote
	FDQuery.Execute(aJson.Count, 0);
	Res.Send<TJSONObject>(oJson);
end;

class procedure TUnidadeMedidaController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	UnidadeMedida: TUnidadeMedida;
begin
	try
		UnidadeMedida := TUnidadeMedida.Create(TDatabase.Connection).fromJson<TUnidadeMedida>(Req.Body);
		UnidadeMedida.SalvaNoBanco(1);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(UnidadeMedida.ToJson) as TJSONObject);
	finally
		UnidadeMedida.DisposeOf;
	end;
end;

class procedure TUnidadeMedidaController.Router;
begin
	THorse.Group.Prefix('/v1')
  	.Route('/unidade_medida')
    	.Get(Get)
      .Post(Post)
      .Put(Put)
    .&End;
  THorse.Group.Prefix('/v1')
  	.Route('/unidade_medida/:id')
    	.Get(GetForID)
      .Delete(Delete)
    .&End;
  THorse.Group.Prefix('/v1')
  	.Route('/unidade_medida/emLote')
    	.Post(PostEmLote)
	  .&End;
end;

end.
