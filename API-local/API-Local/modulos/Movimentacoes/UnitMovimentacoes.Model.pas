unit UnitMovimentacoes.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/movimentacoes')]
  [TNomeTabela('MOVIMENTACOES', 'MOV_CODIGO')]
  TMovimentacoes = class(TTabela)
  private
    { private declarations }
    FCodigo: integer;
    FCredito: double;
    FDebito: double;
    FDescricao: string;
    FTipo: integer;
    FData: TDateTime;
    FSaldoant: double;
    FCon: integer;
    FDatahora: TDateTime;
    FOrdena: integer;
    FPlano: string;
    FNome: string;
    FCai: integer;
    FEstado: string;
    FTroco: double;
  public
    { public declarations }
    [TCampo('MOV_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('MOV_CREDITO', 'NUMERIC(9,2)')]
    property Credito: double read FCredito write FCredito;
    [TCampo('MOV_DEBITO', 'NUMERIC(9,2)')]
    property Debito: double read FDebito write FDebito;
    [TCampo('MOV_DESCRICAO', 'VARCHAR(80)')]
    property Descricao: string read FDescricao write FDescricao;
    [TCampo('MOV_TIPO', 'SMALLINT')]
    property Tipo: integer read FTipo write FTipo;
    [TCampo('MOV_DATA', 'DATE')]
    property Data: TDateTime read FData write FData;
    [TCampo('MOV_SALDOANT', 'NUMERIC(9,2)')]
    property Saldoant: double read FSaldoant write FSaldoant;
    [TCampo('MOV_CON', 'INTEGER')]
    property Con: integer read FCon write FCon;
    [TCampo('MOV_DATAHORA', 'TIMESTAMP')]
    property Datahora: TDateTime read FDatahora write FDatahora;
    [TCampo('MOV_ORDENA', 'INTEGER')]
    property Ordena: integer read FOrdena write FOrdena;
    [TCampo('MOV_PLANO', 'VARCHAR(15)')]
    property Plano: string read FPlano write FPlano;
    [TCampo('MOV_NOME', 'VARCHAR(30)')]
    property Nome: string read FNome write FNome;
    [TCampo('MOV_CAI', 'INTEGER')]
    property Cai: integer read FCai write FCai;
    [TCampo('MOV_ESTADO', 'VARCHAR(1)')]
    property Estado: string read FEstado write FEstado;
    [TCampo('MOV_TROCO', 'NUMERIC(9,2)')]
    property Troco: double read FTroco write FTroco;
  end;

implementation

end.
