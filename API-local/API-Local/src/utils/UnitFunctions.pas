unit UnitFunctions;

interface

uses
	System.SysUtils,
  UnitConnection.Model.Interfaces,
  Horse;

function GeraCodigo(Tabela, Campo: string): integer;
function IncrementaGenerator(Generator: string): integer;
function EnDecryptString(StrValue: String; Chave: Word): String;
function StrInArray(Str: String; const Lista: Array of string): Boolean;
function NormalizaCNPJ(const ACNPJ: string): string;
function GeraClaimEmpresa(const ACNPJ: string): string;
function ObterPorta: integer;
procedure SetaCookieHttpOnly(Res: THorseResponse; const Nome, Valor: string; const Path: string = '/'; const Secure: Boolean = True; const SameSite: string = 'Lax');

implementation

uses
  System.Hash,
  UnitConstants,
  UnitDatabase;

function GeraCodigo(Tabela, Campo: string): integer;
var Query: iQuery;
begin
	Query := TDatabase.Query;
  Query.Clear;
  Query.Open('SELECT MAX(' + Campo + ') FROM ' + Tabela);
  if Query.Dataset.IsEmpty then
    Result := 1
  else
    Result := Query.Dataset.Fields[0].AsInteger + 1;
end;

function IncrementaGenerator(Generator: string): integer;
var Query: iQuery;
begin
	Query := TDatabase.Query;
	Query.Clear;
	Query.Open('SELECT GEN_ID(' + Generator + ', 1) FROM RDB$DATABASE');
	if Query.DataSet.IsEmpty then
    Result := 1
  else
		Result := Query.DataSet.Fields[0].AsInteger;
end;

function EnDecryptString(StrValue: String; Chave: Word): String;
var
  i       : integer;
  OutValue: String;
begin
  OutValue   := '';
  for i      := 1 to Length(StrValue) do
    OutValue := OutValue + Char(Not(Ord(StrValue[i]) - Chave));
  Result     := OutValue;
end;

function StrInArray(Str: String; const Lista: Array of string): Boolean;
var
	i: integer;
begin
	for i := Low(Lista) to High(Lista) do
	begin
		if Lista[i] = Str then
		begin
			Result := True;
			Exit;
		end;
	end;
	Result := false;
end;

function NormalizaCNPJ(const ACNPJ: string): string;
var
  LChar: Char;
begin
  Result := '';
  for LChar in ACNPJ do
    if CharInSet(LChar, ['0'..'9']) then
      Result := Result + LChar;
end;

function GeraClaimEmpresa(const ACNPJ: string): string;
var
  LCNPJNormalizado: string;
begin
  LCNPJNormalizado := NormalizaCNPJ(ACNPJ);
  if LCNPJNormalizado.IsEmpty then
    Exit('');

  Result := THashSHA2.GetHashString(LCNPJNormalizado + TConstants.JWT_SECRET).ToLower;
end;

procedure TesteGet(Res: THorseResponse);
begin
	Res.Send('Pong');
end;

function ObterPorta: integer;
var
  Porta: string;
begin
  Porta :=  GetEnvironmentVariable('PORT');
	if Porta.IsEmpty then
  	Porta := '9000';
  Result := Porta.ToInteger;
end;

procedure SetaCookieHttpOnly(Res: THorseResponse; const Nome, Valor: string; const Path: string; const Secure: Boolean; const SameSite: string);
var
  CookieHeader: string;
begin
  CookieHeader := Format('%s=%s; Path=%s; HttpOnly', [Nome, Valor, Path]);
  if Secure then
    CookieHeader := CookieHeader + '; Secure';
  if not SameSite.IsEmpty then
    CookieHeader := CookieHeader + '; SameSite=' + SameSite;

  Res.AddHeader('Set-Cookie', CookieHeader);
end;

initialization
	THorse.Get('ping', TesteGet);

end.
