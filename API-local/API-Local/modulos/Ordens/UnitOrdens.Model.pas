unit UnitOrdens.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model,
  {$ELSE}
  UnitBancoDeDados.Model,
  {$ENDIF}

  UnitOrdEst.Model,
  UnitClientes.Model,
  UnitFuncionarios.Model;

type
  [TRecursoServidor('/ordSer')]
  [TNomeTabela('ORD_SER', 'OS_CODIGO')]
  TOrdSer = class(TTabela)
  private
    FCodigo: integer;
    FOrd: integer;
    FSer: integer;
    FValor: double;
    FNome: string;
    FTipo: integer;
    FValorr: double;
  public
    [TCampo('OS_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('OS_ORD', 'INTEGER')]
    property Ord: integer read FOrd write FOrd;
    [TCampo('OS_SER', 'INTEGER')]
    property Ser: integer read FSer write FSer;
    [TCampo('OS_VALOR', 'NUMERIC(9,2)')]
    property Valor: double read FValor write FValor;
    [TCampo('OS_NOME', 'VARCHAR(50)')]
    property Nome: string read FNome write FNome;
    [TCampo('OS_TIPO', 'SMALLINT')]
    property Tipo: integer read FTipo write FTipo;
    [TCampo('OS_VALORR', 'NUMERIC(9,2)')]
    property Valorr: double read FValorr write FValorr;
  end;

  [TRecursoServidor('/ordens')]
  [TNomeTabela('ORDENS', 'ORD_CODIGO')]
  TOrdens = class(TTabela)
  private
    { private declarations }
    FCodigo: integer;
    FData: TDate;
    FValor: double;
    FHora: TTime;
    FCodFun: integer;
    FCodCli: integer;
    FDatac: TDate;
    FObs: string;
    FEstado: string;
    FDatapronto: TDate;
    FDataentrega: TDate;
    FVeiculo: string;
    FPlaca: string;
    FDesconto_p: double;
    FDesconto_s: double;
    FHorapronto: TTime;
    FHoraentrega: TTime;
    FFat: integer;
    FCli: TClientesVendas;
    FDevolucao_p: string;
    FUsado: double;
    FFun_faturou: integer;
    FItens: TArray<TTabela>;
    FFun: TFuncionariosVendas;
    FServicos: TArray<TTabela>;
  public
    { public declarations }
    [TCampo('ORD_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
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
    [TCampo('ORD_DATAC', 'DATE')]
    property Datac: TDate read FDatac write FDatac;
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
    [TCampo('ORD_DESCONTO_P', 'NUMERIC(3,2)')]
    property Desconto_p: double read FDesconto_p write FDesconto_p;
    [TCampo('ORD_DESCONTO_S', 'NUMERIC(3,2)')]
    property Desconto_s: double read FDesconto_s write FDesconto_s;
    [TCampo('ORD_HORAPRONTO', 'TIME')]
    property Horapronto: TTime read FHorapronto write FHorapronto;
    [TCampo('ORD_HORAENTREGA', 'TIME')]
    property Horaentrega: TTime read FHoraentrega write FHoraentrega;
    [TCampo('ORD_FAT', 'INTEGER')]
    property Fat: integer read FFat write FFat;
    [TCampo('ORD_DEVOLUCAO_P', 'VARCHAR(1)')]
    property Devolucao_p: string read FDevolucao_p write FDevolucao_p;
    [TCampo('ORD_USADO', 'NUMERIC(9,2)')]
    property Usado: double read FUsado write FUsado;
    [TCampo('ORD_FUN_FATUROU', 'SMALLINT')]
    property Fun_faturou: integer read FFun_faturou write FFun_faturou;
    [TRelacionamento('ORD_EST', 'ORE_CODIGO', 'ORE_ORD', TOrdEst, TTipoRelacionamento.UmPraMuitos)]
    property Itens: TArray<TTabela> read FItens write FItens;
    [TRelacionamento('CLIENTES', 'CLI_CODIGO', 'ORD_CLI', TClientesVendas, TTipoRelacionamento.UmPraUm)]
    property Cli: TClientesVendas read FCli write FCli;
    [TRelacionamento('FUNCIONARIOS', 'FUN_CODIGO', 'ORD_FUN', TFuncionariosVendas, TTipoRelacionamento.UmPraUm)]
    property Fun: TFuncionariosVendas read FFun write FFun;
    [TRelacionamento('ORD_SER', 'OS_CODIGO', 'OS_ORD', TOrdSer, TTipoRelacionamento.UmPraMuitos)]
    property Servicos: TArray<TTabela> read FServicos write FServicos;
  end;

implementation

end.
