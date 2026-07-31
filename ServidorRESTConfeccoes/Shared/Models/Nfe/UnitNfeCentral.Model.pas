unit UnitNfeCentral.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/nfe')]
  [TNomeTabela('NFE_CENTRAL', 'NFE_ID')]
  TNfeCentral = class(TTabela)
  private
    FId: Integer;
    FTransferenciaId: Integer;
    FChave: string;
    FNumero: Integer;
    FSerie: Integer;
    FProtocolo: string;
    FEmitenteCnpj: string;
    FDestinatarioCnpj: string;
    FValorTotal: Double;
    FStatus: string;
    FMotivoSefaz: string;
    FDataEmissao: TDateTime;
    FXml: string;
    FDanfePdf: string;
  public
    [TCampo('NFE_ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('NFE_TRANSFERENCIA_ID', 'INTEGER')]
    property TransferenciaId: Integer read FTransferenciaId write FTransferenciaId;

    [TCampo('NFE_CHAVE', 'VARCHAR(44)')]
    property Chave: string read FChave write FChave;

    [TCampo('NFE_NUMERO', 'INTEGER')]
    property Numero: Integer read FNumero write FNumero;

    [TCampo('NFE_SERIE', 'INTEGER')]
    property Serie: Integer read FSerie write FSerie;

    [TCampo('NFE_PROTOCOLO', 'VARCHAR(60)')]
    property Protocolo: string read FProtocolo write FProtocolo;

    [TCampo('NFE_EMITENTE_CNPJ', 'VARCHAR(14)')]
    property EmitenteCnpj: string read FEmitenteCnpj write FEmitenteCnpj;

    [TCampo('NFE_DESTINATARIO_CNPJ', 'VARCHAR(14)')]
    property DestinatarioCnpj: string read FDestinatarioCnpj write FDestinatarioCnpj;

    [TCampo('NFE_VALOR_TOTAL', 'NUMERIC(15,2)')]
    property ValorTotal: Double read FValorTotal write FValorTotal;

    [TCampo('NFE_STATUS', 'VARCHAR(20)')]
    property Status: string read FStatus write FStatus;

    [TCampo('NFE_MOTIVO_SEFAZ', 'VARCHAR(255)')]
    property MotivoSefaz: string read FMotivoSefaz write FMotivoSefaz;

    [TCampo('NFE_DATA_EMISSAO', 'TIMESTAMP')]
    property DataEmissao: TDateTime read FDataEmissao write FDataEmissao;

    [TCampo('NFE_XML', 'BLOB SUB_TYPE TEXT')]
    property Xml: string read FXml write FXml;

    [TCampo('NFE_PDF_DANFE', 'BLOB SUB_TYPE TEXT')]
    property DanfePdf: string read FDanfePdf write FDanfePdf;
  end;

implementation

end.
