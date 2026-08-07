unit UnitEscolhaImpressora;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UnitFormBase, Vcl.StdCtrls, Vcl.Buttons, System.Actions,
  Vcl.ActnList, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin;

type
	TTipoImpressora = (Lazer, Ribbon);

  TFrmEscolhaImpressora = class(TFrmBase)
    BtnImpressoraLazer: TBitBtn;
    BtnImpressoraRibbon: TBitBtn;
    procedure FormDestroy(Sender: TObject);
    procedure BtnImpressoraLazerClick(Sender: TObject);
    procedure BtnImpressoraRibbonClick(Sender: TObject);
    procedure actSairExecute(Sender: TObject);
  private
    FTipoImpressora: TTipoImpressora;
    procedure SetTipoImpressora(const Value: TTipoImpressora);
    { Private declarations }
  public
    { Public declarations }
    property TipoImpressora: TTipoImpressora read FTipoImpressora write SetTipoImpressora default TTipoImpressora.Lazer;
  end;

var
  FrmEscolhaImpressora: TFrmEscolhaImpressora;

implementation

{$R *.dfm}

procedure TFrmEscolhaImpressora.actSairExecute(Sender: TObject);
begin
  inherited;
	ModalResult := mrCancel;
end;

procedure TFrmEscolhaImpressora.BtnImpressoraLazerClick(Sender: TObject);
begin
  inherited;
	TipoImpressora := TTipoImpressora.Lazer;
  ModalResult := mrOk;
end;

procedure TFrmEscolhaImpressora.BtnImpressoraRibbonClick(Sender: TObject);
begin
  inherited;
	TipoImpressora := TTipoImpressora.Ribbon;
  ModalResult := mrOk;
end;

procedure TFrmEscolhaImpressora.FormDestroy(Sender: TObject);
begin
  inherited;
  FrmEscolhaImpressora := nil;
end;

procedure TFrmEscolhaImpressora.SetTipoImpressora(const Value: TTipoImpressora);
begin
  FTipoImpressora := Value;
  case FTipoImpressora of
    Lazer: BtnImpressoraLazer.SetFocus;
    Ribbon: BtnImpressoraRibbon.SetFocus;
  end;
  
end;

end.
