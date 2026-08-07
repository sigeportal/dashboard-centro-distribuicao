unit UnitProdutosServidor.Model;

interface

uses
	UnitPortalORM.Model;

type
	[TRecursoServidor('/produtos_servidor')]
	[TNomeTabela('PRODUTOS_SERVIDOR', 'PS_CODIGO')]
	TProdutosServidor = class(TTabela)
	private
		FCodigo: integer;
    FLocal: string;
    FValorv: double;
    FValorv_prazo: double;
    FGru: smallint;
    FQuantidadef: double;
    FCodbarra: string;
    FDatauc: TDate;
    FDataua: TDate;
    FCodTotalizador: smallint;
    FDescricao: string;
    FValorl: double;
    FValorc: double;
    FValorf: double;
    FValorcm: double;
    FEmbalagem: string;
    FFabricante: string;
    FQuantidade: double;
    FAbc: string;
    FNome: string;
    FTipo: smallint;
    FQuantidadem: smallint;
    FValors: double;
    FEstado: string;
    FCodFor: smallint;
	public
		[TCampo('PS_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
		property Codigo: integer read FCodigo write FCodigo;
    [TCampo('PS_FOR', 'SMALLINT')]
    property CodFor: smallint read FCodFor write FCodFor;
    [TCampo('PS_FABRICANTE', 'VARCHAR(20)')]
    property Fabricante: string read FFabricante write FFabricante;
    [TCampo('PS_QUANTIDADEM', 'SMALLINT')]
    property Quantidadem: smallint read FQuantidadem write FQuantidadem;
    [TCampo('PS_QUANTIDADE', 'NUMERIC(9,2)')]
    property Quantidade: double read FQuantidade write FQuantidade;
    [TCampo('PS_VALORV', 'NUMERIC(9,4)')]
    property Valorv: double read FValorv write FValorv;
    [TCampo('PS_VALORCM', 'NUMERIC(9,4)')]
    property Valorcm: double read FValorcm write FValorcm;
    [TCampo('PS_VALORC', 'NUMERIC(9,4)')]
    property Valorc: double read FValorc write FValorc;
    [TCampo('PS_VALORL', 'NUMERIC(9,4)')]
    property Valorl: double read FValorl write FValorl;
    [TCampo('PS_VALORF', 'NUMERIC(9,4)')]
    property Valorf: double read FValorf write FValorf;
    [TCampo('PS_QUANTIDADEF', 'NUMERIC(9,2)')]
    property Quantidadef: double read FQuantidadef write FQuantidadef;
    [TCampo('PS_LOCAL', 'VARCHAR(20)')]
    property Local: string read FLocal write FLocal;
    [TCampo('PS_EMBALAGEM', 'VARCHAR(10)')]
    property Embalagem: string read FEmbalagem write FEmbalagem;
    [TCampo('PS_DATAUC', 'DATE')]
    property Datauc: TDate read FDatauc write FDatauc;
    [TCampo('PS_GRU', 'SMALLINT')]
    property Gru: smallint read FGru write FGru;
    [TCampo('PS_DESCRICAO', 'VARCHAR(60)')]
    property Descricao: string read FDescricao write FDescricao;
    [TCampo('PS_DATAUA', 'DATE')]
    property Dataua: TDate read FDataua write FDataua;
    [TCampo('PS_ABC', 'VARCHAR(2)')]
    property Abc: string read FAbc write FAbc;
    [TCampo('PS_CODBARRA', 'VARCHAR(30)')]
    property Codbarra: string read FCodbarra write FCodbarra;
    [TCampo('PS_VALORS', 'NUMERIC(9,2)')]
    property Valors: double read FValors write FValors;
    [TCampo('PS_TIPO', 'SMALLINT')]
    property Tipo: smallint read FTipo write FTipo;
    [TCampo('PS_TOTALIZADOR', 'SMALLINT')]
    property CodTotalizador: smallint read FCodTotalizador write FCodTotalizador;
    [TCampo('PS_NOME', 'VARCHAR(50)')]
    property Nome: string read FNome write FNome;
    [TCampo('PS_ESTADO', 'VARCHAR(8)')]
    property Estado: string read FEstado write FEstado;
    [TCampo('PS_VALORV_PRAZO', 'NUMERIC(9,4)')]
    property Valorv_prazo: double read FValorv_prazo write FValorv_prazo;
	end;

implementation

end.
