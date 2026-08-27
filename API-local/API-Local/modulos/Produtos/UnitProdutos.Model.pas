unit UnitProdutos.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/produtos')]
  [TNomeTabela('PRODUTOS', 'PRO_CODIGO')]
  TProdutos = class(TTabela)
  private
    { private declarations }
    FCodigo: integer;
    FEst: integer;
    FCodFor: integer;
    FFabricante: string;
    FQuantidadem: integer;
    FQuantidade: double;
    FValorv: double;
    FValorcm: double;
    FValorc: double;
    FValorl: double;
    FValorf: double;
    FQuantidadef: double;
    FLocal: string;
    FEmbalagem: string;
    FDatauc: TDate;
    FGru: integer;
    FDescricao: string;
    FDataua: TDate;
    FAbc: string;
    FCodbarra: string;
    FValors: double;
    FTipo: integer;
    FTotalizador: integer;
    FNome: string;
    FEstado: string;
    FGtin: string;
    FIat: string;
    FIppt: string;
    FAliqicms_opint: integer;
    FPerc_red_opint: double;
    FUm: integer;
    FGenero: integer;
    FNcm: string;
    FCfop: string;
    FExcecao_ncm: integer;
    FTipo_item: string;
    FBalanca: string;
    FDias_validade: integer;
    FValorv_prazo: double;
    FLote: string;
    FCest: string;
    FEstoque: string;
    FFcp: string;
    FTexto_semente_tratada: string;
    FCst: string;
    FCadastrar: string;
    FCodFiscal: integer;
    FFiscalGerar: string;
    FModelo: integer;
    FCor: string;
    FMarca: string;
    FColecao: string;
    FReferencia: string;
    FGrupo1: integer;
    FValorDinheiro: double;
    FURL_Imagem: string;
    FEmp: integer;
  public
    { public declarations }
    [TCampo('PRO_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('PRO_EST', 'INTEGER')]
    property Est: integer read FEst write FEst;
    [TCampo('PRO_FOR', 'SMALLINT')]
    property CodFor: integer read FCodFor write FCodFor;
    [TCampo('PRO_FABRICANTE', 'VARCHAR(20)')]
    property Fabricante: string read FFabricante write FFabricante;
    [TCampo('PRO_QUANTIDADEM', 'SMALLINT')]
    property Quantidadem: integer read FQuantidadem write FQuantidadem;
    [TCampo('PRO_QUANTIDADE', 'NUMERIC(9,2)')]
    property Quantidade: double read FQuantidade write FQuantidade;
    [TCampo('PRO_VALORV', 'NUMERIC(9,4)')]
    property Valorv: double read FValorv write FValorv;
    [TCampo('PRO_VALORCM', 'NUMERIC(9,4)')]
    property Valorcm: double read FValorcm write FValorcm;
    [TCampo('PRO_VALORC', 'NUMERIC(9,4)')]
    property Valorc: double read FValorc write FValorc;
    [TCampo('PRO_VALORL', 'NUMERIC(9,4)')]
    property Valorl: double read FValorl write FValorl;
    [TCampo('PRO_VALORF', 'NUMERIC(9,4)')]
    property Valorf: double read FValorf write FValorf;
    [TCampo('PRO_QUANTIDADEF', 'NUMERIC(9,2)')]
    property Quantidadef: double read FQuantidadef write FQuantidadef;
    [TCampo('PRO_LOCAL', 'VARCHAR(20)')]
    property Local: string read FLocal write FLocal;
    [TCampo('PRO_EMBALAGEM', 'VARCHAR(10)')]
    property Embalagem: string read FEmbalagem write FEmbalagem;
    [TCampo('PRO_DATAUC', 'DATE')]
    property Datauc: TDate read FDatauc write FDatauc;
    [TCampo('PRO_GRU', 'SMALLINT')]
    property Gru: integer read FGru write FGru;
    [TCampo('PRO_DESCRICAO', 'VARCHAR(30)')]
    property Descricao: string read FDescricao write FDescricao;
    [TCampo('PRO_DATAUA', 'DATE')]
    property Dataua: TDate read FDataua write FDataua;
    [TCampo('PRO_ABC', 'VARCHAR(2)')]
    property Abc: string read FAbc write FAbc;
    [TCampo('PRO_CODBARRA', 'VARCHAR(30)')]
    property Codbarra: string read FCodbarra write FCodbarra;
    [TCampo('PRO_VALORS', 'NUMERIC(9,2)')]
    property Valors: double read FValors write FValors;
    [TCampo('PRO_TIPO', 'SMALLINT')]
    property Tipo: integer read FTipo write FTipo;
    [TCampo('PRO_TOTALIZADOR', 'SMALLINT')]
    property Totalizador: integer read FTotalizador write FTotalizador;
    [TCampo('PRO_NOME', 'VARCHAR(200)')]
    property Nome: string read FNome write FNome;
    [TCampo('PRO_ESTADO', 'VARCHAR(8)')]
    property Estado: string read FEstado write FEstado;
    [TCampo('PRO_GTIN', 'VARCHAR(14)')]
    property Gtin: string read FGtin write FGtin;
    [TCampo('PRO_IAT', 'VARCHAR(1)')]
    property Iat: string read FIat write FIat;
    [TCampo('PRO_IPPT', 'VARCHAR(1)')]
    property Ippt: string read FIppt write FIppt;
    [TCampo('PRO_ALIQICMS_OPINT', 'SMALLINT')]
    property Aliqicms_opint: integer read FAliqicms_opint write FAliqicms_opint;
    [TCampo('PRO_PERC_RED_OPINT', 'NUMERIC(9,4)')]
    property Perc_red_opint: double read FPerc_red_opint write FPerc_red_opint;
    [TCampo('PRO_UM', 'SMALLINT')]
    property Um: integer read FUm write FUm;
    [TCampo('PRO_GENERO', 'INTEGER')]
    property Genero: integer read FGenero write FGenero;
    [TCampo('PRO_NCM', 'VARCHAR(10)')]
    property Ncm: string read FNcm write FNcm;
    [TCampo('PRO_CFOP', 'VARCHAR(5)')]
    property Cfop: string read FCfop write FCfop;
    [TCampo('PRO_EXCECAO_NCM', 'SMALLINT')]
    property Excecao_ncm: integer read FExcecao_ncm write FExcecao_ncm;
    [TCampo('PRO_TIPO_ITEM', 'VARCHAR(2)')]
    property Tipo_item: string read FTipo_item write FTipo_item;
    [TCampo('PRO_BALANCA', 'CHAR(1)')]
    property Balanca: string read FBalanca write FBalanca;
    [TCampo('PRO_DIAS_VALIDADE', 'SMALLINT')]
    property Dias_validade: integer read FDias_validade write FDias_validade;
    [TCampo('PRO_VALORV_PRAZO', 'NUMERIC(12,4)')]
    property Valorv_prazo: double read FValorv_prazo write FValorv_prazo;
    [TCampo('PRO_LOTE', 'CHAR(1)')]
    property Lote: string read FLote write FLote;
    [TCampo('PRO_CEST', 'VARCHAR(10)')]
    property Cest: string read FCest write FCest;
    [TCampo('PRO_ESTOQUE', 'CHAR(1)')]
    property Estoque: string read FEstoque write FEstoque;
    [TCampo('PRO_FCP', 'CHAR(1)')]
    property Fcp: string read FFcp write FFcp;
    [TCampo('PRO_TEXTO_SEMENTE_TRATADA', 'VARCHAR(200)')]
    property Texto_semente_tratada: string read FTexto_semente_tratada write FTexto_semente_tratada;
    [TCampo('PRO_CST', 'VARCHAR(3)')]
    property Cst: string read FCst write FCst;
    [TCampo('PRO_CADASTRAR', 'CHAR(1) DEFAULT ''N''')]
    property Cadastrar: string read FCadastrar write FCadastrar;
    [TCampo('PRO_COD_FISCAL', 'INTEGER')]
    property CodFiscal: integer read FCodFiscal write FCodFiscal;
    [TCampo('PRO_FISCAL_GERAR', 'CHAR(1) DEFAULT ''S''')]
    property FiscalGerar: string read FFiscalGerar write FFiscalGerar;
    [TCampo('PRO_MODELO', 'INTEGER')]
    property Modelo: integer read FModelo write FModelo;
    [TCampo('PRO_COR', 'VARCHAR(30)')]
    property Cor: string read FCor write FCor;
    [TCampo('PRO_MARCA', 'VARCHAR(30)')]
    property Marca: string read FMarca write FMarca;
    [TCampo('PRO_COLECAO', 'VARCHAR(30)')]
    property Colecao: string read FColecao write FColecao;
    [TCampo('PRO_REFERENCIA', 'VARCHAR(30)')]
    property Referencia: string read FReferencia write FReferencia;
    [TCampo('PRO_GRUPO1', 'SMALLINT')]
    property Grupo1: integer read FGrupo1 write FGrupo1;
    [TCampo('PRO_VALOR_DINHEIRO', 'NUMERIC(12,4)')]
    property ValorDinheiro: double read FValorDinheiro write FValorDinheiro;
    [TCampo('PRO_URL_IMAGEM', 'VARCHAR(1000)')]
    property URL_Imagem: string read FURL_Imagem write FURL_Imagem;
    [TCampo('PRO_EMP', 'NUMERIC(4,0)')]
    property Emp: integer read FEmp write FEmp;
  end;

implementation

end.

