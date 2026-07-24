unit UnitGrupoSubgrupo.Controller;

interface
uses
	Horse,
	Horse.Commons,
	Classes,
	SysUtils,
	System.Json;

type
	TGrupoSubGrupoController = class
		class procedure Router;
		class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
	end;

implementation

{ TGrupoSubGrupoController }

uses
	UnitConnection.Model.Interfaces,
	UnitDatabase,
	UnitFunctions,
	UnitTabela.Helpers;

class procedure TGrupoSubGrupoController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var 
	aJson: TJSONArray;
	Query: iQuery;
	oJson: TJSONObject;
	Nome: string;
begin
	aJson := TJSONArray.Create;
	Query := TDatabase.Query;				
	try
		Nome := Req.Query.Items['descricao'].Replace('''', '');
		Query.Clear;
		if not Nome.IsEmpty then
		begin
			Query.Add('SELECT GRU_CODIGO CODIGO, G1_NOME||'' > ''||GRU_NOME DESCRICAO FROM GRUPO_1 INNER JOIN GRUPOS ON G1_CODIGO = GRU_G1 '); 
			Query.Add(Format('WHERE ((G1_NOME LIKE %s) or (GRU_NOME LIKE %s)) ORDER BY DESCRICAO', [QuotedStr('%'+Nome+'%'), QuotedStr('%'+Nome+'%')]));
		end
		else
		begin
			Query.Add('SELECT GRU_CODIGO CODIGO, G1_NOME||'' > ''||GRU_NOME DESCRICAO FROM GRUPO_1 ');
			Query.Add(' INNER JOIN GRUPOS ON G1_CODIGO = GRU_G1 ORDER BY DESCRICAO');	
		end;
		Query.Open();
		Query.Dataset.First;
		while not Query.Dataset.Eof do
		begin
			oJson := TJSONObject.Create;
			oJson.AddPair('CODIGO', TJSONNumber.Create(Query.DataSet.FieldByName('CODIGO').AsInteger));
			oJson.AddPair('DESCRICAO', Query.DataSet.FieldByName('DESCRICAO').AsString);
			aJson.AddElement(oJson);			
			Query.Dataset.Next;
		end;
		Res.Send<TJSONArray>(aJson);
	finally
	end;
end;

class procedure TGrupoSubGrupoController.Router;
begin
	THorse.Group
				.Prefix('/v1')
				.Route('/grupo_subgrupo')
					.Get(Get)
				.&End
end;

end.
