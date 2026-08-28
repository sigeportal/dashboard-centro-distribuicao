unit UnitEmpresa.Model;

interface

uses
	System.SysUtils,
	{$IFDEF PORTALORM}
	UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type

	[TRecursoServidor('/empresa')]
	[TNomeTabela('EMPRESA', 'EMP_CODIGO')]
	TEmpresa = class(TTabela)
	private
		{ private declarations }
		FCNPJ                             : string;
		FInscricaoEstadual                : string;
		FRazaoSocial                      : string;
		FMunicipio                        : string;
		FUF                               : string;
		FFone                             : string;
		FFAX                              : string;
		FLogradouro                       : string;
		FNumero                           : string;
		FComplemento                      : string;
		FBairro                           : string;
		FCEP                              : string;
		FContato                          : string;
		FCodMunIBGE                       : string;
		FCodUFIBGE                        : string;
		FFantasia                         : string;
		FCRT                              : string;
		FSUFRAMA                          : string;
		FPerfil                           : string;
		FAtividade                        : string;
		FEmail                            : string;
		FLicencaDLLNFe                    : string;
		FTitulo1                          : string;
		FTitulo2                          : string;
		FTitulo3                          : string;
		FInscricaoMunicipal               : string;
		FLicenca                          : string;
		FRNTRC                            : string;
		FLicencaDLLMDFe                   : string;
		FID_CSC                           : string;
		FCSC                              : string;
		FTipoAtividade                    : string;
		FCodigo                           : integer;
		FIndicadorDaNaturezaPessoaJuridica: string;
		FLogo                             : string;
		FCodCNAE                          : string;
    FEmpCC: integer;
		function GetCNPJ: string;
		function GetInscricaoEstadual: string;
		function GetRazaoSocial: string;
		function GetMunicipio: string;
		function GetUF: string;
		function GetAtividade: string;
		function GetBairro: string;
		function GetCEP: string;
		function GetCodMunIBGE: string;
		function GetCodUFIBGE: string;
		function GetComplemento: string;
		function GetContato: string;
		function GetCRT: string;
		function GetEmail: string;
		function GetFantasia: string;
		function GetFAX: string;
		function GetFone: string;
		function GetInscricaoMunicipal: string;
		function GetLicencaDLLNFe: string;
		function GetLogradouro: string;
		function GetNumero: string;
		function GetPerfil: string;
		function GetSUFRAMA: string;
		function GetTitulo1: string;
		function GetTitulo2: string;
		function GetTitulo3: string;
		function GetLicenca: string;
		function GetRNTRC: string;
		function GetLicencaDLLMDFe: string;
		function GetID_CSC: string;
		function GetCSC: string;
		function GetTipoAtividade: string;
		function GetCodigo: integer;
		function GetIndicadorDaNaturezaPessoaJuridica: string;
		function GetCodCNAE: string;
	protected
		procedure BuscaDados(Dado: string; Tentativa: smallint = 0);
		{ protected declarations }
	public
		{ public declarations }
		[TCampo('EMP_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
		property Codigo: integer read GetCodigo write FCodigo;
		[TCampo('EMP_CNPJ', 'VARCHAR(18)')]
		property CNPJ: string read GetCNPJ write FCNPJ;
		[TCampo('EMP_INSCEST', 'VARCHAR(20)')]
		property InscricaoEstadual: string read GetInscricaoEstadual write FInscricaoEstadual;
		[TCampo('EMP_RAZAO_SOCIAL', 'VARCHAR(100)')]
		property RazaoSocial: string read GetRazaoSocial write FRazaoSocial;
		[TCampo('EMP_MUNICIPIO', 'VARCHAR(50)')]
		property Municipio: string read GetMunicipio write FMunicipio;
		[TCampo('EMP_UF', 'CHAR(2)')]
		property UF: string read GetUF write FUF;
		[TCampo('EMP_FONE', 'VARCHAR(13)')]
		property Fone: string read GetFone write FFone;
		[TCampo('EMP_FAX', 'VARCHAR(13)')]
		property FAX: string read GetFAX write FFAX;
		[TCampo('EMP_LOGRADOURO', 'VARCHAR(50)')]
		property Logradouro: string read GetLogradouro write FLogradouro;
		[TCampo('EMP_NUMERO', 'VARCHAR(10)')]
		property Numero: string read GetNumero write FNumero;
		[TCampo('EMP_COMPLEMENTO', 'VARCHAR(50)')]
		property Complemento: string read GetComplemento write FComplemento;
		[TCampo('EMP_BAIRRO', 'VARCHAR(30)')]
		property Bairro: string read GetBairro write FBairro;
		[TCampo('EMP_CEP', 'VARCHAR(10)')]
		property CEP: string read GetCEP write FCEP;
		[TCampo('EMP_CONTATO', 'VARCHAR(30)')]
		property Contato: string read GetContato write FContato;
		[TCampo('EMP_CODMUN_IBGE', 'VARCHAR(10)')]
		property CodMunIBGE: string read GetCodMunIBGE write FCodMunIBGE;
		[TCampo('EMP_CODUF_IBGE', 'VARCHAR(10)')]
		property CodUFIBGE: string read GetCodUFIBGE write FCodUFIBGE;
		[TCampo('EMP_FANTASIA', 'VARCHAR(100)')]
		property Fantasia: string read GetFantasia write FFantasia;
		[TCampo('EMP_CRT', 'VARCHAR(2)')]
		property CRT: string read GetCRT write FCRT;
		[TCampo('EMP_SUFRAMA', 'VARCHAR(9)')]
		property SUFRAMA: string read GetSUFRAMA write FSUFRAMA;
		[TCampo('EMP_PERFIL', 'VARCHAR(1)')]
		property Perfil: string read GetPerfil write FPerfil;
		[TCampo('EMP_ATIVIDADE', 'VARCHAR(1)')]
		property Atividade: string read GetAtividade write FAtividade;
		[TCampo('EMP_EMAIL', 'VARCHAR(50)')]
		property Email: string read GetEmail write FEmail;
		[TCampo('EMP_LICENCA_DLL_NFE', 'VARCHAR(200)')]
		property LicencaDLLNFe: string read GetLicencaDLLNFe write FLicencaDLLNFe;
		[TCampo('EMP_TITULO1', 'VARCHAR(100)')]
		property Titulo1: string read GetTitulo1 write FTitulo1;
		[TCampo('EMP_TITULO2', 'VARCHAR(100)')]
		property Titulo2: string read GetTitulo2 write FTitulo2;
		[TCampo('EMP_TITULO3', 'VARCHAR(100)')]
		property Titulo3: string read GetTitulo3 write FTitulo3;
		[TCampo('EMP_INSCMUN', 'VARCHAR(20)')]
		property InscricaoMunicipal: string read GetInscricaoMunicipal write FInscricaoMunicipal;
		[TCampo('EMP_LICENCA', 'VARCHAR(20)')]
		property Licenca: string read GetLicenca write FLicenca;
		[TCampo('EMP_RNTRC', 'VARCHAR(10)')]
		property RNTRC: string read GetRNTRC write FRNTRC;
		[TCampo('EMP_LICENCA_DLL_MDF', 'VARCHAR(200)')]
		property LicencaDLLMDFe: string read GetLicencaDLLMDFe write FLicencaDLLMDFe;
		[TCampo('EMP_ID_CSC', 'VARCHAR(10)')]
		property ID_CSC: string read GetID_CSC write FID_CSC;
		[TCampo('EMP_CSC', 'VARCHAR(50)')]
		property CSC: string read GetCSC write FCSC;
		[TCampo('EMP_TIPO_ATIVIDADE', 'VARCHAR(2)')]
		property TipoAtividade: string read GetTipoAtividade write FTipoAtividade;
		[TCampo('EMP_IND_NAT_PJ', 'VARCHAR(2)')]
		property IndicadorDaNaturezaPessoaJuridica: string read GetIndicadorDaNaturezaPessoaJuridica write FIndicadorDaNaturezaPessoaJuridica;
		[TCampo('EMP_LOGO', 'VARCHAR(1000)')]
		property Logo: string read FLogo write FLogo;
		[TCampo('EMP_CNAE', 'VARCHAR(10)')]
		property CodCNAE: string read GetCodCNAE write FCodCNAE;
    [TCampo('EMP_CC_CODIGO', 'INTEGER')]
    property EmpCC: integer read FEmpCC write FEmpCC;
	end;

implementation

{ TEmpresa }

function TEmpresa.GetCodCNAE: string;
begin
	BuscaDados(FCodCNAE);
	Result := FCodCNAE;
end;

function TEmpresa.GetCodigo: integer;
begin
	BuscaDados(FCodigo.ToString);
	Result := FCodigo;
end;

function TEmpresa.GetCodMunIBGE: string;
begin
	BuscaDados(FCodMunIBGE);
	Result := FCodMunIBGE;
end;

function TEmpresa.GetCodUFIBGE: string;
begin
	BuscaDados(FCodUFIBGE);
	Result := FCodUFIBGE;
end;

function TEmpresa.GetComplemento: string;
begin
	BuscaDados(FComplemento);
	Result := FComplemento;
end;

function TEmpresa.GetContato: string;
begin
	BuscaDados(FContato);
	Result := FContato;
end;

function TEmpresa.GetCRT: string;
begin
	BuscaDados(FCRT);
	Result := FCRT;
end;

function TEmpresa.GetCSC: string;
begin
	BuscaDados(FCSC);
	Result := FCSC;
end;

function TEmpresa.GetEmail: string;
begin
	BuscaDados(FEmail);
	Result := FEmail;
end;

function TEmpresa.GetFantasia: string;
begin
	BuscaDados(FFantasia);
	Result := FFantasia;
end;

function TEmpresa.GetFAX: string;
begin
	BuscaDados(FFAX);
	Result := FFAX;
end;

function TEmpresa.GetFone: string;
begin
	BuscaDados(FFone);
	Result := FFone;
end;

function TEmpresa.GetID_CSC: string;
begin
	BuscaDados(FID_CSC);
	Result := FID_CSC;
end;

function TEmpresa.GetIndicadorDaNaturezaPessoaJuridica: string;
begin
	BuscaDados(FIndicadorDaNaturezaPessoaJuridica);
	Result := FIndicadorDaNaturezaPessoaJuridica;
end;

function TEmpresa.GetInscricaoEstadual: string;
begin
	BuscaDados(FInscricaoEstadual);
	Result := FInscricaoEstadual;
end;

function TEmpresa.GetInscricaoMunicipal: string;
begin
	BuscaDados(FInscricaoMunicipal);
	Result := FInscricaoMunicipal;
end;

function TEmpresa.GetLicenca: string;
begin
	BuscaDados(FLicenca);
	Result := FLicenca;
end;

function TEmpresa.GetLicencaDLLMDFe: string;
begin
	BuscaDados(FLicencaDLLMDFe);
	Result := FLicencaDLLMDFe;
end;

function TEmpresa.GetLicencaDLLNFe: string;
begin
	BuscaDados(FLicencaDLLNFe);
	Result := FLicencaDLLNFe;
end;

function TEmpresa.GetLogradouro: string;
begin
	BuscaDados(FLogradouro);
	Result := FLogradouro;
end;

function TEmpresa.GetMunicipio: string;
begin
	BuscaDados(FMunicipio);
	Result := FMunicipio;
end;

function TEmpresa.GetNumero: string;
begin
	BuscaDados(FNumero);
	Result := FNumero;
end;

function TEmpresa.GetPerfil: string;
begin
	BuscaDados(FPerfil);
	Result := FPerfil;
end;

function TEmpresa.GetRazaoSocial: string;
begin
	BuscaDados(FRazaoSocial);
	Result := FRazaoSocial;
end;

function TEmpresa.GetRNTRC: string;
begin
	BuscaDados(FRNTRC);
	Result := FRNTRC;
end;

function TEmpresa.GetSUFRAMA: string;
begin
	BuscaDados(FSUFRAMA);
	Result := FSUFRAMA;
end;

function TEmpresa.GetTipoAtividade: string;
begin
	BuscaDados(FTipoAtividade);
	Result := FTipoAtividade;
end;

function TEmpresa.GetTitulo1: string;
begin
	BuscaDados(FTitulo1);
	Result := FTitulo1;
end;

function TEmpresa.GetTitulo2: string;
begin
	BuscaDados(FTitulo2);
	Result := FTitulo2;
end;

function TEmpresa.GetTitulo3: string;
begin
	BuscaDados(FTitulo3);
	Result := FTitulo3;
end;

function TEmpresa.GetUF: string;
begin
	BuscaDados(FUF);
	Result := FUF;
end;

procedure TEmpresa.BuscaDados(Dado: string; Tentativa: smallint = 0);
begin
	if (Dado = '') or (Self.FCodigo = 0) then
	begin
		BuscaDadosTabela(1);
	end;
end;

function TEmpresa.GetAtividade: string;
begin
	BuscaDados(FAtividade);
	Result := FAtividade;
end;

function TEmpresa.GetBairro: string;
begin
	BuscaDados(FBairro);
	Result := FBairro;
end;

function TEmpresa.GetCEP: string;
begin
	BuscaDados(FCEP);
	Result := FCEP;
end;

function TEmpresa.GetCNPJ: string;
begin
	BuscaDados(FCNPJ);
	Result := FCNPJ;
end;

end.
