unit UnitCadEstado;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, Grids, DBGrids, StdCtrls, Mask, DBCtrls, ExtCtrls, Db,
  IBCustomDataSet, IBQuery, System.Actions, Vcl.ActnList, Vcl.ComCtrls, Vcl.ToolWin;

type
  TFrmCadEstado = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    DBText1: TDBText;
    DBEdit2: TDBEdit;
    DBEdit9: TDBEdit;
    DBGrid1: TDBGrid;
    DSEstado: TDataSource;
    IBDSEstado: TIBDataSet;
    IBDSEstadoEST_CODIGO: TIntegerField;
    IBDSEstadoEST_SIGLA: TIBStringField;
    IBDSEstadoEST_NOME: TIBStringField;
    IBDSEstadoEST_CODIGO_IBGE: TIntegerField;
    Label4: TLabel;
    DBEdit1: TDBEdit;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton2: TToolButton;
    ToolBar2: TToolBar;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ActionList1: TActionList;
    actInserir: TAction;
    actExcluir: TAction;
    actConfirmar: TAction;
    actCancelar: TAction;
    actEditar: TAction;
    actSair: TAction;
    actPesquisa: TAction;
    Panel1: TPanel;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure DSEstadoStateChange(Sender: TObject);
    procedure actInserirExecute(Sender: TObject);
    procedure actExcluirExecute(Sender: TObject);
    procedure actConfirmarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure actEditarExecute(Sender: TObject);
    procedure actSairExecute(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
  private
    { Private declarations }
  public
    procedure ClienteBtn;
    { Public declarations }
  end;

var
  FrmCadEstado: TFrmCadEstado;
  ListS: TStrings;

implementation

uses UnitPrincipal, UnitFuncoes, UnitDMPrincipal;
{$R *.DFM}

procedure TFrmCadEstado.ClienteBtn;
var
  logico: boolean;
begin
  logico := (IBDSEstado.State = dsEdit) or (IBDSEstado.State = dsInsert);
  actCancelar.Enabled := logico;
  actConfirmar.Enabled := logico;
  actExcluir.Enabled := not logico;
  actInserir.Enabled := not logico;
  actEditar.Enabled := not logico;
  DBGrid1.Enabled := not logico;
end;

procedure TFrmCadEstado.FormShow(Sender: TObject);
begin
  IBDSEstado.Open;
  DBGrid1.SetFocus;
end;

procedure TFrmCadEstado.actCancelarExecute(Sender: TObject);
begin
  IBDSEstado.Cancel;
end;

procedure TFrmCadEstado.actConfirmarExecute(Sender: TObject);
begin
  ListS := TStringList.Create;
  ListS.Clear;
  if (DBEdit2.Text = '') then
    ListS.Add('Nome');
  if (DBEdit1.Text = '') then
    ListS.Add('Sigla');
  if (DBEdit9.Text = '') then
    ListS.Add('Cód. IBGE');
  if (ListS.Count > 0) then
  begin
    CamposObrigatorios(ListS);
  end
  else
  begin
    IBDSEstado.ApplyUpdates;
    IBDSEstado.Transaction.CommitRetaining;
    DSEstado.AutoEdit := False;
  end;
end;

procedure TFrmCadEstado.actEditarExecute(Sender: TObject);
begin
  IBDSEstado.Edit;
  DBEdit2.SetFocus;
end;

procedure TFrmCadEstado.actExcluirExecute(Sender: TObject);
begin
  try
    if (messagedlg('Deseja realmente excluir este registro?', mtConfirmation, [mbYes, mbNo], 0)) = mrYes then
    begin
      IBDSEstado.Delete;
      IBDSEstado.ApplyUpdates;
      IBDSEstado.Transaction.CommitRetaining;
    end;
  except
    on EDatabaseError do
      showmessage('Este dado não pode ser Excluído');
  end;
end;

procedure TFrmCadEstado.actInserirExecute(Sender: TObject);
begin
  DBEdit2.SetFocus;
  IBDSEstado.Append;
  IBDSEstadoEST_CODIGO.Value := DMPrincipal.GeraCodigo('ESTADOS', 'EST_CODIGO');
  DSEstado.AutoEdit := True;
end;

procedure TFrmCadEstado.actSairExecute(Sender: TObject);
begin
  if Application.MessageBox('Deseja fechar o cadastro de Estados?', 'Confirmar', MB_YesNo + MB_ICONQUESTION) = IDYes then
  begin
    Close;
  end;
end;

procedure TFrmCadEstado.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if IBDSEstado.Transaction.Active then
    IBDSEstado.Transaction.Rollback;
  FrmPrincipal.HabilitaMenu(True);
  FrmPrincipal.Panel1.Visible := True;
end;

procedure TFrmCadEstado.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
    actSair.Execute;
end;

procedure TFrmCadEstado.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    if (Sender is TDBGrid) then
      TDBGrid(Sender).Perform(WM_KeyDown, VK_Tab, 0)
    else
      Perform(Wm_NextDlgCtl, 0, 0);
  end;
end;

procedure TFrmCadEstado.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  GridPadrao(DSEstado.DataSet.RecNo, DBGrid1, Rect, Column, State);
end;

procedure TFrmCadEstado.DSEstadoStateChange(Sender: TObject);
begin
  ClienteBtn;
end;

end.
