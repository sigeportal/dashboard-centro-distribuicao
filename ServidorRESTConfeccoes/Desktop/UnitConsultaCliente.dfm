object FrmConsultaCliente: TFrmConsultaCliente
  Left = 224
  Top = 33
  Caption = 'Consulta Cliente'
  ClientHeight = 589
  ClientWidth = 929
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsMDIChild
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  Visible = True
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object ToolBar2: TToolBar
    Left = 0
    Top = 551
    Width = 929
    Height = 38
    Align = alBottom
    ButtonHeight = 38
    ButtonWidth = 184
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
    TabOrder = 0
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
    object ToolButton17: TToolButton
      Left = 122
      Top = 0
      Action = actPesquisa
      AutoSize = True
    end
    object ToolButton18: TToolButton
      Left = 253
      Top = 0
      Width = 8
      Caption = 'ToolButton11'
      ImageIndex = 4
      Style = tbsSeparator
    end
    object ToolButton1: TToolButton
      Left = 261
      Top = 0
      Action = actImprimirProdutos
      AutoSize = True
    end
    object ToolButton2: TToolButton
      Left = 449
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 103
      Style = tbsSeparator
    end
  end
  object Panel1: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 923
    Height = 111
    Align = alTop
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object DBText1: TDBText
      Left = 4
      Top = 35
      Width = 255
      Height = 17
      Color = clWhite
      DataField = 'CLI_NOME'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBText10: TDBText
      Left = 376
      Top = 83
      Width = 104
      Height = 17
      DataField = 'CLI_FONE'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object DBText11: TDBText
      Left = 535
      Top = 83
      Width = 128
      Height = 17
      Color = clWhite
      DataField = 'CLI_CELULAR'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBText12: TDBText
      Left = 683
      Top = 83
      Width = 176
      Height = 17
      Color = clWhite
      DataField = 'CLI_CNPJ_CPF'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBText2: TDBText
      Left = 576
      Top = 35
      Width = 65
      Height = 17
      Color = clWhite
      DataField = 'CLI_NOTA'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBText3: TDBText
      Left = 268
      Top = 35
      Width = 104
      Height = 17
      Color = clWhite
      DataField = 'CLI_FIDELIDADE'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBText4: TDBText
      Left = 376
      Top = 35
      Width = 65
      Height = 17
      Color = clWhite
      DataField = 'CLI_INADIMPLENCIA'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBText5: TDBText
      Left = 488
      Top = 35
      Width = 65
      Height = 17
      Color = clWhite
      DataField = 'CLI_DESCONTO'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBText7: TDBText
      Left = 683
      Top = 35
      Width = 112
      Height = 17
      Color = clWhite
      DataField = 'CLI_SITUACAO'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBText8: TDBText
      Left = 800
      Top = 35
      Width = 106
      Height = 17
      Color = clWhite
      DataField = 'CLI_LIMITE'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object DBText9: TDBText
      Left = 4
      Top = 83
      Width = 366
      Height = 17
      Color = clWhite
      DataField = 'CLI_ENDERECO'
      DataSource = DSFaturada
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
    end
    object Label1: TLabel
      Left = 4
      Top = 15
      Width = 45
      Height = 16
      Caption = 'Cliente'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label10: TLabel
      Left = 800
      Top = 15
      Width = 42
      Height = 16
      Caption = 'Limite'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label11: TLabel
      Left = 4
      Top = 65
      Width = 60
      Height = 16
      Caption = 'Endere'#231'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label12: TLabel
      Left = 376
      Top = 65
      Width = 59
      Height = 16
      Caption = 'Telefone '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label13: TLabel
      Left = 535
      Top = 65
      Width = 46
      Height = 16
      Caption = 'Celular'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label14: TLabel
      Left = 683
      Top = 65
      Width = 26
      Height = 16
      Caption = 'CPF'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label3: TLabel
      Left = 576
      Top = 15
      Width = 83
      Height = 16
      Caption = 'Classifica'#231#227'o'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label4: TLabel
      Left = 268
      Top = 15
      Width = 68
      Height = 16
      Caption = 'Fidelidade'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label5: TLabel
      Left = 376
      Top = 15
      Width = 91
      Height = 16
      Caption = 'Inadimpl'#234'ncia'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label6: TLabel
      Left = 488
      Top = 15
      Width = 58
      Height = 16
      Caption = 'Desconto'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label8: TLabel
      Left = 683
      Top = 15
      Width = 60
      Height = 16
      Caption = 'Situa'#231#227'o '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object Panel2: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 117
    Width = 923
    Height = 212
    Margins.Top = 0
    Margins.Bottom = 0
    Align = alClient
    BevelInner = bvSpace
    Color = 15856371
    ParentBackground = False
    TabOrder = 2
    object GroupBox1: TGroupBox
      Left = 2
      Top = 2
      Width = 919
      Height = 208
      Align = alClient
      Caption = 'Faturadas'
      Color = 15856371
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentColor = False
      ParentFont = False
      TabOrder = 0
      object Label15: TLabel
        Left = 1360
        Top = 166
        Width = 72
        Height = 16
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label17: TLabel
        Left = 800
        Top = 186
        Width = 78
        Height = 19
        Alignment = taRightJustify
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 6249820
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label24: TLabel
        Left = 684
        Top = 146
        Width = 46
        Height = 16
        Caption = 'Juros : '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label25: TLabel
        Left = 814
        Top = 146
        Width = 64
        Height = 16
        Alignment = taRightJustify
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 6249820
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label26: TLabel
        Left = 649
        Top = 186
        Width = 78
        Height = 19
        Alignment = taRightJustify
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label27: TLabel
        Left = 684
        Top = 127
        Width = 41
        Height = 16
        Caption = 'Valor :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label28: TLabel
        Left = 814
        Top = 127
        Width = 64
        Height = 16
        Alignment = taRightJustify
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 6249820
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label30: TLabel
        Left = 663
        Top = 166
        Width = 63
        Height = 16
        Caption = 'Cheques :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label31: TLabel
        Left = 814
        Top = 166
        Width = 64
        Height = 16
        Alignment = taRightJustify
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 6249820
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DBGrid1: TDBGrid
        Left = 4
        Top = 16
        Width = 908
        Height = 110
        Color = 15856371
        DataSource = DSFaturada
        DrawingStyle = gdsGradient
        GradientEndColor = 5065546
        GradientStartColor = 10724259
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
        ParentFont = False
        PopupMenu = PopupMenu1
        ReadOnly = True
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
            FieldName = 'FAT_CODIGO'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'FATURA'
            Width = 62
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'REC_DUPLICATA'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'DUPLICATA'
            Width = 84
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'FAT_DATA'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'DATA'
            Width = 83
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'REC_VENCIMENTO'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'VENCIMENTO'
            Width = 87
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'REC_VALOR'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'VALOR'
            Width = 125
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'REC_JUROS'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'JUROS'
            Width = 74
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'REC_DESCONTOS'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'DESCONTOS'
            Width = 91
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'VALOR_TOTAL'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'TOTAL'
            Width = 124
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'REC_TIPO'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'TIPO'
            Width = 119
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'REC_DESCONTADO'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'D'
            Width = 21
            Visible = True
          end>
      end
    end
  end
  object Panel3: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 332
    Width = 923
    Height = 180
    Align = alBottom
    BevelInner = bvSpace
    Color = 15856371
    ParentBackground = False
    TabOrder = 3
    object GroupBox3: TGroupBox
      Left = 3
      Top = -1
      Width = 916
      Height = 187
      Caption = 'N Faturadas'
      Color = 15856371
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentColor = False
      ParentFont = False
      TabOrder = 0
      object Label16: TLabel
        Left = 644
        Top = 167
        Width = 78
        Height = 19
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label18: TLabel
        Left = 800
        Top = 166
        Width = 78
        Height = 19
        Alignment = taRightJustify
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 6249820
        Font.Height = -16
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label32: TLabel
        Left = 658
        Top = 145
        Width = 67
        Height = 16
        Caption = 'Cheques : '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label33: TLabel
        Left = 814
        Top = 145
        Width = 64
        Height = 16
        Alignment = taRightJustify
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 6249820
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label34: TLabel
        Left = 680
        Top = 126
        Width = 41
        Height = 16
        Caption = 'Valor :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label35: TLabel
        Left = 814
        Top = 126
        Width = 64
        Height = 16
        Alignment = taRightJustify
        Caption = 'SubTotal :'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 6249820
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DBGrid2: TDBGrid
        Left = 4
        Top = 16
        Width = 908
        Height = 110
        Color = 15856371
        DataSource = DSNFaturada
        DrawingStyle = gdsGradient
        GradientEndColor = 5065546
        GradientStartColor = 10724259
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit, dgTitleClick, dgTitleHotTrack]
        ParentFont = False
        ReadOnly = True
        TabOrder = 0
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = 6812638
        TitleFont.Height = -13
        TitleFont.Name = 'Arial'
        TitleFont.Style = [fsBold]
        OnDrawColumnCell = DBGrid2DrawColumnCell
        Columns = <
          item
            Expanded = False
            FieldName = 'PF_FAT'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'FATURA'
            Width = 59
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'PP_DUPLICATA'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'DUPLICATA'
            Width = 96
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'PF_DATA'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'DATA'
            Width = 81
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'PP_VENCIMENTO'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'VENCIMENTO'
            Width = 88
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'PP_VALOR'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'VALOR'
            Width = 124
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'PP_JUROS'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'JUROS'
            Width = 86
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'PP_DESCONTOS'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'DESCONTOS'
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'VALOR_TOTAL'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'TOTAL'
            Width = 134
            Visible = True
          end
          item
            Expanded = False
            FieldName = 'TP_DESCRICAO'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = [fsBold]
            Title.Caption = 'TIPO'
            Width = 119
            Visible = True
          end>
      end
    end
  end
  object Panel4: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 515
    Width = 923
    Height = 33
    Margins.Top = 0
    Align = alBottom
    BevelInner = bvSpace
    Color = 15856371
    ParentBackground = False
    TabOrder = 4
    object Label21: TLabel
      Left = 136
      Top = 5
      Width = 119
      Height = 20
      Caption = 'Valor vencido :'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6249820
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label7: TLabel
      Left = 8
      Top = 5
      Width = 119
      Height = 20
      Caption = 'Valor vencido :'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label22: TLabel
      Left = 272
      Top = 5
      Width = 126
      Height = 20
      Caption = 'Valor a vencer :'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label23: TLabel
      Left = 405
      Top = 5
      Width = 119
      Height = 20
      Caption = 'Valor vencido :'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6249820
      Font.Height = -16
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label19: TLabel
      Left = 616
      Top = 1
      Width = 120
      Height = 24
      Caption = 'Valor Total : '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object Label20: TLabel
      Left = 768
      Top = 1
      Width = 114
      Height = 24
      Alignment = taRightJustify
      Caption = 'Valor Total :'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6249820
      Font.Height = -19
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object IBQRFaturada: TIBQuery
    Database = DMPrincipal.IBDBPrincipal
    Transaction = DMPrincipal.IBTransPrincipal
    OnCalcFields = IBQRFaturadaCalcFields
    BufferChunks = 1000
    CachedUpdates = True
    ParamCheck = True
    SQL.Strings = (
      
        'SELECT F.FAT_CODIGO, C.CLI_CODIGO, C.CLI_NOME, F.FAT_DATA, C.CLI' +
        '_ENDERECO, C.CLI_FONE, C.CLI_CELULAR, C.CLI_CNPJ_CPF, C.CLI_PLAN' +
        'O, C.CLI_LIMITE, C.CLI_SITUACAO, C.CLI_FIDELIDADE, C.CLI_INADIMP' +
        'LENCIA, C.CLI_DESCONTO, C.CLI_NOTA, R.REC_CODIGO, R.REC_DUPLICAT' +
        'A, R.REC_VENCIMENTO, R.REC_JUROS, R.REC_DESCONTOS, R.REC_VALOR, ' +
        'R.REC_TIPO, R.REC_CON, R.REC_DATAR, R.REC_FPG, R.REC_DESCONTADO,' +
        ' R.REC_OBS, SUM(RP.RP_DINHEIRO + RP.RP_CHEQUE), T.TP_NOME'
      
        'FROM CLIENTES C, FATURAMENTOS F, RECEBIMENTOS R, REC_PGM RP, TIP' +
        'O_PGM T'
      
        'WHERE R.REC_CON = T.TP_CODIGO AND R.REC_CODIGO = RP.RP_REC AND F' +
        '.FAT_CLI = C.CLI_CODIGO AND F.FAT_CODIGO = R.REC_FAT AND (R.REC_' +
        'SITUACAO >= 0 AND R.REC_SITUACAO < 3) AND R.REC_ESTADO < 3 AND C' +
        '.CLI_CODIGO = :CLIENTE'
      
        'GROUP BY F.FAT_CODIGO, C.CLI_CODIGO, C.CLI_NOME, F.FAT_DATA, C.C' +
        'LI_ENDERECO, C.CLI_FONE, C.CLI_CELULAR, C.CLI_CNPJ_CPF, C.CLI_PL' +
        'ANO, C.CLI_LIMITE, C.CLI_SITUACAO, '
      
        'C.CLI_FIDELIDADE, C.CLI_INADIMPLENCIA, C.CLI_DESCONTO, C.CLI_NOT' +
        'A, R.REC_CODIGO, R.REC_DUPLICATA, R.REC_VENCIMENTO, R.REC_JUROS,' +
        ' R.REC_DESCONTOS, R.REC_VALOR,  R.REC_TIPO, R.REC_CON, R.REC_DAT' +
        'AR, R.REC_FPG, R.REC_DESCONTADO, R.REC_OBS, T.TP_NOME')
    Left = 232
    Top = 184
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CLIENTE'
        ParamType = ptUnknown
      end>
    object IBQRFaturadaFAT_CODIGO: TIntegerField
      FieldName = 'FAT_CODIGO'
      Origin = 'FATURAMENTOS.FAT_CODIGO'
      Required = True
    end
    object IBQRFaturadaCLI_CODIGO: TIntegerField
      FieldName = 'CLI_CODIGO'
      Origin = 'CLIENTES.CLI_CODIGO'
      Required = True
    end
    object IBQRFaturadaCLI_NOME: TIBStringField
      FieldName = 'CLI_NOME'
      Origin = 'CLIENTES.CLI_NOME'
      Required = True
      Size = 50
    end
    object IBQRFaturadaCLI_ENDERECO: TIBStringField
      FieldName = 'CLI_ENDERECO'
      Origin = 'CLIENTES.CLI_ENDERECO'
      Size = 50
    end
    object IBQRFaturadaCLI_PLANO: TSmallintField
      FieldName = 'CLI_PLANO'
      Origin = 'CLIENTES.CLI_PLANO'
    end
    object IBQRFaturadaCLI_LIMITE: TIBBCDField
      FieldName = 'CLI_LIMITE'
      Origin = 'CLIENTES.CLI_LIMITE'
      DisplayFormat = '0.00'
      EditFormat = '0.00'
      currency = True
      Precision = 9
      Size = 2
    end
    object IBQRFaturadaCLI_SITUACAO: TIBStringField
      FieldName = 'CLI_SITUACAO'
      Origin = 'CLIENTES.CLI_SITUACAO'
      Size = 15
    end
    object IBQRFaturadaREC_CODIGO: TIntegerField
      FieldName = 'REC_CODIGO'
      Origin = 'RECEBIMENTOS.REC_CODIGO'
      Required = True
    end
    object IBQRFaturadaREC_DUPLICATA: TIBStringField
      FieldName = 'REC_DUPLICATA'
      Origin = 'RECEBIMENTOS.REC_DUPLICATA'
      Size = 30
    end
    object IBQRFaturadaREC_VENCIMENTO: TDateField
      FieldName = 'REC_VENCIMENTO'
      Origin = 'RECEBIMENTOS.REC_VENCIMENTO'
    end
    object IBQRFaturadaREC_JUROS: TIBBCDField
      FieldName = 'REC_JUROS'
      Origin = 'RECEBIMENTOS.REC_JUROS'
      currency = True
      Precision = 9
      Size = 2
    end
    object IBQRFaturadaREC_DESCONTOS: TIBBCDField
      FieldName = 'REC_DESCONTOS'
      Origin = 'RECEBIMENTOS.REC_DESCONTOS'
      currency = True
      Precision = 9
      Size = 2
    end
    object IBQRFaturadaREC_VALOR: TIBBCDField
      FieldName = 'REC_VALOR'
      Origin = 'RECEBIMENTOS.REC_VALOR'
      currency = True
      Precision = 9
      Size = 2
    end
    object IBQRFaturadaREC_TIPO: TIBStringField
      FieldName = 'REC_TIPO'
      Origin = 'RECEBIMENTOS.REC_TIPO'
    end
    object IBQRFaturadaREC_CON: TSmallintField
      FieldName = 'REC_CON'
      Origin = 'RECEBIMENTOS.REC_CON'
    end
    object IBQRFaturadaREC_DATAR: TDateField
      FieldName = 'REC_DATAR'
      Origin = 'RECEBIMENTOS.REC_DATAR'
    end
    object IBQRFaturadaREC_FPG: TSmallintField
      FieldName = 'REC_FPG'
      Origin = 'RECEBIMENTOS.REC_FPG'
    end
    object IBQRFaturadaREC_DESCONTADO: TIBStringField
      FieldName = 'REC_DESCONTADO'
      Origin = 'RECEBIMENTOS.REC_DESCONTADO'
      Size = 2
    end
    object IBQRFaturadaREC_OBS: TIBStringField
      FieldName = 'REC_OBS'
      Origin = 'RECEBIMENTOS.REC_OBS'
      Size = 100
    end
    object IBQRFaturadaSUM: TIBBCDField
      FieldName = 'SUM'
      currency = True
      Precision = 18
      Size = 2
    end
    object IBQRFaturadaCLI_FIDELIDADE: TIBStringField
      FieldName = 'CLI_FIDELIDADE'
      Origin = 'CLIENTES.CLI_FIDELIDADE'
      Size = 15
    end
    object IBQRFaturadaCLI_INADIMPLENCIA: TSmallintField
      FieldName = 'CLI_INADIMPLENCIA'
      Origin = 'CLIENTES.CLI_INADIMPLENCIA'
    end
    object IBQRFaturadaCLI_DESCONTO: TIBBCDField
      FieldName = 'CLI_DESCONTO'
      Origin = 'CLIENTES.CLI_DESCONTO'
      Precision = 9
      Size = 2
    end
    object IBQRFaturadaCLI_CNPJ_CPF: TIBStringField
      FieldName = 'CLI_CNPJ_CPF'
      Origin = 'CLIENTES.CLI_CNPJ_CPF'
      Size = 18
    end
    object IBQRFaturadaCLI_NOTA: TIBStringField
      FieldName = 'CLI_NOTA'
      Origin = 'CLIENTES.CLI_NOTA'
      Size = 6
    end
    object IBQRFaturadaFAT_DATA: TDateField
      FieldName = 'FAT_DATA'
      Origin = 'FATURAMENTOS.FAT_DATA'
    end
    object IBQRFaturadaCLI_CELULAR: TIBStringField
      FieldName = 'CLI_CELULAR'
      Origin = 'CLIENTES.CLI_CELULAR'
      Size = 14
    end
    object IBQRFaturadaCLI_FONE: TIBStringField
      FieldName = 'CLI_FONE'
      Origin = 'CLIENTES.CLI_FONE'
      Size = 14
    end
    object IBQRFaturadaTP_NOME: TIBStringField
      FieldName = 'TP_NOME'
      Origin = 'TIPO_PGM.TP_NOME'
      Size = 2
    end
    object IBQRFaturadaVALOR_TOTAL: TCurrencyField
      FieldKind = fkCalculated
      FieldName = 'VALOR_TOTAL'
      Calculated = True
    end
  end
  object DSFaturada: TDataSource
    DataSet = IBQRFaturada
    Left = 304
    Top = 184
  end
  object IBQRNFaturada: TIBQuery
    Database = DMPrincipal.IBDBPrincipal
    Transaction = DMPrincipal.IBTransPrincipal
    OnCalcFields = IBQRNFaturadaCalcFields
    BufferChunks = 1000
    CachedUpdates = True
    ParamCheck = True
    SQL.Strings = (
      
        'SELECT PF_CODIGO, PF_DATA, PF_CLIENTE, PF_COD_CLI, PF_FUN, CLI_P' +
        'LANO, PF_FAT, PF_PARCELAS, PP_JUROS, PP_DESCONTOS, PP_DUPLICATA,' +
        ' PP_VENCIMENTO, TP_DESCRICAO, PP_VALOR, PP_VALORPG, TP_NOME'
      'FROM PED_FAT, CLIENTES, PF_PARCELA, TIPO_PGM '
      
        'WHERE PP_TP = TP_CODIGO AND PF_DATAC = '#39'01/01/1900'#39' AND PP_PF = ' +
        'PF_CODIGO AND PF_COD_CLI = CLI_CODIGO AND PP_ESTADO = 1 AND PF_T' +
        'IPO = 1 AND CLI_CODIGO = :CLIENTE')
    Left = 360
    Top = 392
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CLIENTE'
        ParamType = ptUnknown
      end>
    object IBQRNFaturadaPF_CODIGO: TIntegerField
      FieldName = 'PF_CODIGO'
      Origin = 'PED_FAT.PF_CODIGO'
      Required = True
    end
    object IBQRNFaturadaPF_DATA: TDateField
      FieldName = 'PF_DATA'
      Origin = 'PED_FAT.PF_DATA'
      DisplayFormat = 'dd/mm/yyyy'
    end
    object IBQRNFaturadaPF_CLIENTE: TIBStringField
      FieldName = 'PF_CLIENTE'
      Origin = 'PED_FAT.PF_CLIENTE'
      Size = 50
    end
    object IBQRNFaturadaPF_COD_CLI: TIntegerField
      FieldName = 'PF_COD_CLI'
      Origin = 'PED_FAT.PF_COD_CLI'
    end
    object IBQRNFaturadaPF_FUN: TSmallintField
      FieldName = 'PF_FUN'
      Origin = 'PED_FAT.PF_FUN'
    end
    object IBQRNFaturadaCLI_PLANO: TSmallintField
      FieldName = 'CLI_PLANO'
      Origin = 'CLIENTES.CLI_PLANO'
    end
    object IBQRNFaturadaPF_FAT: TIntegerField
      FieldName = 'PF_FAT'
      Origin = 'PED_FAT.PF_FAT'
    end
    object IBQRNFaturadaPF_PARCELAS: TSmallintField
      FieldName = 'PF_PARCELAS'
      Origin = 'PED_FAT.PF_PARCELAS'
    end
    object IBQRNFaturadaPP_JUROS: TIBBCDField
      FieldName = 'PP_JUROS'
      Origin = 'PF_PARCELA.PP_JUROS'
      DisplayFormat = ',0.00'
      Precision = 9
      Size = 4
    end
    object IBQRNFaturadaPP_DESCONTOS: TIBBCDField
      FieldName = 'PP_DESCONTOS'
      Origin = 'PF_PARCELA.PP_DESCONTOS'
      Precision = 9
      Size = 4
    end
    object IBQRNFaturadaPP_DUPLICATA: TIBStringField
      FieldName = 'PP_DUPLICATA'
      Origin = 'PF_PARCELA.PP_DUPLICATA'
      Size = 30
    end
    object IBQRNFaturadaPP_VENCIMENTO: TDateField
      FieldName = 'PP_VENCIMENTO'
      Origin = 'PF_PARCELA.PP_VENCIMENTO'
      DisplayFormat = 'dd/mm/yyyy'
    end
    object IBQRNFaturadaTP_DESCRICAO: TIBStringField
      FieldName = 'TP_DESCRICAO'
      Origin = 'TIPO_PGM.TP_DESCRICAO'
    end
    object IBQRNFaturadaPP_VALOR: TIBBCDField
      FieldName = 'PP_VALOR'
      Origin = 'PF_PARCELA.PP_VALOR'
      currency = True
      Precision = 18
      Size = 4
    end
    object IBQRNFaturadaPP_VALORPG: TIBBCDField
      FieldName = 'PP_VALORPG'
      Origin = 'PF_PARCELA.PP_VALORPG'
      currency = True
      Precision = 18
      Size = 4
    end
    object IBQRNFaturadaTP_NOME: TIBStringField
      FieldName = 'TP_NOME'
      Origin = 'TIPO_PGM.TP_NOME'
      Size = 2
    end
    object IBQRNFaturadaVALOR_TOTAL: TCurrencyField
      FieldKind = fkCalculated
      FieldName = 'VALOR_TOTAL'
      Calculated = True
    end
  end
  object DSNFaturada: TDataSource
    DataSet = IBQRNFaturada
    Left = 424
    Top = 392
  end
  object IBQRVen_Est: TIBQuery
    Database = DMPrincipal.IBDBPrincipal
    Transaction = DMPrincipal.IBTransPrincipal
    BufferChunks = 1000
    CachedUpdates = True
    ParamCheck = True
    SQL.Strings = (
      
        'SELECT FAT_CODIGO, PRO_CODIGO, FAT_TIPOPGM, VEN_FUN, VEN_CLI, PR' +
        'O_NOME, PRO_DESCRICAO, VEN_DATA, VE_VALOR, VEN_CODIGO, '
      'VE_QUANTIDADE, VE_ESTADO, VE_QTD_DEVOLVIDA'
      'FROM VENDAS, VEN_EST, FATURAMENTOS, PRODUTOS'
      
        'WHERE VE_PRO = PRO_CODIGO AND VEN_CODIGO = VE_VEN AND VEN_FAT = ' +
        'FAT_CODIGO AND VEN_FAT = :CODIGO'
      'ORDER BY VEN_CODIGO')
    Left = 499
    Top = 187
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO'
        ParamType = ptUnknown
      end>
    object IBQRVen_EstFAT_CODIGO: TIntegerField
      FieldName = 'FAT_CODIGO'
      Origin = 'FATURAMENTOS.FAT_CODIGO'
      Required = True
    end
    object IBQRVen_EstPRO_CODIGO: TIntegerField
      FieldName = 'PRO_CODIGO'
      Origin = 'PRODUTOS.PRO_CODIGO'
      Required = True
    end
    object IBQRVen_EstFAT_TIPOPGM: TSmallintField
      FieldName = 'FAT_TIPOPGM'
      Origin = 'FATURAMENTOS.FAT_TIPOPGM'
    end
    object IBQRVen_EstVEN_FUN: TSmallintField
      FieldName = 'VEN_FUN'
      Origin = 'VENDAS.VEN_FUN'
    end
    object IBQRVen_EstVEN_CLI: TIntegerField
      FieldName = 'VEN_CLI'
      Origin = 'VENDAS.VEN_CLI'
    end
    object IBQRVen_EstPRO_DESCRICAO: TIBStringField
      FieldName = 'PRO_DESCRICAO'
      Origin = 'PRODUTOS.PRO_DESCRICAO'
      Size = 30
    end
    object IBQRVen_EstVEN_DATA: TDateField
      FieldName = 'VEN_DATA'
      Origin = 'VENDAS.VEN_DATA'
    end
    object IBQRVen_EstVEN_CODIGO: TIntegerField
      FieldName = 'VEN_CODIGO'
      Origin = 'VENDAS.VEN_CODIGO'
      Required = True
    end
    object IBQRVen_EstVE_VALOR: TIBBCDField
      FieldName = 'VE_VALOR'
      Origin = 'VEN_EST.VE_VALOR'
      Precision = 9
      Size = 4
    end
    object IBQRVen_EstVE_QUANTIDADE: TIBBCDField
      FieldName = 'VE_QUANTIDADE'
      Origin = 'VEN_EST.VE_QUANTIDADE'
      DisplayFormat = '0.00'
      Precision = 9
      Size = 4
    end
    object IBQRVen_EstPRO_NOME: TIBStringField
      FieldName = 'PRO_NOME'
      Origin = '"PRODUTOS"."PRO_NOME"'
      Size = 50
    end
    object IBQRVen_EstVE_ESTADO: TIBStringField
      FieldName = 'VE_ESTADO'
      Origin = '"VEN_EST"."VE_ESTADO"'
      FixedChar = True
      Size = 1
    end
    object IBQRVen_EstVE_QTD_DEVOLVIDA: TIBBCDField
      FieldName = 'VE_QTD_DEVOLVIDA'
      Origin = '"VEN_EST"."VE_QTD_DEVOLVIDA"'
      Precision = 9
      Size = 2
    end
  end
  object IBQRVen_Est2: TIBQuery
    Database = DMPrincipal.IBDBPrincipal
    Transaction = DMPrincipal.IBTransPrincipal
    BufferChunks = 1000
    CachedUpdates = True
    ParamCheck = True
    SQL.Strings = (
      
        'SELECT PRO_CODIGO, VEN_FUN, VEN_CLI, PRO_NOME, PRO_DESCRICAO, VE' +
        'N_DATA, VEN_CODIGO,'
      
        'VE_VALOR, VE_QUANTIDADE, PF_VALOR, PF_VALORPG, VE_ESTADO, VE_QTD' +
        '_DEVOLVIDA'
      'FROM VENDAS, VEN_EST, PRODUTOS, PED_FAT'
      
        'WHERE PF_COD_PED = VEN_CODIGO AND VE_PRO = PRO_CODIGO AND VEN_CO' +
        'DIGO = VE_VEN AND VEN_FAT = :CODIGO'
      'ORDER BY VEN_CODIGO')
    Left = 579
    Top = 187
    ParamData = <
      item
        DataType = ftUnknown
        Name = 'CODIGO'
        ParamType = ptUnknown
      end>
    object IBQRVen_Est2PRO_CODIGO: TIntegerField
      FieldName = 'PRO_CODIGO'
      Origin = 'PRODUTOS.PRO_CODIGO'
      Required = True
    end
    object IBQRVen_Est2VEN_FUN: TSmallintField
      FieldName = 'VEN_FUN'
      Origin = 'VENDAS.VEN_FUN'
    end
    object IBQRVen_Est2VEN_CLI: TIntegerField
      FieldName = 'VEN_CLI'
      Origin = 'VENDAS.VEN_CLI'
    end
    object IBQRVen_Est2PRO_DESCRICAO: TIBStringField
      FieldName = 'PRO_DESCRICAO'
      Origin = 'PRODUTOS.PRO_DESCRICAO'
      Size = 30
    end
    object IBQRVen_Est2VEN_DATA: TDateField
      FieldName = 'VEN_DATA'
      Origin = 'VENDAS.VEN_DATA'
    end
    object IBQRVen_Est2VEN_CODIGO: TIntegerField
      FieldName = 'VEN_CODIGO'
      Origin = 'VENDAS.VEN_CODIGO'
      Required = True
    end
    object IBQRVen_Est2VE_VALOR: TIBBCDField
      FieldName = 'VE_VALOR'
      Origin = 'VEN_EST.VE_VALOR'
      currency = True
      Precision = 9
      Size = 4
    end
    object IBQRVen_Est2VE_QUANTIDADE: TIBBCDField
      FieldName = 'VE_QUANTIDADE'
      Origin = 'VEN_EST.VE_QUANTIDADE'
      DisplayFormat = '0.00'
      Precision = 9
      Size = 4
    end
    object IBQRVen_Est2PF_VALOR: TIBBCDField
      FieldName = 'PF_VALOR'
      Origin = 'PED_FAT.PF_VALOR'
      Precision = 9
      Size = 4
    end
    object IBQRVen_Est2PF_VALORPG: TIBBCDField
      FieldName = 'PF_VALORPG'
      Origin = 'PED_FAT.PF_VALORPG'
      Precision = 9
      Size = 4
    end
    object IBQRVen_Est2PRO_NOME: TIBStringField
      FieldName = 'PRO_NOME'
      Origin = '"PRODUTOS"."PRO_NOME"'
      Size = 50
    end
    object IBQRVen_Est2VE_ESTADO: TIBStringField
      FieldName = 'VE_ESTADO'
      Origin = '"VEN_EST"."VE_ESTADO"'
      FixedChar = True
      Size = 1
    end
    object IBQRVen_Est2VE_QTD_DEVOLVIDA: TIBBCDField
      FieldName = 'VE_QTD_DEVOLVIDA'
      Origin = '"VEN_EST"."VE_QTD_DEVOLVIDA"'
      Precision = 9
      Size = 2
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 395
    Top = 163
    object Imprimir1: TMenuItem
      Caption = '&Imprimir'
    end
  end
  object ActionList1: TActionList
    Images = DMPrincipal.Icones_Pretos
    Left = 152
    Top = 184
    object actSair: TAction
      Caption = 'Esc - &Sair'
      ImageIndex = 171
      OnExecute = actSairExecute
    end
    object actPesquisa: TAction
      Caption = '&F9 - &Pesquisa'
      ImageIndex = 164
      OnExecute = actPesquisaExecute
    end
    object actImprimirProdutos: TAction
      Caption = 'F5 - Imprimir Produtos'
      ImageIndex = 143
      OnExecute = actImprimirProdutosExecute
    end
  end
end
