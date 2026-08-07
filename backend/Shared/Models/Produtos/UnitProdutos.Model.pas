unit UnitProdutos.Model;

interface

uses
  UnitPortalORM.Model,
  UnitSubGrupos.Model,
  UnitFornecedores.Model,
  UnitTotalizadores.Model;

type
  [TRecursoServidor('/produtos')]
  [TNomeTabela('PRODUTOS', 'PRO_CODIGO')]
  TProdutos = class(TTabela)
  private
		FCodigo: integer;
		FNome: string;		
		FLocal: string;
		FValorv: Real;
		FGru: integer;
		FQuantidadef: Real;
		FCodbarra: string;
		FTipo_item: string;
		FUm: smallint;
		FDatauc: TDate;
    FGenero: integer;
    FAliqicms_opint: Real;
    FDataua: TDate;
    FMar: smallint;
    FSit_trib: string;
    FIat: string;
    FDescricao: string;
    FValorl: Real;
    FCest: string;
		FValorc: Real;
    FGtin: string;
    FExcecao_ncm: smallint;
    FCfop: string;
    FCodTotalizador: smallint;
    FValorf: Real;
    FCod_agrup: string;
    FNcm: string;
    FIppt: string;
    FForCodigo: integer;
    FValorcm: Real;
    FEmbalagem: string;
    FFabricante: string;
    FAbc_analitico: string;
    FQuantidade: Real;
    FAbc: string;
    FTt: integer;
		FTipo: smallint;
    FQuantidadem: Real;
    FCst: string;
		FValors: Real;
		FValorp: Real;
		FEstado: string;
		FPerc_red_opint: Real;
		FSubGrupo: TSubGrupos;
		FFornecedor: TFornecedores;
		FURL_Imagem: string;
    FTotalizador: TTotalizadores;
		FValor_dinheiro: Real;
		FValorv_prazo: Real;
    FEmp: integer;
    FCadastrar: string;
    FCodFiscal: integer;
    FFiscalGerar: string;
		{ private declarations }
	public
		{ public declarations }
		[TCampo('PRO_CODIGO', 'NUMERIC(8,0) NOT NULL PRIMARY KEY')]
		property Codigo: integer read FCodigo write FCodigo;
		[TCampo('PRO_EMP', 'NUMERIC(4,0)')]
		property Emp: integer read FEmp write FEmp;
		[TCampo('PRO_NOME', 'VARCHAR(200)')]
    property Nome: string read FNome write FNome;
		[TCampo('PRO_FOR', 'NUMERIC(4,0)')]
		property ForCodigo: integer read FForCodigo write FForCodigo;
		[TCampo('PRO_FABRICANTE', 'VARCHAR(20)')]
		property Fabricante: string read FFabricante write FFabricante;
		[TCampo('PRO_QUANTIDADEM', 'NUMERIC(3,0)')]
		property Quantidadem: Real read FQuantidadem write FQuantidadem;
		[TCampo('PRO_QUANTIDADE', 'NUMERIC(9,2)')]
		property Quantidade: Real read FQuantidade write FQuantidade;
		[TCampo('PRO_VALORV', 'NUMERIC(9,4)')]
		property Valorv: Real read FValorv write FValorv;
		[TCampo('PRO_VALOR_DINHEIRO', 'NUMERIC(9,4)')]
		property ValorDinheiro: Real read FValor_dinheiro write FValor_dinheiro;
		[TCampo('PRO_VALORV_PRAZO', 'NUMERIC(9,4)')]
		property ValorPrazo: Real read FValorv_prazo write FValorv_prazo;
		[TCampo('PRO_VALORCM', 'NUMERIC(9,4)')]
		property Valorcm: Real read FValorcm write FValorcm;
		[TCampo('PRO_VALORC', 'NUMERIC(9,4)')]
		property Valorc: Real read FValorc write FValorc;
		[TCampo('PRO_VALORL', 'NUMERIC(9,4)')]
		property Valorl: Real read FValorl write FValorl;
		[TCampo('PRO_VALORF', 'NUMERIC(9,4)')]
		property Valorf: Real read FValorf write FValorf;
		[TCampo('PRO_QUANTIDADEF', 'NUMERIC(9,2)')]
		property Quantidadef: Real read FQuantidadef write FQuantidadef;
		[TCampo('PRO_LOCAL', 'VARCHAR(20)')]
		property Local: string read FLocal write FLocal;
		[TCampo('PRO_EMBALAGEM', 'VARCHAR(10)')]
		property Embalagem: string read FEmbalagem write FEmbalagem;
		[TCampo('PRO_DATAUC', 'DATE')]
		property Datauc: TDate read FDatauc write FDatauc;
		[TCampo('PRO_GRU', 'NUMERIC(3,0)')]
		property Gru: integer read FGru write FGru;
		[TCampo('PRO_DESCRICAO', 'VARCHAR(30)')]
		property Descricao: string read FDescricao write FDescricao;
		[TCampo('PRO_DATAUA', 'DATE')]
		property Dataua: TDate read FDataua write FDataua;
		[TCampo('PRO_ABC', 'VARCHAR(2)')]
		property Abc: string read FAbc write FAbc;
		[TCampo('PRO_CODBARRA', 'VARCHAR(30)')]
		property Codbarra: string read FCodbarra write FCodbarra;
		[TCampo('PRO_VALORS', 'NUMERIC(9,2)')]
		property Valors: Real read FValors write FValors;
		[TCampo('PRO_TIPO', 'SMALLINT')]
		property Tipo: smallint read FTipo write FTipo;
		[TCampo('PRO_TOTALIZADOR', 'SMALLINT')]
		property CodTotalizador: smallint read FCodTotalizador write FCodTotalizador;
		[TCampo('PRO_ESTADO', 'VARCHAR(8)')]
    property Estado: string read FEstado write FEstado;
    [TCampo('PRO_GTIN', 'VARCHAR(14)')]
    property Gtin: string read FGtin write FGtin;
    [TCampo('PRO_IAT', 'VARCHAR(1)')]
    property Iat: string read FIat write FIat;
    [TCampo('PRO_IPPT', 'VARCHAR(1)')]
    property Ippt: string read FIppt write FIppt;
    [TCampo('PRO_SIT_TRIB', 'VARCHAR(20)')]
    property Sit_trib: string read FSit_trib write FSit_trib;
    [TCampo('PRO_ALIQICMS_OPINT', 'NUMERIC(3,0)')]
    property Aliqicms_opint: Real read FAliqicms_opint write FAliqicms_opint;
    [TCampo('PRO_PERC_RED_OPINT', 'NUMERIC(9,4)')]
    property Perc_red_opint: Real read FPerc_red_opint write FPerc_red_opint;
    [TCampo('PRO_UM', 'SMALLINT')]
    property Um: smallint read FUm write FUm;
    [TCampo('PRO_CST', 'VARCHAR(3)')]
    property Cst: string read FCst write FCst;
    [TCampo('PRO_GENERO', 'INTEGER')]
    property Genero: integer read FGenero write FGenero;
    [TCampo('PRO_TT', 'INTEGER')]
    property Tt: integer read FTt write FTt;
    [TCampo('PRO_NCM', 'VARCHAR(10)')]
    property Ncm: string read FNcm write FNcm;
    [TCampo('PRO_CFOP', 'VARCHAR(5)')]
    property Cfop: string read FCfop write FCfop;
    [TCampo('PRO_MAR', 'SMALLINT')]
    property Mar: smallint read FMar write FMar;
    [TCampo('PRO_COD_AGRUP', 'VARCHAR(20)')]
    property Cod_agrup: string read FCod_agrup write FCod_agrup;
    [TCampo('PRO_EXCECAO_NCM', 'SMALLINT')]
    property Excecao_ncm: smallint read FExcecao_ncm write FExcecao_ncm;
    [TCampo('PRO_TIPO_ITEM', 'VARCHAR(2)')]
    property Tipo_item: string read FTipo_item write FTipo_item;
    [TCampo('PRO_CEST', 'VARCHAR(10)')]
    property Cest: string read FCest write FCest;
    [TCampo('PRO_VALORP', 'NUMERIC(9,4)')]
    property Valorp: Real read FValorp write FValorp;
    [TCampo('PRO_ABC_ANALITICO', 'VARCHAR(3)')]
    property Abc_analitico: string read FAbc_analitico write FAbc_analitico;
    [TRelacionamento('GRUPOS', 'GRU_CODIGO', 'PRO_GRU', TSubGrupos, UmPraUm)]
    property SubGrupo: TSubGrupos read FSubGrupo write FSubGrupo;
    [TRelacionamento('FORNECEDORES', 'FOR_CODIGO', 'PRO_FOR', TFornecedores, UmPraUm)]
    [TCampo('PRO_URL_IMAGEM', 'VARCHAR(1000)')]
    property URL_Imagem: string read FURL_Imagem write FURL_Imagem;
    [TCampo('PRO_CADASTRAR', 'CHAR(1) DEFAULT ''N''')]
    property Cadastrar: string read FCadastrar write FCadastrar;
    [TCampo('PRO_COD_FISCAL', 'INTEGER')]
    property CodFiscal: integer read FCodFiscal write FCodFiscal;
    [TCampo('PRO_FISCAL_GERAR', 'CHAR(1) DEFAULT ''S''')]
    property FiscalGerar: string read FFiscalGerar write FFiscalGerar;
  end;

implementation

end.
