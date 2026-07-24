object FrmCadEstado: TFrmCadEstado
  Left = 189
  Top = 118
  Caption = 'Cadastro de Estados (UF)'
  ClientHeight = 460
  ClientWidth = 587
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  DesignSize = (
    587
    460)
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 8
    Top = 37
    Width = 576
    Height = 66
    BevelInner = bvSpace
    Color = clWhite
    ParentBackground = False
    TabOrder = 4
  end
  object GroupBox1: TGroupBox
    Left = 5
    Top = 40
    Width = 576
    Height = 59
    Caption = 'Dados Gerais'
    Color = clWhite
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentBackground = False
    ParentColor = False
    ParentFont = False
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 16
      Width = 40
      Height = 13
      Caption = 'C'#243'digo'
    end
    object Label2: TLabel
      Left = 65
      Top = 16
      Width = 38
      Height = 13
      Caption = '*Nome'
    end
    object Label3: TLabel
      Left = 503
      Top = 16
      Width = 65
      Height = 13
      Caption = '*C'#243'd. IBGE'
    end
    object DBText1: TDBText
      Left = 8
      Top = 32
      Width = 41
      Height = 17
      Alignment = taCenter
      DataField = 'EST_CODIGO'
      DataSource = DSEstado
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 450
      Top = 16
      Width = 34
      Height = 13
      Caption = '*Sigla'
    end
    object DBEdit2: TDBEdit
      Left = 66
      Top = 33
      Width = 378
      Height = 20
      BevelInner = bvLowered
      BevelOuter = bvSpace
      BevelKind = bkSoft
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = 15856371
      DataField = 'EST_NOME'
      DataSource = DSEstado
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object DBEdit9: TDBEdit
      Left = 506
      Top = 33
      Width = 60
      Height = 20
      BevelInner = bvLowered
      BevelOuter = bvSpace
      BevelKind = bkSoft
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = 15856371
      DataField = 'EST_CODIGO_IBGE'
      DataSource = DSEstado
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
    end
    object DBEdit1: TDBEdit
      Left = 453
      Top = 33
      Width = 39
      Height = 20
      BevelInner = bvLowered
      BevelOuter = bvSpace
      BevelKind = bkSoft
      BorderStyle = bsNone
      CharCase = ecUpperCase
      Color = 15856371
      DataField = 'EST_SIGLA'
      DataSource = DSEstado
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
    end
  end
  object DBGrid1: TDBGrid
    Left = 4
    Top = 105
    Width = 578
    Height = 312
    Anchors = [akLeft, akTop, akBottom]
    Color = 15856371
    DataSource = DSEstado
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
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = 6812638
    TitleFont.Height = -13
    TitleFont.Name = 'Arial'
    TitleFont.Style = [fsBold]
    OnDrawColumnCell = DBGrid1DrawColumnCell
    Columns = <
      item
        Expanded = False
        FieldName = 'EST_CODIGO'
        Title.Caption = 'CODIGO'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'EST_NOME'
        Title.Caption = 'NOME'
        Width = 348
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'EST_SIGLA'
        Title.Caption = 'SIGLA'
        Width = 48
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'EST_CODIGO_IBGE'
        Title.Caption = 'COD IBGE'
        Width = 81
        Visible = True
      end>
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 587
    Height = 38
    ButtonHeight = 38
    ButtonWidth = 106
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
    TabOrder = 2
    object ToolButton1: TToolButton
      Left = 0
      Top = 0
      Width = 8
      Caption = 'ToolButton1'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton6: TToolButton
      Left = 8
      Top = 0
      Action = actInserir
    end
    object ToolButton7: TToolButton
      Left = 114
      Top = 0
      Width = 8
      Caption = 'ToolButton7'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton8: TToolButton
      Left = 122
      Top = 0
      Action = actExcluir
    end
    object ToolButton9: TToolButton
      Left = 228
      Top = 0
      Width = 8
      Caption = 'ToolButton9'
      ImageIndex = 3
      Style = tbsSeparator
    end
    object ToolButton10: TToolButton
      Left = 236
      Top = 0
      Action = actConfirmar
    end
    object ToolButton11: TToolButton
      Left = 342
      Top = 0
      Width = 8
      Caption = 'ToolButton11'
      ImageIndex = 4
      Style = tbsSeparator
    end
    object ToolButton12: TToolButton
      Left = 350
      Top = 0
      Action = actCancelar
    end
    object ToolButton13: TToolButton
      Left = 456
      Top = 0
      Width = 8
      Caption = 'ToolButton13'
      ImageIndex = 5
      Style = tbsSeparator
    end
    object ToolButton14: TToolButton
      Left = 464
      Top = 0
      Action = actEditar
    end
    object ToolButton2: TToolButton
      Left = 570
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 135
      Style = tbsSeparator
    end
  end
  object ToolBar2: TToolBar
    Left = 0
    Top = 422
    Width = 587
    Height = 38
    Align = alBottom
    ButtonHeight = 38
    ButtonWidth = 102
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
    end
    object ToolButton5: TToolButton
      Left = 110
      Top = 0
      Width = 8
      Caption = 'ToolButton7'
      ImageIndex = 2
      Style = tbsSeparator
    end
  end
  object DSEstado: TDataSource
    DataSet = IBDSEstado
    OnStateChange = DSEstadoStateChange
    Left = 232
    Top = 9
  end
  object IBDSEstado: TIBDataSet
    Database = DMPrincipal.IBDBPrincipal
    Transaction = DMPrincipal.IBTransPrincipal
    BufferChunks = 1000
    CachedUpdates = True
    DeleteSQL.Strings = (
      'delete from ESTADOS'
      'where'
      '  EST_CODIGO = :OLD_EST_CODIGO')
    InsertSQL.Strings = (
      'insert into ESTADOS'
      '  (EST_CODIGO, EST_SIGLA, EST_NOME, EST_CODIGO_IBGE)'
      'values'
      '  (:EST_CODIGO, :EST_SIGLA, :EST_NOME, :EST_CODIGO_IBGE)')
    RefreshSQL.Strings = (
      'Select '
      '  EST_CODIGO,'
      '  EST_SIGLA,'
      '  EST_NOME,'
      '  EST_CODIGO_IBGE'
      'from ESTADOS '
      'where'
      '  EST_CODIGO = :EST_CODIGO')
    SelectSQL.Strings = (
      'select * from ESTADOS'
      'order by EST_nome')
    ModifySQL.Strings = (
      'update ESTADOS'
      'set'
      '  EST_CODIGO = :EST_CODIGO,'
      '  EST_SIGLA = :EST_SIGLA,'
      '  EST_NOME = :EST_NOME,'
      '  EST_CODIGO_IBGE = :EST_CODIGO_IBGE'
      'where'
      '  EST_CODIGO = :OLD_EST_CODIGO')
    ParamCheck = True
    UniDirectional = False
    Left = 200
    Top = 9
    object IBDSEstadoEST_CODIGO: TIntegerField
      FieldName = 'EST_CODIGO'
      Origin = 'ESTADOS.EST_CODIGO'
      Required = True
    end
    object IBDSEstadoEST_SIGLA: TIBStringField
      FieldName = 'EST_SIGLA'
      Origin = 'ESTADOS.EST_SIGLA'
      FixedChar = True
      Size = 2
    end
    object IBDSEstadoEST_NOME: TIBStringField
      FieldName = 'EST_NOME'
      Origin = 'ESTADOS.EST_NOME'
      Size = 100
    end
    object IBDSEstadoEST_CODIGO_IBGE: TIntegerField
      FieldName = 'EST_CODIGO_IBGE'
      Origin = 'ESTADOS.EST_CODIGO_IBGE'
    end
  end
  object ActionList1: TActionList
    Images = DMPrincipal.Icones_Pretos
    Left = 88
    Top = 40
    object actInserir: TAction
      Caption = '&Inserir'
      ImageIndex = 141
      OnExecute = actInserirExecute
    end
    object actExcluir: TAction
      Caption = 'E&xcluir'
      ImageIndex = 185
      OnExecute = actExcluirExecute
    end
    object actConfirmar: TAction
      Caption = 'C&onfirmar'
      ImageIndex = 160
      OnExecute = actConfirmarExecute
    end
    object actCancelar: TAction
      Caption = '&Cancelar'
      ImageIndex = 154
      OnExecute = actCancelarExecute
    end
    object actEditar: TAction
      Caption = '&Editar'
      ImageIndex = 134
      OnExecute = actEditarExecute
    end
    object actSair: TAction
      Caption = 'Esc - &Sair'
      ImageIndex = 171
      OnExecute = actSairExecute
    end
    object actPesquisa: TAction
      Caption = '&F9 - &Pesquisa'
      ImageIndex = 164
    end
  end
end
