unit UnitCliente.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/cliente')]
  [TNomeTabela('CLIENTE', 'CLI_ID')]
  TCliente = class(TTabela)
  private
    { private declarations }
    FId: integer;
    FCpf: string;
    FSalt: string;
    FPasswordhash: string;
    FNome: string;
    FPlano: integer;
  public
    { public declarations }
    [TCampo('CLI_ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: integer read FId write FId;
    [TCampo('CLI_CPF', 'VARCHAR(14)')]
    property Cpf: string read FCpf write FCpf;
    [TCampo('CLI_SALT', 'VARCHAR(100)')]
    property Salt: string read FSalt write FSalt;
    [TCampo('CLI_PASSWORDHASH', 'VARCHAR(100)')]
    property Passwordhash: string read FPasswordhash write FPasswordhash;
    [TCampo('CLI_NOME', 'VARCHAR(100)')]
    property Nome: string read FNome write FNome;
    [TCampo('CLI_PLANO', 'INTEGER')]
    property Plano: integer read FPlano write FPlano;
  end;

implementation

end.
