unit UnitCodBarra;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, IBDatabase, IBCustomDataSet, IBTable, IBQuery, Grids, DBGrids,
  ComCtrls, StdCtrls, ExtCtrls, DBClient, Menus, ACBrBarCode, Vcl.Buttons, JvExStdCtrls, JvEdit, JvValidateEdit,
  UnitProdutos.Model, System.Threading;

type
  TFrmCodBarra = class(TForm)
    Label2: TLabel;
    Label5: TLabel;
    Label8: TLabel;
    BtnInserir: TButton;
    cbTipo: TComboBox;
    chkLegenda: TCheckBox;
    EdtCodigo: TEdit;
    DBGrid1: TDBGrid;
    EdtQtdEtiq: TEdit;
    DSProdutos: TDataSource;
    Label17: TLabel;
    Shape5: TShape;
    Shape3: TShape;
    EdtPularEtiq: TEdit;
    Label9: TLabel;
    Shape4: TShape;
    Shape1: TShape;
    EdtNome: TEdit;
    Label1: TLabel;
    CDSProdutos: TClientDataSet;
    CDSProdutosCODIGO: TIntegerField;
    CDSProdutosNOME: TStringField;
    CDSProdutosCOD_BARRA: TStringField;
    CDSProdutosQUANT: TIntegerField;
    PopupMenu1: TPopupMenu;
    Excluir1: TMenuItem;
    BtnImprimir: TBitBtn;
    Label3: TLabel;
    Shape2: TShape;
    Label4: TLabel;
    Shape6: TShape;
    CDSProdutosVLR_VISTA: TCurrencyField;
    CDSProdutosVLR_PARCELADO: TCurrencyField;
    EdtValorVista: TJvValidateEdit;
    EdtValorParcelado: TJvValidateEdit;
    IBQRCompra: TIBQuery;
    IBQRCompraPRO_CODIGO: TIntegerField;
    IBQRCompraPRO_NOME: TIBStringField;
    IBQRCompraPRO_VALORV: TIBBCDField;
    IBQRCompraPRO_VALORV_PRAZO: TIBBCDField;
    IBQRCompraCE_QUANTIDADE: TIBBCDField;
    IBQRCompraPRO_CODBARRA: TIBStringField;
    procedure EdtCodigoKeyPress(Sender: TObject; var Key: Char);
    procedure BtnInserirClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure EdtCodigoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure BtnImprimirClick(Sender: TObject);
    procedure Excluir1Click(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure cbTipoKeyPress(Sender: TObject; var Key: Char);
    procedure BtnAlternaFiltroClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure Atribuir;
    { Private declarations }
  public
    Cad: String;
    Produto   : TProdutos;
    { Public declarations }
  end;

var
  FrmCodBarra: TFrmCodBarra;
  DigitoPEG: string;

implementation

uses 
	UnitDMPrincipal, 
  UnitPrincipal, 
  UnitGridProduto,
  UnitCadProduto, 
  UnitEtiquetaL45_A12, 
  UnitEtiquetaL21_A15, 
  System.IniFiles, 
  UnitEtiquetaL65_A25,
  UnitEtiquetaEAN13_MaxPrint, 
  UnitEtiquetaEAN13_Pimaco, 
  UnitEtiquetaL34_A21,
  UnitTabela.Helper.Json;

{$R *.DFM}

function RetZero(ZEROS: string; QUANT: Integer): String;
var
  I, Tamanho: Integer;
  aux: string;
begin
  aux     := ZEROS;
  Tamanho := length(ZEROS);
  ZEROS   := '';
  for I   := 1 to QUANT - Tamanho do
    ZEROS := ZEROS + '0';
  aux     := ZEROS + aux;
  RetZero := aux;
end;

procedure TFrmCodBarra.Atribuir;
begin
  // CJVBarcode.Legenda := chkLegenda.Checked;
  // CJVBarcode.Texto := eNumero.Text;
end;

procedure TFrmCodBarra.EdtCodigoKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) and (Label5.Caption = 'Código') then
  begin
    if EdtCodigo.Text = '' then
    begin
      if CDSProdutos.IsEmpty then
        EdtCodigo.SetFocus
      else
        EdtPularEtiq.SetFocus;
    end
    else
    begin
      Produto := Produto.Get<TProdutos>(StrToInt(EdtCodigo.Text));
			if Produto.Codigo = 0 then
			begin
				ShowMessage('Registro não encontrado!!');
				EdtCodigo.Clear;
				EdtCodigo.SetFocus;
			end;
      EdtNome.Text                 := Produto.Nome;
      EdtValorVista.AsCurrency     := Produto.Valorv;
      EdtValorParcelado.AsCurrency := Produto.Valorp;
      EdtValorVista.SetFocus;
    end;
  end;
  if not(Key in ['0' .. '9', chr(vk_back)]) then
    Key := #0;
end;

procedure TFrmCodBarra.BtnInserirClick(Sender: TObject);
begin
  if Produto.Codigo = 0 then
  begin
    ShowMessage('Escolha um Produto!');
    EdtCodigo.SetFocus;
    Exit;
  end;
  if EdtQtdEtiq.Text = '' then
  begin
    ShowMessage('Digite a quantidade de etiquetas para este Produto!');
    EdtQtdEtiq.SetFocus;
    Exit;
  end;
  CDSProdutos.Append;
  CDSProdutosCODIGO.Value        := Produto.Codigo;
  CDSProdutosCOD_BARRA.Value     := Produto.Codbarra;
  CDSProdutosVLR_VISTA.Value     := EdtValorVista.AsCurrency;
  CDSProdutosVLR_PARCELADO.Value := EdtValorParcelado.AsCurrency;
  CDSProdutosNOME.Value          := Produto.Nome;
  CDSProdutosQUANT.Text          := EdtQtdEtiq.Text;
  CDSProdutos.Post;
  EdtCodigo.Clear;
  EdtNome.Clear;
  EdtQtdEtiq.Clear;
  EdtCodigo.SetFocus;
  EdtValorVista.Clear;
  EdtValorParcelado.Clear;
end;

procedure TFrmCodBarra.cbTipoKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    BtnImprimir.SetFocus;
end;

procedure TFrmCodBarra.FormShow(Sender: TObject);
var
  Config: TInifile;
  ENTER: Char;
begin
  try
    Config           := TInifile.Create(ChangeFileExt(ParamStr(0), '.ini'));
    cbTipo.ItemIndex := Config.ReadInteger('CONFIG_COD_BARRA', 'ItemIndex', 0);
  finally
    Config.Free;
  end;
  EdtCodigo.SetFocus;
  if CDSProdutos.IsEmpty then
  begin
    CDSProdutos.Close;
    CDSProdutos.CreateDataSet;
  end;
  if Produto.Codigo > 0 then
  begin
  	TTask.Run(
    procedure   	
    begin
    	Sleep(300);
      ENTER := #13;
      EdtCodigo.Text := Produto.Codigo.ToString;
      EdtCodigoKeyPress(Sender, ENTER);
    end);
  end;
end;

procedure TFrmCodBarra.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
  begin
    if Application.MessageBox('Deseja fechar o Módulo de Etiquetas?', 'Sair', MB_YesNo + MB_ICONQUESTION) = IDYes then
    begin
      Close;
    end;
  end;
end;

procedure TFrmCodBarra.FormClose(Sender: TObject; var Action: TCloseAction);
var
  Config: TInifile;
begin
  try
    Config := TInifile.Create(ChangeFileExt(ParamStr(0), '.ini'));
    Config.WriteInteger('CONFIG_COD_BARRA', 'ItemIndex', cbTipo.ItemIndex);
  finally
    Config.Free;
  end;
  FrmPrincipal.HabilitaMenu(True);
  Action := cafree;
end;

procedure TFrmCodBarra.FormCreate(Sender: TObject);
begin
	Produto := TProdutos.Create;
end;

procedure TFrmCodBarra.FormDestroy(Sender: TObject);
begin
	Produto.DisposeOf;
  FrmCodBarra := nil;
end;

procedure TFrmCodBarra.EdtCodigoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = 40) then
	begin
		if FrmGridProduto = nil then
			FrmGridProduto := TFrmGridProduto.Create(nil);
		if (FrmGridProduto.ShowModal = mrOk) and (DMPrincipal.CodigoPesquisado > 0) then
		begin
			TEdit(Sender).Text := DMPrincipal.CodigoPesquisado.ToString;
		end;
	end;
end;

procedure TFrmCodBarra.BtnAlternaFiltroClick(Sender: TObject);
begin
  EdtCodigo.Clear;
  EdtNome.Clear;
  EdtValorVista.Clear;
  EdtValorParcelado.Clear;
  EdtQtdEtiq.Text := '1';  
  EdtCodigo.SetFocus;
end;

procedure TFrmCodBarra.BtnImprimirClick(Sender: TObject);
begin
  if EdtPularEtiq.Text = '' then
    EdtPularEtiq.Text := '0';
  if CDSProdutos.State in [DsInsert, DsEdit] then
    CDSProdutos.Post;
  if cbTipo.ItemIndex = 0 then
  begin
    if FrmEtiquetaEAN13_MaxPrint = nil then
      FrmEtiquetaEAN13_MaxPrint := TFrmEtiquetaEAN13_MaxPrint.Create(nil);
    FrmEtiquetaEAN13_MaxPrint.QuickRep2.Preview;
  end
  else if cbTipo.ItemIndex = 1 then
  begin
    if FrmEtiquetaEAN13_Pimaco = nil then
      FrmEtiquetaEAN13_Pimaco := TFrmEtiquetaEAN13_Pimaco.Create(nil);
    FrmEtiquetaEAN13_Pimaco.QuickRep2.Preview;
  end
  else if cbTipo.ItemIndex = 2 then
  begin
    if FrmEtiquetaL45_A12 = nil then
      FrmEtiquetaL45_A12 := TFrmEtiquetaL45_A12.Create(nil);
    FrmEtiquetaL45_A12.QuickRep1.Preview;
  end
  else if cbTipo.ItemIndex = 3 then
  begin
    if FrmEtiquetaL21_A15 = nil then
      FrmEtiquetaL21_A15 := TFrmEtiquetaL21_A15.Create(nil);
    FrmEtiquetaL21_A15.QuickRep1.Preview;
  end
  else if cbTipo.ItemIndex = 4 then
  begin
    if FrmEtiquetaL65_A25 = nil then
      FrmEtiquetaL65_A25 := TFrmEtiquetaL65_A25.Create(nil);
    FrmEtiquetaL65_A25.QuickRep2.Preview;
  end
  else if cbTipo.ItemIndex = 5 then
  begin
    if FrmEtiquetaL34_A21 = nil then
      FrmEtiquetaL34_A21 := TFrmEtiquetaL34_A21.Create(nil);
    FrmEtiquetaL34_A21.QuickRep2.Preview;
  end;
end;

procedure TFrmCodBarra.Excluir1Click(Sender: TObject);
begin
  if CDSProdutos.IsEmpty then
    Exit;
  EdtCodigo.Text := CDSProdutosCODIGO.AsString;
  EdtNome.Clear;
  EdtQtdEtiq.Clear;
  CDSProdutos.Delete;
  EdtCodigo.SetFocus;
end;

procedure TFrmCodBarra.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    if (Sender is TDBGrid) then
      TDBGrid(Sender).Perform(WM_KeyDown, VK_Tab, 0)
    else
      Perform(Wm_NextDlgCtl, 0, 0);
  end;
end;

end.
