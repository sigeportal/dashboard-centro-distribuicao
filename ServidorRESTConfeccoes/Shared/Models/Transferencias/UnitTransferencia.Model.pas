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
    FTipoFiscal: string;
    FNumeroNf: string;
    FChaveNfe: string;
    FCadastrar: string;
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

    [TCampo('TR_TIPO_FISCAL', 'VARCHAR(15)')]
    property TipoFiscal: string read FTipoFiscal write FTipoFiscal;

    [TCampo('TR_NUMERO_NF', 'VARCHAR(20)')]
    property NumeroNf: string read FNumeroNf write FNumeroNf;

    [TCampo('TR_CHAVE_NFE', 'VARCHAR(44)')]
    property ChaveNfe: string read FChaveNfe write FChaveNfe;

    [TCampo('TR_CADASTRAR', 'CHAR(1) DEFAULT ''N''')]
    property Cadastrar: string read FCadastrar write FCadastrar;
  end;

implementation

end.
