unit ClienteController;

interface

uses
  Horse;

procedure Router;

implementation

uses
  System.JSON,
  System.SysUtils,
  ClienteService,
  TokenService,
  UnitConstants,
  UnitFunctions,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  Horse.GBSwagger;

function ExtractBearerToken(const AAuthorization: string): string;
const
  BearerPrefix = 'Bearer ';
begin
  Result := AAuthorization.Trim;

  if Result.StartsWith(BearerPrefix, True) then
    Result := Result.Substring(Length(BearerPrefix));
end;

function GetAuthenticatedClienteId(Req: THorseRequest; out AClienteId: string): Boolean;
var
  LAuthorization: string;
  LToken: string;
  LJWT: TJWT;
begin
  Result := False;
  AClienteId := '';

  if not Req.Headers.ContainsKey('Authorization') then
    Exit;

  LAuthorization := Req.Headers.Items['Authorization'];
  LToken := ExtractBearerToken(LAuthorization);

  if LToken.Trim.IsEmpty then
    Exit;

  LJWT := TJOSE.Verify(TTokenService.Secret, LToken);
  try
    if not Assigned(LJWT) then
      Exit;

    AClienteId := LJWT.Claims.Subject;
    Result := not AClienteId.Trim.IsEmpty;
  finally
    LJWT.Free;
  end;
end;

procedure Router;
begin
  THorse.Group
    .Prefix('/v1')
    .Post('register',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      LBody: TJSONObject;
      LNome, LCPF, LPassword: string;
      LClienteId, LError: string;
    begin
      LBody := Req.Body<TJSONObject>;
      if not Assigned(LBody) then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Corpo da requisicao invalido'));
        Exit;
      end;

      LNome := LBody.GetValue<string>('name', '');
      LCPF := LBody.GetValue<string>('cpf', '');
      LPassword := LBody.GetValue<string>('password', '');

      if LNome.Trim.IsEmpty then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Nome deve ser informado'));
        Exit;
      end;

      if not ValidarCPF(LCPF) then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'CPF com formato invalido'));
        Exit;
      end;

      LCPF := ApenasNumeros(LCPF);

      if LPassword.Trim.IsEmpty then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Senha deve ser informada'));
        Exit;
      end;

      if TClienteService.Register(LNome, LCPF, LPassword, LClienteId, LError) then
      begin
        Res.Status(201).Send(
          TJSONObject.Create
            .AddPair('id', LClienteId)
            .AddPair('nome', LNome)
            .AddPair('cpf', LCPF)
            .AddPair('plano', TJSONNumber.Create(0))
        );
      end
      else
      begin
        if LError = 'CPF ja cadastrado' then
          Res.Status(409).Send(TJSONObject.Create.AddPair('error', LError))
        else
          Res.Status(400).Send(TJSONObject.Create.AddPair('error', LError));
      end;
    end)
  .&End;

  THorse.Group
    .Prefix('/v1')
    .Post('update-password',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      LBody: TJSONObject;
      LClienteId, LOldPassword, LNewPassword: string;
    begin
      try
        if not GetAuthenticatedClienteId(Req, LClienteId) then
        begin
          Res.Status(401).Send(TJSONObject.Create.AddPair('error', 'Token invalido ou nao informado'));
          Exit;
        end;
      except
        on E: Exception do
        begin
          Res.Status(401).Send(TJSONObject.Create.AddPair('error', 'Token invalido ou expirado'));
          Exit;
        end;
      end;

      LBody := Req.Body<TJSONObject>;
      if not Assigned(LBody) then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Corpo da requisicao invalido'));
        Exit;
      end;

      LOldPassword := LBody.GetValue<string>('old_password', '');
      LNewPassword := LBody.GetValue<string>('new_password', '');

      if LOldPassword.Trim.IsEmpty then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'A senha antiga deve ser informada'));
        Exit;
      end;

      if LNewPassword.Trim.IsEmpty then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'A nova senha nao pode ser vazia'));
        Exit;
      end;

      if TClienteService.UpdatePassword(LClienteId, LOldPassword, LNewPassword) then
        Res.Status(200).Send(TJSONObject.Create.AddPair('status', 'Senha alterada com sucesso'))
      else
        Res.Status(401).Send(TJSONObject.Create.AddPair('error', 'Credenciais invalidas'));
    end)
  .&End;
end;

initialization
  Swagger
    .Register
      .SchemaOnError(TAPIError)
    .&End
    .BasePath('v1')
    .Path('register')
      .Tag('Clientes')
      .POST('Registrar Cliente', 'Cria um novo cliente com plano padrao 0')
        .AddParamBody('Dados de Cadastro', 'Register')
          .Required(True)
          .Schema(TRegisterRequest)
        .&End
        .AddResponse(201, 'Cliente criado com sucesso')
          .Schema(TRegisterResponse)
        .&End
        .AddResponse(400, 'Requisicao invalida').&End
        .AddResponse(409, 'CPF ja cadastrado').&End
        .AddResponse(500, 'Erro interno do servidor').&End
      .&End
    .&End
    .Path('update-password')
      .Tag('Clientes')
      .POST('Alterar Senha do Cliente', 'Atualiza a senha do cliente autenticado')
        .AddParamBody('Dados', 'Alterar Senha')
          .Required(True)
          .Schema(TUpdatePasswordRequest)
        .&End
        .AddResponse(200, 'Senha alterada com sucesso').&End
        .AddResponse(400, 'Requisicao invalida ou nova senha vazia').&End
        .AddResponse(401, 'Token ou credenciais invalidas').&End
        .AddResponse(500, 'Erro interno do servidor').&End
      .&End
    .&End;

end.
