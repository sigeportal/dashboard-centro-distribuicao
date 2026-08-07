object FrmEtiquetaL45_A12: TFrmEtiquetaL45_A12
  Left = 179
  Top = 120
  Caption = 'FrmEtiquetaL45_A12'
  ClientHeight = 468
  ClientWidth = 804
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
  object QuickRep1: TQuickRep
    Left = 8
    Top = -2
    Width = 814
    Height = 1058
    ShowingPreview = False
    BeforePrint = QuickRep1BeforePrint
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
      130.000000000000000000
      2800.000000000000000000
      130.000000000000000000
      2155.000000000000000000
      150.000000000000000000
      150.000000000000000000
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
      Left = 57
      Top = 49
      Width = 701
      Height = 47
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
        124.354166666666700000
        1854.729166666667000000)
      PreCaluculateBandHeight = False
      KeepOnOnePage = False
      BandType = rbDetail
      object QRImage2: TQRImage
        Left = 178
        Top = 3
        Width = 166
        Height = 29
        Size.Values = (
          76.729166666666680000
          470.958333333333400000
          7.937500000000000000
          439.208333333333400000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
      end
      object QRImage3: TQRImage
        Left = 357
        Top = 3
        Width = 166
        Height = 29
        Size.Values = (
          76.729166666666680000
          944.562500000000000000
          7.937500000000000000
          439.208333333333400000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
      end
      object QRImage4: TQRImage
        Left = 537
        Top = 3
        Width = 166
        Height = 29
        Size.Values = (
          76.729166666666680000
          1420.812500000000000000
          7.937500000000000000
          439.208333333333400000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
      end
      object QRImage1: TQRImage
        Left = 0
        Top = 3
        Width = 166
        Height = 29
        Size.Values = (
          76.729166666666680000
          0.000000000000000000
          7.937500000000000000
          439.208333333333400000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
      end
      object Preco1: TQRLabel
        Left = 0
        Top = 32
        Width = 166
        Height = 15
        Size.Values = (
          39.687500000000000000
          0.000000000000000000
          84.666666666666680000
          439.208333333333400000)
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
        Left = 178
        Top = 32
        Width = 166
        Height = 15
        Size.Values = (
          39.687500000000000000
          470.958333333333400000
          84.666666666666680000
          439.208333333333400000)
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
        Left = 357
        Top = 32
        Width = 166
        Height = 15
        Size.Values = (
          39.687500000000000000
          944.562500000000000000
          84.666666666666680000
          439.208333333333400000)
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
        Left = 537
        Top = 32
        Width = 166
        Height = 15
        Size.Values = (
          39.687500000000000000
          1420.812500000000000000
          84.666666666666680000
          439.208333333333400000)
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
  end
end
