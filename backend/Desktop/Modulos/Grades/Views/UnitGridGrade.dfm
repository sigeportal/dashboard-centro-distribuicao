object FrmGridGrade: TFrmGridGrade
  Left = 185
  Top = 120
  Caption = 'M'#243'dulo de Escolha de Tamanho'
  ClientHeight = 255
  ClientWidth = 446
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Arial'
  Font.Style = [fsBold]
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnKeyDown = FormKeyDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 19
  object Label2: TLabel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 440
    Height = 22
    Align = alTop
    Alignment = taCenter
    Caption = 'Selecione um Tamanho'
    Color = 11468799
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
    Transparent = False
    ExplicitWidth = 217
  end
  object DBGrid1: TDBGrid
    AlignWithMargins = True
    Left = 3
    Top = 28
    Width = 440
    Height = 197
    Margins.Top = 0
    Align = alClient
    Color = 13434879
    DataSource = DSGrades
    DrawingStyle = gdsGradient
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -16
    TitleFont.Name = 'Arial'
    TitleFont.Style = [fsBold]
    OnDblClick = DBGrid1DblClick
    OnKeyPress = DBGrid1KeyPress
    Columns = <
      item
        Expanded = False
        FieldName = 'GRA_CODIGO'
        Title.Caption = 'CODIGO'
        Width = 71
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'TAM_TAMANHO'
        Title.Caption = 'TAMANHO'
        Width = 139
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'GRA_QUANTIDADE'
        Title.Caption = 'QUANT'
        Width = 78
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'GRA_VALOR'
        Title.Caption = 'VALOR (R$)'
        Width = 107
        Visible = True
      end>
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 228
    Width = 446
    Height = 27
    Align = alBottom
    AutoSize = True
    ButtonHeight = 27
    ButtonWidth = 207
    Caption = 'ToolBar1'
    DrawingStyle = dsGradient
    GradientEndColor = clGray
    ShowCaptions = True
    TabOrder = 1
    object ToolButton1: TToolButton
      Left = 0
      Top = 0
      Action = ActSair
      AutoSize = True
    end
    object ToolButton2: TToolButton
      Left = 88
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 1
      Style = tbsSeparator
    end
    object ToolButton3: TToolButton
      Left = 96
      Top = 0
      Action = ActSelecionar
      AutoSize = True
    end
  end
  object DSGrades: TDataSource
    DataSet = IBQRGrades
    Left = 304
    Top = 72
  end
  object IBQRGrades: TPortalQueryREST
    CachedUpdates = True
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    SQL.Strings = (
      'SELECT G.*, TAM_TAMANHO, TAM_SIGLA'
      
        'FROM GRADES G, TAMANHOS WHERE GRA_TAM = TAM_CODIGO AND GRA_PRO =' +
        ' :PRODUTO'
      'ORDER BY TAM_TAMANHO')
    Params = <
      item
        Name = 'PRODUTO'
      end>
    Left = 352
    Top = 72
    object IBQRGradesGRA_CODIGO: TIntegerField
      FieldName = 'GRA_CODIGO'
      Origin = 'GRADES.GRA_CODIGO'
      Required = True
    end
    object IBQRGradesGRA_PRO: TIntegerField
      FieldName = 'GRA_PRO'
      Origin = 'GRADES.GRA_PRO'
    end
    object IBQRGradesGRA_VALOR: TIBBCDField
      FieldName = 'GRA_VALOR'
      Origin = 'GRADES.GRA_VALOR'
      Precision = 9
      Size = 2
    end
    object IBQRGradesGRA_TAM: TIntegerField
      FieldName = 'GRA_TAM'
      Origin = 'GRADES.GRA_TAM'
    end
    object IBQRGradesGRA_QUANTIDADE: TIBBCDField
      FieldName = 'GRA_QUANTIDADE'
      Origin = 'GRADES.GRA_QUANTIDADE'
      Precision = 9
      Size = 2
    end
    object IBQRGradesTAM_TAMANHO: TIBStringField
      FieldName = 'TAM_TAMANHO'
      Origin = 'TAMANHOS.TAM_TAMANHO'
      Size = 25
    end
    object IBQRGradesTAM_SIGLA: TIBStringField
      FieldName = 'TAM_SIGLA'
      Origin = 'TAMANHOS.TAM_SIGLA'
      Size = 2
    end
    object IBQRGradesGRA_CODBARRA: TIBStringField
      FieldName = 'GRA_CODBARRA'
      Origin = 'GRADES.GRA_CODBARRA'
      Size = 30
    end
  end
  object ActionList1: TActionList
    Left = 216
    Top = 136
    object ActSair: TAction
      Caption = 'ESC - Sair'
      OnExecute = ActSairExecute
    end
    object ActSelecionar: TAction
      Caption = 'ENTER - Selecionar Grade'
      OnExecute = ActSelecionarExecute
    end
  end
end
