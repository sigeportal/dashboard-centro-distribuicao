unit UnitRecebimentos.Model;

interface

uses
  {$IFDEF PORTALORM}
  UnitPortalORM.Model;
  {$ELSE}
  UnitBancoDeDados.Model;
  {$ENDIF}

type
  [TRecursoServidor('/recebimentos')]
  [TNomeTabela('RECEBIMENTOS', 'REC_CODIGO')]
  TRecebimentos = class(TTabela)
  private
    { private declarations }
    FCodigo: integer;
    FValor: double;
    FVencimento: TDateTime;
    FEstado: integer;
    FDuplicata: string;
    FFpg: integer;
    FFat: integer;
    FJuros: double;
    FDescontos: double;
    FCai: integer;
    FTipo: string;
    FCon: integer;
    FDatar: TDateTime;
    FSituacao: integer;
    FDescontado: string;
    FObs: string;
  public
    { public declarations }
    [TCampo('REC_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property Codigo: integer read FCodigo write FCodigo;
    [TCampo('REC_VALOR', 'NUMERIC(9,2)')]
    property Valor: double read FValor write FValor;
    [TCampo('REC_VENCIMENTO', 'DATE')]
    property Vencimento: TDateTime read FVencimento write FVencimento;
    [TCampo('REC_ESTADO', 'SMALLINT')]
    property Estado: integer read FEstado write FEstado;
    [TCampo('REC_DUPLICATA', 'VARCHAR(30)')]
    property Duplicata: string read FDuplicata write FDuplicata;
    [TCampo('REC_FPG', 'SMALLINT')]
    property Fpg: integer read FFpg write FFpg;
    [TCampo('REC_FAT', 'INTEGER')]
    property Fat: integer read FFat write FFat;
    [TCampo('REC_JUROS', 'NUMERIC(9,2)')]
    property Juros: double read FJuros write FJuros;
    [TCampo('REC_DESCONTOS', 'NUMERIC(9,2)')]
    property Descontos: double read FDescontos write FDescontos;
    [TCampo('REC_CAI', 'INTEGER')]
    property Cai: integer read FCai write FCai;
    [TCampo('REC_TIPO', 'VARCHAR(20)')]
    property Tipo: string read FTipo write FTipo;
    [TCampo('REC_CON', 'SMALLINT')]
    property Con: integer read FCon write FCon;
    [TCampo('REC_DATAR', 'DATE')]
    property Datar: TDateTime read FDatar write FDatar;
    [TCampo('REC_SITUACAO', 'SMALLINT')]
    property Situacao: integer read FSituacao write FSituacao;
    [TCampo('REC_DESCONTADO', 'VARCHAR(2)')]
    property Descontado: string read FDescontado write FDescontado;
    [TCampo('REC_OBS', 'VARCHAR(100)')]
    property Obs: string read FObs write FObs;
  end;

implementation

end.

