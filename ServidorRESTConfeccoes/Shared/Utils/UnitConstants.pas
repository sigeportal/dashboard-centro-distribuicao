unit UnitConstants;

interface

uses System.SysUtils;

type
  TConstants = class
    class function BancoDados: string;
  end;

implementation

{ TConstants }

uses System.StrUtils;

class function TConstants.BancoDados: string;
begin
  Result := GetEnvironmentVariable('CAMINHO_BD');
end;

end.
