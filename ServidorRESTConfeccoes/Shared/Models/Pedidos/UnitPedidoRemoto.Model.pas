unit UnitPedidoRemoto.Model;

interface

uses
  UnitPortalORM.Model, 
  UnitPedEstRemoto.Model;


type
	[TRecursoServidor('/pedidos')]
  [TNomeTabela('PEDIDOS_REMOTO', 'PED_CODIGO')]
  TPedidoRemoto = class(TTabela)
  private
    FCodigo: integer;
    FData: TDateTime;
    FNome: string;
    FCodCliFor: integer;
    FValor: Currency;
    FItens: TArray<TTabela>;
    FEstado: string;
    FDataCancelamento: TDateTime;
    { private declarations }
  public
    { public declarations }
    [TCampo('PED_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('PED_DATA', 'DATE')]
    property Data: TDateTime read FData write FData;
    [TCampo('PED_NOME', 'VARCHAR(200)')]
    property Nome: string read FNome write FNome;
    [TCampo('PED_CLI_FOR', 'INTEGER')]
    property CodCliFor: integer read FCodCliFor write FCodCliFor;
    [TCampo('PED_VALOR', 'NUMERIC(12,4)')]
    property Valor: Currency read FValor write FValor;
    [TCampo('PED_ESTADO', 'VARCHAR(10)')]
    property Estado: string read FEstado write FEstado;
    [TCampo('PED_DATAC', 'DATE')]
    property DataCancelamento: TDateTime read FDataCancelamento write FDataCancelamento;
    [TRelacionamento('PED_EST', 'PE_CODIGO', 'PE_PED', TPedEstRemoto, TTipoRelacionamento.UmPraMuitos)]
    property Itens: TArray<TTabela> read FItens write FItens;    
  end;

  [TRecursoServidor('/pedidos')]
  [TNomeTabela('PEDIDOS_REMOTO', 'PED_CODIGO')]
  TPedidoRemotoResponse = class(TTabela)
  private
    FCodigo: integer;
    FData: TDateTime;
    FNome: string;
    FCodCliFor: integer;
    FValor: Currency;
    FItens: TArray<TPedEstRemoto>;
    FEstado: string;
    FDataCancelamento: TDateTime;
    { private declarations }
  public
    { public declarations }
    [TCampo('PED_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('PED_DATA', 'DATE')]
    property Data: TDateTime read FData write FData;
    [TCampo('PED_NOME', 'VARCHAR(200)')]
    property Nome: string read FNome write FNome;
    [TCampo('PED_CLI_FOR', 'INTEGER')]
    property CodCliFor: integer read FCodCliFor write FCodCliFor;
    [TCampo('PED_VALOR', 'NUMERIC(12,4)')]
    property Valor: Currency read FValor write FValor;
    [TCampo('PED_ESTADO', 'VARCHAR(10)')]
    property Estado: string read FEstado write FEstado;
    [TCampo('PED_DATAC', 'DATE')]
    property DataCancelamento: TDateTime read FDataCancelamento write FDataCancelamento;
    [TRelacionamento('PED_EST', 'PE_CODIGO', 'PE_PED', TPedEstRemoto, TTipoRelacionamento.UmPraMuitos)]
    property Itens: TArray<TPedEstRemoto> read FItens write FItens;    
  end;

implementation

end.
