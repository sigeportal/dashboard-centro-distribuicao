unit UnitTransferencia.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/transferencias')]
  [TNomeTabela('TRANSFERENCIA', 'TR_ID')]
  TTransferencia = class(TTabela)
  private
    FId: integer;
    FMatrizId: integer;
    FFilialId: integer;
    FData: TDate;
    FStatus: string;
    FObs: string;
  public
    [TCampo('TR_ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: integer read FId write FId;

    [TCampo('TR_MATRIZ_ID', 'INTEGER NOT NULL')]
    property MatrizId: integer read FMatrizId write FMatrizId;

    [TCampo('TR_FILIAL_ID', 'INTEGER NOT NULL')]
    property FilialId: integer read FFilialId write FFilialId;

    [TCampo('TR_DATA', 'DATE NOT NULL')]
    property Data: TDate read FData write FData;

    [TCampo('TR_STATUS', 'VARCHAR(15) NOT NULL')]
    property Status: string read FStatus write FStatus;

    [TCampo('TR_OBS', 'VARCHAR(250)')]
    property Obs: string read FObs write FObs;
  end;

implementation

end.
