unit UnitSubGrupos.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/subgrupos')]
  [TNomeTabela('GRUPOS', 'GRU_CODIGO')]
  TSubGrupos = class(TTabela)
  private
    FCodigo: integer;
    FG1: smallint;
    FTr: smallint;
    FNome: string;
    FCadastrar: string;
    { private declarations }
  public
    { public declarations }
    [TCampo('GRU_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('GRU_NOME', 'VARCHAR(20)')]
    property Nome: string read FNome write FNome;
    [TCampo('GRU_G1', 'SMALLINT')]
    property G1: smallint read FG1 write FG1;
    [TCampo('GRU_TR', 'SMALLINT')]
    property Tr: smallint read FTr write FTr;
    [TCampo('GRU_CADASTRAR', 'CHAR(1) DEFAULT ''N''')]
    property Cadastrar: string read FCadastrar write FCadastrar;
  end;

implementation

end.
