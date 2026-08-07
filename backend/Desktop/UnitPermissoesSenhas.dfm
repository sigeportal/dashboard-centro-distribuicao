object FrmPermissoesSenhas: TFrmPermissoesSenhas
  Left = 186
  Top = 118
  BorderIcons = [biSystemMenu]
  Caption = 'Permiss'#245'es e Senhas'
  ClientHeight = 526
  ClientWidth = 582
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
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnKeyPress = FormKeyPress
  OnShow = FormShow
  DesignSize = (
    582
    526)
  PixelsPerInch = 96
  TextHeight = 13
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 582
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
    TabOrder = 0
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
    Top = 488
    Width = 582
    Height = 38
    Align = alBottom
    ButtonHeight = 38
    ButtonWidth = 127
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
      Left = 135
      Top = 0
      Width = 8
      Caption = 'ToolButton7'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton17: TToolButton
      Left = 143
      Top = 0
      Action = actPesquisa
    end
    object ToolButton18: TToolButton
      Left = 270
      Top = 0
      Width = 8
      Caption = 'ToolButton11'
      ImageIndex = 4
      Style = tbsSeparator
    end
  end
  object Panel1: TPanel
    Left = 3
    Top = 41
    Width = 577
    Height = 123
    BevelInner = bvSpace
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object GroupBox1: TGroupBox
      Left = 4
      Top = 1
      Width = 567
      Height = 118
      Caption = 'Dados do Usu'#225'rio'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      object Label1: TLabel
        Left = 8
        Top = 16
        Width = 45
        Height = 16
        Caption = 'C'#243'digo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label2: TLabel
        Left = 250
        Top = 16
        Width = 76
        Height = 16
        Caption = 'Funcion'#225'rio'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label3: TLabel
        Left = 75
        Top = 16
        Width = 36
        Height = 16
        Caption = 'Login'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label4: TLabel
        Left = 7
        Top = 70
        Width = 41
        Height = 16
        Caption = 'Senha'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label5: TLabel
        Left = 167
        Top = 70
        Width = 115
        Height = 16
        Caption = 'Confirme a Senha'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lbCodigo: TLabel
        Left = 9
        Top = 40
        Width = 45
        Height = 16
        Caption = 'C'#243'digo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object EdtSenha: TEdit
        Left = 7
        Top = 88
        Width = 152
        Height = 24
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvSpace
        BorderStyle = bsNone
        Color = 15856371
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        PasswordChar = '#'
        TabOrder = 0
      end
      object EdtConfirmaSenha: TEdit
        Left = 167
        Top = 88
        Width = 152
        Height = 24
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvSpace
        BorderStyle = bsNone
        Color = 15856371
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        PasswordChar = '#'
        TabOrder = 1
      end
      object EdtLogin: TEdit
        Left = 74
        Top = 33
        Width = 170
        Height = 24
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvSpace
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        TabOrder = 2
      end
      object CbxFuncionario: TComboBox
        Left = 250
        Top = 33
        Width = 303
        Height = 24
        Style = csDropDownList
        TabOrder = 3
        Items.Strings = (
          'F'#205'SICA'
          'JUR'#205'DICA')
      end
    end
  end
  object Panel2: TPanel
    Left = 3
    Top = 166
    Width = 576
    Height = 319
    Anchors = [akLeft, akTop, akBottom]
    BevelInner = bvSpace
    Color = clWhite
    ParentBackground = False
    TabOrder = 3
    DesignSize = (
      576
      319)
    object PageControl1: TPageControl
      Left = 2
      Top = 1
      Width = 570
      Height = 313
      ActivePage = TabSheet2
      Anchors = [akLeft, akTop, akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      object TabSheet1: TTabSheet
        Caption = 'Permiss'#245'es de Menu'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlue
        Font.Height = -13
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        DesignSize = (
          562
          282)
        object ScrollBox1: TScrollBox
          Left = 2
          Top = 2
          Width = 558
          Height = 278
          VertScrollBar.Tracking = True
          Anchors = [akLeft, akTop, akRight, akBottom]
          Color = clWhite
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          ParentColor = False
          ParentFont = False
          TabOrder = 0
        end
      end
      object TabSheet2: TTabSheet
        Caption = 'Outras Permiss'#245'es'
        ImageIndex = 1
        OnShow = TabSheet2Show
        DesignSize = (
          562
          282)
        object Lista: TCheckListBox
          Left = 2
          Top = 2
          Width = 558
          Height = 279
          OnClickCheck = ListaClickCheck
          Anchors = [akLeft, akTop, akRight, akBottom]
          Columns = 1
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Items.Strings = (
            'Libera Venda'
            'Remover Foto Produto')
          ParentFont = False
          TabOrder = 0
        end
      end
    end
  end
  object ActionList1: TActionList
    Images = DMPrincipal.Icones_Pretos
    Left = 264
    Top = 304
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
      OnExecute = actPesquisaExecute
    end
  end
end
