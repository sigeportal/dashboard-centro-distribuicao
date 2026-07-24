unit UnitEmpresa.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/empresa')]
  [TNomeTabela('EMPRESA', 'EMP_CODIGO')]
  TEmpresa = class(TTabela)
  private
    FCodigo: integer;
    FLogradouro: string;
    FFone: string;
    FCnae: string;
    FFantasia: string;
    FCnpj: string;
    FEmail: string;
    FBairro: string;
    FFax: string;
    FRazao_social: string;
    FTipo_atividade: string;
    FCsc: string;
    FInscest: string;
    FUf: string;
    FId_csc: string;
    FInscmun: string;
    FLicenca_dll_nfe: string;
    FLicenca_dll_mdf: string;
    FCep: string;
    FPerfil: string;
    FNumero: string;
    FMd5: string;
    FLicenca: string;
    FSuframa: string;
    FMunicipio: string;
    FRntrc: string;
    FComplemento: string;
    FCodmun_ibge: string;
    FContato: string;
    FAtividade: string;
    FLogo: string;
    FCoduf_ibge: string;
    FTitulo2: string;
    FTitulo3: string;
    FInd_nat_pj: string;
    FCrt: string;
    FTitulo1: string;
    { private declarations }
  public
    { public declarations }
    [TCampo('EMP_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('EMP_CNPJ', 'VARCHAR(18)')]
    property Cnpj: string read FCnpj write FCnpj;
    [TCampo('EMP_INSCEST', 'VARCHAR(20)')]
    property Inscest: string read FInscest write FInscest;
    [TCampo('EMP_RAZAO_SOCIAL', 'VARCHAR(50)')]
    property Razao_social: string read FRazao_social write FRazao_social;
    [TCampo('EMP_MUNICIPIO', 'VARCHAR(50)')]
    property Municipio: string read FMunicipio write FMunicipio;
    [TCampo('EMP_UF', 'CHAR(2)')]
    property Uf: string read FUf write FUf;
    [TCampo('EMP_FONE', 'VARCHAR(14)')]
    property Fone: string read FFone write FFone;
    [TCampo('EMP_FAX', 'VARCHAR(13)')]
    property Fax: string read FFax write FFax;
    [TCampo('EMP_LOGRADOURO', 'VARCHAR(50)')]
    property Logradouro: string read FLogradouro write FLogradouro;
    [TCampo('EMP_NUMERO', 'VARCHAR(10)')]
    property Numero: string read FNumero write FNumero;
    [TCampo('EMP_COMPLEMENTO', 'VARCHAR(50)')]
    property Complemento: string read FComplemento write FComplemento;
    [TCampo('EMP_BAIRRO', 'VARCHAR(30)')]
    property Bairro: string read FBairro write FBairro;
    [TCampo('EMP_CEP', 'VARCHAR(10)')]
    property Cep: string read FCep write FCep;
    [TCampo('EMP_CONTATO', 'VARCHAR(30)')]
    property Contato: string read FContato write FContato;
    [TCampo('EMP_CODMUN_IBGE', 'VARCHAR(10)')]
    property Codmun_ibge: string read FCodmun_ibge write FCodmun_ibge;
    [TCampo('EMP_CODUF_IBGE', 'VARCHAR(10)')]
    property Coduf_ibge: string read FCoduf_ibge write FCoduf_ibge;
    [TCampo('EMP_FANTASIA', 'VARCHAR(100)')]
    property Fantasia: string read FFantasia write FFantasia;
    [TCampo('EMP_CRT', 'CHAR(1)')]
    property Crt: string read FCrt write FCrt;
    [TCampo('EMP_SUFRAMA', 'VARCHAR(9)')]
    property Suframa: string read FSuframa write FSuframa;
    [TCampo('EMP_PERFIL', 'VARCHAR(1)')]
    property Perfil: string read FPerfil write FPerfil;
    [TCampo('EMP_ATIVIDADE', 'VARCHAR(1)')]
    property Atividade: string read FAtividade write FAtividade;
    [TCampo('EMP_EMAIL', 'VARCHAR(50)')]
    property Email: string read FEmail write FEmail;
    [TCampo('EMP_TITULO1', 'VARCHAR(100)')]
    property Titulo1: string read FTitulo1 write FTitulo1;
    [TCampo('EMP_TITULO2', 'VARCHAR(100)')]
    property Titulo2: string read FTitulo2 write FTitulo2;
    [TCampo('EMP_TITULO3', 'VARCHAR(100)')]
    property Titulo3: string read FTitulo3 write FTitulo3;
    [TCampo('EMP_MD5', 'VARCHAR(50)')]
    property Md5: string read FMd5 write FMd5;
    [TCampo('EMP_LICENCA', 'VARCHAR(20)')]
    property Licenca: string read FLicenca write FLicenca;
    [TCampo('EMP_LICENCA_DLL_NFE', 'VARCHAR(200)')]
    property Licenca_dll_nfe: string read FLicenca_dll_nfe write FLicenca_dll_nfe;
    [TCampo('EMP_ID_CSC', 'VARCHAR(10)')]
    property Id_csc: string read FId_csc write FId_csc;
    [TCampo('EMP_CSC', 'VARCHAR(50)')]
    property Csc: string read FCsc write FCsc;
    [TCampo('EMP_INSCMUN', 'VARCHAR(20)')]
    property Inscmun: string read FInscmun write FInscmun;
    [TCampo('EMP_RNTRC', 'VARCHAR(10)')]
    property Rntrc: string read FRntrc write FRntrc;
    [TCampo('EMP_LICENCA_DLL_MDF', 'VARCHAR(200)')]
    property Licenca_dll_mdf: string read FLicenca_dll_mdf write FLicenca_dll_mdf;
    [TCampo('EMP_TIPO_ATIVIDADE', 'VARCHAR(2)')]
    property Tipo_atividade: string read FTipo_atividade write FTipo_atividade;
    [TCampo('EMP_IND_NAT_PJ', 'VARCHAR(2)')]
    property Ind_nat_pj: string read FInd_nat_pj write FInd_nat_pj;
    [TCampo('EMP_LOGO', 'VARCHAR(1000)')]
    property Logo: string read FLogo write FLogo;
    [TCampo('EMP_CNAE', 'VARCHAR(10)')]
    property Cnae: string read FCnae write FCnae;
  end;

implementation

end.
