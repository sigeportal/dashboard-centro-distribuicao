inherited FrmBuscaPedidoRemoto: TFrmBuscaPedidoRemoto
  Caption = 'Busca de Pedidos'
  ClientHeight = 527
  ClientWidth = 862
  ExplicitWidth = 878
  ExplicitHeight = 566
  PixelsPerInch = 96
  TextHeight = 16
  inherited ToolBar2: TToolBar
    Top = 505
    Width = 862
    ExplicitTop = 505
    ExplicitWidth = 793
    inherited ToolButton4: TToolButton
      ExplicitWidth = 75
    end
  end
  inherited Panel1: TPanel
    Width = 856
    Height = 499
    ExplicitWidth = 787
    ExplicitHeight = 499
    object Panel2: TPanel
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 848
      Height = 61
      Align = alTop
      TabOrder = 0
      ExplicitWidth = 779
      object RGBuscaPedidos: TRadioGroup
        Left = 4
        Top = 0
        Width = 210
        Height = 53
        Caption = 'Busca Pedidos'
        Columns = 2
        ItemIndex = 0
        Items.Strings = (
          'Abertos'
          'Fechados')
        TabOrder = 0
        OnClick = RGBuscaPedidosClick
      end
    end
    object Panel3: TPanel
      AlignWithMargins = True
      Left = 4
      Top = 263
      Width = 848
      Height = 232
      Align = alClient
      TabOrder = 1
      ExplicitWidth = 779
      object Label3: TLabel
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 37
        Height = 19
        Align = alTop
        Caption = 'Itens'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DBGrid1: TDBGrid
        AlignWithMargins = True
        Left = 4
        Top = 29
        Width = 840
        Height = 199
        Align = alClient
        DataSource = DSPedEst
        DrawingStyle = gdsGradient
        GradientEndColor = 5065546
        GradientStartColor = 10724259
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
        ParentFont = False
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = 6812638
        TitleFont.Height = -13
        TitleFont.Name = 'Arial'
        TitleFont.Style = [fsBold]
        OnDrawColumnCell = DBGrid1DrawColumnCell
        Columns = <
          item
            Expanded = False
            FieldName = 'CODIGO'
            Width = 60
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'COD_PRO'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'COD_BARRAS'
            Width = 123
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'NOME'
            Width = 241
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'TAM_SIGLA'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'QUANTIDADE'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'VALOR_UNIT'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'VALOR'
            Visible = True
          end>
      end
    end
    object Panel4: TPanel
      AlignWithMargins = True
      Left = 4
      Top = 71
      Width = 848
      Height = 186
      Align = alTop
      TabOrder = 2
      ExplicitWidth = 779
      object DBGrid2: TDBGrid
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 840
        Height = 178
        Align = alClient
        DataSource = DSPedidos
        DrawingStyle = gdsGradient
        GradientEndColor = 5065546
        GradientStartColor = 10724259
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
        ParentFont = False
        PopupMenu = PopupMenu1
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = 6812638
        TitleFont.Height = -13
        TitleFont.Name = 'Arial'
        TitleFont.Style = [fsBold]
        OnDrawColumnCell = DBGrid2DrawColumnCell
        OnKeyPress = DBGrid2KeyPress
        Columns = <
          item
            Expanded = False
            FieldName = 'CODIGO'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'DATA'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'VALOR'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'FORNECEDOR'
            Width = 582
            Visible = True
          end>
      end
    end
  end
  inherited ActionList1: TActionList
    object actSelecionarVendedor: TAction
      Caption = 'F1 - Sel. Vendedor'
      ImageIndex = 8
      ShortCut = 112
    end
  end
  object MemPedidos: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 248
    Top = 136
    object MemPedidosCODIGO: TIntegerField
      FieldName = 'CODIGO'
    end
    object MemPedidosDATA: TDateField
      FieldName = 'DATA'
      DisplayFormat = 'dd/mm/yyyy'
    end
    object MemPedidosVALOR: TCurrencyField
      FieldName = 'VALOR'
      DisplayFormat = ',0.00'
    end
    object MemPedidosFORNECEDOR: TStringField
      FieldName = 'FORNECEDOR'
      Size = 200
    end
  end
  object DSPedidos: TDataSource
    DataSet = MemPedidos
    OnDataChange = DSPedidosDataChange
    Left = 248
    Top = 184
  end
  object MemPedEst: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 256
    Top = 288
    object MemPedEstCODIGO: TIntegerField
      FieldName = 'CODIGO'
    end
    object MemPedEstNOME: TStringField
      FieldName = 'NOME'
      Size = 200
    end
    object MemPedEstQUANTIDADE: TFloatField
      DisplayLabel = 'QTD'
      FieldName = 'QUANTIDADE'
      DisplayFormat = '0.00'
    end
    object MemPedEstVALOR_UNIT: TCurrencyField
      DisplayLabel = 'VLR UNIT'
      FieldName = 'VALOR_UNIT'
      DisplayFormat = ',0.00'
    end
    object MemPedEstVALOR: TCurrencyField
      FieldName = 'VALOR'
      DisplayFormat = ',0.00'
    end
    object MemPedEstCOD_PRO: TIntegerField
      DisplayLabel = 'COD. PROD.'
      FieldName = 'COD_PRO'
    end
    object MemPedEstCOD_PEDIDO: TIntegerField
      FieldName = 'COD_PEDIDO'
    end
    object MemPedEstCOD_BARRAS: TStringField
      DisplayLabel = 'COD. BARRAS'
      FieldName = 'COD_BARRAS'
      Size = 30
    end
    object MemPedEstTAM_SIGLA: TStringField
      DisplayLabel = 'TAM.'
      FieldName = 'TAM_SIGLA'
      Size = 10
    end
  end
  object DSPedEst: TDataSource
    DataSet = MemPedEst
    Left = 256
    Top = 336
  end
  object PopupMenu1: TPopupMenu
    Left = 512
    Top = 168
    object Excluir1: TMenuItem
      Caption = '&Excluir'
      OnClick = Excluir1Click
    end
  end
end
