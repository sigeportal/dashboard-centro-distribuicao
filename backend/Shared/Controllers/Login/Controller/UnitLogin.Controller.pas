unit UnitLogin.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  FireDAC.Comp.Client, UnitConnection.Model.Interfaces;

type
  TLoginController = class
  private
    class function BuscaPermissoesUsuario(Usuario: integer): TJSONArray;
  public
    class procedure Router;
		class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetOne(Req: THorseRequest; Res: THorseResponse);
		class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure CriaPermissoes(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

{ TLoginController }

uses
  UnitFunctions,
  UnitDatabase;

class function TLoginController.BuscaPermissoesUsuario(Usuario: integer): TJSONArray;
var
  oJson: TJSONObject;
  Query: iQuery;
begin
  Result := TJSONArray.Create;
  Query := TDatabase.Query;
  Query.Clear;
  Query.Add('SELECT PER_CODIGO, PER_PERMISSAO, PER_USU FROM PERMISSOES');
  Query.Add('WHERE PER_USU = :USUARIO');
  Query.AddParam('USUARIO', Usuario);
  Query.Open;
  if not Query.DataSet.IsEmpty then
  begin
    Query.DataSet.First;
    while not Query.DataSet.Eof do
    begin
      oJson := TJSONObject.Create;
      oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('PER_CODIGO').AsInteger));
      oJson.AddPair('permissao', Query.DataSet.FieldByName('PER_PERMISSAO').AsString);
      oJson.AddPair('usu_codigo', TJSONNumber.Create(Query.DataSet.FieldByName('PER_USU').AsInteger));
      Result.AddElement(oJson);
      Query.DataSet.Next;
    end;
  end;
end;

class procedure TLoginController.CriaPermissoes(Req: THorseRequest;	Res: THorseResponse);
var
	idUsuario: string;
  Query: iQuery;
  aJsonPermissoes: TJSONArray;
  json: TJSONValue;
	oBody: TJSONObject;
	oUsuario: TJSONObject;
begin
	idUsuario := Req.Params.Items['id'];
	Query := TDatabase.Query;
	Query.Add('DELETE FROM PERMISSOES WHERE PER_USU = :USUARIO');
	Query.AddParam('USUARIO', idUsuario.ToInteger());
	Query.ExecSQL;
	/////
	oBody := Req.Body<TJSONObject>;
	aJsonPermissoes := oBody.GetValue<TJSONArray>('permissoes');
	for json in aJsonPermissoes do
	begin
		Query.Clear;
		Query.Add('INSERT INTO PERMISSOES (PER_CODIGO, PER_PERMISSAO, PER_USU)');
		Query.Add('VALUES (:CODIGO, :PERMISSAO, :USUARIO)');
		Query.AddParam('CODIGO', GeraCodigo('PERMISSOES', 'PER_CODIGO'));
		Query.AddParam('PERMISSAO', json.GetValue<string>('permissao'));
		Query.AddParam('USUARIO', idUsuario);
		Query.ExecSQL;	
	end;
	////
	oUsuario := oBody.GetValue<TJSONObject>('usuario');
	Query.Clear;
	Query.Add('UPDATE USUARIOS');
	Query.Add('SET USU_LOGIN = :LOGIN,');
	Query.Add('USU_FUN = :FUN,');
	Query.Add('USU_SENHA = :SENHA');
	Query.Add('WHERE (USU_CODIGO = :USUARIO)');	
	Query.AddParam('LOGIN', oUsuario.GetValue<string>('login'));
	Query.AddParam('FUN', oUsuario.GetValue<string>('fun_codigo'));
	Query.AddParam('SENHA', oUsuario.GetValue<string>('senha'));
	Query.AddParam('USUARIO', idUsuario.ToInteger());
	Query.ExecSQL;	
	Res.Send<TJSONObject>(oBody).Status(THTTPStatus.Created);	
end;

class procedure TLoginController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  aJson: TJSONArray;
  oJson: TJSONObject;
  Funcionario: Integer;
  Query: iQuery;
begin
	Funcionario := 0;
  if Req.Query.ContainsKey('funcionario') then
    Funcionario := Req.Query.Items['funcionario'].ToInteger();
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  Query.Clear;
  Query.Add('SELECT USU_CODIGO, USU_LOGIN, USU_FUN, USU_SENHA FROM USUARIOS JOIN FUNCIONARIOS ON USU_FUN = FUN_CODIGO');
  Query.Add('WHERE FUN_ESTADO IN (''ATIVO'', ''ADM'')');
  if Funcionario > 0 then
  begin
    Query.Add('AND FUN_CODIGO = :FUNCIONARIO');
    Query.AddParam('FUNCIONARIO', Funcionario);
  end;
  Query.Open;
  if not Query.DataSet.IsEmpty then
  begin
    Query.DataSet.First;
    while not Query.DataSet.Eof do
    begin
      oJson := TJSONObject.Create;
      oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('USU_CODIGO').AsInteger));
      oJson.AddPair('login', Query.DataSet.FieldByName('USU_LOGIN').AsString);
      oJson.AddPair('fun_codigo', TJSONNumber.Create(Query.DataSet.FieldByName('USU_FUN').AsInteger));
			oJson.AddPair('senha', Query.DataSet.FieldByName('USU_SENHA').AsString);
			oJson.AddPair('permissoes', BuscaPermissoesUsuario(Query.DataSet.FieldByName('USU_CODIGO').AsInteger));
      aJson.AddElement(oJson);
      Query.DataSet.Next;
    end;
  end;
	Res.Send<TJSONArray>(aJson);
end;

class procedure TLoginController.GetOne(Req: THorseRequest;	Res: THorseResponse);
var
	oJson: TJSONObject;
	Query: iQuery;
	id: integer;
begin
	id := Req.Params.Items['id'].ToInteger;
	Query := TDatabase.Query;
	Query.Clear;
	Query.Add('SELECT USU_CODIGO, USU_LOGIN, USU_FUN, USU_SENHA FROM USUARIOS JOIN FUNCIONARIOS ON USU_FUN = FUN_CODIGO');
	Query.Add('WHERE USU_CODIGO = :CODIGO');
	Query.AddParam('CODIGO', id);
	Query.Open;
	if not Query.DataSet.IsEmpty then
	begin
		oJson := TJSONObject.Create;
		oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('USU_CODIGO').AsInteger));
		oJson.AddPair('login', Query.DataSet.FieldByName('USU_LOGIN').AsString);
		oJson.AddPair('fun_codigo', TJSONNumber.Create(Query.DataSet.FieldByName('USU_FUN').AsInteger));
		oJson.AddPair('senha', Query.DataSet.FieldByName('USU_SENHA').AsString);
		oJson.AddPair('permissoes', BuscaPermissoesUsuario(Query.DataSet.FieldByName('USU_CODIGO').AsInteger));
	end;
	Res.Send<TJSONObject>(oJson);
end;

class procedure TLoginController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  oJson: TJSONObject;
  LoginJson: TJSONObject;
  Query: iQuery;
begin
  LoginJson := Req.Body<TJSONObject>;
  Query := TDatabase.Query;
  Query.Clear;
  Query.Add('SELECT USU_CODIGO, USU_LOGIN, FUN_CODIGO, FUN_NOME FROM USUARIOS ');
  Query.Add('JOIN FUNCIONARIOS ON USU_FUN = FUN_CODIGO WHERE USU_LOGIN = :LOGIN AND USU_SENHA = :SENHA');
  Query.AddParam('LOGIN', LoginJson.GetValue<string>('login'));
	Query.AddParam('SENHA', EnDecryptString(LoginJson.GetValue<string>('senha'), 236));
  Query.Open;
  if not Query.DataSet.IsEmpty then
  begin
    oJson := TJSONObject.Create;
    oJson.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('USU_CODIGO').AsInteger));
    oJson.AddPair('login', Query.DataSet.FieldByName('USU_LOGIN').AsString);
    oJson.AddPair('fun_codigo', TJSONNumber.Create(Query.DataSet.FieldByName('FUN_CODIGO').AsInteger));
    oJson.AddPair('nome', Query.DataSet.FieldByName('FUN_NOME').AsString);
    oJson.AddPair('permissoes', BuscaPermissoesUsuario(Query.DataSet.FieldByName('USU_CODIGO').AsInteger));
    Res.Send<TJSONObject>(oJson);
  end else
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('error', 'usu�rio n�o autorizado'))
       .Status(THTTPStatus.Unauthorized);
end;

class procedure TLoginController.Router;
begin
  THorse
    .Group
    .Prefix('/v1')
		.Route('/usuarios')
			.Get(Get)
		.&End
		.Group
    .Prefix('/v1')
		.Route('/usuarios/:id')
			.Get(GetOne)
		.&End		
		.Group
		.Prefix('v1')
		.Route('login')
			.Post(Post)
		.&End
		.Group
		.Prefix('v1')
		.Route('/usuarios/:id/permissoes')
			.Post(CriaPermissoes)
		.&End
end;

end.

