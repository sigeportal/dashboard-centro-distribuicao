object FrmEtiquetaEAN13_MaxPrint: TFrmEtiquetaEAN13_MaxPrint
  Left = 179
  Top = 120
  Caption = 'FrmEtiquetaEAN13_MaxPrint'
  ClientHeight = 468
  ClientWidth = 807
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Scaled = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object QuickRep2: TQuickRep
    Left = 8
    Top = -2
    Width = 794
    Height = 1130
    ShowingPreview = False
    BeforePrint = QuickRep2BeforePrint
    DataSet = CDSEtiqueta
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = []
    Functions.Strings = (
      'PAGENUMBER'
      'COLUMNNUMBER'
      'REPORTTITLE')
    Functions.DATA = (
      '0'
      '0'
      #39#39)
    Options = [FirstPageHeader, LastPageFooter]
    Page.Columns = 1
    Page.Orientation = poPortrait
    Page.PaperSize = Custom
    Page.Continuous = False
    Page.Values = (
      105.000000000000000000
      2990.000000000000000000
      120.000000000000000000
      2100.000000000000000000
      50.000000000000000000
      50.000000000000000000
      0.000000000000000000)
    PrinterSettings.Copies = 1
    PrinterSettings.OutputBin = First
    PrinterSettings.Duplex = False
    PrinterSettings.FirstPage = 0
    PrinterSettings.LastPage = 0
    PrinterSettings.UseStandardprinter = False
    PrinterSettings.UseCustomBinCode = False
    PrinterSettings.CustomBinCode = 0
    PrinterSettings.ExtendedDuplex = 0
    PrinterSettings.UseCustomPaperCode = False
    PrinterSettings.CustomPaperCode = 0
    PrinterSettings.PrintMetaFile = False
    PrinterSettings.MemoryLimit = 1000000
    PrinterSettings.PrintQuality = 0
    PrinterSettings.Collate = 0
    PrinterSettings.ColorOption = 0
    PrintIfEmpty = True
    ReportTitle = 'CJVBarCode'
    SnapToGrid = True
    Units = MM
    Zoom = 100
    PrevFormStyle = fsNormal
    PreviewInitialState = wsMaximized
    PreviewWidth = 500
    PreviewHeight = 500
    PrevInitialZoom = qrZoomToWidth
    PreviewDefaultSaveType = stQRP
    PreviewLeft = 0
    PreviewTop = 0
    object QRBand1: TQRBand
      Left = 19
      Top = 45
      Width = 756
      Height = 80
      AlignToBottom = False
      BeforePrint = QRBand1BeforePrint
      TransparentBand = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = []
      ForceNewColumn = False
      ForceNewPage = False
      ParentFont = False
      Size.Values = (
        211.666666666666700000
        2000.250000000000000000)
      PreCaluculateBandHeight = False
      KeepOnOnePage = False
      BandType = rbDetail
      object QRImage2: TQRImage
        Left = 159
        Top = 33
        Width = 136
        Height = 29
        Size.Values = (
          76.729166666666670000
          420.687500000000000000
          87.312500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage3: TQRImage
        Left = 314
        Top = 33
        Width = 136
        Height = 29
        Size.Values = (
          76.729166666666670000
          830.791666666666700000
          87.312500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage4: TQRImage
        Left = 468
        Top = 33
        Width = 136
        Height = 29
        Size.Values = (
          76.729166666666670000
          1238.250000000000000000
          87.312500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage1: TQRImage
        Left = 8
        Top = 33
        Width = 136
        Height = 29
        Size.Values = (
          76.729166666666670000
          21.166666666666670000
          87.312500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage5: TQRImage
        Left = 619
        Top = 33
        Width = 136
        Height = 29
        Size.Values = (
          76.729166666666670000
          1637.770833333333000000
          87.312500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object Preco1: TQRLabel
        Left = 1
        Top = 63
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          2.645833333333333000
          166.687500000000000000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = 'R$ 123,99'
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = False
        ExportAs = exptText
        WrapStyle = BreakOnSpaces
        VerticalAlignment = tlTop
        FontSize = 8
      end
      object Preco2: TQRLabel
        Left = 155
        Top = 63
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          410.104166666666700000
          166.687500000000000000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = 'R$ 123,99'
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = False
        ExportAs = exptText
        WrapStyle = BreakOnSpaces
        VerticalAlignment = tlTop
        FontSize = 8
      end
      object Preco3: TQRLabel
        Left = 309
        Top = 63
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          817.562500000000000000
          166.687500000000000000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = 'R$ 123,99'
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = False
        ExportAs = exptText
        WrapStyle = BreakOnSpaces
        VerticalAlignment = tlTop
        FontSize = 8
      end
      object Preco4: TQRLabel
        Left = 461
        Top = 63
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          1219.729166666667000000
          166.687500000000000000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = 'R$ 123,99'
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = False
        ExportAs = exptText
        WrapStyle = BreakOnSpaces
        VerticalAlignment = tlTop
        FontSize = 8
      end
      object Preco5: TQRLabel
        Left = 614
        Top = 63
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          1624.541666666667000000
          166.687500000000000000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = 'R$ 123,99'
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = False
        ExportAs = exptText
        WrapStyle = BreakOnSpaces
        VerticalAlignment = tlTop
        FontSize = 8
      end
      object Titulo1: TQRMemo
        Left = 8
        Top = 15
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          21.166666666666670000
          39.687500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Descri'#231#227'o do'
          'Produto')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object Titulo2: TQRMemo
        Left = 159
        Top = 15
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          420.687500000000000000
          39.687500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Descri'#231#227'o do'
          'Produto')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object Titulo3: TQRMemo
        Left = 314
        Top = 15
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          830.791666666666700000
          39.687500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Descri'#231#227'o do'
          'Produto')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object Titulo4: TQRMemo
        Left = 468
        Top = 15
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          1238.250000000000000000
          39.687500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Descri'#231#227'o do'
          'Produto')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object Titulo5: TQRMemo
        Left = 619
        Top = 15
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          1637.770833333333000000
          39.687500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Descri'#231#227'o do'
          'Produto')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object QRMemo1: TQRMemo
        Left = 8
        Top = 3
        Width = 136
        Height = 11
        Size.Values = (
          29.104166666666670000
          21.166666666666670000
          7.937500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'C'#233'lia Modas')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object QRMemo2: TQRMemo
        Left = 159
        Top = 3
        Width = 136
        Height = 11
        Size.Values = (
          29.104166666666670000
          420.687500000000000000
          7.937500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'C'#233'lia Modas')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object QRMemo3: TQRMemo
        Left = 314
        Top = 3
        Width = 136
        Height = 11
        Size.Values = (
          29.104166666666670000
          830.791666666666700000
          7.937500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'C'#233'lia Modas')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object QRMemo4: TQRMemo
        Left = 468
        Top = 3
        Width = 136
        Height = 11
        Size.Values = (
          29.104166666666670000
          1238.250000000000000000
          7.937500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'C'#233'lia Modas')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object QRMemo5: TQRMemo
        Left = 619
        Top = 3
        Width = 136
        Height = 11
        Size.Values = (
          29.104166666666670000
          1637.770833333333000000
          7.937500000000000000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'C'#233'lia Modas')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object Tamaho1: TQRMemo
        Left = 8
        Top = 28
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          21.166666666666670000
          74.083333333333330000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Tamanho')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object Tamaho5: TQRMemo
        Left = 619
        Top = 28
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          1637.770833333333000000
          74.083333333333330000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Tamanho')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object Tamaho4: TQRMemo
        Left = 468
        Top = 28
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          1238.250000000000000000
          74.083333333333330000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Tamanho')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object Tamaho3: TQRMemo
        Left = 314
        Top = 28
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          830.791666666666700000
          74.083333333333330000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Tamanho')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object Tamaho2: TQRMemo
        Left = 159
        Top = 28
        Width = 136
        Height = 12
        Size.Values = (
          31.750000000000000000
          420.687500000000000000
          74.083333333333330000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -9
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Tamanho')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
    end
  end
  object CDSEtiqueta: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 295
    Top = 6
    object CDSEtiquetaCODIGO: TIntegerField
      FieldName = 'CODIGO'
    end
    object CDSEtiquetaCODBAR: TStringField
      FieldName = 'CODBAR'
      Size = 13
    end
    object CDSEtiquetaPRECO: TStringField
      FieldName = 'PRECO'
      Size = 30
    end
    object CDSEtiquetaNOME: TStringField
      FieldName = 'NOME'
      Size = 50
    end
    object CDSEtiquetaTAMANHO: TStringField
      FieldName = 'TAMANHO'
      Size = 10
    end
  end
end
