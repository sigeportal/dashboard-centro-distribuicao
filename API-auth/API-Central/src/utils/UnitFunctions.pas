unit UnitFunctions;

interface

uses
	System.SysUtils,
  UnitConnection.Model.Interfaces;

function GeraCodigo(Tabela, Campo: string): integer;
function EnDecryptString(StrValue: String; Chave: Word): String;
function StrInArray(Str: String; const Lista: Array of string): Boolean;
function ObterPorta: integer;
function ApenasNumeros(AValor: string): string;
function ValidarCPF(ACPF: string): Boolean;
function ValidarCNPJ(ACNPJ: string): Boolean;

implementation

uses
	Horse,
  UnitDatabase;

function ApenasNumeros(AValor: string): string;
var
  I: Integer;
begin
  Result := '';

  for I := Low(AValor) to High(AValor) do
    if CharInSet(AValor[I], ['0'..'9']) then
      Result := Result + AValor[I];
end;

function ValidarCNPJ(ACNPJ: string): Boolean;
const
  // Pesos matemáticos oficiais do algoritmo do governo para validação do CNPJ
  Pesos1: array[0..11] of Integer = (5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
  Pesos2: array[0..12] of Integer = (6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2);
var
  i, Soma, Digit1, Digit2: integer;
  S: string;
  BaseIdx: Integer;
begin
  // Por padrão, consideramos o CNPJ inválido até provar o contrário
  Result := False;
  S := '';

  // Remove pontos, traços e barras, mantendo apenas números.
  // O uso de 'Low' e 'High' garante o mapeamento correto dos caracteres independente do SO.
  for i := Low(ACNPJ) to High(ACNPJ) do
    if CharInSet(ACNPJ[i], ['0'..'9']) then
      S := S + ACNPJ[i];

  // Um CNPJ limpo precisa ter rigorosamente 14 dígitos numéricos
  if Length(S) <> 14 then
    Exit;

  // Impede sequências idênticas (ex: '00000000000000', '11111111111111')
  if StringOfChar(S[Low(S)], 14) = S then
    Exit;

  // Captura dinamicamente onde o índice da string começa.
  BaseIdx := Low(S);

  // CÁLCULO DO PRIMEIRO DÍGITO VERIFICADOR (Posição 13 do CNPJ)
  Soma := 0;
  for i := 0 to 11 do
  begin
    // 'Ord(Char) - Ord("0")' converte o caractere numérico em inteiro
    Soma := Soma + (Ord(S[BaseIdx + i]) - Ord('0')) * Pesos1[i];
  end;

  // Aplica a regra oficial do Módulo 11 para o primeiro dígito
  Soma := Soma mod 11;
  if Soma < 2 then
    Digit1 := 0
  else
    Digit1 := 11 - Soma;

  // CÁLCULO DO SEGUNDO DÍGITO VERIFICADOR (Posição 14 do CNPJ)
  Soma := 0;
  for i := 0 to 11 do
  begin
    Soma := Soma + (Ord(S[BaseIdx + i]) - Ord('0')) * Pesos2[i];
  end;

  // O primeiro dígito calculado entra como peso final no cálculo do segundo dígito
  Soma := Soma + (Digit1 * Pesos2[12]);

  // Aplica a regra oficial do Módulo 11 para o segundo dígito
  Soma := Soma mod 11;
  if Soma < 2 then
    Digit2 := 0
  else
    Digit2 := 11 - Soma;

  // Verifica se os dígitos calculados batem com os informados na string.
  // S[BaseIdx + 12] aponta para o 13º caractere e S[BaseIdx + 13] aponta para o 14º caractere.
  Result := ((Ord(S[BaseIdx + 12]) - Ord('0')) = Digit1) and
            ((Ord(S[BaseIdx + 13]) - Ord('0')) = Digit2);
end;

function ValidarCPF(ACPF: string): Boolean;
const
  Pesos1: array[0..8] of Integer = (10, 9, 8, 7, 6, 5, 4, 3, 2);
  Pesos2: array[0..9] of Integer = (11, 10, 9, 8, 7, 6, 5, 4, 3, 2);
var
  I, Soma, Resto, Digit1, Digit2: Integer;
  S: string;
  BaseIdx: Integer;
begin
  Result := False;
  S := '';

  // Mantem somente os numeros para aceitar CPF com ou sem mascara.
  for I := Low(ACPF) to High(ACPF) do
    if CharInSet(ACPF[I], ['0'..'9']) then
      S := S + ACPF[I];

  if Length(S) <> 11 then
    Exit;

  // Bloqueia sequencias como 00000000000, 11111111111, etc.
  if StringOfChar(S[Low(S)], 11) = S then
    Exit;

  // Evita depender se a string esta indexada a partir de 0 ou 1.
  BaseIdx := Low(S);

  Soma := 0;
  for I := 0 to 8 do
    Soma := Soma + (Ord(S[BaseIdx + I]) - Ord('0')) * Pesos1[I];

  Resto := Soma mod 11;
  if Resto < 2 then
    Digit1 := 0
  else
    Digit1 := 11 - Resto;

  Soma := 0;
  for I := 0 to 8 do
    Soma := Soma + (Ord(S[BaseIdx + I]) - Ord('0')) * Pesos2[I];

  Soma := Soma + (Digit1 * Pesos2[9]);

  Resto := Soma mod 11;
  if Resto < 2 then
    Digit2 := 0
  else
    Digit2 := 11 - Resto;

  Result := ((Ord(S[BaseIdx + 9]) - Ord('0')) = Digit1) and
            ((Ord(S[BaseIdx + 10]) - Ord('0')) = Digit2);
end;

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
  	Porta := '3333';
  Result := Porta.ToInteger;
end;

initialization
	THorse.Get('/v1/ping', TesteGet);

end.
