unit UnitEstados.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/estados')]
  [TNomeTabela('ESTADOS', 'EST_CODIGO')]
  TEstados = class(TTabela)
  private
    FCodigo: Integer;
    FSigla: string;
    FNome: string;
    FCodigoIbge: Integer;
  public
    [TCampo('EST_CODIGO', 'SMALLINT NOT NULL PRIMARY KEY')]
    property Codigo: Integer read FCodigo write FCodigo;

    [TCampo('EST_SIGLA', 'CHAR(2)')]
    property Sigla: string read FSigla write FSigla;

    [TCampo('EST_NOME', 'VARCHAR(100)')]
    property Nome: string read FNome write FNome;

    [TCampo('EST_CODIGO_IBGE', 'INTEGER')]
    property CodigoIbge: Integer read FCodigoIbge write FCodigoIbge;
  end;

implementation

end.
