unit UnitModelos.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/modelos')]
  [TNomeTabela('MODELOS', 'MOD_CODIGO')]
  TModelos = class(TTabela)
  private
    FCodigo: Integer;
    FNome: string;
    FGrupo: Integer;
    FSubGrupo: Integer;
    FCadastrar: string;
  public
    [TCampo('MOD_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: Integer read FCodigo write FCodigo;

    [TCampo('MOD_NOME', 'VARCHAR(80) NOT NULL')]
    property Nome: string read FNome write FNome;

    [TCampo('MOD_GRUPO', 'INTEGER')]
    property Grupo: Integer read FGrupo write FGrupo;

    [TCampo('MOD_SUBGRUPO', 'INTEGER')]
    property SubGrupo: Integer read FSubGrupo write FSubGrupo;

    [TCampo('MOD_CADASTRAR', 'CHAR(1) DEFAULT ''N''')]
    property Cadastrar: string read FCadastrar write FCadastrar;
  end;

implementation

end.
