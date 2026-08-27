unit UnitCidades.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/cidades')]
  [TNomeTabela('CIDADES', 'CID_CODIGO')]
  TCidades = class(TTabela)
  private
    FCodigo: Integer;
    FUF: string;
    FCodigoIbge: Integer;
    FEst: Integer;
    FNome: string;
  public
    [TCampo('CID_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: Integer read FCodigo write FCodigo;

    [TCampo('CID_UF', 'VARCHAR(2)')]
    property UF: string read FUF write FUF;

    [TCampo('CID_CODIGO_IBGE', 'INTEGER')]
    property CodigoIbge: Integer read FCodigoIbge write FCodigoIbge;

    [TCampo('CID_EST', 'INTEGER NOT NULL')]
    property Est: Integer read FEst write FEst;

    [TCampo('CID_NOME', 'VARCHAR(100)')]
    property Nome: string read FNome write FNome;
  end;

implementation

end.
