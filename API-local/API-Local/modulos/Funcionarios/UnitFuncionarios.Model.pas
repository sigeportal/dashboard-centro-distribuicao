unit UnitFuncionarios.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/funcionarios')]
  [TNomeTabela('FUNCIONARIOS', 'FUN_CODIGO')]
  TFuncionarios = class(TTabela)
  private
    { private declarations }
    FCodigo: integer;
    FNome: string;
    FCpf: string;
    FEndereco: string;
    FBairro: string;
    FFone: string;
    FEmail: string;
    FSalario: double;
    FComissao: double;
    FAdmissao: TDate;
    FDemissao: TDate;
    FEstado: string;
    FDatapgm: string;
    FRg: string;
    FCelular: string;
    FN_filhos_d: integer;
    FTipo: string;
    FCategoria: string;
    FFunc: integer;
  public
    { public declarations }
    [TCampo('FUN_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('FUN_NOME', 'VARCHAR(50)')]
    property Nome: string read FNome write FNome;
    [TCampo('FUN_CPF', 'VARCHAR(18)')]
    property Cpf: string read FCpf write FCpf;
    [TCampo('FUN_ENDERECO', 'VARCHAR(50)')]
    property Endereco: string read FEndereco write FEndereco;
    [TCampo('FUN_BAIRRO', 'VARCHAR(30)')]
    property Bairro: string read FBairro write FBairro;
    [TCampo('FUN_FONE', 'VARCHAR(13)')]
    property Fone: string read FFone write FFone;
    [TCampo('FUN_EMAIL', 'VARCHAR(30)')]
    property Email: string read FEmail write FEmail;
    [TCampo('FUN_SALARIO', 'NUMERIC(9,2)')]
    property Salario: double read FSalario write FSalario;
    [TCampo('FUN_COMISSAO', 'NUMERIC(9,2)')]
    property Comissao: double read FComissao write FComissao;
    [TCampo('FUN_ADMISSAO', 'DATE')]
    property Admissao: TDate read FAdmissao write FAdmissao;
    [TCampo('FUN_DEMISSAO', 'DATE')]
    property Demissao: TDate read FDemissao write FDemissao;
    [TCampo('FUN_ESTADO', 'VARCHAR(10)')]
    property Estado: string read FEstado write FEstado;
    [TCampo('FUN_DATAPGM', 'VARCHAR(3)')]
    property Datapgm: string read FDatapgm write FDatapgm;
    [TCampo('FUN_RG', 'VARCHAR(18)')]
    property Rg: string read FRg write FRg;
    [TCampo('FUN_CELULAR', 'VARCHAR(14)')]
    property Celular: string read FCelular write FCelular;
    [TCampo('FUN_N_FILHOS_D', 'SMALLINT')]
    property N_filhos_d: integer read FN_filhos_d write FN_filhos_d;
    [TCampo('FUN_TIPO', 'VARCHAR(1)')]
    property Tipo: string read FTipo write FTipo;
    [TCampo('FUN_CATEGORIA', 'VARCHAR(20)')]
    property Categoria: string read FCategoria write FCategoria;
    [TCampo('FUN_FUNC', 'INTEGER')]
    property Func: integer read FFunc write FFunc;
  end;

  [TNomeTabela('FUNCIONARIOS', 'FUN_CODIGO')]
  TFuncionariosVendas = class(TTabela)
  private
    { private declarations }
    FCodigo: integer;
    FNome: string;
    FCpf: string;
    FEmail: string;
    FRg: string;
    FCelular: string;
  public
    { public declarations }
    [TCampo('FUN_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('FUN_NOME', 'VARCHAR(50)')]
    property Nome: string read FNome write FNome;
    [TCampo('FUN_CPF', 'VARCHAR(18)')]
    property Cpf: string read FCpf write FCpf;
    [TCampo('FUN_EMAIL', 'VARCHAR(30)')]
    property Email: string read FEmail write FEmail;
    [TCampo('FUN_RG', 'VARCHAR(18)')]
    property Rg: string read FRg write FRg;
    [TCampo('FUN_CELULAR', 'VARCHAR(14)')]
    property Celular: string read FCelular write FCelular;
  end;

implementation

end.
