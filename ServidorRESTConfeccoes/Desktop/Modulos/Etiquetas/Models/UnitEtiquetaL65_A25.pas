unit UnitEtiquetaL65_A25;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  QuickRpt, Qrctrls, ExtCtrls, Db, DBClient, StdCtrls, Registry;

type
  TFrmEtiquetaL65_A25 = class(TForm)
    QuickRep2: TQuickRep;
    QRBand1: TQRBand;
    QRImage2: TQRImage;
    QRImage3: TQRImage;
    QRImage1: TQRImage;
    CDSEtiqueta: TClientDataSet;
    CDSEtiquetaCODIGO: TIntegerField;
    CDSEtiquetaCODBAR: TStringField;
    CDSEtiquetaPRECO: TStringField;
    Preco1: TQRLabel;
    Preco2: TQRLabel;
    Preco3: TQRLabel;
    Titulo1: TQRMemo;
    Titulo2: TQRMemo;
    Titulo3: TQRMemo;
    CDSEtiquetaNOME: TStringField;
    QRMemo1: TQRMemo;
    QRMemo2: TQRMemo;
    QRMemo3: TQRMemo;
    CDSEtiquetaTAMANHO: TStringField;
    NumBarCode1: TQRMemo;
    NumBarCode2: TQRMemo;
    NumBarCode3: TQRMemo;
    procedure QuickRep2BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
    procedure QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    Images: array [0 .. 2] of TQRImage;
    Titulos: array [0 .. 2] of TQRMemo;
    Titulos2: array [0 .. 2] of TQRMemo;
    NumBarcode: array [0 .. 2] of TQRMemo;
    Precos: array [0 .. 2] of TQRLabel;
  public
    { Public declarations }
    LabelCnt: integer;
    TituloEtiqueta: String;
  end;

var
  FrmEtiquetaL65_A25: TFrmEtiquetaL65_A25;

implementation

uses UnitCodBarra, AJBarcode, ACBrBarCode;

{$R *.DFM}

procedure TFrmEtiquetaL65_A25.QuickRep2BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
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
      CDSEtiquetaNOME.Value := FrmCodBarra.CDSProdutosNOME.AsString;
      CDSEtiquetaCODBAR.Value := FrmCodBarra.CDSProdutosCOD_BARRA.AsString;
      CDSEtiquetaPRECO.Value := FormatFloat('R$ ,0.00', FrmCodBarra.CDSProdutosVLR_VISTA.AsCurrency);
      CDSEtiqueta.post;
    end;
    FrmCodBarra.CDSProdutos.Next;
  end;
  Titulos[2].Enabled := True;
  Titulos2[2].Enabled := True;
  Images[2].Enabled := True;
  Precos[2].Enabled := True;
  NumBarcode[2].Enabled := True;
  LabelCnt := 2;
end;

procedure TFrmEtiquetaL65_A25.QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
var
  nIdx: integer;
  BMP: TBitmap;
  ACBrBarCode: TACBrBarCode;
  i: integer;
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
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
    Images[nIdx].Canvas.Pen.Color := clWhite;
    Images[nIdx].Canvas.Rectangle(0, 0, Images[nIdx].Width, Images[nIdx].Height);
    BMP := TBitmap.Create;
    Images[nIdx].Picture.Bitmap := BMP;
    Titulos[nIdx].Lines.Clear;
    Titulos2[nIdx].Lines.Clear;
    NumBarcode[nIdx].Lines.Clear;
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
            Height := Images[nIdx].Height;
            Color := clWhite;
            ColorBar := clBlack;
            Text := FrmEtiquetaL65_A25.CDSEtiquetaCODBAR.AsString;
            CheckSumMethod := TCheckSumMethod.csmNone;
            Checksum := False;
            Ratio := 2;
            Modul := 1;
            Typ   := bcCode39;
            ShowText := bcoTyp;
            ShowTextPosition := stpBottomCenter;
            ShowTextFont.Name := 'Arial';
            ShowTextFont.Size := 10;
          end;
          try
            BMP := TBitmap.Create;
            BMP.Width := Images[nIdx].Width;
            BMP.Height := Images[nIdx].Height;
            ACBrBarCode.DrawBarcode(BMP.Canvas);
            Images[nIdx].Center := True;
            Images[nIdx].Picture.Bitmap := BMP;
          finally
            BMP.Free;
            ACBrBarCode.Free;
          end;
          Titulos[nIdx].Lines.Add(CDSEtiquetaNOME.AsString);
          Titulos2[nIdx].Lines.Add(TituloEtiqueta);
          Precos[nIdx].Caption := CDSEtiquetaPRECO.AsString;
          NumBarcode[nIdx].Lines.Add(CDSEtiquetaCODBAR.AsString);
        end
        else
        begin
          Images[nIdx].Canvas.Brush.Color := clWhite;
          Titulos[nIdx].Lines.Clear;
          Titulos2[nIdx].Lines.Clear;
          Precos[nIdx].Caption := '';
          NumBarcode[nIdx].Lines.Clear;
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

procedure TFrmEtiquetaL65_A25.FormCreate(Sender: TObject);
begin
  Images[0] := QRImage1;
  Images[1] := QRImage2;
  Images[2] := QRImage3;
  Titulos[0] := Titulo1;
  Titulos[1] := Titulo2;
  Titulos[2] := Titulo3;
  Titulos2[0] := QRMemo1;
  Titulos2[1] := QRMemo2;
  Titulos2[2] := QRMemo3;
  Precos[0] := Preco1;
  Precos[1] := Preco2;
  Precos[2] := Preco3;
  NumBarcode[0] := NumBarCode1;
  NumBarcode[1] := NumBarCode2;
  NumBarcode[2] := NumBarCode3;
end;

end.
