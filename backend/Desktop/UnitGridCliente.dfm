object FrmGridCliente: TFrmGridCliente
  Left = 297
  Top = 151
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'LOCALIZADOR'
  ClientHeight = 472
  ClientWidth = 589
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWhite
  Font.Height = -11
  Font.Name = 'Arial'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  DesignSize = (
    589
    472)
  PixelsPerInch = 96
  TextHeight = 14
  object panel3: TPanel
    Left = 3
    Top = 297
    Width = 583
    Height = 48
    Alignment = taLeftJustify
    Anchors = [akLeft, akRight, akBottom]
    BevelInner = bvSpace
    BevelOuter = bvNone
    Color = 6249820
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentFont = False
    TabOrder = 1
    object DBText2: TDBText
      Left = 337
      Top = 22
      Width = 120
      Height = 16
      DataField = 'RG'
      DataSource = DSGrid
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object DBText3: TDBText
      Left = 465
      Top = 22
      Width = 120
      Height = 16
      DataField = 'CELULAR'
      DataSource = DSGrid
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object DBText4: TDBText
      Left = 1
      Top = 22
      Width = 328
      Height = 16
      DataField = 'ENDERECO'
      DataSource = DSGrid
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label2: TLabel
      Left = 337
      Top = 4
      Width = 23
      Height = 16
      Caption = 'RG'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6812638
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 465
      Top = 4
      Width = 50
      Height = 16
      Caption = 'Celular'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6812638
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 1
      Top = 4
      Width = 68
      Height = 16
      Caption = 'Endere'#231'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6812638
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object DBGrid1: TDBGrid
    Left = 3
    Top = 0
    Width = 583
    Height = 293
    Anchors = [akLeft, akTop, akRight, akBottom]
    Color = 15856371
    DataSource = DSGrid
    DrawingStyle = gdsGradient
    GradientEndColor = 5065546
    GradientStartColor = 10724259
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = 6812638
    TitleFont.Height = -11
    TitleFont.Name = 'MS Sans Serif'
    TitleFont.Style = [fsBold]
    OnDrawColumnCell = DBGrid1DrawColumnCell
    OnDblClick = DBGrid1DblClick
    Columns = <
      item
        Expanded = False
        FieldName = 'CODIGO'
        Width = 59
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'NOME'
        Width = 281
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CPF_CNPJ'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'FONE'
        Width = 94
        Visible = True
      end>
  end
  object Panel1: TPanel
    Left = 3
    Top = 349
    Width = 583
    Height = 84
    Anchors = [akLeft, akRight, akBottom]
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Arial'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    TabOrder = 2
    object RadioGroup1: TRadioGroup
      Left = 277
      Top = 9
      Width = 298
      Height = 69
      Caption = 'Filtros de Busca'
      Columns = 3
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ItemIndex = 1
      Items.Strings = (
        'C'#243'digo'
        'Nome'
        'CPF/CNPJ'
        'RG'
        'Telefone'
        'Celular')
      ParentFont = False
      TabOrder = 0
      OnClick = RadioGroup1Click
    end
    object EDT: TMaskEdit
      Left = 4
      Top = 53
      Width = 267
      Height = 25
      BevelInner = bvLowered
      BevelOuter = bvSpace
      BevelKind = bkSoft
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = 15856371
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      Text = ''
      OnKeyDown = EdtKeyDown
      OnKeyPress = EdtKeyPress
    end
  end
  object ToolBar2: TToolBar
    Left = 0
    Top = 434
    Width = 589
    Height = 38
    Align = alBottom
    ButtonHeight = 38
    ButtonWidth = 162
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
    TabOrder = 3
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
      AutoSize = True
    end
    object ToolButton5: TToolButton
      Left = 114
      Top = 0
      Width = 8
      Caption = 'ToolButton7'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton1: TToolButton
      Left = 122
      Top = 0
      Action = actSelecionarCliente
      AutoSize = True
    end
    object ToolButton2: TToolButton
      Left = 288
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 3
      Style = tbsSeparator
    end
    object ToolButton6: TToolButton
      Left = 296
      Top = 0
      Action = actAlternarFiltro
      AutoSize = True
    end
    object ToolButton7: TToolButton
      Left = 458
      Top = 0
      Width = 8
      Caption = 'ToolButton7'
      ImageIndex = 4
      Style = tbsSeparator
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
    DataSet = IBQRGrid
    Left = 192
    Top = 48
  end
  object IBQRGrid: TIBQuery
    Database = DMPrincipal.IBDBPrincipal
    Transaction = DMPrincipal.IBTransPrincipal
    BufferChunks = 1000
    CachedUpdates = True
    ParamCheck = True
    SQL.Strings = (
      
        'SELECT CLI_CODIGO AS CODIGO, CLI_NOME AS NOME, CLI_CNPJ_CPF AS C' +
        'PF_CNPJ, CLI_RG AS RG, CLI_FONE AS FONE, CLI_CELULAR AS CELULAR,' +
        ' CLI_ENDERECO AS ENDERECO, CLI_SITUACAO, CLI_PLANO, CLI_NOTA'
      ''
      'FROM CLIENTES'
      ''
      'WHERE (CLI_NOME LIKE :NOME) ')
    Left = 226
    Top = 48
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'NOME'
        ParamType = ptUnknown
      end>
    object IBQRGridCODIGO: TIntegerField
      FieldName = 'CODIGO'
      Origin = 'CLIENTES.CLI_CODIGO'
      Required = True
    end
    object IBQRGridNOME: TIBStringField
      FieldName = 'NOME'
      Origin = 'CLIENTES.CLI_NOME'
      Required = True
      Size = 50
    end
    object IBQRGridCPF_CNPJ: TIBStringField
      FieldName = 'CPF_CNPJ'
      Origin = 'CLIENTES.CLI_CNPJ_CPF'
      Size = 18
    end
    object IBQRGridRG: TIBStringField
      FieldName = 'RG'
      Origin = 'CLIENTES.CLI_RG'
      Size = 18
    end
    object IBQRGridENDERECO: TIBStringField
      FieldName = 'ENDERECO'
      Origin = 'CLIENTES.CLI_ENDERECO'
      Size = 50
    end
    object IBQRGridCLI_SITUACAO: TIBStringField
      FieldName = 'CLI_SITUACAO'
      Origin = 'CLIENTES.CLI_SITUACAO'
      Size = 15
    end
    object IBQRGridCLI_PLANO: TSmallintField
      FieldName = 'CLI_PLANO'
      Origin = 'CLIENTES.CLI_PLANO'
    end
    object IBQRGridCLI_NOTA: TIBStringField
      FieldName = 'CLI_NOTA'
      Origin = 'CLIENTES.CLI_NOTA'
      Size = 6
    end
    object IBQRGridCELULAR: TIBStringField
      FieldName = 'CELULAR'
      Origin = 'CLIENTES.CLI_CELULAR'
      Size = 14
    end
    object IBQRGridFONE: TIBStringField
      FieldName = 'FONE'
      Origin = 'CLIENTES.CLI_FONE'
      Size = 14
    end
  end
  object ActionList1: TActionList
    Images = DMPrincipal.Icones_Pretos
    Left = 432
    Top = 112
    object actSair: TAction
      Caption = 'Esc - &Sair'
      ImageIndex = 171
      OnExecute = actSairExecute
    end
    object actSelecionarCliente: TAction
      Caption = 'Enter - Sel. Cliente'
      ImageIndex = 1
      OnExecute = actSelecionarClienteExecute
    end
    object actAlternarFiltro: TAction
      Caption = '&F2 - &Alternar Filtro'
      ImageIndex = 46
      OnExecute = actAlternarFiltroExecute
    end
  end
end
