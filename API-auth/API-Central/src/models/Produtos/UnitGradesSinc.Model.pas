unit UnitGradesSinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/gradesSinc')]
  [TNomeTabela('GRADES', 'GRA_CODIGO')]
  TGradesSinc = class(TTabela)
  private
    FCodigo: integer;
    FPro: integer;
    FValor: double;
    FTam: integer;
    FQuantidade: double;
    FCodbarra: string;
    FCor: string;
  public
    [TCampo('GRA_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('GRA_PRO', 'INTEGER')]
    property Pro: integer read FPro write FPro;

    [TCampo('GRA_VALOR', 'NUMERIC(9,2)')]
    property Valor: double read FValor write FValor;

    [TCampo('GRA_TAM', 'INTEGER')]
    property Tam: integer read FTam write FTam;

    [TCampo('GRA_QUANTIDADE', 'NUMERIC(9,2)')]
    property Quantidade: double read FQuantidade write FQuantidade;

    [TCampo('GRA_CODBARRA', 'VARCHAR(30)')]
    property Codbarra: string read FCodbarra write FCodbarra;

    [TCampo('GRA_COR', 'VARCHAR(30)')]
    property Cor: string read FCor write FCor;
  end;

implementation

end.
