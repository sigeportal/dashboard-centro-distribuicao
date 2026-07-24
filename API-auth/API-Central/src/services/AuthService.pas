unit AuthService;

interface

uses
  HashService,
  UnitCliente.Model,
  System.SysUtils,
  UnitDatabase;

type
  TAuthService = class
  public
    class function Authenticate(const ACPF, APassword: string; out UserId: string): Boolean;
  end;

implementation

class function TAuthService.Authenticate(const ACPF, APassword: string; out UserId: string): Boolean;
var
  User: TCliente;
begin
  Result := False;
  UserId := '';

  User := TCliente.Create(TDataBase.Connection);
  try
    User.BuscaPorCampo('CLI_CPF', ACPF);

    if User.Id <= 0 then
      Exit;

    if THashService.VerifyPassword(APassword, User.Salt, User.PasswordHash) then
    begin
      UserId := User.Id.ToString;
      Result := True;
    end;
  finally
    User.DisposeOf;
  end;
end;

end.
