unit UnitVendas.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model,
  {$ELSE}
  UnitBancoDeDados.Model,
  {$ENDIF}

  UnitVenEst.Model,
  UnitClientes.Model,
  UnitFuncionarios.Model;

type
  [TRecursoServidor('/vendas')]
  [TNomeTabela('VENDAS', 'VEN_CODIGO')]
  TVendas = class(TTabela)
  private
    { private declarations }
    FCodigo: integer;
    FData: TDate;
    FValor: double;
    FHora: TTime;
    FCodFun: integer;
    FNf: integer;
    FDiferenca: double;
    FDatac: TDate;
    FFat: integer;
    FDav: integer;
    FCli: TClientesVendas;
    FDevolucao_p: string;
    FVendedor: integer;
    FJuros_aplicados: double;
    FPdv: integer;
    FItens: TArray<TTabela>;
    FCodCli: integer;
    FFun: TFuncionariosVendas;
  public
    { public declarations }
    [TCampo('VEN_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('VEN_DATA', 'DATE')]
    property Data: TDate read FData write FData;
    [TCampo('VEN_VALOR', 'NUMERIC(9,2)')]
    property Valor: double read FValor write FValor;
    [TCampo('VEN_HORA', 'TIME')]
    property Hora: TTime read FHora write FHora;
    [TCampo('VEN_FUN', 'SMALLINT')]
    property CodFun: integer read FCodFun write FCodFun;
    [TCampo('VEN_NF', 'INTEGER')]
    property Nf: integer read FNf write FNf;
    [TCampo('VEN_DIFERENCA', 'NUMERIC(9,2)')]
    property Diferenca: double read FDiferenca write FDiferenca;
    [TCampo('VEN_DATAC', 'DATE')]
    property Datac: TDate read FDatac write FDatac;
    [TCampo('VEN_FAT', 'INTEGER')]
    property Fat: integer read FFat write FFat;
    [TCampo('VEN_DAV', 'SMALLINT')]
    property Dav: integer read FDav write FDav;
    [TCampo('VEN_DEVOLUCAO_P', 'VARCHAR(1)')]
    property Devolucao_p: string read FDevolucao_p write FDevolucao_p;
    [TCampo('VEN_VENDEDOR', 'SMALLINT')]
    property Vendedor: integer read FVendedor write FVendedor;
    [TCampo('VEN_JUROS_APLICADOS', 'NUMERIC(9,2)')]
    property Juros_aplicados: double read FJuros_aplicados write FJuros_aplicados;
    [TCampo('VEN_PDV', 'SMALLINT')]
    property Pdv: integer read FPdv write FPdv;
    [TRelacionamento('VEN_EST', 'VE_CODIGO', 'VE_VEN', TVenEst, TTipoRelacionamento.UmPraMuitos)]
    property Itens: TArray<TTabela> read FItens write FItens;
    [TRelacionamento('CLIENTES', 'CLI_CODIGO', 'VEN_CLI', TClientesVendas, TTipoRelacionamento.UmPraUm)]
    property Cli: TClientesVendas read FCli write FCli;
    [TCampo('VEN_CLI', 'INTEGER')]
    property CodCli: integer read FCodCli write FCodCli;
    [TRelacionamento('FUNCIONARIOS', 'FUN_CODIGO', 'VEN_FUN', TFuncionariosVendas, TTipoRelacionamento.UmPraUm)]
    property Fun: TFuncionariosVendas read FFun write FFun;
  end;

implementation

end.
