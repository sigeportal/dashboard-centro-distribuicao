unit UnitCompras.Model;

interface

uses
  System.SysUtils,
  UnitPortalORM.Model;

type
  [TRecursoServidor('/compras')]
  [TNomeTabela('COMPRAS', 'COM_CODIGO')]
  TCompras = class(TTabela)
  private
    FComCodigo: Integer;
    FComFor: Integer;
    FComNf: string;
    FComData: TDateTime;
    FComValor: Double;
    FComFrete: Double;
    FComOutros: Double;
    FComIpi: Double;
    FComIcms: Double;
    FComFat2: Integer;
    FComObs: string;
    FComTipo: string;
  public
    [TCampo('COM_CODIGO', 'NUMERIC(8,0) NOT NULL PRIMARY KEY')]
    property comCodigo: Integer read FComCodigo write FComCodigo;

    [TCampo('COM_FOR', 'NUMERIC(4,0)')]
    property comFor: Integer read FComFor write FComFor;

    [TCampo('COM_NF', 'VARCHAR(30)')]
    property comNf: string read FComNf write FComNf;

    [TCampo('COM_DATA', 'DATE')]
    property comData: TDateTime read FComData write FComData;

    [TCampo('COM_VALOR', 'NUMERIC(15,2)')]
    property comValor: Double read FComValor write FComValor;

    [TCampo('COM_FRETE', 'NUMERIC(15,2)')]
    property comFrete: Double read FComFrete write FComFrete;

    [TCampo('COM_OUTROS', 'NUMERIC(15,2)')]
    property comOutros: Double read FComOutros write FComOutros;

    [TCampo('COM_IPI', 'NUMERIC(15,2)')]
    property comIpi: Double read FComIpi write FComIpi;

    [TCampo('COM_ICMS', 'NUMERIC(15,2)')]
    property comIcms: Double read FComIcms write FComIcms;

    [TCampo('COM_FAT2', 'INTEGER')]
    property comFat2: Integer read FComFat2 write FComFat2;

    [TCampo('COM_OBS', 'VARCHAR(250)')]
    property comObs: string read FComObs write FComObs;

    [TCampo('COM_TIPO', 'VARCHAR(5)')]
    property comTipo: string read FComTipo write FComTipo;
  end;

  [TRecursoServidor('/comprasItens')]
  [TNomeTabela('COMPRAS_ITENS', 'ID')]
  TComprasItens = class(TTabela)
  private
    FID: Integer;
    FCompraId: Integer;
    FProdutoCodigo: Integer;
    FProdutoNome: string;
    FQuantidade: Double;
    FValorUnitario: Double;
    FValorFrete: Double;
    FValorIpi: Double;
    FValorSt: Double;
    FValorOutros: Double;
    FCustoMercadoria: Double;
    FCustoMedio: Double;
    FCustoOperacional: Double;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property ID: Integer read FID write FID;

    [TCampo('COMPRA_ID', 'INTEGER NOT NULL')]
    property CompraId: Integer read FCompraId write FCompraId;

    [TCampo('PRODUTO_CODIGO', 'INTEGER NOT NULL')]
    property ProdutoCodigo: Integer read FProdutoCodigo write FProdutoCodigo;

    [TCampo('PRODUTO_NOME', 'VARCHAR(100)')]
    property ProdutoNome: string read FProdutoNome write FProdutoNome;

    [TCampo('QUANTIDADE', 'NUMERIC(15,4) NOT NULL')]
    property Quantidade: Double read FQuantidade write FQuantidade;

    [TCampo('VALOR_UNITARIO', 'NUMERIC(15,4) NOT NULL')]
    property ValorUnitario: Double read FValorUnitario write FValorUnitario;

    [TCampo('VALOR_FRETE', 'NUMERIC(15,4)')]
    property ValorFrete: Double read FValorFrete write FValorFrete;

    [TCampo('VALOR_IPI', 'NUMERIC(15,4)')]
    property ValorIpi: Double read FValorIpi write FValorIpi;

    [TCampo('VALOR_ST', 'NUMERIC(15,4)')]
    property ValorSt: Double read FValorSt write FValorSt;

    [TCampo('VALOR_OUTROS', 'NUMERIC(15,4)')]
    property ValorOutros: Double read FValorOutros write FValorOutros;

    [TCampo('CUSTO_MERCADORIA', 'NUMERIC(15,4)')]
    property CustoMercadoria: Double read FCustoMercadoria write FCustoMercadoria;

    [TCampo('CUSTO_MEDIO', 'NUMERIC(15,4)')]
    property CustoMedio: Double read FCustoMedio write FCustoMedio;

    [TCampo('CUSTO_OPERACIONAL', 'NUMERIC(15,4)')]
    property CustoOperacional: Double read FCustoOperacional write FCustoOperacional;
  end;

implementation

end.
