unit UnitCadEmpresa;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UnitFormCadastroRTTI, System.Actions, Vcl.ActnList, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, UnitEmpresa.Model,
  Vcl.StdCtrls, UnitFormRTTI.Interfaces, Vcl.DBCtrls, System.Threading,
  System.Generics.Collections, UnitClientREST.Model.Interfaces, System.JSON, Vcl.Mask;

type
  TRegimeTrib = (SIMPLES_NACIONAL=1, SIMPLES_NACIONAL_EXCESSO_RECEITA_BRUTA, REGIME_NORMAL);
  THelperRegimeTrib = record helper for TRegimeTrib
    function ToString: string;
  end;

type
  TFrmCadEmpresa = class(TFrmCadastroRTTI)
    Label1: TLabel;
    [TLigarCampos('EMP_CODIGO', True)]
    lbCodigo: TLabel;
    Label3: TLabel;
    [TLigarCampos('EMP_RAZAO_SOCIAL')]
    EdtRazaoSocial: TEdit;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label11: TLabel;
    Label28: TLabel;
    Label30: TLabel;
    Label32: TLabel;
    Label34: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label24: TLabel;
    Label26: TLabel;
    [TLigarCampos('EMP_INSCEST')]
    EdtInscEstadual: TEdit;
    [TLigarCampos('EMP_FANTASIA')]
    EdtFantasia: TEdit;
    [TLigarCampos('EMP_CONTATO')]
    EdtContato: TEdit;
    [TLigarCampos('EMP_LOGRADOURO')]
    EdtEndereco: TEdit;
    [TLigarCampos('EMP_NUMERO')]
    EdtNumero: TEdit;
    [TLigarCampos('EMP_COMPLEMENTO')]
    EdtComplemento: TEdit;
    [TLigarCampos('EMP_BAIRRO')]
    EdtBairro: TEdit;
    [TLigarCampos('EMP_CODMUN_IBGE')]
    EdtCodMunIBGE: TEdit;
    [TLigarCampos('EMP_CODUF_IBGE')]
    EdtUFIBGE: TEdit;
    [TLigarCampos('EMP_SUFRAMA')]
    EdtSuframa: TEdit;
    [TLigarCampos('EMP_ATIVIDADE')]
    EdtAtividade: TEdit;
    [TLigarCampos('EMP_EMAIL')]
    EdtEmail: TEdit;
    [TLigarCampos('EMP_PERFIL')]
    EdtPerfil: TEdit;
    [TLigarCampos('EMP_TITULO1')]
    EdtTitulo1: TEdit;
    [TLigarCampos('EMP_TITULO2')]
    EdtTitulo2: TEdit;
    [TLigarCampos('EMP_TITULO3')]
    EdtTitulo3: TEdit;
    [TLigarCampos('EMP_LICENCA_DLL_NFE')]
    EdtChaveLicencaDLL: TEdit;
    [TLigarCampos('EMP_ID_CSC')]
    EdtID_CSC: TEdit;
    [TLigarCampos('EMP_CSC')]
    EdtCSC: TEdit;
    CbRegimeTrib: TComboBox;
    [TLigarCampos('EMP_MUNICIPIO')]
    CbCidades: TComboBox;
    [TLigarCampos('EMP_UF')]
    CbUF: TComboBox;
    Label2: TLabel;
    [TLigarCampos('EMP_CNPJ')]
    EdtCPF_CNPJ: TMaskEdit;
    [TLigarCampos('EMP_CEP')]
    EdtCEP: TMaskEdit;
    [TLigarCampos('EMP_FONE')]
    EdtFone: TMaskEdit;
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CbUFEnter(Sender: TObject);
    procedure actInserirExecute(Sender: TObject);
    procedure actExcluirExecute(Sender: TObject);
    procedure actConfirmarExecute(Sender: TObject);
    procedure actEditarExecute(Sender: TObject);
    procedure CbCidadesEnter(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    Empresa: TEmpresa;
    function CodToRegimeTrib(Value: string): TRegimeTrib;
  public
    { Public declarations }
  end;

var
  FrmCadEmpresa: TFrmCadEmpresa;

implementation

{$R *.dfm}

uses
  UnitDMPrincipal,
  UnitTabela.Helper.Json,
  UnitPrincipal,
  UnitClientREST.Model,
  UnitCidade.Model,
  UnitConfiguracaoServidor.Singleton,
  UnitFuncoesUtils;

procedure TFrmCadEmpresa.actConfirmarExecute(Sender: TObject);
begin
  if Application.MessageBox('Deseja confirmar o cadastro?', 'Confirmar', MB_YESNO+MB_ICONQUESTION) = mrYes then
  begin
    Empresa.CRT := String(CbRegimeTrib.Text).Substring(0, 1);
    inherited;
  end;
end;

procedure TFrmCadEmpresa.actEditarExecute(Sender: TObject);
begin
  inherited;
  CbRegimeTrib.Enabled := True;
end;

procedure TFrmCadEmpresa.actExcluirExecute(Sender: TObject);
begin
  if Application.MessageBox('Deseja realmente excluir este registro?', 'Excluir', MB_YESNO+MB_ICONQUESTION) = mrYes then
    FormRTTI.Excluir(Empresa.Codigo);
  inherited;
end;

procedure TFrmCadEmpresa.actInserirExecute(Sender: TObject);
begin
  inherited;
  Empresa.Codigo      := DMPrincipal.GeraCodigo('EMPRESA', 'EMP_CODIGO');
	lbCodigo.Caption    := Empresa.Codigo.ToString;
	EdtCPF_CNPJ.SetFocus;
  CbRegimeTrib.Enabled := True;
end;

procedure TFrmCadEmpresa.CbCidadesEnter(Sender: TObject);
begin
  inherited;
  if string(CbUF.Text).IsEmpty then
  begin
    ShowMessage('Escolha um estado!');
    CbUF.SetFocus;
    Exit;
  end;
  CbCidades.Clear;
  CbCidades.Items := BuscaCidades(CbUF.Text);
end;

procedure TFrmCadEmpresa.CbUFEnter(Sender: TObject);
begin
  CbCidades.Items.Clear;
  CbUF.Items.Clear;
  CbUF.Items := BuscaEstados;
end;

function TFrmCadEmpresa.CodToRegimeTrib(Value: string): TRegimeTrib;
var ok: Boolean;
begin
  Result := StrToEnumerado(ok, Value, ['1', '2', '3'], [
    TRegimeTrib.SIMPLES_NACIONAL,
    TRegimeTrib.SIMPLES_NACIONAL_EXCESSO_RECEITA_BRUTA,
    TRegimeTrib.REGIME_NORMAL
  ])
end;

procedure TFrmCadEmpresa.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  FrmPrincipal.HabilitaMenu(True);
end;

procedure TFrmCadEmpresa.FormCreate(Sender: TObject);
begin
  inherited;
  Empresa := TEmpresa.Create();
  try
    Empresa := Empresa.Get<TEmpresa>(1);
    CbUF.Clear;
    CbUF.Items.Add(Empresa.UF);
    CbCidades.Clear;
    CbCidades.Items.Add(Empresa.Municipio);
    CbRegimeTrib.Enabled := False;
    CbRegimeTrib.ItemIndex := CbRegimeTrib.Items.IndexOf(CodToRegimeTrib(Empresa.CRT).ToString);
  except on E: Exception do
    Application.MessageBox(PWideChar(E.Message), 'Erro', MB_OK+MB_ICONERROR);
  end;
  FormRTTI.SetTabela(Empresa);
end;

procedure TFrmCadEmpresa.FormDestroy(Sender: TObject);
begin
  inherited;
  Empresa.DisposeOf;
  FrmCadEmpresa := nil;
end;

procedure TFrmCadEmpresa.FormShow(Sender: TObject);
begin
  inherited;

end;

{ THelperRegimeTrib }

function THelperRegimeTrib.ToString: string;
begin
  Result := EnumeradoToStr(Self, [
    '1 - SIMPLES NACIONAL',
    '2 - SIMPLES NACIONAL - EXCESSO DE SUBLIMITE DE RECEITA BRUTA',
    '3 - REGIME NORMAL'
  ], [
    TRegimeTrib.SIMPLES_NACIONAL,
    TRegimeTrib.SIMPLES_NACIONAL_EXCESSO_RECEITA_BRUTA,
    TRegimeTrib.REGIME_NORMAL
  ])
end;

end.
