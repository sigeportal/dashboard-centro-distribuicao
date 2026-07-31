unit UnitHisPro.Model;

interface

uses
  UnitPortalORM.Model,
  Classes,
  SysUtils,
  FireDAC.Comp.Client;

type
  [TNomeTabela('HIS_PRO', 'HP_CODIGO')]
  THisPro = class(TTabela)
  private
    FHP_CODIGO: Integer;
    FHP_DATA: TDateTime;
    FHP_PRO: Integer;
    FHP_ORIGEM: string;
    FHP_DOC: string;
    FHP_QUANTIDADE: Double;
    FHP_VALORC: Double;
    FHP_VALORV: Double;
    FHP_VALORCM: Double;
    FHP_VALOROP: Double;
    FHP_VALORM: Double;
    FHP_TIPO: string;
    FHP_TIPO2: Integer;
    FHP_QUANTIDADEA: Double;
  public
    [TCampo('HP_CODIGO', 'INTEGER NOT NULL PRIMARY KEY')]
    property codigo: Integer read FHP_CODIGO write FHP_CODIGO;

    [TCampo('HP_DATA', 'DATE')]
    property data: TDateTime read FHP_DATA write FHP_DATA;

    [TCampo('HP_PRO', 'NUMERIC(8,0)')]
    property pro: Integer read FHP_PRO write FHP_PRO;

    [TCampo('HP_ORIGEM', 'VARCHAR(30)')]
    property origem: string read FHP_ORIGEM write FHP_ORIGEM;

    [TCampo('HP_DOC', 'VARCHAR(15)')]
    property doc: string read FHP_DOC write FHP_DOC;

    [TCampo('HP_QUANTIDADE', 'NUMERIC(9,2)')]
    property quantidade: Double read FHP_QUANTIDADE write FHP_QUANTIDADE;

    [TCampo('HP_VALORC', 'NUMERIC(9,2)')]
    property valorc: Double read FHP_VALORC write FHP_VALORC;

    [TCampo('HP_VALORV', 'NUMERIC(9,2)')]
    property valorv: Double read FHP_VALORV write FHP_VALORV;

    [TCampo('HP_VALORCM', 'NUMERIC(9,2)')]
    property valorcm: Double read FHP_VALORCM write FHP_VALORCM;

    [TCampo('HP_VALOROP', 'NUMERIC(9,2)')]
    property valorop: Double read FHP_VALOROP write FHP_VALOROP;

    [TCampo('HP_VALORM', 'NUMERIC(9,2)')]
    property valorm: Double read FHP_VALORM write FHP_VALORM;

    [TCampo('HP_TIPO', 'VARCHAR(2)')]
    property tipo: string read FHP_TIPO write FHP_TIPO;

    [TCampo('HP_TIPO2', 'SMALLINT')]
    property tipo2: Integer read FHP_TIPO2 write FHP_TIPO2;

    [TCampo('HP_QUANTIDADEA', 'NUMERIC(9,2)')]
    property quantidadea: Double read FHP_QUANTIDADEA write FHP_QUANTIDADEA;
  end;

implementation

end.
