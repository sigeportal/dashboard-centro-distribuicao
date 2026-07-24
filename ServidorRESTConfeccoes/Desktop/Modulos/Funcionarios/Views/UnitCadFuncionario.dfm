inherited FrmCadFuncionario: TFrmCadFuncionario
  Caption = 'Cadastro de Funcion'#225'rios'
  ClientHeight = 592
  ClientWidth = 631
  ExplicitTop = -12
  ExplicitWidth = 647
  ExplicitHeight = 631
  PixelsPerInch = 96
  TextHeight = 16
  inherited ToolBar2: TToolBar
    Top = 554
    Width = 631
    ExplicitTop = 554
    ExplicitWidth = 631
    inherited ToolButton3: TToolButton
      ExplicitHeight = 38
    end
    inherited ToolButton4: TToolButton
      ExplicitWidth = 106
    end
  end
  inherited Panel1: TPanel
    Width = 625
    Height = 510
    ExplicitWidth = 625
    ExplicitHeight = 510
    object GroupBox1: TGroupBox
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 617
      Height = 195
      Align = alTop
      Caption = 'Dados Gerais'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      object Label1: TLabel
        Left = 16
        Top = 24
        Width = 39
        Height = 14
        Caption = 'C'#243'digo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label2: TLabel
        Left = 88
        Top = 24
        Width = 36
        Height = 14
        Caption = '*Nome'
        FocusControl = EdtNome
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label3: TLabel
        Left = 360
        Top = 24
        Width = 25
        Height = 14
        Caption = '*CPF'
        FocusControl = EdtCPF
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label4: TLabel
        Left = 16
        Top = 66
        Width = 52
        Height = 14
        Caption = 'Endere'#231'o'
        FocusControl = EdtEndereco
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label5: TLabel
        Left = 360
        Top = 66
        Width = 33
        Height = 14
        Caption = 'Bairro'
        FocusControl = EdtBairro
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label6: TLabel
        Left = 16
        Top = 110
        Width = 27
        Height = 14
        Caption = 'Fone'
        FocusControl = EdtFone
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label7: TLabel
        Left = 16
        Top = 150
        Width = 29
        Height = 14
        Caption = 'Email'
        FocusControl = EdtEmail
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label10: TLabel
        Left = 360
        Top = 110
        Width = 82
        Height = 14
        Caption = 'Data Admiss'#227'o'
        FocusControl = EdtDataAdmissao
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label12: TLabel
        Left = 485
        Top = 110
        Width = 81
        Height = 14
        Caption = 'Data Demiss'#227'o'
        FocusControl = EdtDataDemissao
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label16: TLabel
        Left = 482
        Top = 24
        Width = 19
        Height = 14
        Caption = '*RG'
        FocusControl = EdtRG
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label17: TLabel
        Left = 120
        Top = 110
        Width = 39
        Height = 14
        Caption = 'Celular'
        FocusControl = EdtCelular
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lbCodigo: TLabel
        Left = 16
        Top = 42
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
      object EdtNome: TEdit
        Left = 88
        Top = 39
        Width = 232
        Height = 23
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
      end
      object EdtCPF: TMaskEdit
        Left = 362
        Top = 38
        Width = 107
        Height = 23
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15987699
        EditMask = '999\.999\.999\-99;1;_'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        MaxLength = 14
        ParentFont = False
        TabOrder = 1
        Text = '   .   .   -  '
      end
      object EdtEndereco: TEdit
        Left = 16
        Top = 81
        Width = 304
        Height = 23
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvSpace
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15987699
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
      end
      object EdtBairro: TEdit
        Left = 362
        Top = 80
        Width = 236
        Height = 23
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvSpace
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15987699
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
      end
      object EdtFone: TMaskEdit
        Left = 16
        Top = 125
        Width = 87
        Height = 23
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15987699
        EditMask = '!\(99\)9999-9999;1;_'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        MaxLength = 13
        ParentFont = False
        TabOrder = 5
        Text = '(  )    -    '
      end
      object EdtEmail: TEdit
        Left = 16
        Top = 165
        Width = 304
        Height = 23
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvSpace
        BorderStyle = bsNone
        CharCase = ecLowerCase
        Color = 15987699
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 9
      end
      object EdtDataAdmissao: TDateTimePicker
        Left = 361
        Top = 125
        Width = 113
        Height = 22
        BevelInner = bvNone
        BevelOuter = bvNone
        BevelKind = bkFlat
        Date = 44991.645464328710000000
        Time = 44991.645464328710000000
        Color = 15856371
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 7
      end
      object EdtDataDemissao: TDateTimePicker
        Left = 485
        Top = 125
        Width = 113
        Height = 22
        BevelInner = bvNone
        BevelOuter = bvNone
        BevelKind = bkFlat
        Date = 44991.645478761570000000
        Time = 44991.645478761570000000
        Color = 15856371
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 8
      end
      object EdtRG: TEdit
        Left = 485
        Top = 38
        Width = 113
        Height = 23
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvSpace
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15987699
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
      end
      object EdtCelular: TMaskEdit
        Left = 120
        Top = 125
        Width = 99
        Height = 23
        BevelInner = bvLowered
        BevelOuter = bvSpace
        BevelKind = bkSoft
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        EditMask = '!\(99\)99999-9999;1;_'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Arial'
        Font.Style = [fsBold]
        MaxLength = 14
        ParentFont = False
        TabOrder = 6
        Text = '(  )     -    '
      end
    end
    object DBGrid1: TDBGrid
      AlignWithMargins = True
      Left = 4
      Top = 280
      Width = 617
      Height = 226
      Align = alClient
      Color = clInfoBk
      DataSource = DSFuncionarios
      DrawingStyle = gdsGradient
      Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete, dgCancelOnExit]
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -13
      TitleFont.Name = 'Arial'
      TitleFont.Style = [fsBold]
      OnCellClick = DBGrid1CellClick
      Columns = <
        item
          Expanded = False
          FieldName = 'CODIGO'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          Title.Caption = 'C'#243'digo'
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'NOME'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          Title.Caption = 'Nome'
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 374
          Visible = True
        end
        item
          Expanded = False
          FieldName = 'CPF'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          Title.Font.Charset = DEFAULT_CHARSET
          Title.Font.Color = clWindowText
          Title.Font.Height = -11
          Title.Font.Name = 'MS Sans Serif'
          Title.Font.Style = [fsBold]
          Width = 143
          Visible = True
        end>
    end
    object GroupBox2: TGroupBox
      AlignWithMargins = True
      Left = 4
      Top = 205
      Width = 617
      Height = 69
      Align = alTop
      Caption = 'Dados espec'#237'ficos'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -13
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      object Label8: TLabel
        Left = 16
        Top = 24
        Width = 45
        Height = 13
        Caption = '*Sal'#225'rio'
        FocusControl = EdtSalario
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label9: TLabel
        Left = 152
        Top = 24
        Width = 67
        Height = 13
        Caption = 'Comiss'#227'o %'
        FocusControl = EdtComissao
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label13: TLabel
        Left = 265
        Top = 24
        Width = 45
        Height = 13
        Caption = '*Estado'
        FocusControl = EdtComissao
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label14: TLabel
        Left = 435
        Top = 24
        Width = 55
        Height = 13
        Caption = '*Dia Pgto'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label18: TLabel
        Left = 563
        Top = 24
        Width = 31
        Height = 13
        Caption = '*Tipo'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object EdtSalario: TJvValidateEdit
        Left = 18
        Top = 40
        Width = 81
        Height = 23
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvSpace
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = clInfoBk
        CriticalPoints.MaxValueIncluded = False
        CriticalPoints.MinValueIncluded = False
        DisplayFormat = dfFloat
        DecimalPlaces = 2
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object EdtComissao: TJvValidateEdit
        Left = 152
        Top = 40
        Width = 67
        Height = 23
        BevelInner = bvLowered
        BevelKind = bkSoft
        BevelOuter = bvSpace
        BorderStyle = bsNone
        CharCase = ecUpperCase
        Color = 15856371
        CriticalPoints.MaxValueIncluded = False
        CriticalPoints.MinValueIncluded = False
        DisplayFormat = dfFloat
        DecimalPlaces = 2
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
      end
      object CbxEstado: TComboBox
        Left = 265
        Top = 40
        Width = 121
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
        Items.Strings = (
          'ATIVO'
          'INATIVO'
          'ADM')
      end
      object CbxDiaPagto: TComboBox
        Left = 435
        Top = 40
        Width = 71
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 3
        Items.Strings = (
          '1'
          '2'
          '3'
          '4'
          '5'
          '6'
          '7'
          '8'
          '9'
          '10'
          '11'
          '12'
          '13'
          '14'
          '15'
          '16'
          '17'
          '18'
          '19'
          '20'
          '21'
          '22'
          '23'
          '24'
          '25'
          '26'
          '27'
          '28'
          '29'
          '30')
      end
      object CbxTipo: TComboBox
        Left = 528
        Top = 40
        Width = 67
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
        Items.Strings = (
          'D'
          'C')
      end
    end
  end
  inherited ToolBar3: TToolBar
    Width = 631
    ExplicitWidth = 631
  end
  inherited ActionList1: TActionList
    Left = 416
    Top = 240
  end
  object MemFuncionarios: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 272
    Top = 384
    object MemFuncionariosCODIGO: TIntegerField
      FieldName = 'CODIGO'
    end
    object MemFuncionariosNOME: TStringField
      FieldName = 'NOME'
      Size = 200
    end
    object MemFuncionariosCPF: TStringField
      FieldName = 'CPF'
      Size = 30
    end
  end
  object DSFuncionarios: TDataSource
    DataSet = MemFuncionarios
    Left = 272
    Top = 432
  end
end
