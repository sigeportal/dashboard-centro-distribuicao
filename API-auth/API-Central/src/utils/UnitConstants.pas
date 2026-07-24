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

  TUserPost = class
  private
    FCpf: string;
    FPassword: string;
  public
    property cpf: string read FCpf write FCpf;
    property password: string read FPassword write FPassword;
  end;

  TRegisterRequest = class
  private
    FNome: string;
    FCpf: string;
    FPassword: string;
  public
    property nome: string read FNome write FNome;
    property cpf: string read FCpf write FCpf;
    property password: string read FPassword write FPassword;
  end;

  TRegisterResponse = class
  private
    FId: string;
    FNome: string;
    FCpf: string;
    FPlano: Integer;
  public
    property id: string read FId write FId;
    property nome: string read FNome write FNome;
    property cpf: string read FCpf write FCpf;
    property plano: Integer read FPlano write FPlano;
  end;

  TTokenResponse = class
  private
    FAccessToken: string;
    FRefreshToken: string;
  public
    property access_token: string read FAccessToken write FAccessToken;
    property refresh_token: string read FRefreshToken write FRefreshToken;
  end;

  TRefreshRequest = class
  private
    FRefreshToken: string;
  public
    property refresh_token: string read FRefreshToken write FRefreshToken;
  end;

  TUpdateUrlRequest = class
  private
    FCnpj: string;
    FUrl: string;
    FTimestamp: string;
    FAssinatura: string;
  public
    property cnpj: string read FCnpj write FCnpj;
    property url: string read FUrl write FUrl;
    property timestamp: string read FTimestamp write FTimestamp;
    property assinatura: string read FAssinatura write FAssinatura;
  end;

  TCompanySelfRegisterRequest = class
  private
    FCnpj: string;
    FNome: string;
    FUrl: string;
    FClaim: string;
    FTimestamp: string;
    FAssinatura: string;
  public
    property cnpj: string read FCnpj write FCnpj;
    property nome: string read FNome write FNome;
    property url: string read FUrl write FUrl;
    property claim: string read FClaim write FClaim;
    property timestamp: string read FTimestamp write FTimestamp;
    property assinatura: string read FAssinatura write FAssinatura;
  end;

  TCompanyLinkRequest = class
  private
    FCnpj: string;
    FClaim: string;
  public
    property cnpj: string read FCnpj write FCnpj;
    property claim: string read FClaim write FClaim;
  end;

  TCompanyResponse = class
  private
    FId: string;
    FCnpj: string;
    FNome: string;
    FUrl: string;
  public
    property id: string read FId write FId;
    property cnpj: string read FCnpj write FCnpj;
    property nome: string read FNome write FNome;
    property url: string read FUrl write FUrl;
  end;

  TCompanyLinkResponse = class
  private
    FEmpresaId: string;
    FCnpj: string;
  public
    property empresa_id: string read FEmpresaId write FEmpresaId;
    property cnpj: string read FCnpj write FCnpj;
  end;

  TUpdatePasswordRequest = class
  private
    FOldPassword: string;
    FNewPassword: string;
  public
    property old_password: string read FOldPassword write FOldPassword;
    property new_password: string read FNewPassword write FNewPassword;
  end;
  
  TConstants = class
  const
    JWT_SECRET = 'Portal@3694_05557971000150';
  public
    class function BancoDados: string;
  end;

implementation

{ TConstants }

uses System.StrUtils;

class function TConstants.BancoDados: string;
begin
  Result := GetEnvironmentVariable('CAMINHO_BD');
//  Result := '172.31.144.1:C:\Users\nanan\Documents\DADOS-DELPHI\BANCO_NOVO_TESTE.FDB';
//    Result := 'C:\Users\nanan\Documents\DADOS-DELPHI\BANCO_NOVO_TESTE.FDB';
end;

end.
