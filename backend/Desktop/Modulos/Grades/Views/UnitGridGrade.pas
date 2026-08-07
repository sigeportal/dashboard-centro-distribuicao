unit UnitGridGrade;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, StdCtrls, Grids, DBGrids,
  System.Actions, Vcl.ActnList, Vcl.ComCtrls, Vcl.ToolWin, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, IBX.IBCustomDataSet,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, UnitPortalQueryREST.Component;

type
  TFrmGridGrade = class(TForm)
    DBGrid1: TDBGrid;
    Label2: TLabel;
    DSGrades: TDataSource;
    IBQRGrades: TPortalQueryREST;
    IBQRGradesGRA_CODIGO: TIntegerField;
    IBQRGradesGRA_PRO: TIntegerField;
    IBQRGradesGRA_VALOR: TIBBCDField;
    IBQRGradesGRA_TAM: TIntegerField;
    IBQRGradesGRA_QUANTIDADE: TIBBCDField;
    IBQRGradesTAM_TAMANHO: TIBStringField;
    IBQRGradesTAM_SIGLA: TIBStringField;
    IBQRGradesGRA_CODBARRA: TIBStringField;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ActionList1: TActionList;
    ActSair: TAction;
    ActSelecionar: TAction;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    procedure FormShow(Sender: TObject);
    procedure DBGrid1KeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ActSairExecute(Sender: TObject);
    procedure ActSelecionarExecute(Sender: TObject);
    procedure DBGrid1DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Cod_Produto: Integer;
    Quantidade : Currency;
  end;

var
  FrmGridGrade: TFrmGridGrade;

implementation

uses 
	UnitDMPrincipal, 
  UnitPrincipal, 
  UnitCodBarra;

{$R *.dfm}

procedure TFrmGridGrade.FormShow(Sender: TObject);
begin
  IBQRGrades.Close;
  IBQRGrades.ParamByName('PRODUTO').Value := Cod_Produto;
  IBQRGrades.Open;
end;

procedure TFrmGridGrade.ActSairExecute(Sender: TObject);
begin
  ModalResult := mrCancel; 
end;

procedure TFrmGridGrade.ActSelecionarExecute(Sender: TObject);
begin
  if not IBQRGrades.IsEmpty then
  begin
    DMPrincipal.Cod_Grade := IBQRGradesGRA_CODIGO.AsInteger;
    Close;
  end;
  ModalResult := mrOk;
end;

procedure TFrmGridGrade.DBGrid1DblClick(Sender: TObject);
begin
  ActSelecionar.Execute;
end;

procedure TFrmGridGrade.DBGrid1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    ActSelecionar.Execute;
  end;
end;

procedure TFrmGridGrade.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
  begin
    ActSair.Execute;
  end;
end;

end.
