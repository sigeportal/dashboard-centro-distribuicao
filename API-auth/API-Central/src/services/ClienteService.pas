unit ClienteService;

interface

uses
  System.SysUtils,
  HashService,
  UnitCliente.Model,
  UnitDatabase;

type
  TClienteService = class
  public
    class function Register(const ANome, ACPF, APassword: string; out AClienteId, AError: string): Boolean;
    class function UpdatePassword(const AClienteId, AOldPassword, ANewPassword: string): Boolean;
  end;

implementation

class function TClienteService.Register(const ANome, ACPF, APassword: string;
  out AClienteId, AError: string): Boolean;
var
  LCliente: TCliente;
begin
  Result := False;
  AClienteId := '';
  AError := '';

  if ANome.Trim.IsEmpty then
  begin
    AError := 'Nome deve ser informado';
    Exit;
  end;

  if ACPF.Trim.IsEmpty then
  begin
    AError := 'CPF deve ser informado';
    Exit;
  end;

  if APassword.Trim.IsEmpty then
  begin
    AError := 'Senha deve ser informada';
    Exit;
  end;

  LCliente := TCliente.Create(TDataBase.Connection);
  try
    LCliente.BuscaPorCampo('CLI_CPF', ACPF);
    if LCliente.Id > 0 then
    begin
      AError := 'CPF ja cadastrado';
      Exit;
    end;

    LCliente.Id := LCliente.GeraCodigo('CLI_ID');
    LCliente.CPF := ACPF;
    LCliente.Nome := ANome;
    LCliente.Plano := 0;
    LCliente.Salt := THashService.GenerateSalt;
    LCliente.PasswordHash := THashService.HashPassword(APassword, LCliente.Salt);
    LCliente.SalvaNoBanco(1);

    AClienteId := LCliente.Id.ToString;
    Result := True;
  finally
    LCliente.DisposeOf;
  end;
end;

class function TClienteService.UpdatePassword(const AClienteId, AOldPassword,
  ANewPassword: string): Boolean;
var
  LCliente: TCliente;
begin
  Result := False;

  if AClienteId.Trim.IsEmpty or AOldPassword.Trim.IsEmpty or ANewPassword.Trim.IsEmpty then
    Exit;

  LCliente := TCliente.Create(TDataBase.Connection);
  try
    LCliente.BuscaPorCampo('CLI_ID', AClienteId);

    if LCliente.Id <= 0 then
      Exit;

    if not THashService.VerifyPassword(AOldPassword, LCliente.Salt, LCliente.PasswordHash) then
      Exit;

    LCliente.Salt := THashService.GenerateSalt;
    LCliente.PasswordHash := THashService.HashPassword(ANewPassword, LCliente.Salt);
    LCliente.SalvaNoBanco(1);

    Result := True;
  finally
    LCliente.DisposeOf;
  end;
end;

end.
