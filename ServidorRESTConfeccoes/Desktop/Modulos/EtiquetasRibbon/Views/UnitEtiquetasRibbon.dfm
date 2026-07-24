object FrmEtiquetasRibbon: TFrmEtiquetasRibbon
  Left = 367
  Top = 289
  Caption = 'Impress'#227'o de Etiqueta na Impressora Bematech'
  ClientHeight = 433
  ClientWidth = 362
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -16
  Font.Name = 'Arial'
  Font.Style = [fsBold]
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 19
  object Label1: TLabel
    Left = 120
    Top = 47
    Width = 120
    Height = 19
    Caption = 'Valor Parcelado'
  end
  object Label5: TLabel
    Left = 8
    Top = 0
    Width = 56
    Height = 19
    Caption = 'C'#243'digo'
  end
  object Label8: TLabel
    Left = 264
    Top = 47
    Width = 88
    Height = 19
    Caption = 'N Etiquetas'
  end
  object Shape5: TShape
    Left = 6
    Top = 19
    Width = 76
    Height = 24
    Shape = stRoundRect
  end
  object Shape1: TShape
    Left = 118
    Top = 66
    Width = 127
    Height = 24
    Shape = stRoundRect
  end
  object Shape3: TShape
    Left = 262
    Top = 66
    Width = 92
    Height = 24
    Shape = stRoundRect
  end
  object Label2: TLabel
    Left = 8
    Top = 47
    Width = 94
    Height = 19
    Caption = 'Valor '#224' Vista'
  end
  object Shape2: TShape
    Left = 6
    Top = 66
    Width = 99
    Height = 24
    Shape = stRoundRect
  end
  object Shape4: TShape
    Left = 170
    Top = 354
    Width = 184
    Height = 24
    Shape = stRoundRect
  end
  object Label4: TLabel
    Left = 8
    Top = 356
    Width = 159
    Height = 19
    Caption = 'Caminho impressora'
  end
  object Shape6: TShape
    Left = 94
    Top = 19
    Width = 260
    Height = 24
    Shape = stRoundRect
  end
  object Label3: TLabel
    Left = 96
    Top = 0
    Width = 45
    Height = 19
    Caption = 'Nome'
  end
  object BtnAlternaFiltro: TSpeedButton
    Left = 68
    Top = 3
    Width = 14
    Height = 14
    Hint = 'Alternar para Fatura de Compra'
    ParentShowHint = False
    ShowHint = True
    OnClick = BtnAlternaFiltroClick
  end
  object Label6: TLabel
    Left = 5
    Top = 300
    Width = 169
    Height = 19
    Caption = 'Modelo da impressora'
  end
  object EdtValorPrazo: TEdit
    Left = 121
    Top = 69
    Width = 121
    Height = 18
    BorderStyle = bsNone
    Color = clWhite
    ReadOnly = True
    TabOrder = 3
  end
  object EdtCodigo: TEdit
    Left = 9
    Top = 22
    Width = 70
    Height = 18
    BorderStyle = bsNone
    Color = clWhite
    TabOrder = 0
    OnKeyDown = EdtCodigoKeyDown
    OnKeyPress = EdtCodigoKeyPress
  end
  object EdtNEtiquetas: TEdit
    Left = 265
    Top = 69
    Width = 86
    Height = 18
    BorderStyle = bsNone
    Color = clWhite
    TabOrder = 4
    Text = '1'
    OnKeyPress = EdtNEtiquetasKeyPress
  end
  object EdtValorVista: TEdit
    Left = 9
    Top = 69
    Width = 93
    Height = 18
    BorderStyle = bsNone
    Color = clWhite
    ReadOnly = True
    TabOrder = 2
  end
  object BtnImprimir: TBitBtn
    Left = 136
    Top = 383
    Width = 217
    Height = 48
    Caption = '&Imprimir'
    TabOrder = 8
    OnClick = BtnImprimirClick
  end
  object EdtCaminho: TEdit
    Left = 173
    Top = 357
    Width = 178
    Height = 18
    BorderStyle = bsNone
    Color = clWhite
    TabOrder = 7
    Text = 'LPT1'
  end
  object EdtNome: TEdit
    Left = 97
    Top = 22
    Width = 254
    Height = 18
    BorderStyle = bsNone
    Color = clWhite
    ReadOnly = True
    TabOrder = 1
  end
  object DBGrid1: TDBGrid
    Left = 5
    Top = 96
    Width = 349
    Height = 197
    DataSource = DSEtiquetas
    DrawingStyle = gdsGradient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentFont = False
    PopupMenu = PopupMenu1
    TabOrder = 5
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -13
    TitleFont.Name = 'Arial'
    TitleFont.Style = [fsBold]
    OnKeyDown = DBGrid1KeyDown
    OnKeyPress = DBGrid1KeyPress
    Columns = <
      item
        Expanded = False
        FieldName = 'CODIGO'
        Width = 56
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'NOME'
        Width = 222
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'QTD_ETIQ'
        Title.Caption = 'QTD'
        Width = 31
        Visible = True
      end>
  end
  object CbxModeloImpressora: TComboBox
    Left = 6
    Top = 320
    Width = 348
    Height = 27
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 6
    Text = 'Bematech 3 Colunas'
    OnChange = CbxModeloImpressoraChange
    Items.Strings = (
      'Bematech 3 Colunas'
      'Zebra 3 Colunas')
  end
  object CDSEtiquetas: TClientDataSet
    Aggregates = <>
    Params = <>
    AfterPost = CDSEtiquetasAfterPost
    AfterScroll = CDSEtiquetasAfterScroll
    Left = 128
    Top = 152
    object CDSEtiquetasCODIGO: TIntegerField
      FieldName = 'CODIGO'
    end
    object CDSEtiquetasNOME: TStringField
      FieldName = 'NOME'
      Size = 100
    end
    object CDSEtiquetasCOD_BARRA: TStringField
      FieldName = 'COD_BARRA'
    end
    object CDSEtiquetasVLR_VISTA: TCurrencyField
      FieldName = 'VLR_VISTA'
    end
    object CDSEtiquetasVLR_PRAZO: TCurrencyField
      FieldName = 'VLR_PRAZO'
    end
    object CDSEtiquetasQTD_ETIQ: TIntegerField
      FieldName = 'QTD_ETIQ'
    end
  end
  object DSEtiquetas: TDataSource
    DataSet = CDSEtiquetas
    Left = 160
    Top = 152
  end
  object PopupMenu1: TPopupMenu
    Left = 200
    Top = 152
    object Excluir1: TMenuItem
      Caption = 'Excluir'
      OnClick = Excluir1Click
    end
  end
  object IBQRCompra: TIBQuery
    Database = DMPrincipal.IBDBPrincipal
    Transaction = DMPrincipal.IBTransPrincipal
    BufferChunks = 1000
    CachedUpdates = True
    ParamCheck = True
    SQL.Strings = (
      
        'SELECT PRO_CODIGO, PRO_NOME, PRO_VALORV, PRO_VALORV_PRAZO, PRO_C' +
        'ODBARRA, CE_QUANTIDADE'
      ''
      
        'FROM FATURAMENTO2 JOIN COMPRAS ON ((FAT2_TIPO = 1) AND (FAT2_DES' +
        'CRICAO = COM_CODIGO))'
      'JOIN COM_EST ON COM_CODIGO = CE_COM'
      'JOIN PRODUTOS ON CE_PRO = PRO_CODIGO'
      ''
      'WHERE FAT2_CODIGO = :FATURA'
      ''
      'ORDER BY CE_CODIGO')
    Left = 128
    Top = 208
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'FATURA'
        ParamType = ptUnknown
      end>
    object IBQRCompraPRO_CODIGO: TIntegerField
      FieldName = 'PRO_CODIGO'
      Origin = 'PRODUTOS.PRO_CODIGO'
      Required = True
    end
    object IBQRCompraPRO_NOME: TIBStringField
      FieldName = 'PRO_NOME'
      Origin = 'PRODUTOS.PRO_NOME'
      Size = 50
    end
    object IBQRCompraPRO_VALORV: TIBBCDField
      FieldName = 'PRO_VALORV'
      Origin = 'PRODUTOS.PRO_VALORV'
      Precision = 9
      Size = 4
    end
    object IBQRCompraPRO_VALORV_PRAZO: TIBBCDField
      FieldName = 'PRO_VALORV_PRAZO'
      Origin = 'PRODUTOS.PRO_VALORV_PRAZO'
      Precision = 9
      Size = 4
    end
    object IBQRCompraCE_QUANTIDADE: TIBBCDField
      FieldName = 'CE_QUANTIDADE'
      Origin = 'COM_EST.CE_QUANTIDADE'
      Precision = 9
      Size = 2
    end
    object IBQRCompraPRO_CODBARRA: TIBStringField
      FieldName = 'PRO_CODBARRA'
      Origin = 'PRODUTOS.PRO_CODBARRA'
      Size = 30
    end
  end
end
