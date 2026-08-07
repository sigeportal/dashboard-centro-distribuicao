unit UnitPrincipal;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, IBServices, StdCtrls, Buttons, ExtCtrls, jpeg, Db,
  IBCustomDataSet, IBQuery, ComCtrls, Mask, Registry, AppEvnts,
  Vcl.Imaging.pngimage, System.ImageList, Vcl.ImgList, System.Actions, Vcl.ActnList,
  Vcl.WinXCtrls, Vcl.CategoryButtons, Vcl.ToolWin, QuickRpt, QRPrntr,
  UnitObserver.Model.Interfaces, UnitClientREST.Model.Interfaces;

type
  TFrmPrincipal = class(TForm, iObservador)
    MainMenuPrincipal: TMainMenu;
    Cadastro: TMenuItem;
    Movimentaes1: TMenuItem;
    Manuteno1: TMenuItem;
    Oramento1: TMenuItem;
    Senha1: TMenuItem;
    Diversos1: TMenuItem;
    Panel1: TPanel;
    N5DesligarUsurio1: TMenuItem;
    N8Sair1: TMenuItem;
    N6ConectaBD1: TMenuItem;
    ApplicationEvents1: TApplicationEvents;
    Image1: TImage;
    ToolBarPrincipal: TToolBar;
    ActionList1: TActionList;
    Image2: TImage;
    actSair: TAction;
    TimerReabrirModulo: TTimer;
    N1Empresa1: TMenuItem;
    actCadEmpresa: TAction;
    ToolButton9: TToolButton;
    N3Relatrios1: TMenuItem;
    N2Histrico1: TMenuItem;
    actCadProdutos: TAction;
    Produtos1: TMenuItem;
    actCadGrupoSubGrupo: TAction;
    Grupos1: TMenuItem;
    actFornecedores: TAction;
    actFornecedores1: TMenuItem;
    actCadFuncionarios: TAction;
    Funcionarios1: TMenuItem;
    actPedidos: TAction;
    Pedidos1: TMenuItem;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    N2EtiquetasLazer1: TMenuItem;
    N3EtiquetasRibbon1: TMenuItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Senha1Click(Sender: TObject);
    procedure N5DesligarUsurio1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure N6ConectaBD1Click(Sender: TObject);
    procedure Oramento1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure N8Sair1Click(Sender: TObject);
    procedure actSairExecute(Sender: TObject);
    procedure actCadEmpresaExecute(Sender: TObject);
    procedure N2Histrico1Click(Sender: TObject);
    procedure actCadProdutosExecute(Sender: TObject);
    procedure actCadGrupoSubGrupoExecute(Sender: TObject);
    procedure actFornecedoresExecute(Sender: TObject);
    procedure actCadFuncionariosExecute(Sender: TObject);
    procedure actPedidosExecute(Sender: TObject);
    procedure N2EtiquetasLazer1Click(Sender: TObject);
    procedure N3EtiquetasRibbon1Click(Sender: TObject);
  private
    { Private declarations }
    function Atualizar(Notificacao: TNotificacao): iObservador;
  public
    { Public declarations }
    Tipo, Conta, Porta: string;
    Parametro1, Parametro2, UsaLoginPorModulo: string;
    VerificaTexto: string;
    PDV, i, Tipo_Venda: integer;
    TodasAsPermissoes: TStringList;
    PortaBematechAberta: Boolean;
    Rodape: string;
    procedure HabilitaMenu(Habilitar: Boolean);
    procedure HabilitaItemMenu(Item: TMenuItem; Contador: integer);
    procedure HabilitaMainMenu;
  end;

var
  FrmPrincipal: TFrmPrincipal;
  Form: string;
  Campos: string;

implementation

uses
  UnitConfigIniciaisServidor,
  UnitDMPrincipal,
  UnitPermissoesSenhas,
  UnitLogin,
  UnitSobre,
  UnitCadEmpresa,
  UnitConfiguracaoServidor.Singleton,
  UnitFuncoesUtils,
  UnitRelGeral,
  UnitCadProduto, 
  UnitCadGrupoSubGrupo, 
  UnitCadFornecedores,
	UnitTabela.Helper.Json, 
  UnitEmpresa.Model, UnitCadFuncionario, UnitPedidos.View, UnitEtiquetasRibbon,
  UnitCodBarra;

{$R *.DFM}

procedure TFrmPrincipal.HabilitaItemMenu(Item: TMenuItem; Contador: integer);
var
  i, PosicaoTraco, ContaItem, ImgIndex: smallint;
begin
  Item.Visible := (FrmPrincipal.TodasAsPermissoes.IndexOf('MMenu_Completo') > -1) or (FrmPrincipal.TodasAsPermissoes.IndexOf('M' + Item.Name) > -1) or
    (Item.Hint = 'DESLIGAR') or (Item.Hint = 'SAIR');
  if Item.Visible then
  begin
    PosicaoTraco := Pos('-', Item.Caption);
    Item.Caption := '&' + IntToStr(Contador) + '- ' + Copy(Item.Caption, PosicaoTraco + 2, Length(Item.Caption));
  end;
  ContaItem := 1;
  ImgIndex  := 0;
  for i     := 0 to Item.Count - 1 do
  begin
    // Item.Items[i].ImageIndex := ImgIndex;
    // Inc(ImgIndex, 1);
    HabilitaItemMenu(Item.Items[i], ContaItem);
    if Item.Items[i].Visible then
      Inc(ContaItem, 1);
  end;
end;

procedure TFrmPrincipal.HabilitaMainMenu;
var
  TopoBotao, i, ContaMenu: smallint;
begin
  ContaMenu := 1;
  // Habilita ou desabilita os menus do sistema de acordo com as permissoes do usuario
  for i := 0 to MainMenuPrincipal.Items.Count - 1 do
  begin
    HabilitaItemMenu(MainMenuPrincipal.Items[i], ContaMenu);
    if MainMenuPrincipal.Items[i].Visible then
      Inc(ContaMenu, 1);
  end;
  TopoBotao := 40;
  // Habilita/Desabilita os bot�es da Tela Principal de acordo com seus menus
  for i := 0 to Panel1.ControlCount - 1 do
  begin
    if Panel1.Controls[i] is TSpeedButton then
    begin
      TSpeedButton(Panel1.Controls[i]).Visible := (FrmPrincipal.TodasAsPermissoes.IndexOf('MMenu_Completo') > -1) or
        (FrmPrincipal.TodasAsPermissoes.IndexOf('M' + TSpeedButton(Panel1.Controls[i]).Hint) > -1) or (TSpeedButton(Panel1.Controls[i]).Hint = 'SAIR');
      // Reajusta a altura do botão, caso seja necessário. Para que fique espaços (desproporcionais) entre eles
      if TSpeedButton(Panel1.Controls[i]).Visible then
      begin
        TSpeedButton(Panel1.Controls[i]).Top := TopoBotao;
        Inc(TopoBotao, 75);
      end;
    end;
  end;
end;

procedure TFrmPrincipal.HabilitaMenu(Habilitar: Boolean);
var
  y: smallint;
  ToolButton: TToolButton;
begin
  if not Habilitar then
    FrmPrincipal.Menu := TMainMenu.Create(nil);
  for y               := 0 to MainMenuPrincipal.Items.Count - 1 do
  begin
    MainMenuPrincipal.Items[y].Enabled := Habilitar;
  end;
  if Habilitar then
    FrmPrincipal.Menu      := MainMenuPrincipal;
  Panel1.Visible           := Habilitar;
  ToolBarPrincipal.Visible := Habilitar;
  if Panel1.Visible then
  begin
    Self.SetFocusedControl(ToolBarPrincipal);
  end;
end;

procedure TFrmPrincipal.N2EtiquetasLazer1Click(Sender: TObject);
begin
	AbreModulo('M' + TMenuItem(Sender).Name, TFrmCodBarra, FrmCodBarra, true);
end;

procedure TFrmPrincipal.N2Histrico1Click(Sender: TObject);
begin
	AbreModulo('M' + TMenuItem(Sender).Name, TFrmRelGeral, FrmRelGeral, True);
end;

procedure TFrmPrincipal.N3EtiquetasRibbon1Click(Sender: TObject);
begin
	AbreModulo('M' + TMenuItem(Sender).Name, TFrmEtiquetasRibbon, FrmEtiquetasRibbon, True);
end;

procedure TFrmPrincipal.N5DesligarUsurio1Click(Sender: TObject);
begin
  DMPrincipal.UsuarioLogado.Codigo := 0;
  FrmPrincipal.Caption      := 'SIGE - Sistema Integrado de Gerenciamento Empresarial | --  Usuário: Desligado';
  if FrmLogin = nil then
    FrmLogin         := TFrmLogin.Create(nil);
  FrmLogin.Permissao := 'Logar';
  FrmLogin.ShowModal;
end;

procedure TFrmPrincipal.N6ConectaBD1Click(Sender: TObject);
begin
  if FrmConfigIniciaisServidor = nil then
    FrmConfigIniciaisServidor := TFrmConfigIniciaisServidor.Create(nil);
  FrmConfigIniciaisServidor.ShowModal;
end;

procedure TFrmPrincipal.N8Sair1Click(Sender: TObject);
begin
  Close;
end;

procedure TFrmPrincipal.Oramento1Click(Sender: TObject);
begin
  if FrmSobre = nil then
    FrmSobre := TFrmSobre.Create(nil);
  FrmSobre.ShowModal;
end;

procedure TFrmPrincipal.Senha1Click(Sender: TObject);
begin
  AbreModulo('M' + TMenuItem(Sender).Name, TFrmPermissoesSenhas, FrmPermissoesSenhas);
end;

procedure TFrmPrincipal.actCadEmpresaExecute(Sender: TObject);
begin
  AbreModulo('M' + TMenuItem(Sender).Name, TFrmCadEmpresa, FrmCadEmpresa, True);
end;

procedure TFrmPrincipal.actCadFuncionariosExecute(Sender: TObject);
begin
	AbreModulo('M' + TMenuItem(Sender).Name, TFrmCadFuncionario, FrmCadFuncionario);
end;

procedure TFrmPrincipal.actCadGrupoSubGrupoExecute(Sender: TObject);
begin
	AbreModulo('M' + TMenuItem(Sender).Name, TFrmCadGrupoSubGrupo, FrmCadGrupoSubGrupo);
end;

procedure TFrmPrincipal.actCadProdutosExecute(Sender: TObject);
begin
  AbreModulo('M' + TMenuItem(Sender).Name, TFrmCadProdutos, FrmCadProdutos, true);
end;

procedure TFrmPrincipal.actFornecedoresExecute(Sender: TObject);
begin
	AbreModulo('M' + TMenuItem(Sender).Name, TFrmCadFornecedores, FrmCadFornecedores);
end;

procedure TFrmPrincipal.actPedidosExecute(Sender: TObject);
begin
	AbreModulo('M' + TMenuItem(Sender).Name, TFrmPedidos, FrmPedidos, true);
end;

procedure TFrmPrincipal.actSairExecute(Sender: TObject);
begin
  Close;
end;

function TFrmPrincipal.Atualizar(Notificacao: TNotificacao): iObservador;
begin
  /// //
end;

procedure TFrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Application.MessageBox('Deseja realmente sair da aplicação?', 'Confirmar', MB_YESNO + MB_ICONQUESTION) = IDYes then
  begin
    DestroiForms;
    Application.Terminate;
    KillTask(Application.ExeName);
  end
  else
    Action := canone;
end;

procedure TFrmPrincipal.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
    Close;
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
  // CONECTA OU ABRE A TELA DE CONFIGURACAO
  ConectaServidor;
  UsaLoginPorModulo := 'N';
  FrmPrincipal.HabilitaMenu(True);
  Rodape                    := 'Portal.com : (67) 3467-3694';
  FrmLogin                  := TFrmLogin.Create(nil);
  FrmLogin.Senha            := '1';
  N5DesligarUsurio1.Visible := False;
  if UsaLoginPorModulo = 'N' then
  begin
    N5DesligarUsurio1.Visible := True;
    FrmLogin.Permissao        := 'Logar';
    if FrmLogin.ShowModal <> MrOk then
      Application.Terminate;
	end;
	DMPrincipal.Empresa := DMPrincipal.Empresa.Get<TEmpresa>(1)
end;

end.
