unit CompanyController;

interface

uses
  Horse,
  System.JSON,
  CompanyService,
  System.SysUtils,
  UnitFunctions,
  UnitConstants,
  UnitEmpresa.Model,
  TokenService,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  Horse.GBSwagger;

procedure Router;

implementation

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
    .Get('companies/linked',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      ClienteId, Error: string;
      Companies: TJSONArray;
      Response: TJSONObject;
    begin
      try
        if not GetAuthenticatedClienteId(Req, ClienteId) then
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

      Companies := nil;
      try
        try
          if TCompanyService.ListLinkedCompanies(ClienteId, Companies, Error) then
          begin
            Response := TJSONObject.Create;
            Response.AddPair('companies', Companies);
            Companies := nil;
            Res.Status(200).Send(Response);
          end
          else
            Res.Status(400).Send(TJSONObject.Create.AddPair('error', Error));
        except
          on E: Exception do
            Res.Status(500).Send(TJSONObject.Create.AddPair('error', 'Erro interno do servidor'));
        end;
      finally
        Companies.Free;
      end;
    end)
  .&End;

  THorse.Group
    .Prefix('/v1')
    .Post('update-url',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Body: TJSONObject;
      CNPJ, URL, Timestamp, Assinatura: string;
      LCompanyNotFound: Boolean;
    begin
      Body := Req.Body<TJSONObject>;

      if not Assigned(Body) then
      begin
        Res.Status(400).Send('Corpo da requisicao invalido');
        Exit;
      end;

      Writeln('Requisicao recebida para atualizacao de URL');

      // Extracao dos dados conforme o pacote preparado pela API Local
      CNPJ := Body.GetValue<string>('cnpj', '');

      // Validacao de formato de CNPJ para otimizacao
      if not ValidarCNPJ(CNPJ) then
      begin
        Res.Status(400).Send('CNPJ com formato invalido');
        Exit;
      end;

      CNPJ := ApenasNumeros(CNPJ);

      URL := Body.GetValue<string>('url', '');
      Timestamp := Body.GetValue<string>('timestamp', '');
      Assinatura := Body.GetValue<string>('assinatura', '');

      // Tenta atualizar utilizando o servico de regras de negocio
      LCompanyNotFound := False;
      if TCompanyService.UpdateLocalURL(CNPJ, URL, Timestamp, Assinatura, LCompanyNotFound) then
        Res.Status(200).Send(TJSONObject.Create.AddPair('status', 'URL atualizada com sucesso'))
      else
      begin
        if LCompanyNotFound then
          Res.Status(404).Send(TJSONObject.Create.AddPair('error', 'Empresa nao cadastrada'))
        else
          Res.Status(401).Send('Falha na autenticacao da requisicao');
      end;
    end)
  .&End;

  THorse.Group
    .Prefix('/v1')
    .Post('companies/self-register',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Body: TJSONObject;
      CNPJ, Nome, URL, Claim, Timestamp, Assinatura: string;
      CompanyId, Error: string;
    begin
      Body := Req.Body<TJSONObject>;

      if not Assigned(Body) then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Corpo da requisicao invalido'));
        Exit;
      end;

      CNPJ := Body.GetValue<string>('cnpj', '');
      if not ValidarCNPJ(CNPJ) then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'CNPJ com formato invalido'));
        Exit;
      end;

      CNPJ := ApenasNumeros(CNPJ);
      Nome := Body.GetValue<string>('nome', '');
      URL := Body.GetValue<string>('url', '');
      Claim := Body.GetValue<string>('claim', '');
      Timestamp := Body.GetValue<string>('timestamp', '');
      Assinatura := Body.GetValue<string>('assinatura', '');

      if TCompanyService.SelfRegister(CNPJ, Nome, URL, Claim, Timestamp, Assinatura, CompanyId, Error) then
      begin
        Res.Status(201).Send(
          TJSONObject.Create
            .AddPair('id', CompanyId)
            .AddPair('cnpj', CNPJ)
            .AddPair('nome', Nome)
            .AddPair('url', URL)
        );
      end
      else
      begin
        if Error = 'Empresa ja cadastrada' then
          Res.Status(409).Send(TJSONObject.Create.AddPair('error', Error))
        else if Error = 'Assinatura invalida' then
          Res.Status(401).Send(TJSONObject.Create.AddPair('error', Error))
        else
          Res.Status(400).Send(TJSONObject.Create.AddPair('error', Error));
      end;
    end)
  .&End;

  THorse.Group
    .Prefix('/v1')
    .Post('companies/link',
    procedure(Req: THorseRequest; Res: THorseResponse)
    var
      Body: TJSONObject;
      ClienteId, CNPJ, Claim, EmpresaId, Error: string;
    begin
      try
        if not GetAuthenticatedClienteId(Req, ClienteId) then
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

      Body := Req.Body<TJSONObject>;
      if not Assigned(Body) then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Corpo da requisicao invalido'));
        Exit;
      end;

      CNPJ := Body.GetValue<string>('cnpj', '');
      if not ValidarCNPJ(CNPJ) then
      begin
        Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'CNPJ com formato invalido'));
        Exit;
      end;

      CNPJ := ApenasNumeros(CNPJ);
      Claim := Body.GetValue<string>('claim', '');

      if TCompanyService.LinkCompany(ClienteId, CNPJ, Claim, EmpresaId, Error) then
      begin
        Res.Status(201).Send(
          TJSONObject.Create
            .AddPair('empresa_id', EmpresaId)
            .AddPair('cnpj', CNPJ)
        );
      end
      else
      begin
        if Error = 'Empresa ja vinculada ao cliente' then
          Res.Status(409).Send(TJSONObject.Create.AddPair('error', Error))
        else if Error = 'Empresa nao cadastrada' then
          Res.Status(404).Send(TJSONObject.Create.AddPair('error', Error))
        else if Error = 'Claim invalido' then
          Res.Status(401).Send(TJSONObject.Create.AddPair('error', Error))
        else
          Res.Status(400).Send(TJSONObject.Create.AddPair('error', Error));
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
  .Path('update-url')
    .Tag('Empresas')
    .POST('Atualizar URL da Empresa', 'Atualiza a URL de uma empresa existente')
      .AddParamBody('Dados', 'Update')
        .Required(True)
        .Schema(TUpdateUrlRequest)
      .&End
      .AddResponse(200, 'Operacao realizada com sucesso').&End
      .AddResponse(401, 'Falha na autenticacao').&End
      .AddResponse(404, 'Empresa nao cadastrada').&End
      .AddResponse(400).&End
      .AddResponse(500).&End
    .&End
  .&End
  .Path('companies/self-register')
    .Tag('Empresas')
    .POST('Autocadastrar Empresa', 'Cria uma empresa quando update-url retornar 404')
      .AddParamBody('Dados', 'SelfRegister')
        .Required(True)
        .Schema(TCompanySelfRegisterRequest)
      .&End
      .AddResponse(201, 'Empresa cadastrada com sucesso')
        .Schema(TCompanyResponse)
      .&End
      .AddResponse(400, 'Requisicao invalida').&End
      .AddResponse(401, 'Assinatura invalida').&End
      .AddResponse(409, 'Empresa ja cadastrada').&End
      .AddResponse(500, 'Erro interno do servidor').&End
    .&End
  .&End
  .Path('companies/link')
    .Tag('Empresas')
    .POST('Vincular Empresa', 'Vincula uma empresa existente ao cliente autenticado')
      .AddParamBody('Dados', 'LinkCompany')
        .Required(True)
        .Schema(TCompanyLinkRequest)
      .&End
      .AddResponse(201, 'Empresa vinculada com sucesso')
        .Schema(TCompanyLinkResponse)
      .&End
      .AddResponse(400, 'Requisicao invalida').&End
      .AddResponse(401, 'Token ou claim invalido').&End
      .AddResponse(404, 'Empresa nao cadastrada').&End
      .AddResponse(409, 'Empresa ja vinculada').&End
      .AddResponse(500, 'Erro interno do servidor').&End
    .&End
  .&End
  .Path('companies/linked')
    .Tag('Empresas')
    .GET('Listar Empresas Vinculadas', 'Lista as empresas vinculadas ao cliente autenticado')
      .AddResponse(200, 'Empresas vinculadas listadas com sucesso').&End
      .AddResponse(400, 'Cliente invalido').&End
      .AddResponse(401, 'Token invalido ou nao informado').&End
      .AddResponse(500, 'Erro interno do servidor').&End
    .&End
  .&End;

end.
