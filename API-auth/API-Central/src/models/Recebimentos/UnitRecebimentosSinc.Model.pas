unit UnitRecebimentosSinc.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/recebimentosSinc')]
  [TNomeTabela('RECEBIMENTOS', 'REC_CODIGO')]
  TRecebimentosSinc = class(TTabela)
  private
    FEmpId: integer;
    FCodigo: integer;
    FValor: double;
    FDuplicata: string;
    FObs: string;
    FVencimento: TDate;
    FDatar: TDate;
    FSituacao: integer;
  public
    [TCampo('REC_EMP_ID', 'INTEGER NOT NULL')]
    property EmpId: integer read FEmpId write FEmpId;

    [TCampo('REC_CODIGO', 'INTEGER NOT NULL')]
    property Codigo: integer read FCodigo write FCodigo;

    [TCampo('REC_VALOR', 'NUMERIC(9,2)')]
    property Valor: double read FValor write FValor;

    [TCampo('REC_DUPLICATA', 'VARCHAR(30)')]
    property Duplicata: string read FDuplicata write FDuplicata;

    [TCampo('REC_OBS', 'VARCHAR(100)')]
    property Obs: string read FObs write FObs;

    [TCampo('REC_VENCIMENTO', 'DATE')]
    property Vencimento: TDate read FVencimento write FVencimento;

    [TCampo('REC_DATAR', 'DATE')]
    property Datar: TDate read FDatar write FDatar;

    [TCampo('REC_SITUACAO', 'SMALLINT')]
    property Situacao: integer read FSituacao write FSituacao;
  end;

implementation

end.
