unit UnitTransferencia.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/transferencias')]
  [TNomeTabela('TRANSFERENCIA', 'TR_ID')]
  TTransferencia = class(TTabela)
  private
    FId: Integer;
    FOrigem: Integer;
    FDestino: Integer;
    FData: TDateTime;
    FStatus: string;
    FObs: string;
    FUsuarioRecebimento: string;
    FDataRecebimento: TDateTime;
  public
    [TCampo('TR_ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('TR_ORIGEM', 'INTEGER NOT NULL')]
    property Origem: Integer read FOrigem write FOrigem;

    [TCampo('TR_DESTINO', 'INTEGER NOT NULL')]
    property Destino: Integer read FDestino write FDestino;

    [TCampo('TR_DATA', 'DATE NOT NULL')]
    property Data: TDateTime read FData write FData;

    [TCampo('TR_STATUS', 'VARCHAR(20) NOT NULL')]
    property Status: string read FStatus write FStatus;

    [TCampo('TR_OBS', 'VARCHAR(250)')]
    property Obs: string read FObs write FObs;

    [TCampo('TR_USUARIO_RECEBIMENTO', 'VARCHAR(100)')]
    property UsuarioRecebimento: string read FUsuarioRecebimento write FUsuarioRecebimento;

    [TCampo('TR_DATA_RECEBIMENTO', 'DATE')]
    property DataRecebimento: TDateTime read FDataRecebimento write FDataRecebimento;
  end;

implementation

end.
