unit UnitUnidadeMedida.Model;

interface

uses
  UnitPortalORM.Model;

type
  [TRecursoServidor('/unidade_medida')]
	[TNomeTabela('UNIDADE_MED', 'UM_CODIGO')]
  TUnidadeMedida = class(TTabela)
  private
    FCodigo: integer;
    FDescricao: string;
    FUnidade: string;
    { private declarations }
  public
    { public declarations }
    [TCampo('UM_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
		property Codigo: integer read FCodigo write FCodigo;
		[TCampo('UM_UNIDADE', 'VARCHAR(3)')]
		property Unidade: string read FUnidade write FUnidade;
    [TCampo('UM_DESCRICAO', 'VARCHAR(20)')]
		property Descricao: string read FDescricao write FDescricao;
  end;

implementation

end.
