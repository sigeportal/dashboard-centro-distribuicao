unit CompanyService;

interface

uses
  System.SysUtils,
  System.JSON,
  HashService,
  UnitEmpresa.Model,
  UnitClienteEmpresa.Model,
  UnitConnection.Model.Interfaces,
  UnitDatabase;

type
  TCompanyService = class
  public
    class function UpdateLocalURL(const ACNPJ, AURL, ATimestamp, AReceivedHash: string; out ACompanyNotFound: Boolean): Boolean;
    class function SelfRegister(const ACNPJ, ANome, AURL, AClaim, ATimestamp, AReceivedHash: string; out ACompanyId, AError: string): Boolean;
    class function LinkCompany(const AClienteId, ACNPJ, AClaim: string; out AEmpresaId, AError: string): Boolean;
    class function ListLinkedCompanies(const AClienteId: string; out ACompanies: TJSONArray; out AError: string): Boolean;
  end;

implementation

class function TCompanyService.UpdateLocalURL(const ACNPJ, AURL, ATimestamp,
  AReceivedHash: string; out ACompanyNotFound: Boolean): Boolean;
var
  Empresa: TEmpresa;
  LocalHash, DataToSign: string;
begin
  Result := False;
  ACompanyNotFound := False;

  DataToSign := ACNPJ + AURL + ATimestamp;
  LocalHash := THashService.CalcHMAC(DataToSign, ACNPJ);

  if not SameText(LocalHash, AReceivedHash) then
    Exit;

  Empresa := TEmpresa.Create(TDataBase.Connection);
  try
    Empresa.BuscaPorCampo('EMP_CNPJ', ACNPJ);

    if Empresa.Id <= 0 then
    begin
      ACompanyNotFound := True;
      Exit;
    end;

    Empresa.Url := AURL;
    Empresa.SalvaNoBanco(1);

    Result := True;
  finally
    Empresa.DisposeOf;
  end;
end;

class function TCompanyService.SelfRegister(const ACNPJ, ANome, AURL, AClaim,
  ATimestamp, AReceivedHash: string; out ACompanyId, AError: string): Boolean;
var
  Empresa: TEmpresa;
  LocalHash, DataToSign: string;
begin
  Result := False;
  ACompanyId := '';
  AError := '';

  if ACNPJ.Trim.IsEmpty or ANome.Trim.IsEmpty or AURL.Trim.IsEmpty or AClaim.Trim.IsEmpty or
     ATimestamp.Trim.IsEmpty or AReceivedHash.Trim.IsEmpty then
  begin
    AError := 'Dados obrigatorios nao informados';
    Exit;
  end;

  DataToSign := ACNPJ + ANome + AURL + AClaim + ATimestamp;
  LocalHash := THashService.CalcHMAC(DataToSign, ACNPJ);

  if not SameText(LocalHash, AReceivedHash) then
  begin
    AError := 'Assinatura invalida';
    Exit;
  end;

  Empresa := TEmpresa.Create(TDataBase.Connection);
  try
    Empresa.BuscaPorCampo('EMP_CNPJ', ACNPJ);
    if Empresa.Id > 0 then
    begin
      AError := 'Empresa ja cadastrada';
      Exit;
    end;

    Empresa.Id := Empresa.GeraCodigo('EMP_ID');
    Empresa.Cnpj := ACNPJ;
    Empresa.Nome := ANome;
    Empresa.Url := AURL;
    Empresa.Claimhash := AClaim; //THashService.HashText(AClaim);
    Empresa.SalvaNoBanco(1);

    ACompanyId := Empresa.Id.ToString;
    Result := True;
  finally
    Empresa.DisposeOf;
  end;
end;

class function TCompanyService.LinkCompany(const AClienteId, ACNPJ,
  AClaim: string; out AEmpresaId, AError: string): Boolean;
var
  Empresa: TEmpresa;
  Vinculo: TClienteEmpresa;
  ClaimHash: string;
begin
  Result := False;
  AEmpresaId := '';
  AError := '';

  if AClienteId.Trim.IsEmpty or ACNPJ.Trim.IsEmpty or AClaim.Trim.IsEmpty then
  begin
    AError := 'Dados obrigatorios nao informados';
    Exit;
  end;

  Empresa := TEmpresa.Create(TDataBase.Connection);
  try
    Empresa.BuscaPorCampo('EMP_CNPJ', ACNPJ);
    if Empresa.Id <= 0 then
    begin
      AError := 'Empresa nao cadastrada';
      Exit;
    end;

    ClaimHash := AClaim; //THashService.HashText(AClaim);
    if not SameText(Empresa.Claimhash, ClaimHash) then
    begin
      AError := 'Claim invalido';
      Exit;
    end;

    Vinculo := TClienteEmpresa.Create(TDataBase.Connection);
    try
      Vinculo.BuscaPorCampos(
        ['CE_CLI_ID', 'CE_EMP_ID'],
        [AClienteId, Empresa.Id.ToString]
      );

      if Vinculo.Id > 0 then
      begin
        AError := 'Empresa ja vinculada ao cliente';
        Exit;
      end;

      Vinculo.Id := Vinculo.GeraCodigo('CE_ID');
      Vinculo.Cli_id := AClienteId.ToInteger;
      Vinculo.Emp_id := Empresa.Id;
      Vinculo.SalvaNoBanco(1);

      AEmpresaId := Empresa.Id.ToString;
      Result := True;
    finally
      Vinculo.DisposeOf;
    end;
  finally
    Empresa.DisposeOf;
  end;
end;

class function TCompanyService.ListLinkedCompanies(const AClienteId: string;
  out ACompanies: TJSONArray; out AError: string): Boolean;
var
  Query: iQuery;
  ClienteId: Integer;
begin
  Result := False;
  ACompanies := nil;
  AError := '';

  if (not TryStrToInt(AClienteId, ClienteId)) or (ClienteId <= 0) then
  begin
    AError := 'Cliente invalido';
    Exit;
  end;

  ACompanies := TJSONArray.Create;
  try
    Query := TDatabase.Query;
    Query.Clear;
    Query.Add('SELECT E.EMP_ID, E.EMP_CNPJ, E.EMP_NOME, E.EMP_URL');
    Query.Add('FROM CLIENTE_EMPRESA CE');
    Query.Add('JOIN EMPRESA E ON E.EMP_ID = CE.CE_EMP_ID');
    Query.Add(Format('WHERE CE.CE_CLI_ID = %d', [ClienteId]));
    Query.Add('ORDER BY E.EMP_NOME');
    Query.Open;

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      ACompanies.AddElement(
        TJSONObject.Create
          .AddPair('id', Query.Dataset.FieldByName('EMP_ID').AsString)
          .AddPair('cnpj', Query.Dataset.FieldByName('EMP_CNPJ').AsString)
          .AddPair('nome', Query.Dataset.FieldByName('EMP_NOME').AsString)
          .AddPair('url', Query.Dataset.FieldByName('EMP_URL').AsString)
      );

      Query.Dataset.Next;
    end;

    Result := True;
  except
    ACompanies.Free;
    ACompanies := nil;
    raise;
  end;
end;

end.
