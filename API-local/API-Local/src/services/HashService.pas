unit HashService;

interface

uses
  System.Hash, System.SysUtils, System.Classes;

type
  THashService = class
  public
    class function GenerateSalt: string;
    class function HashPassword(const Password, Salt: string): string;
    class function VerifyPassword(const Password, Salt, Hash: string): Boolean;
    class function CalcHMAC(const DATA, Secret: string): string;
  end;

implementation

{ Gera o "Sal" para o hash da senha }
class function THashService.GenerateSalt: string;
begin
  Result := THashSHA2.GetHashString(GuidToString(TGUID.NewGuid));
end;

{ Gera o hash (senha + sal) }
class function THashService.HashPassword(const Password, Salt: string): string;
begin
  Result := THashSHA2.GetHashString(Password + Salt);
end;

{ Verifica a senha armazenada com a recebida }
class function THashService.VerifyPassword(const Password, Salt, Hash: string): Boolean;
begin
  Result := HashPassword(Password, Salt) = Hash;
end;

{ Verifica o Hash conhecido com o Hash recebido }
class function THashService.CalcHMAC(const DATA, Secret: string): string;
var
  LKey, LIpad, LOpad, LDataBytes, LInnerHash, LBuffer: TBytes;
  I: Integer;
  LStream: TBytesStream;
const
  BlockSize = 64;
begin
  LKey := TEncoding.UTF8.GetBytes(Secret);

  // Se a chave for maior que o bloco, faz o hash da chave
  if Length(LKey) > BlockSize then
  begin
    LStream := TBytesStream.Create(LKey);
    try
      LKey := THashSHA2.GetHashBytes(LStream);
    finally
      LStream.Free;
    end;
  end;

  // Ajusta a chave para o tamanho do bloco (64 bytes)
  SetLength(LKey, BlockSize);

  SetLength(LIpad, BlockSize);
  SetLength(LOpad, BlockSize);

  for I := 0 to BlockSize - 1 do
  begin
    LIpad[I] := LKey[I] xor $36;
    LOpad[I] := LKey[I] xor $5C;
  end;

  LDataBytes := TEncoding.UTF8.GetBytes(DATA);

  // Inner Hash = Hash(Ipad + Data)
  SetLength(LBuffer, BlockSize + Length(LDataBytes));
  Move(LIpad[0], LBuffer[0], BlockSize);
  Move(LDataBytes[0], LBuffer[BlockSize], Length(LDataBytes));

  LStream := TBytesStream.Create(LBuffer);
  try
    LInnerHash := THashSHA2.GetHashBytes(LStream);
  finally
    LStream.Free;
  end;

  // Final Hash = Hash(Opad + InnerHash)
  SetLength(LBuffer, BlockSize + Length(LInnerHash));
  Move(LOpad[0], LBuffer[0], BlockSize);
  Move(LInnerHash[0], LBuffer[BlockSize], Length(LInnerHash));

  LStream := TBytesStream.Create(LBuffer);
  try
    // Chamamos o método estático passando o Stream
    Result := THashSHA2.GetHashString(LStream).ToLower;
  finally
    LStream.Free;
  end;
end;

end.
