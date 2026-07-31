unit UnitCompras.Model;

interface

uses
  System.SysUtils,
  UnitPortalORM.Model;

type
  [TRecursoServidor('/compras')]
  [TNomeTabela('COMPRAS', 'ID')]
  TCompras = class(TTabela)
  private
    FID: Integer;
    FFornecedorId: Integer;
    FFornecedorNome: string;
    FNumeroNF: string;
    FChaveNFe: string;
    FDataEmissao: TDateTime;
    FDataEntrada: TDateTime;
    FValorTotal: Double;
    FValorFrete: Double;
    FValorOutros: Double;
    FObservacao: string;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property ID: Integer read FID write FID;

    [TCampo('FORNECEDOR_ID', 'INTEGER')]
    property FornecedorId: Integer read FFornecedorId write FFornecedorId;

    [TCampo('FORNECEDOR_NOME', 'VARCHAR(100)')]
    property FornecedorNome: string read FFornecedorNome write FFornecedorNome;

    [TCampo('NUMERO_NF', 'VARCHAR(30)')]
    property NumeroNF: string read FNumeroNF write FNumeroNF;

    [TCampo('CHAVE_NFE', 'VARCHAR(50)')]
    property ChaveNFe: string read FChaveNFe write FChaveNFe;

    [TCampo('DATA_EMISSAO', 'DATE')]
    property DataEmissao: TDateTime read FDataEmissao write FDataEmissao;

    [TCampo('DATA_ENTRADA', 'DATE')]
    property DataEntrada: TDateTime read FDataEntrada write FDataEntrada;

    [TCampo('VALOR_TOTAL', 'NUMERIC(15,2)')]
    property ValorTotal: Double read FValorTotal write FValorTotal;

    [TCampo('VALOR_FRETE', 'NUMERIC(15,2)')]
    property ValorFrete: Double read FValorFrete write FValorFrete;

    [TCampo('VALOR_OUTROS', 'NUMERIC(15,2)')]
    property ValorOutros: Double read FValorOutros write FValorOutros;

    [TCampo('OBSERVACAO', 'VARCHAR(250)')]
    property Observacao: string read FObservacao write FObservacao;
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
