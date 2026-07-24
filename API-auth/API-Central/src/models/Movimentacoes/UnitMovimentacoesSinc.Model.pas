unit UnitMovimentacoesSinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/movimentacoesSinc')]
  [TNomeTabela('MOVIMENTACOES', 'MOV_CODIGO')]
  TMovimentacoesSinc = class(TTabela)
  private
    FEmpId: integer;
    FCodigo: integer;
    FDescricao: string;
    FNome: string;
    FData: TDate;
    FDebito: double;
    FCredito: double;
    FTipo: integer;
    FDatahora: TDateTime;
  public
    [TCampo('MOV_EMP_ID', 'INTEGER NOT NULL')]
    property EmpId: integer read FEmpId write FEmpId;

    [TCampo('MOV_CODIGO', 'INTEGER NOT NULL')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('MOV_DESCRICAO', 'VARCHAR(100)')]
    property Descricao: string read FDescricao write FDescricao;

    [TCampo('MOV_NOME', 'VARCHAR(50)')]
    property Nome: string read FNome write FNome;

    [TCampo('MOV_DATA', 'DATE')]
    property Data: TDate read FData write FData;

    [TCampo('MOV_DEBITO', 'NUMERIC(9,2)')]
    property Debito: double read FDebito write FDebito;

    [TCampo('MOV_CREDITO', 'NUMERIC(9,2)')]
    property Credito: double read FCredito write FCredito;

    [TCampo('MOV_TIPO', 'SMALLINT')]
    property Tipo: integer read FTipo write FTipo;

    [TCampo('MOV_DATAHORA', 'TIMESTAMP')]
    property Datahora: TDateTime read FDatahora write FDatahora;
  end;

implementation

end.
