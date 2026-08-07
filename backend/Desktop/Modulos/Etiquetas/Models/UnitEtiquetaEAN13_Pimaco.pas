unit UnitEtiquetaEAN13_Pimaco;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  QuickRpt, Qrctrls, ExtCtrls, Db, DBClient, StdCtrls, Registry;

type
  TFrmEtiquetaEAN13_Pimaco = class(TForm)
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
    CDSEtiquetaPRECO: TStringField;
    Preco1: TQRLabel;
    Preco2: TQRLabel;
    Preco3: TQRLabel;
    Preco4: TQRLabel;
    Preco5: TQRLabel;
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
    Tamaho1: TQRMemo;
    Tamaho2: TQRMemo;
    Tamaho3: TQRMemo;
    Tamaho4: TQRMemo;
    Tamaho5: TQRMemo;
    procedure QuickRep2BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
    procedure QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    Images: array [0 .. 4] of TQRImage;
    Titulos: array [0 .. 4] of TQRMemo;
    Titulos2: array [0 .. 4] of TQRMemo;
    Tamanho: array [0 .. 4] of TQRMemo;
    Precos: array [0 .. 4] of TQRLabel;
  public
    { Public declarations }
    LabelCnt: integer;
    TituloEtiqueta: String;
  end;

var
  FrmEtiquetaEAN13_Pimaco: TFrmEtiquetaEAN13_Pimaco;

implementation

uses UnitCodBarra, AJBarcode, ACBrBarCode, UnitDMPrincipal;

{$R *.DFM}

procedure TFrmEtiquetaEAN13_Pimaco.QuickRep2BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
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
      CDSEtiquetaCODIGO.Value  := FrmCodBarra.CDSProdutosCODIGO.AsInteger;
      CDSEtiquetaNOME.Value    := FrmCodBarra.CDSProdutosNOME.AsString;
      CDSEtiquetaCODBAR.Value  := FrmCodBarra.CDSProdutosCOD_BARRA.AsString;
      CDSEtiquetaPRECO.Value   := FormatFloat('R$ ,0.00', FrmCodBarra.CDSProdutosVLR_VISTA.AsCurrency);
      CDSEtiqueta.post;
    end;
    FrmCodBarra.CDSProdutos.Next;
  end;
  Titulos[4].Enabled  := True;
  Titulos2[4].Enabled := True;
  Images[4].Enabled   := True;
  Precos[4].Enabled   := True;
  Tamanho[4].Enabled  := True;
  LabelCnt            := 4;
end;

procedure TFrmEtiquetaEAN13_Pimaco.QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
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
    Titulos[nIdx].Lines.Clear;
    Titulos2[nIdx].Lines.Clear;
    Tamanho[nIdx].Lines.Clear;
    Precos[nIdx].Caption := '';
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
            Text              := FrmEtiquetaEAN13_Pimaco.CDSEtiquetaCODBAR.AsString;
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
          Titulos[nIdx].Lines.Add(CDSEtiquetaNOME.AsString);
          Titulos2[nIdx].Lines.Add(TituloEtiqueta);
          Precos[nIdx].Caption := CDSEtiquetaPRECO.AsString;
          Tamanho[nIdx].Lines.Add(CDSEtiquetaTAMANHO.AsString);
        end
        else
        begin
          Images[nIdx].Canvas.Brush.Color := clWhite;
          Titulos[nIdx].Lines.Clear;
          Titulos2[nIdx].Lines.Clear;
          Precos[nIdx].Caption := '';
          Tamanho[nIdx].Lines.Clear;
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

procedure TFrmEtiquetaEAN13_Pimaco.FormCreate(Sender: TObject);
begin
  Images[0]   := QRImage1;
  Images[1]   := QRImage2;
  Images[2]   := QRImage3;
  Images[3]   := QRImage4;
  Images[4]   := QRImage5;
  Titulos[0]  := Titulo1;
  Titulos[1]  := Titulo2;
  Titulos[2]  := Titulo3;
  Titulos[3]  := Titulo4;
  Titulos[4]  := Titulo5;
  Titulos2[0] := QRMemo1;
  Titulos2[1] := QRMemo2;
  Titulos2[2] := QRMemo3;
  Titulos2[3] := QRMemo4;
  Titulos2[4] := QRMemo5;
  Precos[0]   := Preco1;
  Precos[1]   := Preco2;
  Precos[2]   := Preco3;
  Precos[3]   := Preco4;
  Precos[4]   := Preco5;
  Tamanho[0]  := Tamaho1;
  Tamanho[1]  := Tamaho2;
  Tamanho[2]  := Tamaho3;
  Tamanho[3]  := Tamaho4;
  Tamanho[4]  := Tamaho5;
end;

end.
