unit UnitGrades.Model;

interface

uses
	UnitPortalORM.Model,
  UnitTamanho.Model;

type
	[TRecursoServidor('/grades')]
	[TNomeTabela('GRADES', 'GRA_CODIGO')]
	TGrades = class(TTabela)
	private
		FCodigo: integer;
    FCodbarra: string;
    FCor: string;
    FValor: double;
    FTam: integer;
    FPro: integer;
    FQuantidade: double;
    FTamanho: TTamanho;
    FValorDinheiro: Currency;
    FValorPrazo: Currency;
	public
		[TCampo('GRA_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
		property Codigo: integer read FCodigo write FCodigo;
    [TCampo('GRA_PRO', 'INTEGER')]
    property Pro: integer read FPro write FPro;
    [TCampo('GRA_VALOR', 'NUMERIC(9,2)')]
    property Valor: double read FValor write FValor;
    [TCampo('GRA_TAM', 'INTEGER')]
    property Tam: integer read FTam write FTam;
    [TCampo('GRA_QUANTIDADE', 'NUMERIC(9,2)')]
    property Quantidade: double read FQuantidade write FQuantidade;
    [TCampo('GRA_CODBARRA', 'VARCHAR(30)')]
    property Codbarra: string read FCodbarra write FCodbarra;
    [TCampo('GRA_COR', 'VARCHAR(30)')]
    property Cor: string read FCor write FCor;
    [TCampo('GRA_VALOR_DINHEIRO', 'NUMERIC(9,2)')]
		property ValorDinheiro: Currency read FValorDinheiro write FValorDinheiro;
		[TCampo('GRA_VALOR_PRAZO', 'NUMERIC(9,2)')]
		property ValorPrazo: Currency read FValorPrazo write FValorPrazo;
    [TRelacionamento('TAMANHOS', 'TAM_CODIGO', 'GRA_TAM', TTamanho, TTipoRelacionamento.UmPraUm)]
    property Tamanho: TTamanho read FTamanho write FTamanho;
	end;

implementation

end.
