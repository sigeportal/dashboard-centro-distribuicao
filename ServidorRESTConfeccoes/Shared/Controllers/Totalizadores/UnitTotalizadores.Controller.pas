unit UnitTotalizadores.Controller;

interface

uses
	Horse,
	Horse.Commons,
	Classes,
	SysUtils,
	System.Json;

type
	TTotalizadoresController = class
		class procedure Router;
		class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
		class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
	end;

implementation

{ TTotalizadoresController }

uses
	UnitConnection.Model.Interfaces,
	UnitDatabase,
	UnitFunctions,
	UnitTotalizadores.Model,
	UnitTabela.Helpers, FireDAC.Comp.Client;

class procedure TTotalizadoresController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Totalizadores: TTotalizadores;
	id           : Integer;
begin
	try
		id            := Req.Params.Items['id'].ToInteger();
		Totalizadores := TTotalizadores.Create(TDatabase.Connection);
		Totalizadores.Apagar(id);
		Res.Send('').Status(THTTPStatus.NoContent);
	finally
		Totalizadores.DisposeOf;
	end;
end;

class procedure TTotalizadoresController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Totalizadores: TTotalizadores;
	aJson        : TJSONArray;
	Query        : iQuery;
	oJson        : TJSONObject;
begin
	aJson := TJSONArray.Create;
	Query := TDatabase.Query;
	try
		Totalizadores := TTotalizadores.Create(TDatabase.Connection);
		try
			Totalizadores.BuscaDadosTabela(GeraCodigo('TOTALIZADORES', 'TOT_CODIGO') - 1);
		except
			Totalizadores.BuscaDadosTabela(1);
		end;
		Query.Add('SELECT TOT_CODIGO, TOT_TOTALIZADOR, TOT_ALIQUOTA, TOT_SIT_TRIB, TOT_CST,');
		Query.Add('TRIM(CASE WHEN TOT_SIT_TRIB = ''I'' THEN ''I - Isento''');
		Query.Add('WHEN TOT_SIT_TRIB = ''N'' THEN ''N - Nao Tributado''');
		Query.Add('WHEN TOT_SIT_TRIB = ''F'' THEN ''F - Substituicaoo Tributaria''');
		Query.Add('WHEN TOT_SIT_TRIB = ''T'' THEN ''T - Tributado pelo ICMS''');
		Query.Add('WHEN TOT_SIT_TRIB = ''S'' THEN ''S - Tributado pelo ISSQN'' END) ||'' / ''||TOT_CST||'' / ''||TOT_ALIQUOTA DESCRICAO');
		Query.Add('');
		Query.Add('FROM TOTALIZADORES');
		Query.Add('');
		Query.Add('ORDER BY TOT_TOTALIZADOR');
		Query.Open;
		Query.Dataset.First;
		while not Query.Dataset.Eof do
		begin
			oJson := TJSONObject.Create;
			oJson.AddPair('codigo', TJSONNumber.Create(Query.Dataset.FieldByName('TOT_CODIGO').AsInteger));
			oJson.AddPair('totalizador', Query.Dataset.FieldByName('TOT_TOTALIZADOR').AsString);
			oJson.AddPair('aliquota', TJSONNumber.Create(Query.Dataset.FieldByName('TOT_ALIQUOTA').AsFloat));
			oJson.AddPair('sit_trib', Query.Dataset.FieldByName('TOT_SIT_TRIB').AsString);
			oJson.AddPair('cst', Query.Dataset.FieldByName('TOT_CST').AsString);
			oJson.AddPair('descricao', Query.Dataset.FieldByName('DESCRICAO').AsString);
			aJson.Add(oJson);
			Query.Dataset.Next;
		end;
		Res.Send<TJSONArray>(aJson);
	finally
		Totalizadores.DisposeOf;
	end;
end;

class procedure TTotalizadoresController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Totalizadores: TTotalizadores;
	aJson        : TJSONArray;
	id           : Integer;
	Query        : iQuery;
	oJson        : TJSONObject;
begin
	aJson := TJSONArray.Create;
	id    := Req.Params.Items['id'].ToInteger();
	Query := TDatabase.Query;
	Query.Add('SELECT TOT_CODIGO, TOT_TOTALIZADOR, TOT_ALIQUOTA, TOT_SIT_TRIB, TOT_CST,');
	Query.Add('TRIM(CASE WHEN TOT_SIT_TRIB = ''I'' THEN ''I - Isento''');
	Query.Add('WHEN TOT_SIT_TRIB = ''N'' THEN ''N - N�o Tributado''');
	Query.Add('WHEN TOT_SIT_TRIB = ''F'' THEN ''F - Substitui��o Tribut�ria''');
	Query.Add('WHEN TOT_SIT_TRIB = ''T'' THEN ''T - Tributado pelo ICMS''');
	Query.Add('WHEN TOT_SIT_TRIB = ''S'' THEN ''S - Tributado pelo ISSQN'' END) ||'' / ''||TOT_CST||'' / ''||TOT_ALIQUOTA DESCRICAO');
	Query.Add('');
	Query.Add('FROM TOTALIZADORES');
	Query.Add('');
	Query.Add('WHERE TOT_CODIGO = :CODIGO');
	Query.AddParam('CODIGO', id);
	Query.Open;
	if not Query.Dataset.IsEmpty then
	begin
		oJson := TJSONObject.Create;
		oJson.AddPair('codigo', TJSONNumber.Create(Query.Dataset.FieldByName('TOT_CODIGO').AsInteger));
		oJson.AddPair('totalizador', Query.Dataset.FieldByName('TOT_TOTALIZADOR').AsString);
		oJson.AddPair('aliquota', TJSONNumber.Create(Query.Dataset.FieldByName('TOT_ALIQUOTA').AsFloat));
		oJson.AddPair('sit_trib', Query.Dataset.FieldByName('TOT_SIT_TRIB').AsString);
		oJson.AddPair('cst', Query.Dataset.FieldByName('TOT_CST').AsString);
		oJson.AddPair('descricao', Query.Dataset.FieldByName('DESCRICAO').AsString);
		Res.Send<TJSONObject>(oJson);
	end
	else
		Res.Send<TJSONObject>(TJSONObject.Create.AddPair('msg', 'n�o encontrado')).Status(THTTPStatus.NotFound);
end;

class procedure TTotalizadoresController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Totalizadores: TTotalizadores;
begin
	try
		Totalizadores := TTotalizadores.Create(TDatabase.Connection).fromJson<TTotalizadores>(Req.Body);
		if Totalizadores.Codigo = 0 then
			Totalizadores.Codigo := Totalizadores.GeraCodigo('TOT_CODIGO');
		Totalizadores.SalvaNoBanco(0);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Totalizadores.ToJson) as TJSONObject).Status(THTTPStatus.Created);
	finally
		Totalizadores.DisposeOf;
	end;
end;

class procedure TTotalizadoresController.PostEmLote(Req: THorseRequest; Res: THorseResponse);
var
	Itens     : TTotalizadores;
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
	FDQuery.SQL.Add('UPDATE OR INSERT INTO TOTALIZADORES (TOT_CODIGO, TOT_TOTALIZADOR, TOT_MD5, TOT_SIT_TRIB, TOT_CST, TOT_ALIQUOTA,');
	FDQuery.SQL.Add('TOT_CST_PIS, TOT_ALIQ_PIS, TOT_CST_COFINS, TOT_ALIQ_COFINS)');
	FDQuery.SQL.Add('VALUES (:TOT_CODIGO, :TOT_TOTALIZADOR, :TOT_MD5, :TOT_SIT_TRIB, :TOT_CST, :TOT_ALIQUOTA, :TOT_CST_PIS, :TOT_ALIQ_PIS,');
	FDQuery.SQL.Add(':TOT_CST_COFINS, :TOT_ALIQ_COFINS)');
	FDQuery.SQL.Add('MATCHING (TOT_CODIGO)');
	// preparando para usar inser��es via ArrayDML
	FDQuery.Params.ArraySize := aJson.Count;
	for i                    := 0 to Pred(aJson.Count) do
	begin
		oJsonValue := aJson.Items[i];
		Itens      := TTotalizadores.Create(TDatabase.Connection).fromJson<TTotalizadores>(oJsonValue.ToJson);
		try
			FDQuery.ParamByName('TOT_CODIGO').AsIntegers[i]     := Itens.Codigo;
			FDQuery.ParamByName('TOT_TOTALIZADOR').AsStrings[i] := Itens.Totalizador;
			FDQuery.ParamByName('TOT_MD5').AsStrings[i]         := Itens.Md5;
			FDQuery.ParamByName('TOT_SIT_TRIB').AsStrings[i]    := Itens.Sit_trib;
			FDQuery.ParamByName('TOT_CST').AsStrings[i]         := Itens.Cst;
			FDQuery.ParamByName('TOT_ALIQUOTA').AsFloats[i]     := Itens.Aliquota;
			FDQuery.ParamByName('TOT_CST_PIS').AsStrings[i]     := Itens.Cst_pis;
			FDQuery.ParamByName('TOT_ALIQ_PIS').AsFloats[i]     := Itens.Aliq_pis;
			FDQuery.ParamByName('TOT_CST_COFINS').AsStrings[i]  := Itens.Cst_cofins;
			FDQuery.ParamByName('TOT_ALIQ_COFINS').AsFloats[i]  := Itens.Aliq_cofins;
		finally
			Itens.DisposeOf;
		end;
	end;
	// Executa as inser��es em lote
	FDQuery.Execute(aJson.Count, 0);
	Res.Send<TJSONObject>(oJson);
end;

class procedure TTotalizadoresController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Totalizadores: TTotalizadores;
begin
	try
		Totalizadores := TTotalizadores.Create(TDatabase.Connection).fromJson<TTotalizadores>(Req.Body);
		Totalizadores.SalvaNoBanco(1);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Totalizadores.ToJson) as TJSONObject);
	finally
		Totalizadores.DisposeOf;
	end;
end;

class procedure TTotalizadoresController.Router;
begin
	THorse.Group.Prefix('/v1')
  	.Route('/totalizadores')
    	.Get(Get)
      .Post(Post)
      .Put(Put)
    .&End;
  THorse.Group.Prefix('/v1')
  	.Route('/totalizadores/:id')
    	.Get(GetForID)
      .Delete(Delete)
    .&End;
  THorse.Group.Prefix('/v1')
  	.Route('/totalizadores/emLote')
    	.Post(PostEmLote)
	  .&End;
end;

end.
