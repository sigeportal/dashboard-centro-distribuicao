unit UnitOrdEst.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/ordEst')]
  [TNomeTabela('ORD_EST', 'ORE_CODIGO')]
  TOrdEst = class(TTabela)
  private
    { private declarations }
    FCodigo: integer;
    FOrd: integer;
    FPro: integer;
    FQuantidade: double;
    FValor: double;
    FLucro: double;
    FValorr: double;
    FValorl: double;
    FValorf: double;
    FNome: string;
    FValorc: double;
    FValorcm: double;
    FAliqicms: string;
    FEmbalagem: string;
  public
    { public declarations }
    [TCampo('ORE_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('ORE_ORD', 'INTEGER')]
    property Ord: integer read FOrd write FOrd;
    [TCampo('ORE_PRO', 'INTEGER')]
    property Pro: integer read FPro write FPro;
    [TCampo('ORE_QUANTIDADE', 'NUMERIC(9,2)')]
    property Quantidade: double read FQuantidade write FQuantidade;
    [TCampo('ORE_VALOR', 'NUMERIC(9,2)')]
    property Valor: double read FValor write FValor;
    [TCampo('ORE_LUCRO', 'NUMERIC(9,2)')]
    property Lucro: double read FLucro write FLucro;
    [TCampo('ORE_VALORR', 'NUMERIC(9,2)')]
    property Valorr: double read FValorr write FValorr;
    [TCampo('ORE_VALORL', 'NUMERIC(9,2)')]
    property Valorl: double read FValorl write FValorl;
    [TCampo('ORE_VALORF', 'NUMERIC(9,2)')]
    property Valorf: double read FValorf write FValorf;
    [TCampo('ORE_NOME', 'VARCHAR(50)')]
    property Nome: string read FNome write FNome;
    [TCampo('ORE_VALORC', 'NUMERIC(9,2)')]
    property Valorc: double read FValorc write FValorc;
    [TCampo('ORE_VALORCM', 'NUMERIC(9,2)')]
    property Valorcm: double read FValorcm write FValorcm;
    [TCampo('ORE_ALIQICMS', 'VARCHAR(5)')]
    property Aliqicms: string read FAliqicms write FAliqicms;
    [TCampo('ORE_EMBALAGEM', 'VARCHAR(10)')]
    property Embalagem: string read FEmbalagem write FEmbalagem;
  end;

implementation

end.
