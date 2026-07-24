unit UnitTransferenciaItem.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/transferenciaItens')]
  [TNomeTabela('TRANSFERENCIA_ITEM', 'TRI_ID')]
  TTransferenciaItem = class(TTabela)
  private
    FId: Integer;
    FTransferenciaId: Integer;
    FProdutoId: Integer;
    FQuantidade: double;
    FValor: double;
    FQuantidadeConferida: double;
  public
    [TCampo('TRI_ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('TRI_TRANSFERENCIA_ID', 'INTEGER NOT NULL')]
    property TransferenciaId: Integer read FTransferenciaId write FTransferenciaId;

    [TCampo('TRI_PRODUTO_ID', 'INTEGER NOT NULL')]
    property ProdutoId: Integer read FProdutoId write FProdutoId;

    [TCampo('TRI_QUANTIDADE', 'NUMERIC(9,2) NOT NULL')]
    property Quantidade: double read FQuantidade write FQuantidade;

    [TCampo('TRI_VALOR', 'NUMERIC(9,4) NOT NULL')]
    property Valor: double read FValor write FValor;

    [TCampo('TRI_QTD_CONFERIDA', 'NUMERIC(9,2)')]
    property QuantidadeConferida: double read FQuantidadeConferida write FQuantidadeConferida;
  end;

implementation

end.
