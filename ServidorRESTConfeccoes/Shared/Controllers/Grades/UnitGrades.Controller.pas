unit UnitGrades.Controller;

interface

uses
	Horse,
	Horse.Commons,
	Classes,
	SysUtils,
	System.Json;

type
	TGradesController = class
		class procedure Router;
		class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetGradeProduto(Req: THorseRequest; Res: THorseResponse);
		class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
		class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
	end;

implementation

{ TGradesController }

uses
	UnitConnection.Model.Interfaces,
	UnitDatabase,
	UnitFunctions,
	UnitGrades.Model,
	UnitTabela.Helpers, FireDAC.Comp.Client;

class procedure TGradesController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Grades: TGrades;
	id    : Integer;
begin
	try
		id     := Req.Params.Items['id'].ToInteger();
		Grades := TGrades.Create(TDatabase.Connection);
		Grades.Apagar(id);
		Res.Send('').Status(THTTPStatus.NoContent);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Grades: TGrades;
	aJson : TJSONArray;
	Query : iQuery;
begin
	aJson := TJSONArray.Create;
	Query := TDatabase.Query;
	try
		Grades := TGrades.Create(TDatabase.Connection);
		try
			Grades.BuscaDadosTabela(GeraCodigo('GRADES', 'GRA_CODIGO') - 1);
		except
			Grades.BuscaDadosTabela(1);
		end;
		Query.Open('SELECT GRA_CODIGO FROM GRADES ORDER BY GRA_CODIGO');
		Query.Dataset.First;
		while not Query.Dataset.Eof do
		begin
			Grades.BuscaDadosTabela(Query.Dataset.FieldByName('GRA_CODIGO').AsInteger);
			aJson.Add(TJSONObject.ParseJSONValue(Grades.ToJson) as TJSONObject);
			Query.Dataset.Next;
		end;
		Res.Send<TJSONArray>(aJson);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Grades: TGrades;
	aJson : TJSONArray;
	id    : Integer;
begin
	aJson := TJSONArray.Create;
	id    := Req.Params.Items['id'].ToInteger();
	try
		Grades := TGrades.Create(TDatabase.Connection);
		Grades.BuscaDadosTabela(id);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Grades.ToJson) as TJSONObject);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.GetGradeProduto(Req: THorseRequest; Res: THorseResponse);
var
	Grades    : TGrades;
	aJson     : TJSONArray;
	Query     : iQuery;
	CodProduto: Integer;
begin
	aJson := TJSONArray.Create;
	if not Req.Params.ContainsKey('id') then
		raise Exception.Create('Campo id � obrigatorio');
	CodProduto := Req.Params.Items['id'].ToInteger();
	Query      := TDatabase.Query;
	try
		Grades := TGrades.Create(TDatabase.Connection);
		try
			Grades.BuscaDadosTabela(GeraCodigo('GRADES', 'GRA_CODIGO') - 1);
		except
			Grades.BuscaDadosTabela(1);
		end;
		Query.Add('SELECT GRA_CODIGO FROM GRADES WHERE GRA_PRO = :PRODUTO ORDER BY GRA_CODIGO');
		Query.AddParam('PRODUTO', CodProduto);
		Query.Open();
		Query.Dataset.First;
		while not Query.Dataset.Eof do
		begin
			Grades.BuscaDadosTabela(Query.Dataset.FieldByName('GRA_CODIGO').AsInteger);
			aJson.Add(TJSONObject.ParseJSONValue(Grades.ToJson) as TJSONObject);
			Query.Dataset.Next;
		end;
		Res.Send<TJSONArray>(aJson);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Grades: TGrades;
begin
	try
		Grades := TGrades.Create(TDatabase.Connection).fromJson<TGrades>(Req.Body);
    if Grades.Codigo = 0 then
    	Grades.Codigo := Grades.GeraCodigo('GRA_CODIGO');
    Grades.Cadastrar := 'S';
		Grades.SalvaNoBanco(0);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Grades.ToJson) as TJSONObject).Status(THTTPStatus.Created);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.PostEmLote(Req: THorseRequest; Res: THorseResponse);
var
	Itens     : TGrades;
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
	FDQuery.SQL.Add('UPDATE OR INSERT INTO GRADES (GRA_CODIGO, GRA_PRO, GRA_VALOR, GRA_TAM, GRA_QUANTIDADE, GRA_CODBARRA, GRA_COR)');
	FDQuery.SQL.Add('VALUES (:GRA_CODIGO, :GRA_PRO, :GRA_VALOR, :GRA_TAM, :GRA_QUANTIDADE, :GRA_CODBARRA, :GRA_COR)');
	FDQuery.SQL.Add('MATCHING (GRA_CODIGO)');
	// preparando para usar inser��es via ArrayDML
	FDQuery.Params.ArraySize := aJson.Count;
	for i                    := 0 to Pred(aJson.Count) do
	begin
		oJsonValue := aJson.Items[i];
		Itens      := TGrades.Create(TDatabase.Connection).fromJson<TGrades>(oJsonValue.ToJson);
		try
			FDQuery.ParamByName('GRA_CODIGO').AsIntegers[i]   := Itens.Codigo;
			FDQuery.ParamByName('GRA_PRO').AsIntegers[i]      := Itens.Pro;
			FDQuery.ParamByName('GRA_VALOR').AsCurrencys[i]   := Itens.Valor;
			FDQuery.ParamByName('GRA_TAM').AsIntegers[i]      := Itens.Tam;
			FDQuery.ParamByName('GRA_QUANTIDADE').AsFloats[i] := Itens.Quantidade;
			FDQuery.ParamByName('GRA_CODBARRA').AsStrings[i]  := Itens.Codbarra;
			FDQuery.ParamByName('GRA_COR').AsStrings[i]       := Itens.Cor;
		finally
			Itens.DisposeOf;
		end;
	end;
	// Executa as inser��es em lote
	FDQuery.Execute(aJson.Count, 0);
	Res.Send<TJSONObject>(oJson);
end;

class procedure TGradesController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Grades: TGrades;
begin
	try
		Grades := TGrades.Create(TDatabase.Connection).fromJson<TGrades>(Req.Body);
		Grades.SalvaNoBanco(1);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Grades.ToJson) as TJSONObject);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.Router;
begin
	THorse.Group
  	.Prefix('/v1')
    .Route('/grades')
    	.Get(Get)
      .Post(Post)
      .Put(Put)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/grades/:id')
    	.Get(GetForID)
      .Delete(Delete)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/grades/produto/:id')
    	.Get(GetGradeProduto)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/grades/emLote')
    	.Post(PostEmLote)
    .&End
end;

end.
