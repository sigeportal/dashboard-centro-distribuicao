unit UnitEtiquetaL45_A12;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  QuickRpt, Qrctrls, ExtCtrls, Db, DBClient, StdCtrls, Registry, AJBarCode, ACBrBarCode;

type
  TFrmEtiquetaL45_A12 = class(TForm)
    QuickRep1: TQuickRep;
    QRBand1: TQRBand;
    QRImage2: TQRImage;
    QRImage3: TQRImage;
    QRImage4: TQRImage;
    QRImage1: TQRImage;
    CDSEtiqueta: TClientDataSet;
    CDSEtiquetaCODIGO: TIntegerField;
    CDSEtiquetaCODBAR: TStringField;
    CDSEtiquetaPRECO: TStringField;
    Preco1: TQRLabel;
    Preco2: TQRLabel;
    Preco3: TQRLabel;
    Preco4: TQRLabel;
    procedure QuickRep1BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
    procedure QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    Images: array [0 .. 3] of TQRImage;
    Precos: array [0 .. 3] of TQRLabel;
  public
    { Public declarations }
    LabelCnt: integer;
    TituloEtiqueta: String;
  end;

var
  FrmEtiquetaL45_A12: TFrmEtiquetaL45_A12;

implementation

uses UnitCodBarra, System.StrUtils;

{$R *.DFM}

procedure TFrmEtiquetaL45_A12.QuickRep1BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
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
      CDSEtiquetaCODIGO.Value := FrmCodBarra.CDSProdutosCODIGO.AsInteger;
      CDSEtiquetaCODBAR.Value := FrmCodBarra.CDSProdutosCOD_BARRA.AsString;
      CDSEtiquetaPRECO.Value := FormatFloat('R$ ,0.00', FrmCodBarra.CDSProdutosVLR_VISTA.AsCurrency);
      CDSEtiqueta.post;
    end;
    FrmCodBarra.CDSProdutos.Next;
  end;
  Images[3].Enabled := True;
  Precos[3].Enabled := True;
  LabelCnt := 3;
end;

procedure TFrmEtiquetaL45_A12.QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
var
  nIdx: integer;
  BMP: TBitmap;
  ACBrBarCode: TACBrBarCode;
begin
  for nIdx := low(Images) to high(Images) do
  begin
    Images[nIdx].Canvas.Brush.Color := clWhite;
    Images[nIdx].Canvas.Pen.Color := clWhite;
    Images[nIdx].Canvas.Rectangle(0, 0, Images[nIdx].Width, Images[nIdx].Height);
    Precos[nIdx].Caption := '';
  end;
  with QuickRep1.DataSet do
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
            Width := Images[nIdx].Width;
            Height := Images[nIdx].Height;
            Color := clWhite;
            ColorBar := clBlack;
            Margins.Left := 20;
            Checksum := True;
            Typ := bcCodeEAN13;
            ShowText := bcoCode;
            ShowTextPosition := stpBottomCenter;
            ShowTextFont.Name := 'Arial';
            ShowTextFont.Size := 8;
            Ratio := 3;
            Text := LeftStr(CDSEtiquetaCODBAR.AsString, 12);
          end;
          try
            BMP := TBitmap.Create;
            BMP.Width := Images[nIdx].Width;
            BMP.Height := Images[nIdx].Height;
            ACBrBarCode.BarCode.DrawBarcode(BMP.Canvas);
            Images[nIdx].Center := True;
            Images[nIdx].Picture.Bitmap := BMP;
          finally
            BMP.Free;
            ACBrBarCode.Free;
          end;
          Precos[nIdx].Caption := CDSEtiquetaPRECO.AsString;
        end
        else
        begin
          Images[nIdx].Canvas.Brush.Color := clWhite;
          Precos[nIdx].Caption := '';
        end;
      end;
      if (nIdx < LabelCnt) and (not Eof) then
        Next
      else
        break;
    end;
  end;
end;

procedure TFrmEtiquetaL45_A12.FormCreate(Sender: TObject);
begin
  Images[0] := QRImage1;
  Images[1] := QRImage2;
  Images[2] := QRImage3;
  Images[3] := QRImage4;
  Precos[0] := Preco1;
  Precos[1] := Preco2;
  Precos[2] := Preco3;
  Precos[3] := Preco4;
end;

end.
