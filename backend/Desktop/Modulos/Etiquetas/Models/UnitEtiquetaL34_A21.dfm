object FrmEtiquetaL34_A21: TFrmEtiquetaL34_A21
  Left = 179
  Top = 120
  Caption = 'FrmEtiquetaL34_A21'
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
        Left = 158
        Top = 40
        Width = 136
        Height = 24
        Size.Values = (
          63.500000000000000000
          418.041666666666700000
          105.833333333333300000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage3: TQRImage
        Left = 310
        Top = 40
        Width = 136
        Height = 24
        Size.Values = (
          63.500000000000000000
          820.208333333333300000
          105.833333333333300000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage4: TQRImage
        Left = 462
        Top = 40
        Width = 136
        Height = 24
        Size.Values = (
          63.500000000000000000
          1222.375000000000000000
          105.833333333333300000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage1: TQRImage
        Left = 7
        Top = 40
        Width = 136
        Height = 24
        Size.Values = (
          63.500000000000000000
          18.520833333333330000
          105.833333333333300000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object QRImage5: TQRImage
        Left = 613
        Top = 40
        Width = 136
        Height = 24
        Size.Values = (
          63.500000000000000000
          1621.895833333333000000
          105.833333333333300000
          359.833333333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Center = True
        Stretch = True
      end
      object Codigo1: TQRLabel
        Left = 3
        Top = 64
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          7.937500000000000000
          169.333333333333300000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = '123'
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
      object Codigo2: TQRLabel
        Left = 154
        Top = 64
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          407.458333333333300000
          169.333333333333300000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = '123'
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
      object Codigo3: TQRLabel
        Left = 305
        Top = 64
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          806.979166666666700000
          169.333333333333300000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = '123'
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
      object Codigo4: TQRLabel
        Left = 457
        Top = 64
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          1209.145833333333000000
          169.333333333333300000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = '123'
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
      object Codigo5: TQRLabel
        Left = 608
        Top = 64
        Width = 145
        Height = 15
        Size.Values = (
          39.687500000000000000
          1608.666666666667000000
          169.333333333333300000
          383.645833333333300000)
        XLColumn = 0
        XLNumFormat = nfGeneral
        ActiveInPreview = False
        Alignment = taCenter
        AlignToBand = False
        AutoSize = False
        Caption = '123'
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
        Left = 7
        Top = 24
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          18.520833333333330000
          63.500000000000000000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'PARCELADO: R$ 6,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
      end
      object Titulo2: TQRMemo
        Left = 158
        Top = 24
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          418.041666666666700000
          63.500000000000000000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'PARCELADO: R$ 6,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
      end
      object Titulo3: TQRMemo
        Left = 310
        Top = 24
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          820.208333333333300000
          63.500000000000000000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'PARCELADO: R$ 6,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
      end
      object Titulo4: TQRMemo
        Left = 462
        Top = 24
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          1222.375000000000000000
          63.500000000000000000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'PARCELADO: R$ 6,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
      end
      object Titulo5: TQRMemo
        Left = 613
        Top = 24
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          1621.895833333333000000
          63.500000000000000000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          'PARCELADO: R$ 6,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
      end
      object QRMemo1: TQRMemo
        Left = 7
        Top = 10
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          18.520833333333330000
          26.458333333333330000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          #193' VISTA: R$ 5,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
      end
      object QRMemo2: TQRMemo
        Left = 158
        Top = 10
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          418.041666666666700000
          26.458333333333330000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          #193' VISTA: R$ 5,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
      end
      object QRMemo3: TQRMemo
        Left = 310
        Top = 10
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          820.208333333333300000
          26.458333333333330000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          #193' VISTA: R$ 5,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
      end
      object QRMemo4: TQRMemo
        Left = 462
        Top = 10
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          1222.375000000000000000
          26.458333333333330000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          #193' VISTA: R$ 5,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
      end
      object QRMemo5: TQRMemo
        Left = 613
        Top = 10
        Width = 136
        Height = 16
        Size.Values = (
          42.333333333333330000
          1621.895833333333000000
          26.458333333333330000
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
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Lines.Strings = (
          #193' VISTA: R$ 5,00')
        ParentFont = False
        Transparent = False
        FullJustify = False
        MaxBreakChars = 0
        FontSize = 8
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
    object CDSEtiquetaNOME: TStringField
      FieldName = 'NOME'
      Size = 50
    end
    object CDSEtiquetaTAMANHO: TStringField
      FieldName = 'TAMANHO'
      Size = 10
    end
    object CDSEtiquetaVLR_VISTA: TCurrencyField
      FieldName = 'VLR_VISTA'
    end
    object CDSEtiquetaVLR_PARCELADO: TCurrencyField
      FieldName = 'VLR_PARCELADO'
    end
  end
end
