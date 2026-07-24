unit UnitTransferenciaItem.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/transferenciaItens')]
  [TNomeTabela('TRANSFERENCIA_ITEM', 'TRI_ID')]
  TTransferenciaItem = class(TTabela)
  private
    FId: integer;
    FTrId: integer;
    FProCodigo: integer;
    FQuantidade: double;
    FValor: double;
  public
    [TCampo('TRI_ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: integer read FId write FId;

    [TCampo('TRI_TR_ID', 'INTEGER NOT NULL')]
    property TrId: integer read FTrId write FTrId;

    [TCampo('TRI_PRO_CODIGO', 'INTEGER NOT NULL')]
    property ProCodigo: integer read FProCodigo write FProCodigo;

    [TCampo('TRI_QUANTIDADE', 'NUMERIC(9,2) NOT NULL')]
    property Quantidade: double read FQuantidade write FQuantidade;

    [TCampo('TRI_VALOR', 'NUMERIC(9,4) NOT NULL')]
    property Valor: double read FValor write FValor;
  end;

implementation

end.
