unit UnitGrupo1Sinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/grupo1Sinc')]
  [TNomeTabela('GRUPO_1', 'G1_CODIGO')]
  TGrupo1Sinc = class(TTabela)
  private
    FCodigo: integer;
    FNome: string;
  public
    [TCampo('G1_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('G1_NOME', 'VARCHAR(30)')]
    property Nome: string read FNome write FNome;
  end;

implementation

end.
