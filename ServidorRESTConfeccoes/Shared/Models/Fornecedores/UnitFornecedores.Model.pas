unit UnitFornecedores.Model;

interface

uses
	UnitPortalORM.Model,
	UnitCidade.Model;

type
  [TRecursoServidor('/fornecedores')]
  [TNomeTabela('FORNECEDORES', 'FOR_CODIGO')]
  TFornecedores = class(TTabela)
  private
    FCodigo: integer;
    FNome: string;
		FIndic_ie: string;
    FInsc_estadual: string;
    FFone: string;
    FEnd_numero: string;
    FFantasia: string;
    FCnpj_cpf: string;
    FObs: string;
    FEmail: string;
    FBairro: string;
    FInsc: string;
    FDatac: TDate;
    FFax: string;
		FRazao_social: string;
		FUf: string;
		FCod_pais: integer;
		FCep: string;
		FSuframa: string;
		FComplemento: string;
		FCid: integer;
		FEndcorresp: string;
		FContato: string;
		FTipo: string;
		FDatau: TDate;
		FCgc: string;
    FEndereco: string;
    FCelular: string;
    FInscMunicipal: string;
    FCidade: TCidade;
    FCadastrar: string;
    { private declarations }
  public
    { public declarations }
    [TCampo('FOR_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('FOR_NOME', 'VARCHAR(80) NOT NULL')]
    property Nome: string read FNome write FNome;
		[TCampo('FOR_ENDERECO', 'VARCHAR(50)')]
    property Endereco: string read FEndereco write FEndereco;
    [TCampo('FOR_BAIRRO', 'VARCHAR(30)')]
    property Bairro: string read FBairro write FBairro;
		[TCampo('FOR_CEP', 'VARCHAR(9)')]
    property Cep: string read FCep write FCep;
    [TCampo('FOR_UF', 'VARCHAR(2)')]
    property Uf: string read FUf write FUf;
    [TCampo('FOR_FONE', 'VARCHAR(13)')]
    property Fone: string read FFone write FFone;
		[TCampo('FOR_CONTATO', 'VARCHAR(15)')]
    property Contato: string read FContato write FContato;
    [TCampo('FOR_EMAIL', 'VARCHAR(30)')]
    property Email: string read FEmail write FEmail;
    [TCampo('FOR_DATAC', 'DATE')]
    property Datac: TDate read FDatac write FDatac;
    [TCampo('FOR_DATAU', 'DATE')]
    property Datau: TDate read FDatau write FDatau;
    [TCampo('FOR_CELULAR', 'VARCHAR(14)')]
    property Celular: string read FCelular write FCelular;
    [TCampo('FOR_ENDCORRESP', 'VARCHAR(50)')]
    property Endcorresp: string read FEndcorresp write FEndcorresp;
    [TCampo('FOR_OBS', 'VARCHAR(255)')]
    property Obs: string read FObs write FObs;
    [TCampo('FOR_CNPJ_CPF', 'VARCHAR(18)')]
    property Cnpj_cpf: string read FCnpj_cpf write FCnpj_cpf;
    [TCampo('FOR_INSC_ESTADUAL', 'VARCHAR(20)')]
    property Insc_estadual: string read FInsc_estadual write FInsc_estadual;
    [TCampo('FOR_COMPLEMENTO', 'VARCHAR(50)')]
    property Complemento: string read FComplemento write FComplemento;
    [TCampo('FOR_COD_PAIS', 'INTEGER')]
    property Cod_pais: integer read FCod_pais write FCod_pais;
    [TCampo('FOR_SUFRAMA', 'VARCHAR(9)')]
    property Suframa: string read FSuframa write FSuframa;
    [TCampo('FOR_INDIC_IE', 'CHAR(1)')]
    property Indic_ie: string read FIndic_ie write FIndic_ie;
    [TCampo('FOR_CID', 'INTEGER')]
    property Cid: integer read FCid write FCid;
    [TCampo('FOR_RAZAO_SOCIAL', 'VARCHAR(100)')]
    property Razao_social: string read FRazao_social write FRazao_social;
    [TCampo('FOR_FANTASIA', 'VARCHAR(100)')]
    property Fantasia: string read FFantasia write FFantasia;
    [TCampo('FOR_END_NUMERO', 'VARCHAR(10)')]
    property End_numero: string read FEnd_numero write FEnd_numero;
    [TCampo('FOR_TIPO', 'VARCHAR(9)')]
		property Tipo: string read FTipo write FTipo;
		[TCampo('FOR_INSC_MUNICIPAL', 'VARCHAR(20)')]
		property InscMunicipal: string read FInscMunicipal write FInscMunicipal;
    [TRelacionamento('CIDADES', 'CID_CODIGO', 'FOR_CID', TCidade, UmPraUm)]
		property Cidade: TCidade read FCidade write FCidade;
    [TCampo('FOR_CADASTRAR', 'CHAR(1) DEFAULT ''N''')]
    property Cadastrar: string read FCadastrar write FCadastrar;
  end;

implementation

end.
