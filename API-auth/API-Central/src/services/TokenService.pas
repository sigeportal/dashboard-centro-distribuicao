unit TokenService;

interface

uses
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  System.SysUtils,
  UnitConstants;

type
  TTokenService = class
  private
    class var FSecret: string;
  public
    class property Secret: string read FSecret write FSecret;
    class procedure Init;

    class function GenerateAccessToken(UserId: string): string;
    class function GenerateRefreshToken(UserId: string): string;
  end;

implementation

{ TTokenService }

{ Inicia o serviço de token com a chave secreta }
class procedure TTokenService.Init;
begin
  Secret := TConstants.JWT_SECRET;
end;

{ Gera um token de acesso com a lib JOSE }
class function TTokenService.GenerateAccessToken(UserId: string): string;
var
  LToken : TJWT;
begin
  // Cria o token e o preenche
  LToken := TJWT.Create;
  try
    LToken.Claims.Issuer := 'Portal.com';             // Emissor do token
    LToken.Claims.Subject := UserId;                  // Dono do token
    LToken.Claims.IssuedAt := Now;                    // Data emissao
    LToken.Claims.Expiration := Now + (1.0 / 48.0);   // Expira em 30 minutos (1 dia / 48)

    Result := TJOSE.SHA256CompactToken(FSecret, LToken);
  finally
    LToken.Free;
  end;
end;

{ Cria token para gerar novamente o token de acesso }
class function TTokenService.GenerateRefreshToken(UserId: string): string;
var
  LToken : TJWT;
begin
  LToken := TJWT.Create;
  try
    LToken.Claims.Issuer := 'Portal.com'; // Emissor do token
    LToken.Claims.Subject := UserId;      // Dono do token
    LToken.Claims.Expiration := Now + 7;  // Tempo para token expirar

    Result := TJOSE.SHA256CompactToken(FSecret, LToken);
  finally
    LToken.Free;
  end;
end;

end.
