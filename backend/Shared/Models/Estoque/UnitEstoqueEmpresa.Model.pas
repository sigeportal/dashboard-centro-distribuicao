unit UnitEstoqueEmpresa.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/estoqueEmpresa')]
  [TNomeTabela('ESTOQUE_EMPRESA', 'EE_ID')]
  TEstoqueEmpresa = class(TTabela)
  private
    FId: Integer;
    FEmpresaId: Integer;
    FProCodigo: Integer;
    FQuantidade: double;
    FDataAtualizacao: TDateTime;
  public
    [TCampo('EE_ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('EE_EMPRESA_ID', 'INTEGER NOT NULL')]
    property EmpresaId: Integer read FEmpresaId write FEmpresaId;

    [TCampo('EE_PRO_CODIGO', 'INTEGER NOT NULL')]
    property ProCodigo: Integer read FProCodigo write FProCodigo;

    [TCampo('EE_QUANTIDADE', 'NUMERIC(12,4) NOT NULL')]
    property Quantidade: double read FQuantidade write FQuantidade;

    [TCampo('EE_DATA_ATUALIZACAO', 'TIMESTAMP')]
    property DataAtualizacao: TDateTime read FDataAtualizacao write FDataAtualizacao;
  end;

implementation

end.
