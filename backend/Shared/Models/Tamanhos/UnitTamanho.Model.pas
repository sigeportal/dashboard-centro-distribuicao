unit UnitTamanho.Model;

interface

uses
	UnitPortalORM.Model;

type
	[TNomeTabela('TAMANHOS', 'TAM_CODIGO')]
	TTamanho = class(TTabela)
	private
		FCodigo: integer;
    FValor: double;
    FPro: integer;
    FSigla: string;
    FTamanho: string;
    FCadastrar: string;
	public
		[TCampo('TAM_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
		property Codigo: integer read FCodigo write FCodigo;
    [TCampo('TAM_PRO', 'INTEGER')]
		property Pro: integer read FPro write FPro;
		[TCampo('TAM_TAMANHO', 'VARCHAR(25)')]
		property Tamanho: string read FTamanho write FTamanho;
		[TCampo('TAM_SIGLA', 'VARCHAR(2)')]
		property Sigla: string read FSigla write FSigla;
		[TCampo('TAM_VALOR', 'NUMERIC(9,4)')]
		property Valor: double read FValor write FValor;
    [TCampo('TAM_CADASTRAR', 'CHAR(1) DEFAULT ''N''')]
    property Cadastrar: string read FCadastrar write FCadastrar;
	end;

implementation

end.
