unit AuthController;

interface

uses Horse;

procedure Router;

implementation

uses
  System.JSON, AuthService, TokenService, System.SysUtils, UnitFunctions,
  UnitCliente.Model, UnitDatabase, UnitConstants,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  JOSE.Consumer,
  JOSE.Types.JSON,
  Horse.GBSwagger;

procedure Router;
begin
  THorse.Group
    .Prefix('/v1')
    .Post('login',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      UserId, CPF, Password: string;
      Token, Refresh: string;
      Body: TJSONObject;
    begin
      Body := Req.Body<TJSONObject>;

      if (not Assigned(Body)) then
      begin
        Res.Status(400).Send('Corpo da requisição inválido');
        Exit;
      end;

      CPF := Body.GetValue<string>('cpf', '');

      if not ValidarCPF(CPF) then
      begin
        Res.Status(400).Send('CPF com formato inválido');
        Exit;
      end;

      CPF := ApenasNumeros(CPF);

      Password := Body.GetValue<string>('password', '');

      if TAuthService.Authenticate(CPF, Password, UserId) then
      begin
        Token := TTokenService.GenerateAccessToken(UserId);
        Refresh := TTokenService.GenerateRefreshToken(UserId);

        Res.Send(
          TJSONObject.Create
            .AddPair('access_token', Token)
            .AddPair('refresh_token', Refresh)
          );
      end
      else
        Res.Status(401).Send('Credenciais inválidas!');
    end)
  .&End;

  THorse.Group
    .Prefix('/v1')
    .Post('refresh-token',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Body: TJSONObject;
      RefreshToken, UserId, NewAccessToken: string;
      LUser: TCliente;
      LJWT: TJWT;
    begin
      Body := Req.Body<TJSONObject>;
      if not Assigned(Body) then
      begin
        Res.Status(400).Send('Corpo da requisição inválido');
        Exit;
      end;

      RefreshToken := Body.GetValue<string>('refresh_token', '');
      if RefreshToken.IsEmpty then
      begin
        Res.Status(400).Send('Refresh Token não informado');
        Exit;
      end;

      try
        LJWT := TJOSE.Verify(TTokenService.Secret, RefreshToken);

        try
          if Assigned(LJWT) then
            UserId := LJWT.Claims.Subject
          else
            UserId := '';
        finally
          LJWT.Free;
        end;
      except
        on E: Exception do
        begin
          Res.Status(401).Send('Refresh Token inválido ou expirado');
          Exit;
        end;
      end;

      if UserId.IsEmpty then
      begin
        Res.Status(401).Send('Token não contém identificação de usuário');
        Exit;
      end;

      LUser := TCliente.Create(TDataBase.Connection);
      try
        LUser.BuscaPorCampo('CLI_ID', UserId);
        if LUser.Id > 0 then
        begin
          NewAccessToken := TTokenService.GenerateAccessToken(UserId);
          Res.Send(
            TJSONObject.Create
              .AddPair('access_token', NewAccessToken)
          );
        end
        else
          Res.Status(401).Send('Usuário não encontrado');
      finally
        LUser.Free;
      end;
    end)
  .&End;
end;

initialization
  Swagger
    .Register
      .SchemaOnError(TAPIError)
    .&End
    .BasePath('v1')
    .Path('login')
      .Tag('Autenticação')
      .POST('Realizar Login', 'Autentica o cliente por CPF e senha e retorna tokens de acesso')
        .AddParamBody('Dados de Acesso', 'Login')
          .Required(True)
          .Schema(TUserPost)
        .&End
        .AddResponse(200, 'Sucesso')
          .Schema(TTokenResponse)
        .&End
        .AddResponse(401, 'Credenciais Inválidas').&End
        .AddResponse(400).&End
        .AddResponse(500).&End
      .&End
    .&End
    .Path('refresh-token')
      .Tag('Autenticação')
      .POST('Renovar Token', 'Gera um novo Access Token a partir de um Refresh Token válido')
        .AddParamBody('Token de Renovação', 'Refresh')
          .Required(True)
          .Schema(TRefreshRequest)
        .&End
        .AddResponse(200, 'Sucesso')
          .Schema(TTokenResponse)
        .&End
        .AddResponse(401, 'Token Inválido ou Expirado').&End
        .AddResponse(400).&End
        .AddResponse(500).&End
      .&End
    .&End;

end.
