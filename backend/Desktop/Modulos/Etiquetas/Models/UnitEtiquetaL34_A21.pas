unit UnitEtiquetaL34_A21;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  QuickRpt, Qrctrls, ExtCtrls, Db, DBClient, StdCtrls, Registry;

type
  TFrmEtiquetaL34_A21 = class(TForm)
    QuickRep2: TQuickRep;
    QRBand1: TQRBand;
    QRImage2: TQRImage;
    QRImage3: TQRImage;
    QRImage4: TQRImage;
    QRImage1: TQRImage;
    QRImage5: TQRImage;
    CDSEtiqueta: TClientDataSet;
    CDSEtiquetaCODIGO: TIntegerField;
    CDSEtiquetaCODBAR: TStringField;
    Codigo1: TQRLabel;
    Codigo2: TQRLabel;
    Codigo3: TQRLabel;
    Codigo4: TQRLabel;
    Codigo5: TQRLabel;
    Titulo1: TQRMemo;
    Titulo2: TQRMemo;
    Titulo3: TQRMemo;
    Titulo4: TQRMemo;
    Titulo5: TQRMemo;
    CDSEtiquetaNOME: TStringField;
    QRMemo1: TQRMemo;
    QRMemo2: TQRMemo;
    QRMemo3: TQRMemo;
    QRMemo4: TQRMemo;
    QRMemo5: TQRMemo;
    CDSEtiquetaTAMANHO: TStringField;
    CDSEtiquetaVLR_VISTA: TCurrencyField;
    CDSEtiquetaVLR_PARCELADO: TCurrencyField;
    procedure QuickRep2BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
    procedure QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    Images: array [0 .. 4] of TQRImage;
    ValorVista: array [0 .. 4] of TQRMemo;
    ValorParcelado: array [0 .. 4] of TQRMemo;
    Codigos: array [0 .. 4] of TQRLabel;
  public
    { Public declarations }
    LabelCnt: integer;
    TituloEtiqueta: String;
  end;

var
  FrmEtiquetaL34_A21: TFrmEtiquetaL34_A21;

implementation

uses UnitCodBarra, AJBarcode, ACBrBarCode, UnitDMPrincipal;

{$R *.DFM}

procedure TFrmEtiquetaL34_A21.QuickRep2BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
var
  i: integer;
begin
  CDSEtiqueta.Close;
  CDSEtiqueta.CreateDataSet;
  CDSEtiqueta.open;
  // Pula Etiquetas
  for i := 1 to StrToInt(FrmCodBarra.EdtPularEtiq.Text) do
  begin
    CDSEtiqueta.Append;
    CDSEtiquetaCODIGO.Value := i;
    CDSEtiquetaCODBAR.Value := '';
    CDSEtiqueta.post;
  end;
  // Insere os registros de acordo com o numero de etiquetas de cada produto
  FrmCodBarra.CDSProdutos.First;
  while not FrmCodBarra.CDSProdutos.Eof do
  begin
    for i := 1 to FrmCodBarra.CDSProdutosQUANT.AsInteger do
    begin
      CDSEtiqueta.Append;
      CDSEtiquetaCODIGO.Value        := FrmCodBarra.CDSProdutosCODIGO.AsInteger;
      CDSEtiquetaNOME.Value          := FrmCodBarra.CDSProdutosNOME.AsString;
      CDSEtiquetaCODBAR.Value        := FrmCodBarra.CDSProdutosCOD_BARRA.AsString;
      CDSEtiquetaVLR_VISTA.Value     := FrmCodBarra.CDSProdutosVLR_VISTA.AsCurrency;
      CDSEtiquetaVLR_PARCELADO.Value := FrmCodBarra.CDSProdutosVLR_PARCELADO.AsCurrency;
      CDSEtiqueta.post;
    end;
    FrmCodBarra.CDSProdutos.Next;
  end;
  ValorVista[4].Enabled  := True;
  ValorParcelado[4].Enabled := True;
  Images[4].Enabled   := True;
  Codigos[4].Enabled   := True;
  LabelCnt            := 4;
end;

procedure TFrmEtiquetaL34_A21.QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
var
  nIdx: integer;
  BMP: TBitmap;
  ACBrBarCode: TACBrBarCode;
  i: integer;
  Reg: TRegistry;
begin
  Reg         := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.OpenKey('SOFTWARE\PORTAL.COM\' + ExtractFileName(Application.ExeName), True);
  try
    TituloEtiqueta := Reg.ReadString('TituloEtiqueta');
  except
    TituloEtiqueta := '';
  end;
  for nIdx := low(Images) to high(Images) do
  begin
    Images[nIdx].Canvas.Brush.Color := clWhite;
    Images[nIdx].Canvas.Pen.Color   := clWhite;
    Images[nIdx].Canvas.Rectangle(0, 0, Images[nIdx].Width, Images[nIdx].Height);
    BMP                         := TBitmap.Create;
    Images[nIdx].Picture.Bitmap := BMP;
    ValorVista[nIdx].Lines.Clear;
    ValorParcelado[nIdx].Lines.Clear;
    Codigos[nIdx].Caption := '';
  end;
  with QuickRep2.DataSet do
  begin
    for nIdx := 0 to LabelCnt do
    begin
      if not Eof then
      begin
        if CDSEtiquetaCODBAR.AsString <> '' then
        begin
          ACBrBarCode := TACBrBarCode.Create(nil);
          with ACBrBarCode.BarCode do
          begin
            Height            := Images[nIdx].Height;
            Color             := clWhite;
            ColorBar          := clBlack;
            Text              := CDSEtiquetaCODBAR.AsString;
            Ratio             := 2;
            Typ               := bcCodeEAN13;
            ShowText          := bcoBoth;
            ShowTextPosition  := stpBottomCenter;
            ShowTextFont.Name := 'Arial';
            ShowTextFont.Size := 10;
          end;
          try
            BMP        := TBitmap.Create;
            BMP.Width  := 200; // Images[nIdx].Width;
            BMP.Height := Images[nIdx].Height;
            ACBrBarCode.DrawBarcode(BMP.Canvas);
            Images[nIdx].Center         := True;
            Images[nIdx].Picture.Bitmap := BMP;
          finally
            BMP.Free;
            ACBrBarCode.Free;
          end;
          ValorVista[nIdx].Lines.Add('Á VISTA: '+ FormatFloat('R$ #,##0.00', CDSEtiquetaVLR_VISTA.AsCurrency));
          ValorParcelado[nIdx].Lines.Add('PARCELADO: '+ FormatFloat('R$ #,##0.00', CDSEtiquetaVLR_PARCELADO.AsCurrency));
          Codigos[nIdx].Caption := CDSEtiquetaCODIGO.AsString;
        end
        else
        begin
          Images[nIdx].Canvas.Brush.Color := clWhite;
          ValorVista[nIdx].Lines.Clear;
          ValorParcelado[nIdx].Lines.Clear;
          Codigos[nIdx].Caption := '';
        end;
      end;
      if (nIdx < LabelCnt) and (not Eof) then
        Next
      else
      begin
        break;
      end;
    end;
  end;
end;

procedure TFrmEtiquetaL34_A21.FormCreate(Sender: TObject);
begin
  Images[0]   := QRImage1;
  Images[1]   := QRImage2;
  Images[2]   := QRImage3;
  Images[3]   := QRImage4;
  Images[4]   := QRImage5;
  ValorVista[0]  := QRMemo1;
  ValorVista[1]  := QRMemo2;
  ValorVista[2]  := QRMemo3;
  ValorVista[3]  := QRMemo4;
  ValorVista[4]  := QRMemo5;
  ValorParcelado[0] := Titulo1;
  ValorParcelado[1] := Titulo2;
  ValorParcelado[2] := Titulo3;
  ValorParcelado[3] := Titulo4;
  ValorParcelado[4] := Titulo5;
  Codigos[0]   := Codigo1;
  Codigos[1]   := Codigo2;
  Codigos[2]   := Codigo3;
  Codigos[3]   := Codigo4;
  Codigos[4]   := Codigo5;
end;

end.
