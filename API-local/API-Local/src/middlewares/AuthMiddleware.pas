unit AuthMiddleware;

interface

uses Horse, Horse.JWT, System.SysUtils, UnitConstants;

type
  TAuthMiddleware = class
  public
    class procedure RegisterAuthMiddleware;
  end;

implementation

{ Registrar Middleware de autenticação }
class procedure TAuthMiddleware.RegisterAuthMiddleware;
var
  JWT_SECRET: string;
begin
  JWT_SECRET := TConstants.JWT_SECRET;

  THorse.Use(HorseJWT(JWT_SECRET, THorseJWTConfig.New.SkipRoutes([
    '/favicon.ico',
    '/swagger/doc/html',
    '/swagger/doc/html/*',
    '/swagger/doc/json',
    'ping'
    ])));
end;

end.
