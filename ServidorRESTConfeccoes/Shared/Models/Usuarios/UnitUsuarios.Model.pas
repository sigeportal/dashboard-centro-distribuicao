unit UnitUsuarios.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TNomeTabela('USUARIOS', 'USU_CODIGO')]
  TUsuarios = class(TTabela)
  private
    FCodigo: integer;
    FLogin: string;
    FFun: integer;
    FSenha: string;
    { private declarations }
  public
    { public declarations }
    [TCampo('USU_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('USU_LOGIN', 'VARCHAR(100)')]
    property Login: string read FLogin write FLogin;
    [TCampo('USU_FUN', 'INTEGER')]
    property Fun: integer read FFun write FFun;
    [TCampo('USU_SENHA', 'VARCHAR(30)')]
    property Senha: string read FSenha write FSenha;
  end;

implementation

end.
