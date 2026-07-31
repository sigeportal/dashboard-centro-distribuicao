unit UnitDashboardSync.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TNomeTabela('DASHBOARD_DIARIO', 'ID')]
  TDashboardDiario = class(TTabela)
  private
    FId: Integer;
    FEmpresaId: Integer;
    FDataRef: TDateTime;
    FVendasValor: Double;
    FVendasLucro: Double;
    FVendasMaior: Double;
    FVendasQtd: Integer;
    FOsValor: Double;
    FOsLucro: Double;
    FOsMaior: Double;
    FOsQtd: Integer;
    FMovCredito: Double;
    FMovDebito: Double;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('EMPRESA_ID', 'INTEGER NOT NULL')]
    property EmpresaId: Integer read FEmpresaId write FEmpresaId;

    [TCampo('DATA_REF', 'DATE NOT NULL')]
    property DataRef: TDateTime read FDataRef write FDataRef;

    [TCampo('VENDAS_VALOR', 'DOUBLE PRECISION')]
    property VendasValor: Double read FVendasValor write FVendasValor;

    [TCampo('VENDAS_LUCRO', 'DOUBLE PRECISION')]
    property VendasLucro: Double read FVendasLucro write FVendasLucro;

    [TCampo('VENDAS_MAIOR', 'DOUBLE PRECISION')]
    property VendasMaior: Double read FVendasMaior write FVendasMaior;

    [TCampo('VENDAS_QTD', 'INTEGER')]
    property VendasQtd: Integer read FVendasQtd write FVendasQtd;

    [TCampo('OS_VALOR', 'DOUBLE PRECISION')]
    property OsValor: Double read FOsValor write FOsValor;

    [TCampo('OS_LUCRO', 'DOUBLE PRECISION')]
    property OsLucro: Double read FOsLucro write FOsLucro;

    [TCampo('OS_MAIOR', 'DOUBLE PRECISION')]
    property OsMaior: Double read FOsMaior write FOsMaior;

    [TCampo('OS_QTD', 'INTEGER')]
    property OsQtd: Integer read FOsQtd write FOsQtd;

    [TCampo('MOV_CREDITO', 'DOUBLE PRECISION')]
    property MovCredito: Double read FMovCredito write FMovCredito;

    [TCampo('MOV_DEBITO', 'DOUBLE PRECISION')]
    property MovDebito: Double read FMovDebito write FMovDebito;
  end;

  [TNomeTabela('DASHBOARD_PAGAMENTOS', 'ID')]
  TDashboardPagamento = class(TTabela)
  private
    FId: Integer;
    FEmpresaId: Integer;
    FTipoRegistro: string;
    FTipoOperacao: string;
    FTipoPagamento: string;
    FValor: Double;
    FDataRef: TDateTime;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('EMPRESA_ID', 'INTEGER NOT NULL')]
    property EmpresaId: Integer read FEmpresaId write FEmpresaId;

    [TCampo('TIPO_REGISTRO', 'VARCHAR(30) NOT NULL')]
    property TipoRegistro: string read FTipoRegistro write FTipoRegistro;

    [TCampo('TIPO_OPERACAO', 'VARCHAR(50)')]
    property TipoOperacao: string read FTipoOperacao write FTipoOperacao;

    [TCampo('TIPO_PAGAMENTO', 'VARCHAR(100) NOT NULL')]
    property TipoPagamento: string read FTipoPagamento write FTipoPagamento;

    [TCampo('VALOR', 'DOUBLE PRECISION NOT NULL')]
    property Valor: Double read FValor write FValor;

    [TCampo('DATA_REF', 'DATE')]
    property DataRef: TDateTime read FDataRef write FDataRef;
  end;

  [TNomeTabela('DASHBOARD_VENDAS_GRUPO', 'ID')]
  TDashboardVendasGrupo = class(TTabela)
  private
    FId: Integer;
    FEmpresaId: Integer;
    FNomeGrupo: string;
    FValor: Double;
    FLucro: Double;
    FDataRef: TDateTime;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('EMPRESA_ID', 'INTEGER NOT NULL')]
    property EmpresaId: Integer read FEmpresaId write FEmpresaId;

    [TCampo('NOME_GRUPO', 'VARCHAR(100) NOT NULL')]
    property NomeGrupo: string read FNomeGrupo write FNomeGrupo;

    [TCampo('VALOR', 'DOUBLE PRECISION NOT NULL')]
    property Valor: Double read FValor write FValor;

    [TCampo('LUCRO', 'DOUBLE PRECISION')]
    property Lucro: Double read FLucro write FLucro;

    [TCampo('DATA_REF', 'DATE')]
    property DataRef: TDateTime read FDataRef write FDataRef;
  end;

  [TNomeTabela('DASHBOARD_CLIENTES_CIDADE', 'ID')]
  TDashboardClientesCidade = class(TTabela)
  private
    FId: Integer;
    FEmpresaId: Integer;
    FCidade: string;
    FQuantidade: Integer;
    FDataRef: TDateTime;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('EMPRESA_ID', 'INTEGER NOT NULL')]
    property EmpresaId: Integer read FEmpresaId write FEmpresaId;

    [TCampo('CIDADE', 'VARCHAR(100) NOT NULL')]
    property Cidade: string read FCidade write FCidade;

    [TCampo('QUANTIDADE', 'INTEGER NOT NULL')]
    property Quantidade: Integer read FQuantidade write FQuantidade;

    [TCampo('DATA_REF', 'DATE')]
    property DataRef: TDateTime read FDataRef write FDataRef;
  end;

  [TNomeTabela('DASHBOARD_VENDAS_HORA', 'ID')]
  TDashboardVendasHora = class(TTabela)
  private
    FId: Integer;
    FEmpresaId: Integer;
    FHora: string;
    FValor: Double;
    FDataRef: TDateTime;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;

    [TCampo('EMPRESA_ID', 'INTEGER NOT NULL')]
    property EmpresaId: Integer read FEmpresaId write FEmpresaId;

    [TCampo('HORA', 'VARCHAR(10) NOT NULL')]
    property Hora: string read FHora write FHora;

    [TCampo('VALOR', 'DOUBLE PRECISION NOT NULL')]
    property Valor: Double read FValor write FValor;

    [TCampo('DATA_REF', 'DATE')]
    property DataRef: TDateTime read FDataRef write FDataRef;
  end;

implementation

end.
