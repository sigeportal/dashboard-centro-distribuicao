unit UnitTamanhosSinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/tamanhosSinc')]
  [TNomeTabela('TAMANHOS', 'TAM_CODIGO')]
  TTamanhosSinc = class(TTabela)
  private
    FCodigo: integer;
    FPro: integer;
    FTamanho: string;
    FSigla: string;
    FValor: double;
  public
    [TCampo('TAM_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('TAM_PRO', 'INTEGER')]
    property Pro: integer read FPro write FPro;

    [TCampo('TAM_TAMANHO', 'VARCHAR(25)')]
    property Tamanho: string read FTamanho write FTamanho;

    [TCampo('TAM_SIGLA', 'VARCHAR(2)')]
    property Sigla: string read FSigla write FSigla;

    [TCampo('TAM_VALOR', 'NUMERIC(9,4)')]
    property Valor: double read FValor write FValor;
  end;

implementation

end.
