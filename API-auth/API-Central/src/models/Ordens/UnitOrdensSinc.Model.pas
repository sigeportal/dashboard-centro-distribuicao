unit UnitOrdensSinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/ordensSinc')]
  [TNomeTabela('ORDENS', 'ORD_CODIGO')]
  TOrdensSinc = class(TTabela)
  private
    FEmpId: integer;
    FCodigo: integer;
    FData: TDate;
    FValor: double;
    FHora: TTime;
    FCodFun: integer;
    FCodCli: integer;
    FObs: string;
    FEstado: string;
    FDatapronto: TDate;
    FDataentrega: TDate;
    FVeiculo: string;
    FPlaca: string;
  public
    [TCampo('ORD_EMP_ID', 'INTEGER NOT NULL')]
    property EmpId: integer read FEmpId write FEmpId;

    [TCampo('ORD_CODIGO', 'INTEGER NOT NULL')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('ORD_DATA', 'DATE')]
    property Data: TDate read FData write FData;

    [TCampo('ORD_VALOR', 'NUMERIC(9,2)')]
    property Valor: double read FValor write FValor;

    [TCampo('ORD_HORA', 'TIME')]
    property Hora: TTime read FHora write FHora;

    [TCampo('ORD_FUN', 'SMALLINT')]
    property CodFun: integer read FCodFun write FCodFun;

    [TCampo('ORD_CLI', 'INTEGER')]
    property CodCli: integer read FCodCli write FCodCli;

    [TCampo('ORD_OBS', 'VARCHAR(300)')]
    property Obs: string read FObs write FObs;

    [TCampo('ORD_ESTADO', 'VARCHAR(15)')]
    property Estado: string read FEstado write FEstado;

    [TCampo('ORD_DATAPRONTO', 'DATE')]
    property Datapronto: TDate read FDatapronto write FDatapronto;

    [TCampo('ORD_DATAENTREGA', 'DATE')]
    property Dataentrega: TDate read FDataentrega write FDataentrega;

    [TCampo('ORD_VEICULO', 'VARCHAR(30)')]
    property Veiculo: string read FVeiculo write FVeiculo;

    [TCampo('ORD_PLACA', 'VARCHAR(10)')]
    property Placa: string read FPlaca write FPlaca;
  end;

implementation

end.
