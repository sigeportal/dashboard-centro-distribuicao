unit UnitClientesSinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/clientesSinc')]
  [TNomeTabela('CLIENTES', 'CLI_CODIGO')]
  TClientesSinc = class(TTabela)
  private
    FEmpId: integer;
    FCodigo: integer;
    FNome: string;
    FCelular: string;
    FEmail: string;
    FCidade: string;
    FUf: string;
    FCnpjCpf: string;
    FSituacao: string;
    FLimite: double;
    FBairro: string;
    FCep: string;
    FDatau: TDateTime;
  public
    [TCampo('CLI_EMP_ID', 'INTEGER NOT NULL')]
    property EmpId: integer read FEmpId write FEmpId;

    [TCampo('CLI_CODIGO', 'INTEGER NOT NULL')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('CLI_NOME', 'VARCHAR(100)')]
    property Nome: string read FNome write FNome;

    [TCampo('CLI_CELULAR', 'VARCHAR(20)')]
    property Celular: string read FCelular write FCelular;

    [TCampo('CLI_EMAIL', 'VARCHAR(100)')]
    property Email: string read FEmail write FEmail;

    [TCampo('CLI_CIDADE', 'VARCHAR(50)')]
    property Cidade: string read FCidade write FCidade;

    [TCampo('CLI_UF', 'VARCHAR(2)')]
    property Uf: string read FUf write FUf;

    [TCampo('CLI_CNPJ_CPF', 'VARCHAR(18)')]
    property CnpjCpf: string read FCnpjCpf write FCnpjCpf;

    [TCampo('CLI_SITUACAO', 'VARCHAR(15)')]
    property Situacao: string read FSituacao write FSituacao;

    [TCampo('CLI_LIMITE', 'NUMERIC(9,2)')]
    property Limite: double read FLimite write FLimite;

    [TCampo('CLI_BAIRRO', 'VARCHAR(30)')]
    property Bairro: string read FBairro write FBairro;

    [TCampo('CLI_CEP', 'VARCHAR(10)')]
    property Cep: string read FCep write FCep;

    [TCampo('CLI_DATAU', 'TIMESTAMP')]
    property Datau: TDateTime read FDatau write FDatau;
  end;

implementation

end.
