unit UnitClientes.Model;

interface

uses
  System.SysUtils,
  System.Classes,
  UnitTabela.Model,
  UnitTabela.Atributos;

type
  [TNomeTabela('CLIENTES', 'CLI_CODIGO')]
  TClientes = class(TTabela)
  private
    FCLI_CODIGO: Integer;
    FCLI_NOME: string;
    FCLI_CELULAR: string;
    FCLI_FONE: string;
    FCLI_EMAIL: string;
    FCLI_CIDADE: string;
    FCLI_UF: string;
    FCLI_ENDERECO: string;
    FCLI_BAIRRO: string;
    FCLI_CEP: string;
    FCLI_CNPJ_CPF: string;
    FCLI_RG: string;
    FCLI_LIMITE: Double;
    FCLI_CADASTRAR: string;
  public
    [TCampo('CLI_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: Integer read FCLI_CODIGO write FCLI_CODIGO;

    [TCampo('CLI_NOME', 'VARCHAR(100)')]
    property Nome: string read FCLI_NOME write FCLI_NOME;

    [TCampo('CLI_CELULAR', 'VARCHAR(20)')]
    property Celular: string read FCLI_CELULAR write FCLI_CELULAR;

    [TCampo('CLI_FONE', 'VARCHAR(20)')]
    property Telefone: string read FCLI_FONE write FCLI_FONE;

    [TCampo('CLI_EMAIL', 'VARCHAR(100)')]
    property Email: string read FCLI_EMAIL write FCLI_EMAIL;

    [TCampo('CLI_CIDADE', 'VARCHAR(60)')]
    property Cidade: string read FCLI_CIDADE write FCLI_CIDADE;

    [TCampo('CLI_UF', 'VARCHAR(2)')]
    property Uf: string read FCLI_UF write FCLI_UF;

    [TCampo('CLI_ENDERECO', 'VARCHAR(100)')]
    property Endereco: string read FCLI_ENDERECO write FCLI_ENDERECO;

    [TCampo('CLI_BAIRRO', 'VARCHAR(50)')]
    property Bairro: string read FCLI_BAIRRO write FCLI_BAIRRO;

    [TCampo('CLI_CEP', 'VARCHAR(10)')]
    property Cep: string read FCLI_CEP write FCLI_CEP;

    [TCampo('CLI_CNPJ_CPF', 'VARCHAR(20)')]
    property CnpjCpf: string read FCLI_CNPJ_CPF write FCLI_CNPJ_CPF;

    [TCampo('CLI_RG', 'VARCHAR(20)')]
    property Rg: string read FCLI_RG write FCLI_RG;

    [TCampo('CLI_LIMITE', 'DOUBLE PRECISION')]
    property Limite: Double read FCLI_LIMITE write FCLI_LIMITE;

    [TCampo('CLI_CADASTRAR', 'CHAR(1) DEFAULT ''N''')]
    property Cadastrar: string read FCLI_CADASTRAR write FCLI_CADASTRAR;
  end;

implementation

end.
