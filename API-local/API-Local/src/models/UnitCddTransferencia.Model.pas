unit UnitCddTransferencia.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TNomeTabela('CDD_TRANSFERENCIAS', 'ID')]
  TCddTransferencia = class(TTabela)
  private
    FId: Integer;
    FCodigo: string;
    FStatus: string;
    FDataCriacao: string;
    FDataXml: string;
    FDataRecebimento: string;
    FDataCancelamento: string;
    FConteudoXml: string;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('CODIGO', 'VARCHAR(40) NOT NULL')]
    property Codigo: string read FCodigo write FCodigo;

    [TCampo('STATUS', 'VARCHAR(30) NOT NULL')]
    property Status: string read FStatus write FStatus;

    [TCampo('DATA_CRIACAO', 'VARCHAR(30)')]
    property DataCriacao: string read FDataCriacao write FDataCriacao;

    [TCampo('DATA_XML', 'VARCHAR(30)')]
    property DataXml: string read FDataXml write FDataXml;

    [TCampo('DATA_RECEBIMENTO', 'VARCHAR(30)')]
    property DataRecebimento: string read FDataRecebimento write FDataRecebimento;

    [TCampo('DATA_CANCELAMENTO', 'VARCHAR(30)')]
    property DataCancelamento: string read FDataCancelamento write FDataCancelamento;

    [TCampo('CONTEUDO_XML', 'BLOB SUB_TYPE TEXT')]
    property ConteudoXml: string read FConteudoXml write FConteudoXml;
  end;

  [TNomeTabela('CDD_TRANSFERENCIAS_ITENS', 'ID')]
  TCddTransferenciaItem = class(TTabela)
  private
    FId: Integer;
    FTransferenciaId: Integer;
    FProCodigo: Integer;
    FQuantidade: Double;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('TRANSFERENCIA_ID', 'INTEGER NOT NULL')]
    property TransferenciaId: Integer read FTransferenciaId write FTransferenciaId;

    [TCampo('PRO_CODIGO', 'INTEGER NOT NULL')]
    property ProCodigo: Integer read FProCodigo write FProCodigo;

    [TCampo('QUANTIDADE', 'NUMERIC(15,4) NOT NULL')]
    property Quantidade: Double read FQuantidade write FQuantidade;
  end;

implementation

end.
