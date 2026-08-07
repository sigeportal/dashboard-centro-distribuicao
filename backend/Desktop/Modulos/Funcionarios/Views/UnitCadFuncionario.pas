unit UnitCadFuncionario;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UnitFormCadastroRTTI, System.Actions,
  Vcl.ActnList, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Data.DB, Vcl.StdCtrls,
  Vcl.DBCtrls, Vcl.Grids, Vcl.DBGrids, Vcl.Mask, JvExStdCtrls, JvEdit,
	JvValidateEdit, UnitFuncionarios.Model, UnitFormRTTI.Interfaces,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TFrmCadFuncionario = class(TFrmCadastroRTTI)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label10: TLabel;
    Label12: TLabel;
    Label16: TLabel;
		Label17: TLabel;
		[TLigarCampos('FUN_NOME')]
		EdtNome: TEdit;
		[TLigarCampos('FUN_CPF')]
		EdtCPF: TMaskEdit;
		[TLigarCampos('FUN_ENDERECO')]
		EdtEndereco: TEdit;
		[TLigarCampos('FUN_BAIRRO')]		
		EdtBairro: TEdit;
		[TLigarCampos('FUN_FONE')]		
		EdtFone: TMaskEdit;
		[TLigarCampos('FUN_EMAIL')]		
		EdtEmail: TEdit;
		[TLigarCampos('FUN_ADMISSAO')]		
		EdtDataAdmissao: TDateTimePicker;
		[TLigarCampos('FUN_DEMISSAO')]		
		EdtDataDemissao: TDateTimePicker;
		[TLigarCampos('FUN_RG')]		
		EdtRG: TEdit;
		[TLigarCampos('FUN_CELULAR')]				
		EdtCelular: TMaskEdit;
    DBGrid1: TDBGrid;
    GroupBox2: TGroupBox;
    Label8: TLabel;
    Label9: TLabel;
    Label13: TLabel;
    Label14: TLabel;
		Label18: TLabel;
		[TLigarCampos('FUN_SALARIO')]				
		EdtSalario: TJvValidateEdit;
    [TLigarCampos('FUN_COMISSAO')]				
		EdtComissao: TJvValidateEdit;
		[TLigarCampos('FUN_ESTADO')]
		CbxEstado: TComboBox;
		[TLigarCampos('FUN_DATAPGM')]
		CbxDiaPagto: TComboBox;
		[TLigarCampos('FUN_TIPO')]
		CbxTipo: TComboBox;
		[TLigarCampos('FUN_CODIGO', True)]
    lbCodigo: TLabel;
    MemFuncionarios: TFDMemTable;
    MemFuncionariosCODIGO: TIntegerField;
    MemFuncionariosNOME: TStringField;
    MemFuncionariosCPF: TStringField;
    DSFuncionarios: TDataSource;
		procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure actInserirExecute(Sender: TObject);
    procedure actExcluirExecute(Sender: TObject);
    procedure actEditarExecute(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure actConfirmarExecute(Sender: TObject);
  private
		{ Private declarations }
		Funcionario: TFuncionarios;
		procedure BuscaFuncionarios;
	public
		{ Public declarations }
		ExibirPainelPrincipal: Boolean;
	end;

var
	FrmCadFuncionario: TFrmCadFuncionario;

implementation
uses
	UnitTabela.Helper.Json, UnitPrincipal, UnitDMPrincipal, 
  System.Generics.Collections;

{$R *.dfm}

procedure TFrmCadFuncionario.actConfirmarExecute(Sender: TObject);
begin
  inherited;
	BuscaFuncionarios;
end;

procedure TFrmCadFuncionario.actEditarExecute(Sender: TObject);
begin
	inherited;
	EdtNome.SetFocus;
end;

procedure TFrmCadFuncionario.actExcluirExecute(Sender: TObject);
begin
	if Application.MessageBox('Deseja realmente excluir esse registro?', 'Excluir', MB_YESNO+MB_ICONQUESTION) = mrYes then
	begin
		FormRTTI.Excluir(Funcionario.Codigo);
	end;
	inherited;
	BuscaFuncionarios;
end;

procedure TFrmCadFuncionario.actInserirExecute(Sender: TObject);
begin
  inherited;
	Funcionario.Codigo := DMPrincipal.GeraCodigo('FUNCIONARIOS', 'FUN_CODIGO');
	lbCodigo.Caption := Funcionario.Codigo.ToString;
	EdtNome.SetFocus;
end;

procedure TFrmCadFuncionario.BuscaFuncionarios;
var
	ListaFuncionarios: TList<TFuncionarios>;
	Fun: TFuncionarios;
begin
	ListaFuncionarios := Funcionario.Get<TFuncionarios>;
	MemFuncionarios.Close;
	MemFuncionarios.CreateDataSet;	
	for Fun in ListaFuncionarios do
	begin
		MemFuncionarios.Append;
		MemFuncionariosCODIGO.Value := Fun.Codigo;
		MemFuncionariosNOME.Value   := Fun.Nome;
		MemFuncionariosCPF.Value    := Fun.Cpf;
		MemFuncionarios.Post;
	end;
end;

procedure TFrmCadFuncionario.DBGrid1CellClick(Column: TColumn);
begin
	inherited;
	Funcionario := Funcionario.Get<TFuncionarios>(MemFuncionariosCODIGO.AsInteger);
	FormRTTI.SetTabela(Funcionario);
	FormRTTI.BindForm(Self);
end;

procedure TFrmCadFuncionario.FormCreate(Sender: TObject);
begin
	inherited;
	MemFuncionarios.Close;
	MemFuncionarios.CreateDataSet;
	ExibirPainelPrincipal := True;
	Funcionario := TFuncionarios.Create.Get<TFuncionarios>(1);
	FormRTTI.SetTabela(Funcionario);
end;

procedure TFrmCadFuncionario.FormDestroy(Sender: TObject);
begin
	inherited;
	FrmCadFuncionario := nil;
	if ExibirPainelPrincipal then
		FrmPrincipal.HabilitaMenu(True);
end;

procedure TFrmCadFuncionario.FormShow(Sender: TObject);
begin
	inherited;
	BuscaFuncionarios;
	DBGrid1.SetFocus;
end;

end.
