unit UnitVenEst.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/venEst')]
  [TNomeTabela('VEN_EST', 'VE_CODIGO')]
  TVenEst = class(TTabela)
  private
    { private declarations }
    FCodigo: integer;
    FValor: double;
    FQuantidade: double;
    FVen: integer;
    FPro: integer;
    FLucro: double;
    FValorr: double;
    FValorl: double;
    FValorf: double;
    FDiferenca: double;
    FLiquido: integer;
    FValor2: double;
    FValorcm: double;
    FGtin: string;
    FEmbalagem: string;
    FValorb: double;
    FDesconto: double;
    FValorc: double;
    FAliquota: double;
    FNome: string;
    FValor_partida: double;
    FVariacao: double;
    FSemente_tratada: string;
    FEstado: string;
    procedure SetPro(const Value: integer);
    function GetNome: string;
  public
    { public declarations }
    [TCampo('VE_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('VE_VALOR', 'NUMERIC(9,4)')]
    property Valor: double read FValor write FValor;
    [TCampo('VE_QUANTIDADE', 'NUMERIC(9,4)')]
    property Quantidade: double read FQuantidade write FQuantidade;
    [TCampo('VE_VEN', 'INTEGER')]
    property Ven: integer read FVen write FVen;
    [TCampo('VE_NOME', 'VARCHAR(200)')]
    property Nome: string read GetNome write FNome;
    [TCampo('VE_PRO', 'INTEGER')]
    property Pro: integer read FPro write SetPro;
    [TCampo('VE_LUCRO', 'NUMERIC(9,4)')]
    property Lucro: double read FLucro write FLucro;
    [TCampo('VE_VALORR', 'NUMERIC(9,4)')]
    property Valorr: double read FValorr write FValorr;
    [TCampo('VE_VALORL', 'NUMERIC(9,4)')]
    property Valorl: double read FValorl write FValorl;
    [TCampo('VE_VALORF', 'NUMERIC(9,4)')]
    property Valorf: double read FValorf write FValorf;
    [TCampo('VE_DIFERENCA', 'NUMERIC(9,4)')]
    property Diferenca: double read FDiferenca write FDiferenca;
    [TCampo('VE_LIQUIDO', 'SMALLINT')]
    property Liquido: integer read FLiquido write FLiquido;
    [TCampo('VE_VALOR2', 'NUMERIC(9,4)')]
    property Valor2: double read FValor2 write FValor2;
    [TCampo('VE_VALORCM', 'NUMERIC(9,4)')]
    property Valorcm: double read FValorcm write FValorcm;
    [TCampo('VE_GTIN', 'VARCHAR(14)')]
    property Gtin: string read FGtin write FGtin;
    [TCampo('VE_EMBALAGEM', 'VARCHAR(10)')]
    property Embalagem: string read FEmbalagem write FEmbalagem;
    [TCampo('VE_VALORB', 'NUMERIC(9,4)')]
    property Valorb: double read FValorb write FValorb;
    [TCampo('VE_DESCONTO', 'FLOAT')]
    property Desconto: double read FDesconto write FDesconto;
    [TCampo('VE_VALORC', 'NUMERIC(9,4)')]
    property Valorc: double read FValorc write FValorc;
    [TCampo('VE_ALIQUOTA', 'NUMERIC(5,2)')]
    property Aliquota: double read FAliquota write FAliquota;
    [TCampo('VE_VALOR_PARTIDA', 'NUMERIC(12,4)')]
    property Valor_partida: double read FValor_partida write FValor_partida;
    [TCampo('VE_VARIACAO', 'NUMERIC(12,4)')]
    property Variacao: double read FVariacao write FVariacao;
    [TCampo('VE_SEMENTE_TRATADA', 'CHAR(1)')]
    property Semente_tratada: string read FSemente_tratada write FSemente_tratada;
    [TCampo('VE_ESTADO', 'CHAR(1)')]
    property Estado: string read FEstado write FEstado;
  end;

implementation

uses
  System.Classes, System.SysUtils;

{ TVenEst }

function TVenEst.GetNome: string;
begin
  Result := FNome;
end;

procedure TVenEst.SetPro(const Value: integer);
begin
  FPro := Value;
  if Assigned(Self.IBQRBusca) then
  begin
    try
      Self.IBQRBusca.Close;
      Self.IBQRBusca.SQL.Clear;
      Self.IBQRBusca.SQL.Add('SELECT PRO_NOME FROM PRODUTOS WHERE PRO_CODIGO = ' + FPro.ToString);
      Self.IBQRBusca.Open();
      if not Self.IBQRBusca.IsEmpty then
        FNome := Self.IBQRBusca.FieldByName('PRO_NOME').AsString;
    finally
      Self.IBQRBusca.Close;
      if Assigned(Self.IBQRBusca.Transaction) and Self.IBQRBusca.Transaction.Active then
        Self.IBQRBusca.Transaction.Rollback;
    end;
  end;
end;

end.
