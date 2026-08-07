unit UnitGrupos.Model;

interface

uses
  UnitPortalORM.Model,
  UnitSubGrupos.Model,
  System.Generics.Collections;

type
	[TRecursoServidor('/grupos')]
  [TNomeTabela('GRUPO_1', 'G1_CODIGO')]
  TGrupos = class(TTabela)
  private
    FCodigo: integer;
    FNome: string;
    FCadastrar: string;
    { private declarations }
  public
    { public declarations }
    [TCampo('G1_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('G1_NOME', 'VARCHAR(30)')]
    property Nome: string read FNome write FNome;
    [TCampo('G1_CADASTRAR', 'CHAR(1) DEFAULT ''N''')]
    property Cadastrar: string read FCadastrar write FCadastrar;
  end;

implementation

end.
