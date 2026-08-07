object FrmGrid: TFrmGrid
  Left = 388
  Top = 213
  BorderIcons = []
  Caption = 'LOCALIZADOR'
  ClientHeight = 265
  ClientWidth = 640
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 192
    Width = 634
    Height = 32
    Align = alBottom
    BevelInner = bvSpace
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object Edt: TEdit
      Left = 3
      Top = 3
      Width = 324
      Height = 24
      BevelInner = bvLowered
      BevelKind = bkSoft
      BevelOuter = bvSpace
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = 15856371
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnKeyDown = EdtKeyDown
      OnKeyPress = EdtKeyPress
    end
  end
  object DBGrid1: TDBGrid
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 634
    Height = 186
    Margins.Bottom = 0
    Align = alClient
    Color = 15856371
    DataSource = DSGrid
    DrawingStyle = gdsGradient
    GradientEndColor = 5065546
    GradientStartColor = 10724259
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = 6812638
    TitleFont.Height = -13
    TitleFont.Name = 'Arial'
    TitleFont.Style = [fsBold]
    OnDrawColumnCell = DBGrid1DrawColumnCell
    OnDblClick = DBGrid1DblClick
    OnKeyPress = DBGrid1KeyPress
  end
  object ToolBar2: TToolBar
    Left = 0
    Top = 227
    Width = 640
    Height = 38
    Align = alBottom
    ButtonHeight = 38
    ButtonWidth = 157
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
      Left = 165
      Top = 0
      Width = 8
      Caption = 'ToolButton7'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton1: TToolButton
      Left = 173
      Top = 0
      Action = actSelecionar
    end
    object ToolButton2: TToolButton
      Left = 330
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 3
      Style = tbsSeparator
    end
  end
  object IBQRVerifica: TIBQuery
    BufferChunks = 1000
    CachedUpdates = True
    ParamCheck = True
    SQL.Strings = (
      
        'select rf.rf_res, c.cli_nome from res_fit rf, reservas r, client' +
        'es c, fitas f'
      'where rf.rf_fit = f.fit_codigo and r.res_codigo = rf.rf_res'
      
        'and r.res_cli = c.cli_codigo and rf.rf_fit = :fita and rf.rf_dat' +
        'a = :Date')
    Left = 368
    Top = 56
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'fita'
        ParamType = ptUnknown
      end
      item
        DataType = ftUnknown
        Name = 'Date'
        ParamType = ptUnknown
      end>
    object IBQRVerificaRF_RES: TIntegerField
      FieldName = 'RF_RES'
      Required = True
    end
    object IBQRVerificaCLI_NOME: TIBStringField
      FieldName = 'CLI_NOME'
      Required = True
      Size = 50
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 300
    OnTimer = Timer1Timer
    Left = 432
    Top = 56
  end
  object DSGrid: TDataSource
    DataSet = FDMemTableGrid
    OnDataChange = DSGridDataChange
    Left = 192
    Top = 48
  end
  object ActionList1: TActionList
    Left = 432
    Top = 112
    object actSelecionar: TAction
      Caption = 'Enter - Selecionar'
      ImageIndex = 49
      OnExecute = actSelecionarExecute
    end
    object actSair: TAction
      Caption = 'Esc - &Sair'
      ImageIndex = 171
      OnExecute = actSairExecute
    end
  end
  object FDMemTableGrid: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    FormatOptions.AssignedValues = [fvDataSnapCompatibility, fvFmtDisplayDateTime, fvFmtDisplayDate, fvFmtDisplayTime, fvFmtEditNumeric]
    FormatOptions.DataSnapCompatibility = True
    FormatOptions.FmtDisplayDateTime = 'DD/MM/YYYY'
    FormatOptions.FmtDisplayDate = 'DD/MM/YYYY'
    FormatOptions.FmtDisplayTime = 'DD/MM/YYYY'
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 192
    Top = 112
  end
end
