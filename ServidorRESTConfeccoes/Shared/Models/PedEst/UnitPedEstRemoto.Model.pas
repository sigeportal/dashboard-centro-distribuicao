unit UnitPedEstRemoto.Model;

interface

uses
  UnitPortalORM.Model, UnitGrades.Model;

type
	[TRecursoServidor('/ped_est')]
  [TNomeTabela('PED_EST_REMOTO', 'PE_CODIGO')]
  TPedEstRemoto = class(TTabela)
  private
    FCodigo: integer;
    FNome: string;
    FQuantidade: Double;
    FValorC: Currency;
    FCodPed: integer;
    FCodPro: integer;
    FDataCriacao: TDateTime;
    FCodBarras: string;
    FCadastrar: string;
    FPrecoVista: Currency;
    FPrecoPrazo: Currency;
    FCodGrade: integer;
    FGrade: TGrades;
    { private declarations }
  public
    { public declarations }
    [TCampo('PE_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('PE_PED', 'INTEGER NOT NULL REFERENCES PEDIDOS_REMOTO(PED_CODIGO)')]
    property CodPed: integer read FCodPed write FCodPed;
    [TCampo('PE_NOME', 'VARCHAR(200)')]
    property Nome: string read FNome write FNome;
    [TCampo('PE_QUANTIDADE', 'NUMERIC(9,2)')]
    property Quantidade: Double read FQuantidade write FQuantidade;
    [TCampo('PE_VALORC', 'NUMERIC(12,4)')]
    property ValorC: Currency read FValorC write FValorC;
    [TCampo('PE_PRO', 'INTEGER')]
    property CodPro: integer read FCodPro write FCodPro;
    [TCampo('PE_COD_BARRAS', 'VARCHAR(30)')]
    property CodBarras: string read FCodBarras write FCodBarras;
    [TCampo('PE_DATA_CRIACAO', 'DATE')]
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
    [TCampo('PE_CADASTRAR', 'CHAR(1)')]
    property Cadastrar: string read FCadastrar write FCadastrar;
    [TCampo('PE_PRECO_VISTA', 'NUMERIC(12,4)')]
    property PrecoVista: Currency read FPrecoVista write FPrecoVista;
    [TCampo('PE_PRECO_PRAZO', 'NUMERIC(12,4)')]
    property PrecoPrazo: Currency read FPrecoPrazo write FPrecoPrazo;
    [TCampo('PE_COD_GRADE', 'INTEGER')]
    property CodGrade: integer read FCodGrade write FCodGrade;
    [TRelacionamento('GRADES', 'GRA_CODIGO', 'PE_COD_GRADE', TGrades, TTipoRelacionamento.UmPraUm)]
    property Grade: TGrades read FGrade write FGrade;
  end;

implementation

end.
