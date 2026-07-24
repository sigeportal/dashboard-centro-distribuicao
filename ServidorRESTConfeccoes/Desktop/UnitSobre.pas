unit UnitSobre;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, DBCtrls, jpeg;

type
  TFrmSobre = class(TForm)
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label4: TLabel;
    DBText1: TDBText;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmSobre: TFrmSobre;

implementation

uses UnitPrincipal, UnitDMPrincipal;

{$R *.dfm}

procedure TFrmSobre.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
    Close;
end;

procedure TFrmSobre.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  FrmPrincipal.HabilitaMenu(True);
end;

procedure TFrmSobre.FormDestroy(Sender: TObject);
begin
  FrmSobre := nil;
end;

end.
