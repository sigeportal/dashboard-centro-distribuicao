unit UnitConstants;

interface

uses System.SysUtils;

type
	TAPIError = class
  private
    Ferror: string;
  public
    property error: string read Ferror write Ferror;
  end;
  
   TConstants = class
  const
//    URL_AUTENTICACAO = 'https://servidor-auth-dash-fboxwqyjfq-rj.a.run.app';
    URL_AUTENTICACAO = 'http://127.0.0.1:9000';
    JWT_SECRET = 'Portal@3694_05557971000150';
  public
    class function BancoDados: string; static;
    class function URL_CD: string; static;
  end;

implementation

{ TConstants }

uses System.StrUtils;

class function TConstants.URL_CD: string;
begin
  Result := GetEnvironmentVariable('URL_CD').Trim;
  if Result.IsEmpty then
    Result := 'http://127.0.0.1:9000';
end;

class function TConstants.BancoDados: string;
begin
  Result := GetEnvironmentVariable('CAMINHO_BD');
//  Result := 'C:\Users\nanan\Documents\Estudos 4� Ano\Est�gio\API-Local\Dados\PRINCIPAL.FDB'
end;

end.
