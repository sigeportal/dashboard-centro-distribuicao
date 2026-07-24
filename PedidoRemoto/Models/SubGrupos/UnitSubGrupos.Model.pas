unit UnitSubGrupos.Model;

interface

uses
	UnitBancoDeDados.Model;

type

	[TRecursoServidor('/subgrupos')]
	[TNomeTabela('GRUPOS', 'GRU_CODIGO')]
	TSubGrupos = class(TTabela)
	private
		FCodigo: integer;
		FG1    : smallint;
		FTr    : smallint;
		FNome  : string;
		{ private declarations }
	public
		{ public declarations }
		[TCampo('GRU_CODIGO', 'NUMERIC(3,0) NOT NULL')]
		property Codigo: integer read FCodigo write FCodigo;
		[TCampo('GRU_NOME', 'VARCHAR(20)')]
		property Nome: string read FNome write FNome;
		[TCampo('GRU_G1', 'SMALLINT')]
		property G1: smallint read FG1 write FG1;
		[TCampo('GRU_TR', 'SMALLINT')]
		property Tr: smallint read FTr write FTr;
		function Clone: TSubGrupos;
	end;

implementation

{ TSubGrupos }

function TSubGrupos.Clone: TSubGrupos;
begin
	Result        := TSubGrupos.Create();
	Result.Codigo := Self.Codigo;
	Result.G1     := Self.G1;
	Result.Tr     := Self.Tr;
	Result.Nome   := Self.Nome;
end;

end.
