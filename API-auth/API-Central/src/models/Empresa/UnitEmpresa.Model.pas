unit UnitEmpresa.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/empresa')]
  [TNomeTabela('EMPRESA', 'EMP_ID')]
  TEmpresa = class(TTabela)
  private
    { private declarations }
    FId: integer;
    FCnpj: string;
    FUrl: string;
    FNome: string;
    FClaimhash: string;
    FTipo: string;
    FMatrizId: integer;
  public
    { public declarations }
    [TCampo('EMP_ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: integer read FId write FId;
    [TCampo('EMP_CNPJ', 'VARCHAR(18)')]
    property Cnpj: string read FCnpj write FCnpj;
    [TCampo('EMP_URL', 'VARCHAR(100)')]
    property Url: string read FUrl write FUrl;
    [TCampo('EMP_NOME', 'VARCHAR(100)')]
    property Nome: string read FNome write FNome;
    [TCampo('EMP_CLAIMHASH', 'VARCHAR(100)')]
    property Claimhash: string read FClaimhash write FClaimhash;
    [TCampo('EMP_TIPO', 'VARCHAR(10)')]
    property Tipo: string read FTipo write FTipo;
    [TCampo('EMP_MATRIZ_ID', 'INTEGER')]
    property MatrizId: integer read FMatrizId write FMatrizId;
  end;

implementation

end.
