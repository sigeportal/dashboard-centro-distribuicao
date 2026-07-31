unit UnitFornecedores.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json;

type
  TFornecedoresController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TFornecedoresController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitFornecedores.Model,
  UnitTabela.Helpers, FireDAC.Comp.Client;

class procedure TFornecedoresController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Fornecedores: TFornecedores;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Fornecedores := TFornecedores.Create(TDatabase.Connection);
    Fornecedores.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Fornecedores.DisposeOf;
  end;
end;

class procedure TFornecedoresController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Fornecedor  : TFornecedores;
	aJson     : TJSONArray;
	Query     : iQuery;
	FiltroNome: string;
	Total     : Integer;
	Codigo    : string;
	Codbarras : string;
  Cadastrar: string;
begin
	aJson    := TJSONArray.Create;
	Query    := TDatabase.Query;
	Fornecedor := TFornecedores.Create(TDatabase.Connection);
	try
		if Req.Query.ContainsKey('total') then
		begin
			Total := Req.Query.Items['total'].ToInteger();
			if Total > 0 then
				Query.Add(Format('SELECT FIRST %d DISTINCT FOR_CODIGO FROM FORNECEDORES ', [Total]))
		end
		else
			Query.Add('SELECT FOR_CODIGO FROM FORNECEDORES ');
		if Req.Query.ContainsKey('codigo') then
		begin
			Codigo := Req.Query.Items['codigo'].Replace('''', '');
			if not Codigo.IsEmpty then
				Query.Add(Format('WHERE FOR_CODIGO LIKE %s', [QuotedStr('%' + Codigo + '%')]));
		end;
		if Req.Query.ContainsKey('nome') then
		begin
			FiltroNome := Req.Query.Items['nome'].Replace('''', '');
			if not FiltroNome.IsEmpty then
				Query.Add(Format('OR FOR_NOME LIKE %s', [QuotedStr('%' + FiltroNome + '%')]));
		end;
    if Req.Query.ContainsKey('cadastrar') then
    begin
      Cadastrar := Req.Query.Items['cadastrar'];
      if Cadastrar.Contains('S') then
      	Query.Add('WHERE FOR_CADASTRAR = ''S''')
    end;
		Query.Add('ORDER BY FOR_CODIGO');
		Query.Open();
		Query.Dataset.First;
		while not Query.Dataset.Eof do
		begin
			Fornecedor.BuscaDadosTabela(Query.Dataset.FieldByName('FOR_CODIGO').AsInteger);
			aJson.Add(TJSONObject.ParseJSONValue(Fornecedor.ToJson) as TJSONObject);
			Query.Dataset.Next;
		end;
		Res.Send<TJSONArray>(aJson);
	finally
		Fornecedor.DisposeOf;
	end;
end;

class procedure TFornecedoresController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Fornecedores: TFornecedores;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    Fornecedores := TFornecedores.Create(TDatabase.Connection);
    Fornecedores.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Fornecedores.ToJson) as TJSONObject);
  finally
    Fornecedores.DisposeOf;
  end;
end;

class procedure TFornecedoresController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Fornecedores: TFornecedores;
begin
  try
    Fornecedores := TFornecedores.Create(TDatabase.Connection).fromJson<TFornecedores>(Req.Body);
    Fornecedores.Cadastrar := 'S';
    Fornecedores.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Fornecedores.ToJson) as TJSONObject);
  finally
    Fornecedores.DisposeOf;
  end;
end;

class procedure TFornecedoresController.PostEmLote(Req: THorseRequest;
  Res: THorseResponse);
var
	Itens     : TFornecedores;
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
	FDQuery.SQL.Add('UPDATE OR INSERT INTO FORNECEDORES (FOR_CODIGO, FOR_NOME, FOR_ENDERECO, FOR_BAIRRO, FOR_CEP, FOR_UF, FOR_FONE,');
  FDQuery.SQL.Add('FOR_CONTATO, FOR_EMAIL, FOR_DATAC, FOR_DATAU, FOR_CELULAR, FOR_ENDCORRESP, FOR_OBS,');
  FDQuery.SQL.Add('FOR_CNPJ_CPF, FOR_INSC_ESTADUAL, FOR_COMPLEMENTO, FOR_COD_PAIS, FOR_SUFRAMA,');
  FDQuery.SQL.Add('FOR_INDIC_IE, FOR_CID, FOR_RAZAO_SOCIAL, FOR_FANTASIA, FOR_END_NUMERO, FOR_TIPO,');
  FDQuery.SQL.Add('FOR_INSC_MUNICIPAL, FOR_CADASTRAR)');
  FDQuery.SQL.Add('VALUES (:FOR_CODIGO, :FOR_NOME, :FOR_ENDERECO, :FOR_BAIRRO, :FOR_CEP, :FOR_UF, :FOR_FONE, :FOR_CONTATO, :FOR_EMAIL,');
  FDQuery.SQL.Add(':FOR_DATAC, :FOR_DATAU, :FOR_CELULAR, :FOR_ENDCORRESP, :FOR_OBS, :FOR_CNPJ_CPF, :FOR_INSC_ESTADUAL,');
  FDQuery.SQL.Add(':FOR_COMPLEMENTO, :FOR_COD_PAIS, :FOR_SUFRAMA, :FOR_INDIC_IE, :FOR_CID, :FOR_RAZAO_SOCIAL, :FOR_FANTASIA,');
  FDQuery.SQL.Add(':FOR_END_NUMERO, :FOR_TIPO, :FOR_INSC_MUNICIPAL, :FOR_CADASTRAR)');
  FDQuery.SQL.Add('MATCHING (FOR_CODIGO)');  
	// preparando para usar inser��es via ArrayDML
	FDQuery.Params.ArraySize := aJson.Count;
	for i                    := 0 to Pred(aJson.Count) do
	begin
		oJsonValue := aJson.Items[i];
		Itens      := TFornecedores.Create(TDatabase.Connection).fromJson<TFornecedores>(oJsonValue.ToJson);
		try
			FDQuery.ParamByName('FOR_CODIGO').AsIntegers[i] := Itens.Codigo;
      FDQuery.ParamByName('FOR_NOME').AsStrings[i] := Itens.Nome;
      FDQuery.ParamByName('FOR_ENDERECO').AsStrings[i] := Itens.Endereco;
      FDQuery.ParamByName('FOR_BAIRRO').AsStrings[i] := Itens.Bairro;
      FDQuery.ParamByName('FOR_CEP').AsStrings[i] := Itens.Cep;
      FDQuery.ParamByName('FOR_UF').AsStrings[i] := Itens.Uf;
      FDQuery.ParamByName('FOR_FONE').AsStrings[i] := Itens.Fone;
      FDQuery.ParamByName('FOR_CONTATO').AsStrings[i] := Itens.Contato;
      FDQuery.ParamByName('FOR_EMAIL').AsStrings[i] := Itens.Email;
      FDQuery.ParamByName('FOR_DATAC').AsDates[i] := Itens.Datac;
      FDQuery.ParamByName('FOR_DATAU').AsDates[i] := Itens.Datau;
      FDQuery.ParamByName('FOR_CELULAR').AsStrings[i] := Itens.Celular;
      FDQuery.ParamByName('FOR_ENDCORRESP').AsStrings[i] := Itens.Endcorresp;
      FDQuery.ParamByName('FOR_OBS').AsStrings[i] := Itens.Obs;
      FDQuery.ParamByName('FOR_CNPJ_CPF').AsStrings[i] := Itens.Cnpj_cpf;
      FDQuery.ParamByName('FOR_INSC_ESTADUAL').AsStrings[i] := Itens.Insc_estadual;
      FDQuery.ParamByName('FOR_COMPLEMENTO').AsStrings[i] := Itens.Complemento;
      FDQuery.ParamByName('FOR_COD_PAIS').AsIntegers[i] := Itens.Cod_pais;
      FDQuery.ParamByName('FOR_SUFRAMA').AsStrings[i] := Itens.Suframa;
      FDQuery.ParamByName('FOR_INDIC_IE').AsStrings[i] := Itens.Indic_ie;
      FDQuery.ParamByName('FOR_CID').AsIntegers[i] := Itens.Cid;
      FDQuery.ParamByName('FOR_RAZAO_SOCIAL').AsStrings[i] := Itens.Razao_social;
      FDQuery.ParamByName('FOR_FANTASIA').AsStrings[i] := Itens.Fantasia;
      FDQuery.ParamByName('FOR_END_NUMERO').AsStrings[i] := Itens.End_numero;
      FDQuery.ParamByName('FOR_TIPO').AsStrings[i] := Itens.Tipo;
      FDQuery.ParamByName('FOR_INSC_MUNICIPAL').AsStrings[i] := Itens.InscMunicipal;
      FDQuery.ParamByName('FOR_CADASTRAR').AsStrings[i] := 'S';
		finally
			Itens.DisposeOf;
		end;
	end;
	// Executa as inser��es em lote
	FDQuery.Execute(aJson.Count, 0);
	Res.Send<TJSONObject>(oJson);
end;

class procedure TFornecedoresController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Fornecedores: TFornecedores;
begin
  try
    Fornecedores := TFornecedores.Create(TDatabase.Connection).fromJson<TFornecedores>(Req.Body);
    Fornecedores.Cadastrar := 'S';
    Fornecedores.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Fornecedores.ToJson) as TJSONObject);
  finally
    Fornecedores.DisposeOf;
  end;
end;

class procedure TFornecedoresController.Router;
begin
  THorse.Group.Prefix('/v1')
    .Route('/fornecedores')
      .Get(Get)
      .Post(Post)
      .Put(Put)
    .&End;
  THorse.Group.Prefix('/v1')
    .Route('/fornecedores/:id')
      .Get(GetForID)
      .Delete(Delete)
    .&End;
  THorse.Group.Prefix('/v1')
  	.Route('/fornecedores/emLote')
    	.Post(PostEmLote)
	  .&End;
end;

end.
