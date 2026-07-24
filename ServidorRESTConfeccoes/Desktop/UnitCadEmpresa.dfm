object FrmCadEmpresa: TFrmCadEmpresa
  Left = 184
  Top = 116
  Caption = 'Cadastro da Empresa'
  ClientHeight = 504
  ClientWidth = 620
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
  object PageControl1: TPageControl
    Left = 5
    Top = 43
    Width = 610
    Height = 419
    ActivePage = TabSheet1
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlue
    Font.Height = -13
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Dados da Empresa'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object Label1: TLabel
        Left = 4
        Top = 2
        Width = 39
        Height = 14
        Caption = 'C'#243'digo'
        Color = clBtnFace
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object DBText1: TDBText
        Left = 5
        Top = 18
        Width = 84
        Height = 17
        DataField = 'EMP_CODIGO'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label2: TLabel
        Left = 356
        Top = 3
        Width = 67
        Height = 14
        Caption = 'Raz'#227'o Social'
        Color = clBtnFace
        FocusControl = DBEdit2
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label3: TLabel
        Left = 88
        Top = 2
        Width = 28
        Height = 14
        Caption = 'CNPJ'
        Color = clBtnFace
        FocusControl = DBEdit3
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label4: TLabel
        Left = 4
        Top = 82
        Width = 65
        Height = 14
        Caption = 'Logradouro'
        Color = clBtnFace
        FocusControl = DBEdit4
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label5: TLabel
        Left = 4
        Top = 119
        Width = 33
        Height = 14
        Caption = 'Bairro'
        Color = clBtnFace
        FocusControl = DBEdit5
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label6: TLabel
        Left = 280
        Top = 119
        Width = 38
        Height = 14
        Caption = 'Cidade'
        Color = clBtnFace
        FocusControl = DBEdit6
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label7: TLabel
        Left = 4
        Top = 156
        Width = 21
        Height = 14
        Caption = 'CEP'
        Color = clBtnFace
        FocusControl = DBEdit7
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label8: TLabel
        Left = 543
        Top = 119
        Width = 13
        Height = 14
        Caption = 'UF'
        Color = clBtnFace
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label9: TLabel
        Left = 377
        Top = 156
        Width = 27
        Height = 14
        Caption = 'Fone'
        FocusControl = DBEdit9
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label25: TLabel
        Left = 491
        Top = 156
        Width = 18
        Height = 14
        Caption = 'Fax'
        FocusControl = DBEdit18
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label28: TLabel
        Left = 281
        Top = 44
        Width = 43
        Height = 14
        Caption = 'Contato'
        Color = clBtnFace
        FocusControl = DBEdit19
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label30: TLabel
        Left = 280
        Top = 83
        Width = 44
        Height = 14
        Caption = 'N'#250'mero'
        FocusControl = DBEdit23
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label32: TLabel
        Left = 356
        Top = 83
        Width = 79
        Height = 14
        Caption = 'Complemento'
        FocusControl = DBEdit24
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label34: TLabel
        Left = 225
        Top = 3
        Width = 75
        Height = 14
        Caption = 'Insc. Estadual'
        FocusControl = DBEdit26
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label10: TLabel
        Left = 87
        Top = 156
        Width = 82
        Height = 14
        Caption = 'C'#243'd. Mun. IBGE'
        Color = clBtnFace
        FocusControl = DBEdit1
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label11: TLabel
        Left = 189
        Top = 156
        Width = 68
        Height = 14
        Caption = 'C'#243'd. UF IBGE'
        Color = clBtnFace
        FocusControl = DBEdit8
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label12: TLabel
        Left = 5
        Top = 44
        Width = 80
        Height = 14
        Caption = 'Nome Fantasia'
        Color = clBtnFace
        FocusControl = DBEdit10
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label13: TLabel
        Left = 190
        Top = 196
        Width = 157
        Height = 14
        Caption = 'C'#243'digo de Regime Tribut'#225'rio'
        Color = clBtnFace
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label14: TLabel
        Left = 280
        Top = 156
        Width = 53
        Height = 14
        Caption = 'SUFRAMA'
        Color = clBtnFace
        FocusControl = DBEdit11
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label15: TLabel
        Left = 4
        Top = 196
        Width = 29
        Height = 14
        Caption = 'Perfil'
        Color = clBtnFace
        FocusControl = DBEdit12
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label16: TLabel
        Left = 88
        Top = 196
        Width = 51
        Height = 14
        Caption = 'Atividade'
        Color = clBtnFace
        FocusControl = DBEdit13
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label17: TLabel
        Left = 4
        Top = 233
        Width = 33
        Height = 14
        Caption = 'E-mail'
        Color = clBtnFace
        FocusControl = DBEdit14
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object Label18: TLabel
        Left = 3
        Top = 270
        Width = 40
        Height = 14
        Caption = 'T'#237'tulo 1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label19: TLabel
        Left = 3
        Top = 308
        Width = 40
        Height = 14
        Caption = 'T'#237'tulo 2'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label20: TLabel
        Left = 3
        Top = 346
        Width = 40
        Height = 14
        Caption = 'T'#237'tulo 3'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object DBEdit2: TDBEdit
        Left = 359
        Top = 20
        Width = 237
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_RAZAO_SOCIAL'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
      end
      object DBEdit3: TDBEdit
        Left = 91
        Top = 20
        Width = 118
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_CNPJ'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
        OnKeyPress = DBEdit3KeyPress
      end
      object DBEdit4: TDBEdit
        Left = 7
        Top = 100
        Width = 261
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_LOGRADOURO'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 5
      end
      object DBEdit5: TDBEdit
        Left = 7
        Top = 135
        Width = 261
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_BAIRRO'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 8
      end
      object DBEdit6: TDBEdit
        Left = 283
        Top = 135
        Width = 246
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_MUNICIPIO'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 9
      end
      object DBEdit7: TDBEdit
        Left = 7
        Top = 172
        Width = 66
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_CEP'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 11
      end
      object DBComboBox1: TDBComboBox
        Left = 543
        Top = 135
        Width = 57
        Height = 22
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_UF'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Items.Strings = (
          'AC'
          'AL'
          'AM'
          'AP'
          'BA'
          'CE'
          'ES'
          'GO'
          'MA'
          'MG'
          'MS'
          'MT'
          'PA'
          'PB'
          'PE'
          'PI'
          'PR'
          'RJ'
          'RN'
          'RO'
          'RR'
          'RS'
          'SC'
          'SE'
          'SP'
          'TO'
          ''
          ''
          ''
          ''
          ''
          ''
          '')
        ParentFont = False
        TabOrder = 10
      end
      object DBEdit9: TDBEdit
        Left = 379
        Top = 172
        Width = 94
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_FONE'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 15
      end
      object DBEdit18: TDBEdit
        Left = 492
        Top = 172
        Width = 103
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_FAX'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 16
      end
      object DBEdit19: TDBEdit
        Left = 283
        Top = 60
        Width = 313
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_CONTATO'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
      end
      object DBEdit23: TDBEdit
        Left = 283
        Top = 100
        Width = 62
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_NUMERO'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 6
      end
      object DBEdit24: TDBEdit
        Left = 359
        Top = 100
        Width = 237
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_COMPLEMENTO'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 7
      end
      object DBEdit26: TDBEdit
        Left = 227
        Top = 20
        Width = 118
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_INSCEST'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
      end
      object DBEdit1: TDBEdit
        Left = 90
        Top = 172
        Width = 85
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_CODMUN_IBGE'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 12
      end
      object DBEdit8: TDBEdit
        Left = 192
        Top = 172
        Width = 76
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_CODUF_IBGE'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 13
      end
      object DBEdit10: TDBEdit
        Left = 7
        Top = 60
        Width = 261
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_FANTASIA'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
      end
      object DBComboBox2: TDBComboBox
        Left = 189
        Top = 212
        Width = 410
        Height = 22
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        Color = 15856371
        DataField = 'EMP_CRT'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        Items.Strings = (
          '1 - SIMPLES NACIONAL'
          '2 - SIMPLES NACIONAL - EXCESSO DE SUBLIMITE DE RECEITA BRUTA'
          '3 - REGIME NORMAL')
        ParentFont = False
        TabOrder = 19
      end
      object DBEdit11: TDBEdit
        Left = 283
        Top = 172
        Width = 76
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_SUFRAMA'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 14
      end
      object DBEdit12: TDBEdit
        Left = 7
        Top = 212
        Width = 66
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_PERFIL'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 17
      end
      object DBEdit13: TDBEdit
        Left = 90
        Top = 212
        Width = 85
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        DataField = 'EMP_ATIVIDADE'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 18
      end
      object DBEdit14: TDBEdit
        Left = 7
        Top = 250
        Width = 262
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_EMAIL'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 20
      end
      object DBEdit15: TDBEdit
        Left = 7
        Top = 288
        Width = 586
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_TITULO1'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 21
      end
      object DBEdit16: TDBEdit
        Left = 7
        Top = 326
        Width = 586
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_TITULO2'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 22
      end
      object DBEdit17: TDBEdit
        Left = 7
        Top = 363
        Width = 586
        Height = 20
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        DataField = 'EMP_TITULO3'
        DataSource = DSEmpresa
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 23
      end
    end
  end
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 620
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
    TabOrder = 1
    object ToolButton1: TToolButton
      Left = 0
      Top = 0
      Width = 8
      Caption = 'ToolButton1'
      ImageIndex = 2
      Style = tbsSeparator
    end
    object ToolButton10: TToolButton
      Left = 8
      Top = 0
      Action = actConfirmar
    end
    object ToolButton11: TToolButton
      Left = 114
      Top = 0
      Width = 8
      Caption = 'ToolButton11'
      ImageIndex = 4
      Style = tbsSeparator
    end
    object ToolButton12: TToolButton
      Left = 122
      Top = 0
      Action = actCancelar
    end
    object ToolButton13: TToolButton
      Left = 228
      Top = 0
      Width = 8
      Caption = 'ToolButton13'
      ImageIndex = 5
      Style = tbsSeparator
    end
    object ToolButton14: TToolButton
      Left = 236
      Top = 0
      Action = actEditar
    end
    object ToolButton2: TToolButton
      Left = 342
      Top = 0
      Width = 8
      Caption = 'ToolButton2'
      ImageIndex = 135
      Style = tbsSeparator
    end
  end
  object ToolBar2: TToolBar
    Left = 0
    Top = 466
    Width = 620
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
    TabOrder = 2
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
  object DSEmpresa: TDataSource
    AutoEdit = False
    DataSet = IBDSEmpresa
    OnStateChange = DSEmpresaStateChange
    Left = 517
    Top = 307
  end
  object IBDSEmpresa: TIBDataSet
    Database = DMPrincipal.IBDBPrincipal
    Transaction = DMPrincipal.IBTransPrincipal
    BufferChunks = 1000
    CachedUpdates = True
    DeleteSQL.Strings = (
      'delete from EMPRESA'
      'where'
      '  EMP_CODIGO = :OLD_EMP_CODIGO')
    InsertSQL.Strings = (
      'insert into EMPRESA'
      
        '  (EMP_CODIGO, EMP_CNPJ, EMP_INSCEST, EMP_MUNICIPIO, EMP_UF, EMP' +
        '_FONE, '
      
        '   EMP_FAX, EMP_LOGRADOURO, EMP_NUMERO, EMP_COMPLEMENTO, EMP_BAI' +
        'RRO, EMP_CEP, '
      
        '   EMP_CONTATO, EMP_CODMUN_IBGE, EMP_CODUF_IBGE, EMP_FANTASIA, E' +
        'MP_CRT, '
      
        '   EMP_LICENCA_DLL_NFE, EMP_RAZAO_SOCIAL, EMP_SUFRAMA, EMP_PERFI' +
        'L, EMP_ATIVIDADE, '
      
        '   EMP_EMAIL, EMP_TITULO1, EMP_TITULO2, EMP_TITULO3, EMP_MD5, EM' +
        'P_LICENCA, '
      '   EMP_INSCMUN)'
      'values'
      
        '  (:EMP_CODIGO, :EMP_CNPJ, :EMP_INSCEST, :EMP_MUNICIPIO, :EMP_UF' +
        ', :EMP_FONE, '
      
        '   :EMP_FAX, :EMP_LOGRADOURO, :EMP_NUMERO, :EMP_COMPLEMENTO, :EM' +
        'P_BAIRRO, '
      
        '   :EMP_CEP, :EMP_CONTATO, :EMP_CODMUN_IBGE, :EMP_CODUF_IBGE, :E' +
        'MP_FANTASIA, '
      
        '   :EMP_CRT, :EMP_LICENCA_DLL_NFE, :EMP_RAZAO_SOCIAL, :EMP_SUFRA' +
        'MA, :EMP_PERFIL, '
      
        '   :EMP_ATIVIDADE, :EMP_EMAIL, :EMP_TITULO1, :EMP_TITULO2, :EMP_' +
        'TITULO3, '
      '   :EMP_MD5, :EMP_LICENCA, :EMP_INSCMUN)')
    RefreshSQL.Strings = (
      'Select '
      '  EMP_CODIGO,'
      '  EMP_CNPJ,'
      '  EMP_INSCEST,'
      '  EMP_MUNICIPIO,'
      '  EMP_UF,'
      '  EMP_FONE,'
      '  EMP_FAX,'
      '  EMP_LOGRADOURO,'
      '  EMP_NUMERO,'
      '  EMP_COMPLEMENTO,'
      '  EMP_BAIRRO,'
      '  EMP_CEP,'
      '  EMP_CONTATO,'
      '  EMP_CODMUN_IBGE,'
      '  EMP_CODUF_IBGE,'
      '  EMP_FANTASIA,'
      '  EMP_CRT,'
      '  EMP_LICENCA_DLL_NFE,'
      '  EMP_RAZAO_SOCIAL,'
      '  EMP_SUFRAMA,'
      '  EMP_PERFIL,'
      '  EMP_ATIVIDADE,'
      '  EMP_EMAIL,'
      '  EMP_TITULO1,'
      '  EMP_TITULO2,'
      '  EMP_TITULO3,'
      '  EMP_MD5,'
      '  EMP_LICENCA,'
      '  EMP_INSCMUN'
      'from EMPRESA '
      'where'
      '  EMP_CODIGO = :EMP_CODIGO')
    SelectSQL.Strings = (
      'SELECT * FROM EMPRESA')
    ModifySQL.Strings = (
      'update EMPRESA'
      'set'
      '  EMP_CODIGO = :EMP_CODIGO,'
      '  EMP_CNPJ = :EMP_CNPJ,'
      '  EMP_INSCEST = :EMP_INSCEST,'
      '  EMP_MUNICIPIO = :EMP_MUNICIPIO,'
      '  EMP_UF = :EMP_UF,'
      '  EMP_FONE = :EMP_FONE,'
      '  EMP_FAX = :EMP_FAX,'
      '  EMP_LOGRADOURO = :EMP_LOGRADOURO,'
      '  EMP_NUMERO = :EMP_NUMERO,'
      '  EMP_COMPLEMENTO = :EMP_COMPLEMENTO,'
      '  EMP_BAIRRO = :EMP_BAIRRO,'
      '  EMP_CEP = :EMP_CEP,'
      '  EMP_CONTATO = :EMP_CONTATO,'
      '  EMP_CODMUN_IBGE = :EMP_CODMUN_IBGE,'
      '  EMP_CODUF_IBGE = :EMP_CODUF_IBGE,'
      '  EMP_FANTASIA = :EMP_FANTASIA,'
      '  EMP_CRT = :EMP_CRT,'
      '  EMP_LICENCA_DLL_NFE = :EMP_LICENCA_DLL_NFE,'
      '  EMP_RAZAO_SOCIAL = :EMP_RAZAO_SOCIAL,'
      '  EMP_SUFRAMA = :EMP_SUFRAMA,'
      '  EMP_PERFIL = :EMP_PERFIL,'
      '  EMP_ATIVIDADE = :EMP_ATIVIDADE,'
      '  EMP_EMAIL = :EMP_EMAIL,'
      '  EMP_TITULO1 = :EMP_TITULO1,'
      '  EMP_TITULO2 = :EMP_TITULO2,'
      '  EMP_TITULO3 = :EMP_TITULO3,'
      '  EMP_MD5 = :EMP_MD5,'
      '  EMP_LICENCA = :EMP_LICENCA,'
      '  EMP_INSCMUN = :EMP_INSCMUN'
      'where'
      '  EMP_CODIGO = :OLD_EMP_CODIGO')
    ParamCheck = True
    UniDirectional = False
    Left = 485
    Top = 307
    object IBDSEmpresaEMP_CODIGO: TSmallintField
      FieldName = 'EMP_CODIGO'
      Origin = 'EMPRESA.EMP_CODIGO'
      Required = True
    end
    object IBDSEmpresaEMP_CNPJ: TIBStringField
      FieldName = 'EMP_CNPJ'
      Origin = 'EMPRESA.EMP_CNPJ'
      EditMask = '99.999.999/9999-99;1;_'
      Size = 18
    end
    object IBDSEmpresaEMP_INSCEST: TIBStringField
      FieldName = 'EMP_INSCEST'
      Origin = 'EMPRESA.EMP_INSCEST'
    end
    object IBDSEmpresaEMP_MUNICIPIO: TIBStringField
      FieldName = 'EMP_MUNICIPIO'
      Origin = 'EMPRESA.EMP_MUNICIPIO'
      Size = 50
    end
    object IBDSEmpresaEMP_UF: TIBStringField
      FieldName = 'EMP_UF'
      Origin = 'EMPRESA.EMP_UF'
      FixedChar = True
      Size = 2
    end
    object IBDSEmpresaEMP_FONE: TIBStringField
      FieldName = 'EMP_FONE'
      Origin = 'EMPRESA.EMP_FONE'
      EditMask = '!\(99\)9999-9999;1;_'
      Size = 13
    end
    object IBDSEmpresaEMP_FAX: TIBStringField
      FieldName = 'EMP_FAX'
      Origin = 'EMPRESA.EMP_FAX'
      EditMask = '!\(99\)9999-9999;1;_'
      Size = 13
    end
    object IBDSEmpresaEMP_LOGRADOURO: TIBStringField
      FieldName = 'EMP_LOGRADOURO'
      Origin = 'EMPRESA.EMP_LOGRADOURO'
      Size = 50
    end
    object IBDSEmpresaEMP_NUMERO: TIBStringField
      FieldName = 'EMP_NUMERO'
      Origin = 'EMPRESA.EMP_NUMERO'
      Size = 10
    end
    object IBDSEmpresaEMP_COMPLEMENTO: TIBStringField
      FieldName = 'EMP_COMPLEMENTO'
      Origin = 'EMPRESA.EMP_COMPLEMENTO'
      Size = 50
    end
    object IBDSEmpresaEMP_BAIRRO: TIBStringField
      FieldName = 'EMP_BAIRRO'
      Origin = 'EMPRESA.EMP_BAIRRO'
      Size = 30
    end
    object IBDSEmpresaEMP_CEP: TIBStringField
      FieldName = 'EMP_CEP'
      Origin = 'EMPRESA.EMP_CEP'
      EditMask = '99999\-999;1;_'
      Size = 10
    end
    object IBDSEmpresaEMP_CONTATO: TIBStringField
      FieldName = 'EMP_CONTATO'
      Origin = 'EMPRESA.EMP_CONTATO'
      Size = 30
    end
    object IBDSEmpresaEMP_FANTASIA: TIBStringField
      FieldName = 'EMP_FANTASIA'
      Origin = 'EMPRESA.EMP_FANTASIA'
      Size = 100
    end
    object IBDSEmpresaEMP_CRT: TIBStringField
      FieldName = 'EMP_CRT'
      Origin = 'EMPRESA.EMP_CRT'
      Size = 2
    end
    object IBDSEmpresaEMP_LICENCA_DLL_NFE: TIBStringField
      FieldName = 'EMP_LICENCA_DLL_NFE'
      Origin = 'EMPRESA.EMP_LICENCA_DLL_NFE'
      Size = 200
    end
    object IBDSEmpresaEMP_RAZAO_SOCIAL: TIBStringField
      FieldName = 'EMP_RAZAO_SOCIAL'
      Origin = 'EMPRESA.EMP_RAZAO_SOCIAL'
      Size = 50
    end
    object IBDSEmpresaEMP_SUFRAMA: TIBStringField
      FieldName = 'EMP_SUFRAMA'
      Origin = 'EMPRESA.EMP_SUFRAMA'
      Size = 9
    end
    object IBDSEmpresaEMP_PERFIL: TIBStringField
      FieldName = 'EMP_PERFIL'
      Origin = 'EMPRESA.EMP_PERFIL'
      Size = 1
    end
    object IBDSEmpresaEMP_ATIVIDADE: TIBStringField
      FieldName = 'EMP_ATIVIDADE'
      Origin = 'EMPRESA.EMP_ATIVIDADE'
      Size = 1
    end
    object IBDSEmpresaEMP_EMAIL: TIBStringField
      FieldName = 'EMP_EMAIL'
      Origin = 'EMPRESA.EMP_EMAIL'
      Size = 50
    end
    object IBDSEmpresaEMP_TITULO1: TIBStringField
      FieldName = 'EMP_TITULO1'
      Origin = 'EMPRESA.EMP_TITULO1'
      Size = 100
    end
    object IBDSEmpresaEMP_TITULO2: TIBStringField
      FieldName = 'EMP_TITULO2'
      Origin = 'EMPRESA.EMP_TITULO2'
      Size = 100
    end
    object IBDSEmpresaEMP_TITULO3: TIBStringField
      FieldName = 'EMP_TITULO3'
      Origin = 'EMPRESA.EMP_TITULO3'
      Size = 100
    end
    object IBDSEmpresaEMP_MD5: TIBStringField
      FieldName = 'EMP_MD5'
      Origin = 'EMPRESA.EMP_MD5'
      Size = 50
    end
    object IBDSEmpresaEMP_LICENCA: TIBStringField
      FieldName = 'EMP_LICENCA'
      Origin = 'EMPRESA.EMP_LICENCA'
      EditMask = 's'
    end
    object IBDSEmpresaEMP_CODMUN_IBGE: TIBStringField
      FieldName = 'EMP_CODMUN_IBGE'
      Origin = 'EMPRESA.EMP_CODMUN_IBGE'
      Size = 10
    end
    object IBDSEmpresaEMP_CODUF_IBGE: TIBStringField
      FieldName = 'EMP_CODUF_IBGE'
      Origin = 'EMPRESA.EMP_CODUF_IBGE'
      Size = 10
    end
    object IBDSEmpresaEMP_INSCMUN: TIBStringField
      FieldName = 'EMP_INSCMUN'
      Origin = 'EMPRESA.EMP_INSCMUN'
    end
  end
  object ActionList1: TActionList
    Images = DMPrincipal.Icones_Pretos
    Left = 88
    Top = 40
    object actInserir: TAction
      Caption = '&Inserir'
      ImageIndex = 141
    end
    object actExcluir: TAction
      Caption = 'E&xcluir'
      ImageIndex = 185
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
