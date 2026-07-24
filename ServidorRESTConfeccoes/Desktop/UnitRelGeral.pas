unit UnitRelGeral;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, StdCtrls, ExtCtrls, Mask, Grids, DBGrids, jpeg, Vcl.Imaging.pngimage,
  QRNewXLSXFilt, QRWebFilt, QRPDFFilt;

type
  TFrmRelGeral = class(TForm)
    MaskEdit1: TMaskEdit;
    Label20: TLabel;
    Label21: TLabel;
    MaskEdit2: TMaskEdit;
    BtnImprimir: TBitBtn;
    Image1: TImage;
    QRPDFFilter1: TQRPDFFilter;
    QRHTMLFilter1: TQRHTMLFilter;
    QRXLSXFilter1: TQRXLSXFilter;
    EdtCodigo: TEdit;
    Label1: TLabel;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure MaskEdit1KeyPress(Sender: TObject; var Key: Char);
    procedure MaskEdit2KeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure CbTipoPecuariaKeyPress(Sender: TObject; var Key: Char);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnImprimirClick(Sender: TObject);
  private
    { Private declarations }
  public
    Codigo: integer;
    Rodape: string;
    Valor_Sal: currency;
    { Public declarations }
  end;

var
  FrmRelGeral: TFrmRelGeral;

implementation

uses
  UnitPrincipal,
  UnitDMPrincipal,
  UnitGrid,
  DB,
  UnitLogin;

{$R *.DFM}

procedure TFrmRelGeral.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    if (Sender is TDBGrid) then
      TDBGrid(Sender).Perform(WM_KeyDown, VK_Tab, 0)
    else
      Perform(Wm_NextDlgCtl, 0, 0);
  end;
end;

procedure TFrmRelGeral.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
  begin
    ModalResult := mrOk;
  end;
end;

procedure TFrmRelGeral.FormShow(Sender: TObject);
begin
  MaskEdit1.SelLength := length(MaskEdit1.Text);
  MaskEdit1.SetFocus;
  Rodape := FrmPrincipal.Rodape;
end;

procedure TFrmRelGeral.MaskEdit1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    try
      strtodate(MaskEdit1.Text);
    except
      Application.MessageBox('Data Invalida!!!', 'Erro', MB_OK);
      MaskEdit1.SetFocus;
    end;
  end;
end;

procedure TFrmRelGeral.MaskEdit2KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    try
      strtodate(MaskEdit2.Text);
    except
      Application.MessageBox('Data Invalida!!!', 'Erro', MB_OK);
      MaskEdit2.SetFocus;
    end;
  end;
end;

procedure TFrmRelGeral.BtnImprimirClick(Sender: TObject);
begin
  ModalResult := MrOk;
end;

procedure TFrmRelGeral.CbTipoPecuariaKeyPress(Sender: TObject; var Key: Char);
begin
  if key = #13 then
    BtnImprimir.SetFocus;
end;

procedure TFrmRelGeral.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FrmPrincipal.HabilitaMenu(True);
end;

procedure TFrmRelGeral.FormCreate(Sender: TObject);
begin
  MaskEdit1.Text := datetostr(Date);
  MaskEdit2.Text := datetostr(Date);
  //
end;

end.
