unit UnitClienteEmpresa.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/clienteEmpresa')]
  [TNomeTabela('CLIENTE_EMPRESA', 'CE_ID')]
  TClienteEmpresa = class(TTabela)
  private
    { private declarations }
    FId: integer;
    FCli_id: integer;
    FEmp_id: integer;
  public
    { public declarations }
    [TCampo('CE_ID', 'INTEGER NOT NULL PRIMARY KEY')]
    property Id: integer read FId write FId;
    [TCampo('CE_CLI_ID', 'INTEGER')]
    property Cli_id: integer read FCli_id write FCli_id;
    [TCampo('CE_EMP_ID', 'INTEGER')]
    property Emp_id: integer read FEmp_id write FEmp_id;
  end;

implementation

end.
