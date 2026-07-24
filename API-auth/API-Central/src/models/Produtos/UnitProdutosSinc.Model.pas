unit UnitProdutosSinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/produtosSinc')]
  [TNomeTabela('PRODUTOS', 'PRO_CODIGO')]
  TProdutosSinc = class(TTabela)
  private
    FEmpId: integer;
    FCodigo: integer;
    FNome: string;
    FDescricao: string;
    FFabricante: string;
    FCodbarra: string;
    FQuantidade: double;
    FValorv: double;
    FValorc: double;
    FGru: integer;
    FEstado: string;
    FGtin: string;
    FDataua: TDate;
  public
    [TCampo('PRO_EMP_ID', 'INTEGER NOT NULL')]
    property EmpId: integer read FEmpId write FEmpId;

    [TCampo('PRO_CODIGO', 'INTEGER NOT NULL')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('PRO_NOME', 'VARCHAR(200)')]
    property Nome: string read FNome write FNome;

    [TCampo('PRO_DESCRICAO', 'VARCHAR(100)')]
    property Descricao: string read FDescricao write FDescricao;

    [TCampo('PRO_FABRICANTE', 'VARCHAR(50)')]
    property Fabricante: string read FFabricante write FFabricante;

    [TCampo('PRO_CODBARRA', 'VARCHAR(30)')]
    property Codbarra: string read FCodbarra write FCodbarra;

    [TCampo('PRO_QUANTIDADE', 'NUMERIC(9,2)')]
    property Quantidade: double read FQuantidade write FQuantidade;

    [TCampo('PRO_VALORV', 'NUMERIC(9,4)')]
    property Valorv: double read FValorv write FValorv;

    [TCampo('PRO_VALORC', 'NUMERIC(9,4)')]
    property Valorc: double read FValorc write FValorc;

    [TCampo('PRO_GRU', 'INTEGER')]
    property Gru: integer read FGru write FGru;

    [TCampo('PRO_ESTADO', 'VARCHAR(8)')]
    property Estado: string read FEstado write FEstado;

    [TCampo('PRO_GTIN', 'VARCHAR(14)')]
    property Gtin: string read FGtin write FGtin;

    [TCampo('PRO_DATAUA', 'DATE')]
    property Dataua: TDate read FDataua write FDataua;
  end;

implementation

end.
