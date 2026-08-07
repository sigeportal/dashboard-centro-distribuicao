object FrmPesquisa: TFrmPesquisa
  Left = 219
  Top = 164
  Caption = 'PESQUISA'
  ClientHeight = 326
  ClientWidth = 459
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = [fsBold]
  KeyPreview = True
  OldCreateOrder = False
  Position = poScreenCenter
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  DesignSize = (
    459
    326)
  PixelsPerInch = 96
  TextHeight = 13
  object DBGrid1: TDBGrid
    Left = 3
    Top = 107
    Width = 453
    Height = 178
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = 15856371
    DataSource = DSPesquisa
    DrawingStyle = gdsGradient
    GradientEndColor = 5065546
    GradientStartColor = 10724259
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
    ParentFont = False
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = 6812638
    TitleFont.Height = -11
    TitleFont.Name = 'Arial'
    TitleFont.Style = [fsBold]
    OnDrawColumnCell = DBGrid1DrawColumnCell
  end
  object ToolBar2: TToolBar
    Left = 0
    Top = 288
    Width = 459
    Height = 38
    Align = alBottom
    ButtonHeight = 38
    ButtonWidth = 141
    Caption = 'ToolBar1'
    Color = clBlack
    DrawingStyle = dsGradient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 6812638
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    GradientEndColor = 4934475
    GradientStartColor = 11184552
    HotTrackColor = 7895160
    Images = DMPrincipal.Icones_Brancos
    List = True
    ParentColor = False
    ParentFont = False
    ShowCaptions = True
    TabOrder = 1
    ExplicitWidth = 457
    object ToolButton3: TToolButton
      Left = 0
      Top = 0
      Width = 8
      Caption = 'ToolButton1'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton4: TToolButton
      Left = 8
      Top = 0
      Action = actSair
    end
    object ToolButton5: TToolButton
      Left = 149
      Top = 0
      Width = 8
      Caption = 'ToolButton7'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton1: TToolButton
      Left = 157
      Top = 0
      Action = actNovaPesquisa
    end
    object ToolButton2: TToolButton
      Left = 298
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 3
      Style = tbsSeparator
    end
    object ToolButton6: TToolButton
      Left = 306
      Top = 0
      Action = actAlternarIndice
    end
    object ToolButton7: TToolButton
      Left = 447
      Top = 0
      Width = 8
      Caption = 'ToolButton7'
      ImageIndex = 4
      Style = tbsSeparator
    end
  end
  object Panel1: TPanel
    Left = 3
    Top = 3
    Width = 454
    Height = 101
    Anchors = [akLeft, akTop, akRight]
    BevelInner = bvSpace
    Color = clWhite
    Ctl3D = False
    ParentBackground = False
    ParentCtl3D = False
    TabOrder = 2
    ExplicitWidth = 452
    object Label22: TLabel
      Left = 5
      Top = 50
      Width = 74
      Height = 19
      Caption = 'Localizar '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 5
      Top = 2
      Width = 46
      Height = 19
      Caption = 'Indice'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object EditLocalizar: TEdit
      Left = 5
      Top = 70
      Width = 442
      Height = 24
      BevelInner = bvLowered
      BevelKind = bkSoft
      BevelOuter = bvSpace
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = 15856371
      Ctl3D = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentCtl3D = False
      ParentFont = False
      TabOrder = 0
      OnKeyDown = EditLocalizarKeyDown
      OnKeyPress = EditLocalizarKeyPress
    end
    object ComboBox1: TComboBox
      Left = 5
      Top = 21
      Width = 145
      Height = 24
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnChange = ComboBox1Change
      Items.Strings = (
        'C'#243'digo'
        'Nome')
    end
  end
  object DSPesquisa: TDataSource
    DataSet = IBQRPesquisa
    Left = 312
    Top = 32
  end
  object IBQRPesquisa: TIBQuery
    BufferChunks = 1000
    CachedUpdates = True
    ParamCheck = True
    Left = 192
    Top = 8
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 240
    Top = 16
  end
  object ActionList1: TActionList
    Images = DMPrincipal.Icones_Pretos
    Left = 252
    Top = 120
    object actNovaPesquisa: TAction
      Caption = 'F1 - Nova Pesq.'
      ImageIndex = 47
      OnExecute = actNovaPesquisaExecute
    end
    object actSair: TAction
      Caption = 'Esc - &Sair'
      ImageIndex = 171
      OnExecute = actSairExecute
    end
    object actAlternarIndice: TAction
      Caption = '&F2 - &Alt. '#205'ndice'
      ImageIndex = 46
      OnExecute = actAlternarIndiceExecute
    end
  end
end
