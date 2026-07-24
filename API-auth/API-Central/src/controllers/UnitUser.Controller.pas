unit UnitUser.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json,
  HashService;

type
  TUserController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse);
    class procedure Post(Req: THorseRequest; Res: THorseResponse);
    class procedure Put(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitCliente.Model,
  UnitConstants,
  UnitTabela.Helpers;

class procedure TUserController.Get(Req: THorseRequest; Res: THorseResponse);
var
  User: TUser;
  aJson: TJSONArray;
  Query: iQuery;
  Filtros: TStringList;
  ParamName, ParamValue, QueryParams: string;
  i: Integer;
  Limite: Integer;
  Pagina: Integer;
  Pular: Integer;
  SQLBase: string;
  WhereClause: string;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  User := TUser.Create(TDatabase.Connection);
  Filtros := TStringList.Create;
  try
    Limite := 10;
    Pagina := 1;

    if Req.Query.ContainsKey('limit') then
      Limite := Req.Query.Items['limit'].ToInteger();
    if Req.Query.ContainsKey('page') then
      Pagina := Req.Query.Items['page'].ToInteger();

    if Pagina < 1 then
      Pagina := 1;
    Pular := (Pagina - 1) * Limite;

    if Limite > 0 then
      SQLBase := Format('SELECT FIRST %d SKIP %d DISTINCT USER_CODIGO FROM USERS', [Limite, Pular])
    else
      SQLBase := 'SELECT DISTINCT USER_CODIGO FROM USERS';

    for QueryParams in Req.Query.Dictionary.Keys do
    begin
    	ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[ParamName].Replace('''', '');

      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

      if not ParamValue.IsEmpty then
        Filtros.Add(Format('%s LIKE %s', [ParamName, QuotedStr('%' + ParamValue + '%')]));
    end;

    Query.Add(SQLBase);
    if Filtros.Count > 0 then
    begin
      WhereClause := 'WHERE ' + String.Join(' OR ', Filtros.ToStringArray);
      Query.Add(WhereClause);
    end;
    Query.Add('ORDER BY USER_CODIGO');
    Query.Open;

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      User.BuscaDadosTabela(Query.Dataset.FieldByName('USER_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(User.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;

    Res.Send<TJSONArray>(aJson);
  finally
    Filtros.Free;
    User.DisposeOf;
  end;
end;

class procedure TUserController.GetForID(Req: THorseRequest; Res: THorseResponse);
var User: TUser;
    id: Integer;
begin
  id := Req.Params.Items['id'].ToInteger();
  try
    User := TUser.Create(TDatabase.Connection);
    User.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(User.ToJsonObject);
  finally
    User.DisposeOf;
  end;
end;

class procedure TUserController.Post(Req: THorseRequest; Res: THorseResponse);
var
  User, LUser_Aux: TUser;
  BodyOBJ: TJSONObject;
begin
  try
    User := TUser.Create(TDatabase.Connection).fromJson<TUser>(Req.Body);
    BodyOBJ := Req.Body<TJSONObject>;

    if not ValidarCNPJ(User.CNPJ) then
    begin
      Res.Status(400).Send('CNPJ com formato inválido');
      Exit;
    end;

    if User.Codigo = 0 then
        User.Codigo := GeraCodigo('USERS', 'USER_CODIGO');
    User.URL := '';
    User.Salt := THashService.GenerateSalt;
    User.PasswordHash := THashService.HashPassword(BodyOBJ.GetValue<string>('password'), User.Salt);

    LUser_Aux := TUser.Create(TDataBase.Connection);
    LUser_Aux.BuscaPorCampo('USER_CNPJ', User.CNPJ);

    if LUser_Aux.Codigo > 0 then
    begin
      Res.Send('Usuário já existe, abortando!').Status(THTTPStatus.BadRequest);
      Exit;
    end;

    User.SalvaNoBanco(1);
    Res.Send<TJSONObject>(User.ToJsonObject);
  finally
    User.DisposeOf;
  end;
end;

class procedure TUserController.Put(Req: THorseRequest; Res: THorseResponse);
var User: TUser;
begin
  try
    User := TUser.Create(TDatabase.Connection).fromJson<TUser>(Req.Body);

    if not ValidarCNPJ(User.CNPJ) then
    begin
      Res.Status(400).Send('CNPJ com formato inválido');
      Exit;
    end;

    User.SalvaNoBanco(1);
    Res.Send<TJSONObject>(User.ToJsonObject);
  finally
    User.DisposeOf;
  end;
end;

class procedure TUserController.Router;
begin
{  THorse.Group
        .Prefix('/v1')
        .Route('/users')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/users/:id')
          .Get(GetForID)
        .&End }
end;

initialization
{  Swagger
    .Register
      .SchemaOnError(TAPIError)
    .&End
    .BasePath('v1')
    .Path('users')
      .Tag('Usuários')
      .GET('Listar Usuários', 'Retorna a lista de usuários cadastrados')
        .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TUserSchema)
          .IsArray(True)
        .&End
        .AddResponse(400).&End
        .AddResponse(500).&End
      .&End
      .POST('Criar Usuário', 'Cadastra uma nova empresa/usuário na Central')
        .AddParamBody('Dados do Usuário', 'User')
          .Required(True)
          .Schema(TUserPost)
        .&End
        .AddResponse(201, 'Criado com Sucesso')
          .Schema(TUserSchema)
        .&End
        .AddResponse(400).&End
        .AddResponse(500).&End
      .&End
      .PUT('Atualizar Usuário', 'Atualiza os dados de um usuário existente')
        .AddParamBody('Novos Dados', 'User')
          .Required(True)
          .Schema(TUserSchema)
        .&End
        .AddResponse(200, 'Atualizado com Sucesso')
          .Schema(TUserSchema)
        .&End
        .AddResponse(400).&End
        .AddResponse(500).&End
      .&End
    .&End
    .Path('users/{id}  //')
      { .Tag('Usuários')
      .GET('Obter Usuário por ID', 'Busca os detalhes de um usuário específico')
        .AddParamPath('id', 'ID Interno do Usuário')
          .Required(True)
          .Schema(SWAG_INTEGER)
        .&End
        .AddResponse(200, 'Sucesso')
          .Schema(TUserSchema)
        .&End
        .AddResponse(404, 'Usuário não encontrado').&End
        .AddResponse(400).&End
        .AddResponse(500).&End
    .&End; }

end.
