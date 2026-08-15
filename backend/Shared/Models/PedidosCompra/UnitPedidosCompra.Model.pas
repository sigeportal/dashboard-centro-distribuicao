unit UnitPedidosCompra.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/pedidos-compra')]
  [TNomeTabela('PEDIDOS_COMPRA', 'ID')]
  TPedidosCompra = class(TTabela)
  private
    FId: Integer;
    FNumeroOrdem: string;
    FFornecedorId: Integer;
    FFornecedorNome: string;
    FMarca: string;
    FRepresentante: string;
    FContatoRepresentante: string;
    FEmpresaNome: string;
    FEmpresaCnpj: string;
    FLocalPedido: string;
    FLocalEntrega: string;
    FDataPedido: TDate;
    FDataEntrega: string;
    FPrazoPagamento: string;
    FDescontoPerc: Double;
    FDescontoValor: Double;
    FImpostoIcms: Double;
    FTotalPecas: Double;
    FValorTotal: Double;
    FStatus: string;
    FObservacao: string;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;
    [TCampo('NUMERO_ORDEM', 'VARCHAR(50)')]
    property NumeroOrdem: string read FNumeroOrdem write FNumeroOrdem;
    [TCampo('FORNECEDOR_ID', 'INTEGER')]
    property FornecedorId: Integer read FFornecedorId write FFornecedorId;
    [TCampo('FORNECEDOR_NOME', 'VARCHAR(200)')]
    property FornecedorNome: string read FFornecedorNome write FFornecedorNome;
    [TCampo('MARCA', 'VARCHAR(100)')]
    property Marca: string read FMarca write FMarca;
    [TCampo('REPRESENTANTE', 'VARCHAR(100)')]
    property Representante: string read FRepresentante write FRepresentante;
    [TCampo('CONTATO_REPRESENTANTE', 'VARCHAR(50)')]
    property ContatoRepresentante: string read FContatoRepresentante write FContatoRepresentante;
    [TCampo('EMPRESA_NOME', 'VARCHAR(200)')]
    property EmpresaNome: string read FEmpresaNome write FEmpresaNome;
    [TCampo('EMPRESA_CNPJ', 'VARCHAR(30)')]
    property EmpresaCnpj: string read FEmpresaCnpj write FEmpresaCnpj;
    [TCampo('LOCAL_PEDIDO', 'VARCHAR(100)')]
    property LocalPedido: string read FLocalPedido write FLocalPedido;
    [TCampo('LOCAL_ENTREGA', 'VARCHAR(100)')]
    property LocalEntrega: string read FLocalEntrega write FLocalEntrega;
    [TCampo('DATA_PEDIDO', 'DATE')]
    property DataPedido: TDate read FDataPedido write FDataPedido;
    [TCampo('DATA_ENTREGA', 'VARCHAR(50)')]
    property DataEntrega: string read FDataEntrega write FDataEntrega;
    [TCampo('PRAZO_PAGAMENTO', 'VARCHAR(100)')]
    property PrazoPagamento: string read FPrazoPagamento write FPrazoPagamento;
    [TCampo('DESCONTO_PERC', 'NUMERIC(9,2)')]
    property DescontoPerc: Double read FDescontoPerc write FDescontoPerc;
    [TCampo('DESCONTO_VALOR', 'NUMERIC(15,2)')]
    property DescontoValor: Double read FDescontoValor write FDescontoValor;
    [TCampo('IMPOSTO_ICMS', 'NUMERIC(15,2)')]
    property ImpostoIcms: Double read FImpostoIcms write FImpostoIcms;
    [TCampo('TOTAL_PECAS', 'NUMERIC(12,2)')]
    property TotalPecas: Double read FTotalPecas write FTotalPecas;
    [TCampo('VALOR_TOTAL', 'NUMERIC(15,2)')]
    property ValorTotal: Double read FValorTotal write FValorTotal;
    [TCampo('STATUS', 'VARCHAR(30) DEFAULT ''RASCUNHO''')]
    property Status: string read FStatus write FStatus;
    [TCampo('OBSERVACAO', 'VARCHAR(1000)')]
    property Observacao: string read FObservacao write FObservacao;
  end;

  [TNomeTabela('PEDIDOS_COMPRA_ITENS', 'ID')]
  TPedidosCompraItens = class(TTabela)
  private
    FId: Integer;
    FPedidoId: Integer;
    FProdutoCodigo: Integer;
    FProdutoNome: string;
    FCor: string;
    FReferencia: string;
    FValorUnitario: Double;
    FValorImposto: Double;
    FValorDinheiro: Double;
    FValorVista: Double;
    FValorPrazo: Double;
    FGradeTamanhos: string;
    FTotalPecas: Double;
    FValorTotal: Double;
  public
    [TCampo('ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: Integer read FId write FId;
    [TCampo('PEDIDO_ID', 'INTEGER')]
    property PedidoId: Integer read FPedidoId write FPedidoId;
    [TCampo('PRODUTO_CODIGO', 'INTEGER')]
    property ProdutoCodigo: Integer read FProdutoCodigo write FProdutoCodigo;
    [TCampo('PRODUTO_NOME', 'VARCHAR(200)')]
    property ProdutoNome: string read FProdutoNome write FProdutoNome;
    [TCampo('COR', 'VARCHAR(50)')]
    property Cor: string read FCor write FCor;
    [TCampo('REFERENCIA', 'VARCHAR(50)')]
    property Referencia: string read FReferencia write FReferencia;
    [TCampo('VALOR_UNITARIO', 'NUMERIC(15,2)')]
    property ValorUnitario: Double read FValorUnitario write FValorUnitario;
    [TCampo('VALOR_IMPOSTO', 'NUMERIC(15,2)')]
    property ValorImposto: Double read FValorImposto write FValorImposto;
    [TCampo('VALOR_DINHEIRO', 'NUMERIC(15,2)')]
    property ValorDinheiro: Double read FValorDinheiro write FValorDinheiro;
    [TCampo('VALOR_VISTA', 'NUMERIC(15,2)')]
    property ValorVista: Double read FValorVista write FValorVista;
    [TCampo('VALOR_PRAZO', 'NUMERIC(15,2)')]
    property ValorPrazo: Double read FValorPrazo write FValorPrazo;
    [TCampo('GRADE_TAMANHOS', 'VARCHAR(1000)')]
    property GradeTamanhos: string read FGradeTamanhos write FGradeTamanhos;
    [TCampo('TOTAL_PECAS', 'NUMERIC(9,2)')]
    property TotalPecas: Double read FTotalPecas write FTotalPecas;
    [TCampo('VALOR_TOTAL', 'NUMERIC(15,2)')]
    property ValorTotal: Double read FValorTotal write FValorTotal;
  end;

implementation

end.
