object FrmEtiquetaL65_A25: TFrmEtiquetaL65_A25
  Left = 179
  Top = 120
  Caption = 'FrmEtiquetaL65_A25'
  ClientHeight = 468
  ClientWidth = 806
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
    Left = 7
    Top = -2
    Width = 794
    Height = 1123
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
    Page.PaperSize = A4
    Page.Continuous = False
    Page.Values = (
      130.000000000000000000
      2970.000000000000000000
      130.000000000000000000
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
      Top = 49
      Width = 756
      Height = 95
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
        251.354166666666700000
        2000.250000000000000000)
      PreCaluculateBandHeight = False
      KeepOnOnePage = False
      BandType = rbDetail
      object QRImage2: TQRImage
        Left = 277
        Top = 47
        Width = 200
        Height = 29
        Size.Values = (
          76.729166666666680000
          732.895833333333400000
          124.354166666666700000
          529.166666666666800000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage3: TQRImage
        Left = 530
        Top = 47
        Width = 200
        Height = 29
        Size.Values = (
          76.729166666666680000
          1402.291666666667000000
          124.354166666666700000
          529.166666666666800000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage1: TQRImage
        Left = 24
        Top = 47
        Width = 200
        Height = 29
        Size.Values = (
          76.729166666666680000
          63.500000000000000000
          124.354166666666700000
          529.166666666666800000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object Preco1: TQRLabel
        Left = 75
        Top = 77
        Width = 89
        Height = 17
        Size.Values = (
          44.979166666666670000
          198.437500000000000000
          203.729166666666700000
          235.479166666666700000)
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
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = False
        ExportAs = exptText
        WrapStyle = BreakOnSpaces
        VerticalAlignment = tlTop
        FontSize = 10
      end
      object Preco2: TQRLabel
        Left = 333
        Top = 77
        Width = 89
        Height = 17
        Size.Values = (
          44.979166666666670000
          881.062500000000000000
          203.729166666666700000
          235.479166666666700000)
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
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = False
        ExportAs = exptText
        WrapStyle = BreakOnSpaces
        VerticalAlignment = tlTop
        FontSize = 10
      end
      object Preco3: TQRLabel
        Left = 591
        Top = 77
        Width = 89
        Height = 17
        Size.Values = (
          44.979166666666670000
          1563.687500000000000000
          203.729166666666700000
          235.479166666666700000)
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
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = False
        ExportAs = exptText
        WrapStyle = BreakOnSpaces
        VerticalAlignment = tlTop
        FontSize = 10
      end
      object Titulo1: TQRMemo
        Left = 24
        Top = 23
        Width = 200
        Height = 12
        Size.Values = (
          31.750000000000000000
          63.500000000000000000
          60.854166666666680000
          529.166666666666800000)
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
        Left = 277
        Top = 23
        Width = 200
        Height = 12
        Size.Values = (
          31.750000000000000000
          732.895833333333400000
          60.854166666666680000
          529.166666666666800000)
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
        Left = 530
        Top = 23
        Width = 200
        Height = 12
        Size.Values = (
          31.750000000000000000
          1402.291666666667000000
          60.854166666666680000
          529.166666666666800000)
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
        Left = 24
        Top = 4
        Width = 200
        Height = 19
        Size.Values = (
          50.270833333333330000
          63.500000000000000000
          10.583333333333330000
          529.166666666666800000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Titulo')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 10
      end
      object QRMemo2: TQRMemo
        Left = 277
        Top = 4
        Width = 200
        Height = 19
        Size.Values = (
          50.270833333333330000
          732.895833333333400000
          10.583333333333330000
          529.166666666666800000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Titulo')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 10
      end
      object QRMemo3: TQRMemo
        Left = 530
        Top = 4
        Width = 200
        Height = 19
        Size.Values = (
          50.270833333333330000
          1402.291666666667000000
          10.583333333333330000
          529.166666666666800000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Color = clWhite
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'Titulo')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 10
      end
      object NumBarCode1: TQRMemo
        Left = 24
        Top = 35
        Width = 200
        Height = 12
        Size.Values = (
          31.750000000000000000
          63.500000000000000000
          92.604166666666680000
          529.166666666666800000)
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
          'Num Cod. Barras')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object NumBarCode3: TQRMemo
        Left = 530
        Top = 35
        Width = 200
        Height = 12
        Size.Values = (
          31.750000000000000000
          1402.291666666667000000
          92.604166666666680000
          529.166666666666800000)
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
          'Num Cod. Barras')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 7
      end
      object NumBarCode2: TQRMemo
        Left = 277
        Top = 35
        Width = 200
        Height = 12
        Size.Values = (
          31.750000000000000000
          732.895833333333400000
          92.604166666666680000
          529.166666666666800000)
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
          'Num Cod. Barras')
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
    Left = 343
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
      Size = 15
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
