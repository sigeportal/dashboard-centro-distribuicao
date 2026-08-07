unit UnitPermissoesSenhas;

interface

uses
  DBGrids, Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Buttons, Db, IBCustomDataSet, DBCtrls, StdCtrls, ExtCtrls, Mask, CheckLst,
  Grids, IBQuery, Menus, ComCtrls, System.Actions, Vcl.ActnList, Vcl.ToolWin, UnitClientREST.Model.Interfaces, UnitTabela.Helper.Json,
  System.JSON, UnitFormRTTI.Interfaces, UnitPermissoes.Model, UnitUsuarios.Model;

type
  TFrmPermissoesSenhas = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    EdtSenha: TEdit;
    EdtConfirmaSenha: TEdit;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    ScrollBox1: TScrollBox;
    Lista: TCheckListBox;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ToolButton8: TToolButton;
    ToolButton9: TToolButton;
    ToolButton10: TToolButton;
    ToolButton11: TToolButton;
    ToolButton12: TToolButton;
    ToolButton13: TToolButton;
    ToolButton14: TToolButton;
    ToolButton2: TToolButton;
    ActionList1: TActionList;
    actInserir: TAction;
    actExcluir: TAction;
    actConfirmar: TAction;
    actCancelar: TAction;
    actEditar: TAction;
    actSair: TAction;
    actPesquisa: TAction;
    ToolBar2: TToolBar;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton17: TToolButton;
    ToolButton18: TToolButton;
    Panel1: TPanel;
    Panel2: TPanel;
		[TLigarCampos('USU_LOGIN')]
		EdtLogin: TEdit;
		CbxFuncionario: TComboBox;
		[TLigarCampos('USU_CODIGO', True)]
    lbCodigo: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure ListaClickCheck(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure IBDSUsuariosAfterScroll(DataSet: TDataSet);
    procedure ChecaSubItens(Sender: TObject);
    procedure TabSheet2Show(Sender: TObject);
    procedure actInserirExecute(Sender: TObject);
    procedure actEditarExecute(Sender: TObject);
    procedure actCancelarExecute(Sender: TObject);
    procedure actConfirmarExecute(Sender: TObject);
    procedure actExcluirExecute(Sender: TObject);
    procedure actSairExecute(Sender: TObject);
    procedure actPesquisaExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FormRTTI: iFormRTTI;
    Usuarios: TUsuarios;
  public
    { Public declarations }
    HabilitaClickCheckBox: boolean;
    procedure HabilitarAcoes(TipoOperacao: TTipoOperacao);
    procedure BuscaPermissoes;
  end;

var
  FrmPermissoesSenhas: TFrmPermissoesSenhas;
  Topo: integer;

implementation

uses
  UnitDMPrincipal,
  UnitPrincipal,
  UnitPesquisa,
  UnitFuncoesUtils,
  UnitClientREST.Model,
  UnitConfiguracaoServidor.Singleton,
  UnitFormRTTI.Model, UnitFuncionarios.Model;

{$R *.DFM}

procedure TFrmPermissoesSenhas.ChecaSubItens(Sender: TObject);
var
  i: integer;
  Nivel: string;
  Checar: boolean;
begin
  if not HabilitaClickCheckBox then
    Exit;
  Nivel := TCheckBox(Sender).Hint;
  Checar := TCheckBox(Sender).Checked;
  for i := 0 to ScrollBox1.ControlCount - 1 do
  begin
    if ScrollBox1.Controls[i] is TCheckBox then
    begin
      if Copy(TCheckBox(ScrollBox1.Controls[i]).Hint, 1, Length(Nivel)) = Nivel then
        TCheckBox(ScrollBox1.Controls[i]).Checked := Checar;
    end;
  end;
end;

procedure CriaCheckBox(Nome, Descricao: string; Nivel: smallint; NivelExtenso: string);
var
  Lista: TCheckBox;
begin
  Lista := TCheckBox.Create(FrmPermissoesSenhas);
  Lista.Name := Nome;
  Lista.Caption := StringReplace(Descricao, '&', '', [rfReplaceAll]);
  Lista.Left := (Nivel * 18) - 18;
  Lista.Top := Topo;
  Lista.Hint := NivelExtenso;
  Lista.ShowHint := True;
  Lista.Width := 300;
  Lista.OnClick := FrmPermissoesSenhas.ChecaSubItens;
  Lista.Parent := FrmPermissoesSenhas.ScrollBox1;
end;

procedure VarreMainMenu(Item: TMenuItem; Nivel: smallint; NivelMenu: string);
var
  i: smallint;
begin
  Inc(Topo, 16);
  CriaCheckBox(Item.Name, Item.Caption, Nivel, NivelMenu);
  for i := 0 to Item.Count - 1 do
  begin
    VarreMainMenu(Item.Items[i], Nivel + 1, NivelMenu + '.' + IntToStr(i + 1)); // Item.Items[i].Name);//
  end;
end;

procedure TFrmPermissoesSenhas.BuscaPermissoes;
var
	i: integer;
  Response: TClientResult;
	aJson: TJSONArray;
  permissoesJsonValue: TJSONValue;
  oJson: TJSONObject;
	ListaPermissoes: TStringList;
begin
  HabilitaClickCheckBox := False;
  Response := TClientREST.New(TConfiguracaoServidor.BaseURL+'/usuarios/'+Usuarios.Codigo.ToString).Get();
  if Response.StatusCode = 200 then
	begin
		oJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONObject;
		aJson := oJson.GetValue<TJSONArray>('permissoes');
		ListaPermissoes := TStringList.Create;
		try
			for permissoesJsonValue in aJson do
			begin
				 ListaPermissoes.Add(permissoesJsonValue.GetValue<string>('permissao'));
			end;
			for i := 0 to ScrollBox1.ControlCount - 1 do
			begin
				if ScrollBox1.Controls[i] is TCheckBox then
				begin
					TCheckBox(ScrollBox1.Controls[i]).Checked := ListaPermissoes.IndexOf('M' + TCheckBox(ScrollBox1.Controls[i]).Name) > -1;
				end;
			end;
			for i := 0 to Lista.Items.Count - 1 do
			begin
				Lista.Checked[i] := ListaPermissoes.IndexOf('P' + Lista.Items[i]) > -1;
			end;
			HabilitaClickCheckBox := True;
    finally
			ListaPermissoes.DisposeOf;
    end;
  end;
end;

procedure TFrmPermissoesSenhas.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := CaFree;
end;

procedure TFrmPermissoesSenhas.FormCreate(Sender: TObject);
begin
  FormRTTI := TFormRTTI.New;
  Usuarios := TUsuarios.Create.Get<TUsuarios>(1);
	FormRTTI.SetTabela(Usuarios);
	Usuarios.Funcionario := TFuncionarios.Create.Get<TFuncionarios>(Usuarios.fun_codigo);
	CbxFuncionario.Clear;
	CbxFuncionario.Items := TFuncionarios.Create.GetDataComboBox<TFuncionarios>('nome');
	CbxFuncionario.ItemIndex := CbxFuncionario.Items.IndexOf(Usuarios.Funcionario.Nome);
	FormRTTI.SetEventoTipoOperacao(HabilitarAcoes);
end;

procedure TFrmPermissoesSenhas.FormDestroy(Sender: TObject);
begin
  FrmPermissoesSenhas := nil;
  if FrmPrincipal.UsaLoginPorModulo = 'N' then
    FrmPrincipal.HabilitaMainMenu;
  FrmPrincipal.HabilitaMenu(True);
end;

procedure TFrmPermissoesSenhas.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    if (Sender is TDBGrid) then
      TDBGrid(Sender).Perform(WM_KeyDown, VK_Tab, 0)
    else
      Perform(Wm_NextDlgCtl, 0, 0);
  end;
end;

procedure TFrmPermissoesSenhas.actCancelarExecute(Sender: TObject);
begin
  FormRTTI.Cancelar;
  BuscaPermissoes;
end;

procedure TFrmPermissoesSenhas.actConfirmarExecute(Sender: TObject);
var
  i: integer;
  aJson: TJSONArray;
  Response: TClientResult;
  oJson: TJSONObject;
  JsonRequest: TJSONObject;
  oJsonCodigo: TJSONObject;
begin
  if EdtSenha.Text <> EdtConfirmaSenha.Text then
  begin
    Application.MessageBox('As senhas digitadas não conferem!'#13'Tente novamente!', 'Atenção!', MB_OK + MB_ICONWARNING);
    EdtSenha.SetFocus;
    Exit;
	end;  
	try
		if Usuarios.Codigo = 0 then
		begin
			Response := TClientREST.New(TConfiguracaoServidor.BaseURL+'/gera_codigo')
													 .AddHeader('Content-Type', 'application/json')
													 .AddBody(TJSONObject.Create.AddPair('tabela', 'USUARIOS').AddPair('campo', 'USU_CODIGO'))
													 .Post();
			if Response.StatusCode = 200 then		
			begin
				oJsonCodigo := TJSONObject.ParseJSONValue(Response.Content) as TJSONObject;
				Usuarios.Codigo := oJsonCodigo.GetValue<Integer>('codigo');			
			end;
		end;
		//preenche dados do usuario
		Usuarios.Login := EdtLogin.Text;
		Usuarios.fun_codigo := TFuncionarios(CbxFuncionario.Items.Objects[CbxFuncionario.ItemIndex]).Codigo;
		Usuarios.Senha := EnDecryptString(EdtSenha.Text, 236);
		////permissoes
		aJson := TJSONArray.Create;
		// Permissoes de Menus
		for i := 0 to ScrollBox1.ControlCount - 1 do
		begin
			if ScrollBox1.Controls[i] is TCheckBox then
			begin
				if TCheckBox(ScrollBox1.Controls[i]).Checked then
				begin
					oJson := TJSONObject.Create;
					oJson.AddPair('permissao', 'M' + TCheckBox(ScrollBox1.Controls[i]).Name);
					aJson.AddElement(oJson);
				end
			end;
		end;
		// Outras Permissoes
		for i := 0 to Lista.Items.Count - 1 do
		begin
			if Lista.Checked[i] then
			begin
				oJson := TJSONObject.Create;
				oJson.AddPair('permissao', 'P' + Lista.Items.Strings[i]);
				aJson.AddElement(oJson);
			end;
		end;
		//add no json da requisicao
		JsonRequest := TJSONObject.Create;
		JsonRequest.AddPair('permissoes', aJson);
		if EdtSenha.Text <> '' then
		 JsonRequest.AddPair('usuario',	TJSONObject.ParseJSONValue(Usuarios.ToJson) as TJSONObject);				
		//envia para o servidor
		Response := TClientREST.New(TConfiguracaoServidor.BaseURL+'/usuarios/'+Usuarios.Codigo.ToString+'/permissoes')
													 .AddHeader('Content-Type','application/json')
													 .AddBody(JsonRequest)
													 .Post();
		if Response.StatusCode = 201 then
		begin
			ShowMessage('Permissões criadas com sucesso');
			FrmPermissoesSenhas.Close;
		end
		else
    begin
			ShowMessage('Erro ao criar permissoes!'+sLineBreak+Response.Content);
    end;
	except on E: Exception do
		ShowMessage('Erro ao criar permissoes'+sLineBreak+E.Message);
	end;
end;

procedure TFrmPermissoesSenhas.actEditarExecute(Sender: TObject);
begin
  FormRTTI.Editar;
  EdtLogin.SetFocus;
end;

procedure TFrmPermissoesSenhas.actExcluirExecute(Sender: TObject);
var
  permissao: TPermissoes;
begin
  if Application.MessageBox('Deseja excluir este Usuário?', 'Exclusão de Usuário', MB_YESNO + MB_ICONQUESTION) = MrYes then
  begin
    try
      //deleta no servidor
      for permissao in Usuarios.Permissoes do
        permissao.Delete(permissao.Codigo);
      FormRTTI.Excluir(Usuarios.Codigo);
      BuscaPermissoes;
    except
      on E: Exception do
      begin
        Application.MessageBox(PWideChar('Houve erro ao excluir o Usuário!'#13 + E.Message), 'Erro', MB_OK + MB_ICONERROR);
      end;
    end;
  end;
end;

procedure TFrmPermissoesSenhas.actInserirExecute(Sender: TObject);
begin
  FormRTTI.Inserir;
  EdtLogin.SetFocus;
  BuscaPermissoes;
end;

procedure TFrmPermissoesSenhas.actPesquisaExecute(Sender: TObject);
begin
  FrmPesquisa.Pesquisa := 'Usuario';
  FrmPesquisa.ShowModal;
end;

procedure TFrmPermissoesSenhas.actSairExecute(Sender: TObject);
begin
  Close;
end;

procedure TFrmPermissoesSenhas.ListaClickCheck(Sender: TObject);
begin
  FormRTTI.Editar;
end;

procedure TFrmPermissoesSenhas.FormShow(Sender: TObject);
var
  k: smallint;
begin
  Topo := 0;
  CriaCheckBox('Menu_Completo', 'Menu Completo', 1, '0');
  for k := 0 to FrmPrincipal.MainMenuPrincipal.Items.Count - 1 do
  begin
    VarreMainMenu(FrmPrincipal.MainMenuPrincipal.Items[k], 1, IntToStr(k + 1));
  end;
	PageControl1.ActivePageIndex := 0;
	FormRTTI.BindForm(Self);
	EdtSenha.Text := EnDecryptString(Usuarios.Senha, 236);
	EdtConfirmaSenha.Text := EdtSenha.Text;
	BuscaPermissoes;	
end;

procedure TFrmPermissoesSenhas.HabilitarAcoes(TipoOperacao: TTipoOperacao);
var
  logico: boolean;
begin
  logico               := (TipoOperacao = TTipoOperacao.Insercao) or (TipoOperacao = TTipoOperacao.Edicao);
  actCancelar.Enabled  := logico;
  actConfirmar.Enabled := logico;
  actExcluir.Enabled   := not logico;
  actInserir.Enabled   := not logico;
  actEditar.Enabled    := not logico;
end;

procedure TFrmPermissoesSenhas.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
    actSair.Execute;
  if Key = vk_F9 then
    actPesquisa.Execute;
end;

procedure TFrmPermissoesSenhas.IBDSUsuariosAfterScroll(DataSet: TDataSet);
begin
  EdtSenha.Clear;
  EdtConfirmaSenha.Clear;
end;

procedure TFrmPermissoesSenhas.TabSheet2Show(Sender: TObject);
begin
  Lista.SetFocus;
end;

end.
