unit UnitCadEmpresa;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, DBGrids, StdCtrls, DBCtrls, Mask, Buttons, ExtCtrls, Db,
  IBCustomDataSet, IBQuery, Menus, ComCtrls, MD5, System.Actions, Vcl.ActnList, Vcl.ToolWin;

type
  TFrmCadEmpresa = class(TForm)
    DSEmpresa: TDataSource;
    IBDSEmpresa: TIBDataSet;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Label1: TLabel;
    DBText1: TDBText;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    DBEdit2: TDBEdit;
    DBEdit3: TDBEdit;
    DBEdit4: TDBEdit;
    DBEdit5: TDBEdit;
    DBEdit6: TDBEdit;
    DBEdit7: TDBEdit;
    DBComboBox1: TDBComboBox;
    DBEdit9: TDBEdit;
    Label25: TLabel;
    DBEdit18: TDBEdit;
    Label28: TLabel;
    DBEdit19: TDBEdit;
    Label30: TLabel;
    DBEdit23: TDBEdit;
    DBEdit24: TDBEdit;
    Label32: TLabel;
    Label34: TLabel;
    DBEdit26: TDBEdit;
    DBEdit1: TDBEdit;
    Label10: TLabel;
    DBEdit8: TDBEdit;
    Label11: TLabel;
    Label12: TLabel;
    DBEdit10: TDBEdit;
    Label13: TLabel;
    DBComboBox2: TDBComboBox;
    Label14: TLabel;
    DBEdit11: TDBEdit;
    Label15: TLabel;
    DBEdit12: TDBEdit;
    Label16: TLabel;
    DBEdit13: TDBEdit;
    Label17: TLabel;
    DBEdit14: TDBEdit;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    DBEdit15: TDBEdit;
    DBEdit16: TDBEdit;
    DBEdit17: TDBEdit;
    IBDSEmpresaEMP_CODIGO: TSmallintField;
    IBDSEmpresaEMP_CNPJ: TIBStringField;
    IBDSEmpresaEMP_INSCEST: TIBStringField;
    IBDSEmpresaEMP_MUNICIPIO: TIBStringField;
    IBDSEmpresaEMP_UF: TIBStringField;
    IBDSEmpresaEMP_FONE: TIBStringField;
    IBDSEmpresaEMP_FAX: TIBStringField;
    IBDSEmpresaEMP_LOGRADOURO: TIBStringField;
    IBDSEmpresaEMP_NUMERO: TIBStringField;
    IBDSEmpresaEMP_COMPLEMENTO: TIBStringField;
    IBDSEmpresaEMP_BAIRRO: TIBStringField;
    IBDSEmpresaEMP_CEP: TIBStringField;
    IBDSEmpresaEMP_CONTATO: TIBStringField;
    IBDSEmpresaEMP_FANTASIA: TIBStringField;
    IBDSEmpresaEMP_CRT: TIBStringField;
    IBDSEmpresaEMP_LICENCA_DLL_NFE: TIBStringField;
    IBDSEmpresaEMP_RAZAO_SOCIAL: TIBStringField;
    IBDSEmpresaEMP_SUFRAMA: TIBStringField;
    IBDSEmpresaEMP_PERFIL: TIBStringField;
    IBDSEmpresaEMP_ATIVIDADE: TIBStringField;
    IBDSEmpresaEMP_EMAIL: TIBStringField;
    IBDSEmpresaEMP_TITULO1: TIBStringField;
    IBDSEmpresaEMP_TITULO2: TIBStringField;
    IBDSEmpresaEMP_TITULO3: TIBStringField;
    IBDSEmpresaEMP_MD5: TIBStringField;
    IBDSEmpresaEMP_LICENCA: TIBStringField;
    IBDSEmpresaEMP_CODMUN_IBGE: TIBStringField;
    IBDSEmpresaEMP_CODUF_IBGE: TIBStringField;
    IBDSEmpresaEMP_INSCMUN: TIBStringField;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
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
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DBEdit3KeyPress(Sender: TObject; var Key: Char);
    procedure DSEmpresaStateChange(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure actEditarExecute(Sender: TObject);
    procedure actSairExecute(Sender: TObject);
    procedure actConfirmarExecute(Sender: TObject);
  private
    { Private declarations }
  public
    PodeExcluir: boolean;
    procedure ClienteBtn;
    { Public declarations }
  end;

var
  FrmCadEmpresa: TFrmCadEmpresa;

implementation

uses UnitDMPrincipal, UnitPrincipal, UnitValidacao;

function cpf(num: string): boolean; forward;
function cgc(num: string): boolean; forward;

{$R *.DFM}

function cpf(num: string): boolean;
var
  n1, n2, n3, n4, n5, n6, n7, n8, n9: integer;
  d1, d2: integer;
  digitado, calculado: string;
begin
  n1 := StrToInt(num[1]);
  n2 := StrToInt(num[2]);
  n3 := StrToInt(num[3]);
  n4 := StrToInt(num[5]);
  n5 := StrToInt(num[6]);
  n6 := StrToInt(num[7]);
  n7 := StrToInt(num[9]);
  n8 := StrToInt(num[10]);
  n9 := StrToInt(num[11]);
  d1 := n9 * 2 + n8 * 3 + n7 * 4 + n6 * 5 + n5 * 6 + n4 * 7 + n3 * 8 + n2 * 9 + n1 * 10;
  d1 := 11 - (d1 mod 11);
  if d1 >= 10 then
    d1 := 0;
  d2 := d1 * 2 + n9 * 3 + n8 * 4 + n7 * 5 + n6 * 6 + n5 * 7 + n4 * 8 + n3 * 9 + n2 * 10 + n1 * 11;
  d2 := 11 - (d2 mod 11);
  if d2 >= 10 then
    d2 := 0;
  calculado := inttostr(d1) + inttostr(d2);
  digitado := num[13] + num[14];
  if calculado = digitado then
    cpf := true
  else
    cpf := false;
end;

function cgc(num: string): boolean;
var
  n1, n2, n3, n4, n5, n6, n7, n8, n9, n10, n11, n12: integer;
  d1, d2: integer;
  digitado, calculado: string;
begin
  n1 := StrToInt(num[1]);
  n2 := StrToInt(num[2]);
  n3 := StrToInt(num[4]);
  n4 := StrToInt(num[5]);
  n5 := StrToInt(num[6]);
  n6 := StrToInt(num[8]);
  n7 := StrToInt(num[9]);
  n8 := StrToInt(num[10]);
  n9 := StrToInt(num[12]);
  n10 := StrToInt(num[13]);
  n11 := StrToInt(num[14]);
  n12 := StrToInt(num[15]);
  d1 := n12 * 2 + n11 * 3 + n10 * 4 + n9 * 5 + n8 * 6 + n7 * 7 + n6 * 8 + n5 * 9 + n4 * 2 + n3 * 3 + n2 * 4 + n1 * 5;
  d1 := 11 - (d1 mod 11);
  if d1 >= 10 then
    d1 := 0;
  d2 := d1 * 2 + n12 * 3 + n11 * 4 + n10 * 5 + n9 * 6 + n8 * 7 + n7 * 8 + n6 * 9 + n5 * 2 + n4 * 3 + n3 * 4 + n2 * 5 + n1 * 6;
  d2 := 11 - (d2 mod 11);
  if d2 >= 10 then
    d2 := 0;
  calculado := inttostr(d1) + inttostr(d2);
  digitado := num[17] + num[18];
  if calculado = digitado then
    cgc := true
  else
    cgc := false;
end;

procedure TFrmCadEmpresa.ClienteBtn;
var
  logico: boolean;
begin
  logico := (IBDSEmpresa.State = dsEdit) or (IBDSEmpresa.State = dsInsert);
  actCancelar.Enabled := logico;
  actConfirmar.Enabled := logico;
  actEditar.Enabled := not logico;
end;

procedure TFrmCadEmpresa.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    if (Sender is TDBGrid) then
      TDBGrid(Sender).Perform(WM_KeyDown, VK_Tab, 0)
    else
      Perform(Wm_NextDlgCtl, 0, 0);
  end;
end;

procedure TFrmCadEmpresa.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if DMPrincipal.IBTransPrincipal.Active then
    DMPrincipal.IBTransPrincipal.Rollback;
  Action := cafree;
  FrmPrincipal.HabilitaMenu(true);
end;

procedure TFrmCadEmpresa.FormDestroy(Sender: TObject);
begin
  FrmCadEmpresa := nil;
end;

procedure TFrmCadEmpresa.FormShow(Sender: TObject);
begin
  IBDSEmpresa.Close;
  IBDSEmpresa.Open;
  if IBDSEmpresa.IsEmpty then
  begin
    IBDSEmpresa.Append;
    IBDSEmpresaEMP_CODIGO.Value := 1;
  end;
  DBEdit3.SetFocus;
end;

procedure TFrmCadEmpresa.actCancelarExecute(Sender: TObject);
begin
  IBDSEmpresa.Cancel;
end;

procedure TFrmCadEmpresa.actConfirmarExecute(Sender: TObject);
begin
  IBDSEmpresaEMP_CRT.Value := DBComboBox2.Text[1];
  IBDSEmpresa.ApplyUpdates;
  IBDSEmpresa.Transaction.CommitRetaining;
  Valida;
end;

procedure TFrmCadEmpresa.actEditarExecute(Sender: TObject);
begin
  IBDSEmpresa.Edit;
  DBEdit3.SetFocus;
end;

procedure TFrmCadEmpresa.actSairExecute(Sender: TObject);
begin
  if Application.MessageBox('Deseja fechar o cadastro da Empresa?', 'Confirmar', MB_YesNo + MB_ICONQUESTION) = IDYes then
  begin
    Close;
  end;
end;

procedure TFrmCadEmpresa.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = 27) then
    actSair.Execute;
end;

procedure TFrmCadEmpresa.DBEdit3KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    if not cgc(DBEdit3.Text) then
    begin
      showmessage('CNPJ invalido!!!');
      DBEdit3.SetFocus;
    end;
  end;
end;

procedure TFrmCadEmpresa.DSEmpresaStateChange(Sender: TObject);
begin
  ClienteBtn;
end;

end.
