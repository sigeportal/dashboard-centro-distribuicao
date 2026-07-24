unit UnitGruposSinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/gruposSinc')]
  [TNomeTabela('GRUPOS', 'GRU_CODIGO')]
  TGruposSinc = class(TTabela)
  private
    FCodigo: integer;
    FNome: string;
    FG1: integer;
  public
    [TCampo('GRU_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('GRU_NOME', 'VARCHAR(20)')]
    property Nome: string read FNome write FNome;

    [TCampo('GRU_G1', 'INTEGER')]
    property G1: integer read FG1 write FG1;
  end;

implementation

end.
