unit UnitTotalizadores.Model;

interface

uses
	UnitBancoDeDados.Model;

type

	[TRecursoServidor('/totalizadores')]
	[TNomeTabela('TOTALIZADORES', 'TOT_CODIGO')]
	TTotalizadores = class(TTabela)
	private
		FCodigo     : integer;
		FCst_pis    : string;
		FCst_cofins : string;
		FSit_trib   : string;
		FTotalizador: string;
		FMd5        : string;
		FAliq_pis   : Real;
		FAliq_cofins: Real;
		FAliquota   : Real;
		FCst        : string;
		{ private declarations }
	public
		{ public declarations }
		[TCampo('TOT_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
		property Codigo: integer read FCodigo write FCodigo;
		[TCampo('TOT_TOTALIZADOR', 'VARCHAR(5)')]
		property Totalizador: string read FTotalizador write FTotalizador;
		[TCampo('TOT_MD5', 'VARCHAR(40)')]
		property Md5: string read FMd5 write FMd5;
		[TCampo('TOT_SIT_TRIB', 'CHAR(1)')]
		property Sit_trib: string read FSit_trib write FSit_trib;
		[TCampo('TOT_CST', 'VARCHAR(5)')]
		property Cst: string read FCst write FCst;
		[TCampo('TOT_ALIQUOTA', 'NUMERIC(5,2)')]
		property Aliquota: Real read FAliquota write FAliquota;
		[TCampo('TOT_CST_PIS', 'VARCHAR(5)')]
		property Cst_pis: string read FCst_pis write FCst_pis;
		[TCampo('TOT_ALIQ_PIS', 'NUMERIC(3,2)')]
		property Aliq_pis: Real read FAliq_pis write FAliq_pis;
		[TCampo('TOT_CST_COFINS', 'VARCHAR(5)')]
		property Cst_cofins: string read FCst_cofins write FCst_cofins;
		[TCampo('TOT_ALIQ_COFINS', 'NUMERIC(3,2)')]
		property Aliq_cofins: Real read FAliq_cofins write FAliq_cofins;
		function Clone: TTotalizadores;
	end;

implementation

{ TTotalizadores }

function TTotalizadores.Clone: TTotalizadores;
begin
	Result             := TTotalizadores.Create();
	Result.Codigo      := Self.Codigo;
	Result.Cst_pis     := Self.Cst_pis;
	Result.Cst_cofins  := Self.Cst_cofins;
	Result.Sit_trib    := Self.Sit_trib;
	Result.Totalizador := Self.Totalizador;
	Result.Md5         := Self.Md5;
	Result.Aliq_pis    := Self.Aliq_pis;
	Result.Aliq_cofins := Self.Aliq_cofins;
	Result.Aliquota    := Self.Aliquota;
	Result.Cst         := Self.Cst;
end;

end.
