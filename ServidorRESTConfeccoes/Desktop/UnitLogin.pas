unit UnitLogin;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, DBGrids, DBCtrls, ExtCtrls, Db, IBCustomDataSet, IBQuery,
  IBDatabase, IBStoredProc, Vcl.Imaging.pngimage,
  System.Generics.Collections, UnitObserver.Model.Interfaces, UnitClientREST.Model.Interfaces, UnitUsuarios.Model,
  System.JSON;

type
  TDadosAcesso = record
    Funcionario: integer;
    Modulo: string;
  end;

type
  TFrmLogin = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    EdtSenha: TEdit;
    Timer1: TTimer;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    CbLogin: TComboBox;
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure EdtSenhaKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure DBLookupComboBox1KeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);
    // function EnDecryptString(StrValue : String; Chave: Word) : String;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CbLoginKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    FRefazerMenu: Boolean;
  public
    Permissao, Senha    : string;
    TodasAsPermissoes   : TStrings;
    property RefazerMenu: Boolean read FRefazerMenu write FRefazerMenu;
    procedure BuscaPermissoes;
    { Public declarations }
  end;

var
  FrmLogin: TFrmLogin;

implementation

uses
  UnitPermissoesSenhas,
  UnitDMPrincipal,
  UnitPrincipal,
  UnitFuncoesUtils,
  Math,
  StrUtils,
  UnitInsereTabela.Model,
  UnitClientREST.Model,
  UnitConfiguracaoServidor.Singleton,
  UnitTabela.Helper.Json;

{$R *.DFM}

procedure TFrmLogin.BuscaPermissoes;
var
  Notificacao: TNotificacao;
  i: Integer;
begin
  if FrmPrincipal.TodasAsPermissoes = nil then
    FrmPrincipal.TodasAsPermissoes := TStringList.Create;
  FrmPrincipal.TodasAsPermissoes.Clear;
  // Busca todas as permissoes do usuário
  for i := 0 to High(DMPrincipal.UsuarioLogado.Permissoes) do
  begin
    FrmPrincipal.TodasAsPermissoes.Add(DMPrincipal.UsuarioLogado.Permissoes[i].Permissao);
  end;
  // Chama o método de notificação
  Notificacao.Evento      := 'Usuario Logou';
  Notificacao.Permissoes  := FrmPrincipal.TodasAsPermissoes.Text;
  DMPrincipal.Notificar(Notificacao);
end;

procedure TFrmLogin.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    if (Sender is TDBGrid) then
      TDBGrid(Sender).Perform(WM_KeyDown, VK_Tab, 0)
    else
      Perform(Wm_NextDlgCtl, 0, 0);
  end;
end;

procedure TFrmLogin.EdtSenhaKeyPress(Sender: TObject; var Key: Char);
var
  DadosAcesso: TDadosAcesso;
  Response: TClientResult;
begin
  if Key = #13 then
  begin
    DMPrincipal.UsuarioLogado.Login := CbLogin.Text;
    DMPrincipal.UsuarioLogado.Senha := EdtSenha.Text;
    Response := TClientREST.New(TConfiguracaoServidor.BaseURL+'/login')
                            .AddHeader('Content-Type', 'application/json')
                            .AddBody(TJSONObject.ParseJSONValue(DMPrincipal.UsuarioLogado.ToJson) as TJSONObject)
                            .Post();
    if (Response.StatusCode <> 200) then
    begin
      Showmessage('Usuário não permitido ou senha incorreta. Por favor tente novamente!');
    end
    else
    begin
      DMPrincipal.UsuarioLogado   := DMPrincipal.UsuarioLogado.fromJson<TUsuarios>(Response.Content);
      DMPrincipal.UsuarioLogado.Senha := EdtSenha.Text;
      BuscaPermissoes;
      // registra acesso
      DadosAcesso.Funcionario := DMPrincipal.UsuarioLogado.fun_codigo;
      DadosAcesso.Modulo      := LeftStr(Permissao, 25);
      EdtSenha.Clear;
      ModalResult := mrOk;
    end;
  end;
end;

procedure TFrmLogin.FormShow(Sender: TObject);
begin
  CbLogin.SetFocus;
  if FrmPrincipal.UsaLoginPorModulo = 'N' then
    Timer1.Enabled := DMPrincipal.UsuarioLogado.Codigo > 0;
end;

procedure TFrmLogin.CbLoginKeyPress(Sender: TObject; var Key: Char);
begin
  if key = #13 then
    EdtSenha.SetFocus;
end;

procedure TFrmLogin.DBLookupComboBox1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
  begin
    EdtSenha.Clear;
    ModalResult := mrCancel;
  end;
end;

procedure TFrmLogin.FormCreate(Sender: TObject);
var
  Response: TClientResult;
  aJson: TJSONArray;
  usuarioJsonValue: TJSONValue;
  Usuario: TUsuarios;
begin
  CbLogin.Items.Clear;
  Response := TClientREST.New(TConfiguracaoServidor.BaseURL+'/usuarios').Get();
  if Response.StatusCode = 200 then
  begin
    aJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONArray;
    for usuarioJsonValue in aJson do
    begin
      Usuario := TUsuarios.Create.fromJson<TUsuarios>(usuarioJsonValue.ToJSON);
      CbLogin.Items.Add(Usuario.Login);
    end;
  end;
end;

procedure TFrmLogin.FormDestroy(Sender: TObject);
begin
  FrmLogin := nil;
end;

procedure TFrmLogin.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
    ModalResult := mrCancel;
  Key           := 0;
end;

procedure TFrmLogin.Timer1Timer(Sender: TObject);
var
  Tecla: Char;
begin
  Timer1.Enabled             := False;
  Tecla                      := #13;
  CbLogin.ItemIndex := CbLogin.Items.IndexOf(DMPrincipal.UsuarioLogado.Login);
  EdtSenha.Text                 := DMPrincipal.UsuarioLogado.Senha;
  EdtSenhaKeyPress(Sender, Tecla);
end;

end.
