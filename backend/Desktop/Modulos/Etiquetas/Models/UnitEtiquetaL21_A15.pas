unit UnitEtiquetaL21_A15;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  QuickRpt, Qrctrls, ExtCtrls, Db, DBClient, StdCtrls, Registry, AJBarCode, ACBrBarCode;

type
  TFrmEtiquetaL21_A15 = class(TForm)
    QuickRep1: TQuickRep;
    QRBand1: TQRBand;
    QRImage2: TQRImage;
    QRImage4: TQRImage;
    QRImage6: TQRImage;
    QRImage1: TQRImage;
    CDSEtiqueta: TClientDataSet;
    CDSEtiquetaCODIGO: TIntegerField;
    CDSEtiquetaCODBAR: TStringField;
    CDSEtiquetaPRECO: TStringField;
    Preco1: TQRLabel;
    Preco2: TQRLabel;
    Preco4: TQRLabel;
    Preco6: TQRLabel;
    Titulo1: TQRLabel;
    Titulo2: TQRLabel;
    Titulo4: TQRLabel;
    Titulo6: TQRLabel;
    QRImage3: TQRImage;
    QRImage5: TQRImage;
    QRImage7: TQRImage;
    Titulo3: TQRLabel;
    Titulo5: TQRLabel;
    Titulo7: TQRLabel;
    Preco3: TQRLabel;
    Preco5: TQRLabel;
    Preco7: TQRLabel;
    procedure QuickRep1BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
    procedure QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    Images: array [0 .. 6] of TQRImage;
    Precos: array [0 .. 6] of TQRLabel;
    Titulos: array [0 .. 6] of TQRLabel;
  public
    { Public declarations }
    LabelCnt: integer;
    TituloEtiqueta: String;
  end;

var
  FrmEtiquetaL21_A15: TFrmEtiquetaL21_A15;

implementation

uses UnitCodBarra, UnitDMPrincipal;

{$R *.DFM}

procedure TFrmEtiquetaL21_A15.QuickRep1BeforePrint(Sender: TCustomQuickRep; var PrintReport: Boolean);
var
  i: integer;
begin
  try
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
        CDSEtiquetaPRECO.Value  := FormatFloat('R$ ,0.00', FrmCodBarra.CDSProdutosVLR_VISTA.AsCurrency);
        CDSEtiqueta.post;
      end;
      FrmCodBarra.CDSProdutos.Next;
    end;
    Images[6].Enabled  := True;
    Precos[6].Enabled  := True;
    Titulos[6].Enabled := True;
    LabelCnt           := 6;
  except
    on E: Exception do
      raise Exception.Create('Erro ao carregar dados das Etiquetas' + sLineBreak + E.Message);
  end;
end;

procedure TFrmEtiquetaL21_A15.QRBand1BeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
var
  nIdx: integer;
  BMP: TBitmap;
  ACBrBarCode: TACBrBarCode;
  Reg: TRegistry;
begin
  try
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
      Precos[nIdx].Caption  := '';
      Titulos[nIdx].Caption := '';
    end;
    with QuickRep1.DataSet do
    begin
      for nIdx := 0 to LabelCnt do
      begin
        if not Eof then
        begin
          if (CDSEtiquetaCODBAR.AsString <> '') and (not CDSEtiquetaCODBAR.AsString.ToUpper.Contains('SEM GTIN')) then
          begin
            ACBrBarCode := TACBrBarCode.Create(nil);
            with ACBrBarCode.BarCode do
            begin
              Width    := 95; // Images[nIdx].Width;
              Height   := Images[nIdx].Height;
              Color    := clWhite;
              ColorBar := clBlack;
              Typ      := bcCodeEAN13;
              Ratio    := 2;
              Text     := CDSEtiquetaCODBAR.AsString;
            end;
            try
              BMP        := TBitmap.Create;
              BMP.Width  := 95; // Images[nIdx].Width;
              BMP.Height := Images[nIdx].Height;
              ACBrBarCode.BarCode.DrawBarcode(BMP.Canvas);
              Images[nIdx].Center         := True;
              Images[nIdx].Picture.Bitmap := BMP;
            finally
              BMP.Free;
              ACBrBarCode.Free;
            end;
            Precos[nIdx].Caption  := 'COD: ' + CDSEtiquetaCODIGO.AsString + ' - ' + CDSEtiquetaPRECO.AsString;
            Titulos[nIdx].Caption := TituloEtiqueta;
          end
          else
          begin
            Images[nIdx].Canvas.Brush.Color := clWhite;
            Precos[nIdx].Caption            := '';
            Titulos[nIdx].Caption           := '';
          end;
        end;
        if (nIdx < LabelCnt) and (not Eof) then
          Next
        else
          break;
      end;
    end;
  except
    on E: Exception do
      raise Exception.Create('Erro ao gerar Etiquetas' + sLineBreak + E.Message);
  end;
end;

procedure TFrmEtiquetaL21_A15.FormCreate(Sender: TObject);
begin
  Images[0]  := QRImage1;
  Images[1]  := QRImage2;
  Images[2]  := QRImage3;
  Images[3]  := QRImage4;
  Images[4]  := QRImage5;
  Images[5]  := QRImage6;
  Images[6]  := QRImage7;
  Precos[0]  := Preco1;
  Precos[1]  := Preco2;
  Precos[2]  := Preco3;
  Precos[3]  := Preco4;
  Precos[4]  := Preco5;
  Precos[5]  := Preco6;
  Precos[6]  := Preco7;
  Titulos[0] := Titulo1;
  Titulos[1] := Titulo2;
  Titulos[2] := Titulo3;
  Titulos[3] := Titulo4;
  Titulos[4] := Titulo5;
  Titulos[5] := Titulo6;
  Titulos[6] := Titulo7;
end;

end.
