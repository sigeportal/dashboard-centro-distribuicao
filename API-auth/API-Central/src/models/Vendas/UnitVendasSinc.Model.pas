unit UnitVendasSinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/vendasSinc')]
  [TNomeTabela('VENDAS', 'VEN_CODIGO')]
  TVendasSinc = class(TTabela)
  private
    FEmpId: integer;
    FCodigo: integer;
    FData: TDate;
    FValor: double;
    FHora: TTime;
    FCodFun: integer;
    FCodCli: integer;
    FVendedor: integer;
    FNf: integer;
    FDatac: TDate;
  public
    [TCampo('VEN_EMP_ID', 'INTEGER NOT NULL')]
    property EmpId: integer read FEmpId write FEmpId;

    [TCampo('VEN_CODIGO', 'INTEGER NOT NULL')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('VEN_DATA', 'DATE')]
    property Data: TDate read FData write FData;

    [TCampo('VEN_VALOR', 'NUMERIC(9,2)')]
    property Valor: double read FValor write FValor;

    [TCampo('VEN_HORA', 'TIME')]
    property Hora: TTime read FHora write FHora;

    [TCampo('VEN_FUN', 'SMALLINT')]
    property CodFun: integer read FCodFun write FCodFun;

    [TCampo('VEN_CLI', 'INTEGER')]
    property CodCli: integer read FCodCli write FCodCli;

    [TCampo('VEN_VENDEDOR', 'SMALLINT')]
    property Vendedor: integer read FVendedor write FVendedor;

    [TCampo('VEN_NF', 'INTEGER')]
    property Nf: integer read FNf write FNf;

    [TCampo('VEN_DATAC', 'DATE')]
    property Datac: TDate read FDatac write FDatac;
  end;

implementation

end.
