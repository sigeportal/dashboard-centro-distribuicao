unit UnitCadProduto;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
	Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UnitFormCadastroRTTI, System.Actions,
	Vcl.ActnList, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, UnitProdutos.Model,
	Vcl.Mask, Vcl.StdCtrls, Data.DB, Vcl.DBCtrls, Vcl.Grids, Vcl.DBGrids,
	Vcl.Imaging.jpeg, UnitDMPrincipal, UnitFormRTTI.Interfaces, JvValidateEdit,
	JvExStdCtrls, JvEdit, Vcl.ExtDlgs, System.ImageList, Vcl.ImgList, Vcl.Buttons,
	UnitClientREST.Model.Interfaces, UnitFuncoesUtils, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, IBX.IBCustomDataSet,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, UnitPortalQueryREST.Component;

type
	TFrmCadProdutos = class(TFrmCadastroRTTI)
		GroupBox1: TGroupBox;
		Label1: TLabel;
		Label2: TLabel;
		Label4: TLabel;
		Label5: TLabel;
		Label14: TLabel;
		Label20: TLabel;
		Label19: TLabel;
		Label24: TLabel;
		Image1: TImage;
		[Validador('Nome Produto')]
		[TLigarCampos('PRO_NOME')]
		EdtNome: TEdit;
		[TLigarCampos('PRO_LOCAL')]
		EdtLocal: TEdit;
		[TLigarCampos('PRO_IAT')]
		CbxIndArredondamento: TComboBox;
		[TLigarCampos('PRO_DATAUA')]
		EdtDataUlteracao: TDateTimePicker;
		[TLigarCampos('PRO_ABC')]
		EdtABC: TEdit;
		[TLigarCampos('PRO_CODBARRA')]
		EdtCodBarra: TEdit;
		EdtGrupoSubGrupo: TButtonedEdit;
		GroupBox2: TGroupBox;
		Label7: TLabel;
		Label8: TLabel;
		Label9: TLabel;
		Label10: TLabel;
		Label11: TLabel;
		Label12: TLabel;
		Label15: TLabel;
		Label16: TLabel;
		Label18: TLabel;
		Label21: TLabel;
		Label37: TLabel;
		Label31: TLabel;
		[TLigarCampos('PRO_QUANTIDADEM')]
		EdtQtdMinima: TJvValidateEdit;
		[TLigarCampos('PRO_QUANTIDADE')]
		EdtQuantidade: TJvValidateEdit;
		[TLigarCampos('PRO_EMBALAGEM')]
		EdtEmbalagem: TEdit;
		[TLigarCampos('PRO_VALORL')]
		EdtCustoOperacional: TJvValidateEdit;
		[TLigarCampos('PRO_DATAUC')]
		EdtDataUltCompra: TDateTimePicker;
		[TLigarCampos('PRO_VALORF')]
		EdtCustoMercadoria: TJvValidateEdit;
		[TLigarCampos('PRO_VALORS')]
		EdtPrecoSugerido: TJvValidateEdit;
		DBGrid1: TDBGrid;
		GroupBox3: TGroupBox;
		Label26: TLabel;
		Label27: TLabel;
		Label39: TLabel;
		Label41: TLabel;
		Label42: TLabel;
		Label43: TLabel;
		Label45: TLabel;
		Label46: TLabel;
		Label47: TLabel;
		Label48: TLabel;
		Label49: TLabel;
		Label28: TLabel;
		Label40: TLabel;
		Label29: TLabel;
		[TLigarCampos('PRO_GTIN')]
		EdtGTIN: TEdit;
		[TLigarCampos('PRO_IPPT')]
		CbxIndProducao: TComboBox;
		[TLigarCampos('PRO_ALIQICMS_OPINT')]
		EdtAliqOpInternas: TJvValidateEdit;
		[TLigarCampos('PRO_PERC_RED_OPINT')]
		EdtPercRedOpInterna: TJvValidateEdit;
		[Validador('Estado')]
		[TLigarCampos('PRO_ESTADO')]
		CbxEstado: TComboBox;
		[TLigarCampos('PRO_NCM')]
		EdtNCM: TEdit;
		EdtGenero: TEdit;
		CbxTotalizadores: TComboBox;
		CbxUnidadeMedida: TComboBox;
		CbxExNCM: TComboBox;
		EdtDescricaoNCM: TEdit;
		AliqAproximadaTributos: TJvValidateEdit;
		[TLigarCampos('PRO_CODIGO', True)]
		lbCodigo: TLabel;
		CbxTipoItem: TComboBox;
		[TLigarCampos('PRO_VALORC')]
		EdtCusto: TJvValidateEdit;
		[TLigarCampos('PRO_VALORCM')]
		EdtCustoMedio: TJvValidateEdit;
		[TLigarCampos('PRO_VALORV')]
		EdtValorVista: TJvValidateEdit;
		[TLigarCampos('PRO_VALORP')]
		EdtValorPrazo: TJvValidateEdit;
		[Validador('Fornecedor')]
		CbxFornecedor: TComboBox;
		ImageList1: TImageList;
		CarregaFoto: TOpenPictureDialog;
		actPesquisar: TAction;
		ToolButton1: TToolButton;
		ToolButton2: TToolButton;
		PnlFoto: TPanel;
		ImgFoto: TImage;
		Panel3: TPanel;
		actCarregarFoto: TAction;
		actDesvincularFoto: TAction;
		ToolBar1: TToolBar;
		ToolButton6: TToolButton;
		ToolButton15: TToolButton;
		ToolButton16: TToolButton;
		ToolButton17: TToolButton;
    actCadGrades: TAction;
    ToolButton18: TToolButton;
    ToolButton22: TToolButton;
    IBQRGrade: TPortalQueryREST;
    IBQRGradeGRA_CODIGO: TIntegerField;
    IBQRGradeTAM_TAMANHO: TIBStringField;
    IBQRGradeGRA_VALOR: TIBBCDField;
    IBQRGradeGRA_QUANTIDADE: TIBBCDField;
    IBQRGradeGRA_TAM: TIntegerField;
    IBQRGradeGRA_CODBARRA: TIBStringField;
    IBQRGradeGRA_COR: TIBStringField;
    DSGrade: TDataSource;
    actGerarEtiquetas: TAction;
    ToolButton23: TToolButton;
    ToolButton24: TToolButton;
    actEtiquetasRibbon: TAction;
    ToolButton25: TToolButton;
		procedure FormDestroy(Sender: TObject);
		procedure actExcluirExecute(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure EdtGrupoSubGrupoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure EdtGrupoSubGrupoRightButtonClick(Sender: TObject);
		procedure FormShow(Sender: TObject);
		procedure EdtFornecedoresKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure actConfirmarExecute(Sender: TObject);
		procedure ImgFotoClick(Sender: TObject);
		procedure actInserirExecute(Sender: TObject);
		procedure actEditarExecute(Sender: TObject);
		procedure actPesquisarExecute(Sender: TObject);
		procedure EdtGrupoSubGrupoKeyPress(Sender: TObject; var Key: Char);
		procedure actCarregarFotoExecute(Sender: TObject);
		procedure actDesvincularFotoExecute(Sender: TObject);
    procedure actCadGradesExecute(Sender: TObject);
    procedure actGerarEtiquetasExecute(Sender: TObject);
    procedure actEtiquetasRibbonExecute(Sender: TObject);
	private
		{ Private declarations }
		Produto: TProdutos;
		procedure BuscaSubGrupo(CodSubGrupo: integer);
		procedure BuscaFornecedor(CodFornecedor: integer);
		procedure BuscaTotalizador(CodTotalizador: integer);
		procedure BuscaUnidadeMedida(CodUnidadeMedida: integer);
		procedure BuscaFotoProduto(Url: string);
		procedure BuscaTipoItem(Tipo: string);
		procedure LogUpload(msg: string);
	public
		{ Public declarations }
    ExibePanelPrincipal: Boolean;
    procedure BuscaDadosProduto(Codigo: integer);		
	end;

var
	FrmCadProdutos: TFrmCadProdutos;

implementation

{$R *.dfm}

uses
	UnitGrid,
	UnitPrincipal,
	UnitSubGrupos.Model,
	UnitTabela.Helper.Json,
	UnitFornecedores.Model,
	UnitTotalizadores.Model,
	UnitUnidadeMedida.Model,
	Bitmap.HelperClass,
	UnitClientREST.Model,
	UnitConfiguracaoServidor.Singleton,
	System.Json,
	UnitAmpliaFoto,
	UnitGrupos.Model, 
  UnitUploadCloudStorage.Model, 
  UnitGridProduto, UnitCadGrades, UnitCodBarra, UnitEtiquetasRibbon;

procedure TFrmCadProdutos.actCadGradesExecute(Sender: TObject);
begin
  inherited;
	if FrmCadGrades = nil then
		FrmCadGrades         := TFrmCadGrades.Create(nil);
	FrmCadGrades.Produto   := Produto.Codigo;
	FrmCadGrades.Pro_Valor := Produto.Valorv;
  FrmCadGrades.ShowModal;
  BuscaDadosProduto(Produto.Codigo);
end;

procedure TFrmCadProdutos.actCarregarFotoExecute(Sender: TObject);
var
	Response          : TClientResult;
	oJson             : TJSONObject;
	UploadCloudStorage: TUploadCloudStorage;
	UrlArquivo        : string;
begin
	inherited;
	if CarregaFoto.Execute then
	begin
		UploadCloudStorage := TUploadCloudStorage.Create;
		try
			UploadCloudStorage.LogUpload   := LogUpload;
			UploadCloudStorage.NomeArquivo := CarregaFoto.FileName;
			UploadCloudStorage.Diretorio   := 'Produtos';
			UrlArquivo                     := UploadCloudStorage.Upload;
			if not UrlArquivo.IsEmpty then
			begin
				Produto.URL_Imagem := UrlArquivo;
				Response           := Produto.Put;
				if Response.StatusCode = 200 then
				begin
					ShowMessage('Imagem atualizada com sucesso!');
					BuscaFotoProduto(UrlArquivo);
				end
				else
				begin
					ShowMessage('Falha ao enviar imagem!' + sLineBreak + Response.Content + sLineBreak + Response.Error);
				end;
			end;
		finally
			UploadCloudStorage.DisposeOf;
		end;
	end;
end;

procedure TFrmCadProdutos.actConfirmarExecute(Sender: TObject);
begin
	if Self.ValidarCampos then
	begin
		if CbxIndArredondamento.ItemIndex = -1 then
			CbxIndArredondamento.ItemIndex := 0;
		if CbxIndProducao.ItemIndex = -1 then
			CbxIndProducao.ItemIndex := 0;
		Produto.ForCodigo          := TFornecedores(CbxFornecedor.Items.Objects[CbxFornecedor.ItemIndex]).Codigo;
		Produto.Gru                := Produto.SubGrupo.Codigo;
		if CbxUnidadeMedida.ItemIndex <> -1 then
			Produto.Um := TUnidadeMedida(CbxUnidadeMedida.Items.Objects[CbxUnidadeMedida.ItemIndex]).Codigo
		else
			Produto.Um := 1;
		if CbxTotalizadores.ItemIndex <> -1 then
			Produto.CodTotalizador := TTotalizadores(CbxTotalizadores.Items.Objects[CbxTotalizadores.ItemIndex]).Codigo
		else
			Produto.CodTotalizador := 1;
		if not String(CbxTipoItem.Text).IsEmpty then
			Produto.Tipo_item := String(CbxTipoItem.Text).Substring(0, 2);
		inherited;
	end;
end;

procedure TFrmCadProdutos.actDesvincularFotoExecute(Sender: TObject);
var
	Response: TClientResult;
begin
	inherited;
	if (FrmPrincipal.TodasAsPermissoes.IndexOf('PRemover Foto Produto') < 0) then
	begin
		ShowMessage('Usuário sem permissão para remover a foto do Produto!');
		Exit;
	end;
	if Application.MessageBox('Deseja desvincular a foto deste Produto?', 'Desvincular foto', MB_YESNO + MB_ICONQUESTION) = IDYes then
	begin
		try
			Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/produtos/foto/' + Produto.Codigo.ToString).Delete();
			if Response.StatusCode = 200 then
			begin
				Application.MessageBox('Imagem deletada com sucesso', 'Deletar imagem no servidor', MB_OK + MB_ICONINFORMATION);
				BuscaFotoProduto('');
			end
			else
				raise Exception.Create('Houve erro ao enviar a foto para o servidor!' + sLineBreak + Response.Content + sLineBreak + Response.StatusCode.ToString);
		except
			on E: Exception do
			begin
				ShowMessage(E.Message);
			end;
		end;
	end;
end;

procedure TFrmCadProdutos.actEditarExecute(Sender: TObject);
begin
	inherited;
	if (Produto.Codigo > 0) and String(EdtCodBarra.Text).IsEmpty then
		EdtCodBarra.Text := GeraCodigoBarras(Produto.Codigo);
end;

procedure TFrmCadProdutos.actEtiquetasRibbonExecute(Sender: TObject);
begin
  inherited;
	if FrmEtiquetasRibbon = nil then
    FrmEtiquetasRibbon := TFrmEtiquetasRibbon.Create(nil);
  FrmEtiquetasRibbon.Produto.Codigo := Produto.Codigo;
  FrmEtiquetasRibbon.ShowModal;
end;

procedure TFrmCadProdutos.actExcluirExecute(Sender: TObject);
begin
	if Application.MessageBox('Deseja realmente excluir este registro?', 'Excluir', MB_YESNO + MB_ICONQUESTION) = mrYes then
		FormRTTI.Excluir(Produto.Codigo);
	inherited;
end;

procedure TFrmCadProdutos.actGerarEtiquetasExecute(Sender: TObject);
begin
  try
		if FrmCodBarra = nil then
			FrmCodBarra := TFrmCodBarra.Create(nil);
    FrmCodBarra.Produto.Codigo := Produto.Codigo;
		FrmCodBarra.ShowModal;
	finally

	end;	
end;

procedure TFrmCadProdutos.actInserirExecute(Sender: TObject);
begin
	inherited;
	Produto.Codigo      := DMPrincipal.GeraCodigo('PRODUTOS', 'PRO_CODIGO');
  Produto.Cadastrar   := 'S';//indica produto novo para cadatrar
	lbCodigo.Caption    := Produto.Codigo.ToString;
	EdtCodBarra.Text    := GeraCodigoBarras(Produto.Codigo);
	CbxEstado.ItemIndex := 0;
end;

procedure TFrmCadProdutos.actPesquisarExecute(Sender: TObject);
begin
	inherited;
	if FrmGridProduto = nil then
		FrmGridProduto := TFrmGridProduto.Create(nil);
	if (FrmGridProduto.ShowModal = mrOk) and (DMPrincipal.CodigoPesquisado > 0) then
	begin
		BuscaDadosProduto(DMPrincipal.CodigoPesquisado);
	end;
end;

procedure TFrmCadProdutos.BuscaDadosProduto(Codigo: integer);
begin
	MensagemUsuario('Aguarde, buscando produtos...', 1, False, False);
	Produto := TProdutos.Create.Get<TProdutos>(Codigo);
	if Produto.Codigo > 0 then
	begin
		if Produto.Gru > 0 then
			BuscaSubGrupo(Produto.Gru);
		if Produto.ForCodigo > 0 then
			BuscaFornecedor(Produto.ForCodigo);
		if Produto.CodTotalizador > 0 then
			BuscaTotalizador(Produto.CodTotalizador);
		if Produto.Um > 0 then
			BuscaUnidadeMedida(Produto.Um);
		BuscaFotoProduto(Produto.URL_Imagem);
		BuscaTipoItem(Produto.Tipo_item);
		FormRTTI.SetTabela(Produto);
		FormRTTI.BindForm(Self);
    IBQRGrade.Close;
    IBQRGrade.ParamByName('PRODUTO').Value := Produto.Codigo;
    IBQRGrade.Open;  
	end;
end;

procedure TFrmCadProdutos.BuscaFornecedor(CodFornecedor: integer);
begin
	Produto.Fornecedor      := TFornecedores.Create.Get<TFornecedores>(CodFornecedor);
	CbxFornecedor.ItemIndex := CbxFornecedor.Items.IndexOf(Produto.Fornecedor.Nome);
end;

procedure TFrmCadProdutos.BuscaFotoProduto(Url: string);
begin
	// Foto
	ImgFoto.Hint     := Url;
	ImgFoto.ShowHint := ImgFoto.Hint <> '';
	ImgFoto.Hint     := ImgFoto.Hint + #13 + 'Clique p/ ampliar!';
	if Url.IsEmpty then
	begin
		// Foto nao carregada
		ImgFoto.Picture.Assign(nil);
		ImageList1.GetBitmap(0, ImgFoto.Picture.Bitmap);
	end
	else
	begin
		try
			ImgFoto.Picture.Bitmap.LoadFromUrl(Url);
		except
			// foto nao encontrada;
			ImgFoto.Picture.Assign(nil);
			ImageList1.GetBitmap(1, ImgFoto.Picture.Bitmap);
		end;
	end;
end;

procedure TFrmCadProdutos.BuscaSubGrupo(CodSubGrupo: integer);
var
	Grupo: TGrupos;
begin
	Produto.SubGrupo := TSubGrupos.Create.Get<TSubGrupos>(CodSubGrupo);
	Grupo            := TGrupos.Create.Get<TGrupos>(Produto.SubGrupo.G1);
	try
		EdtGrupoSubGrupo.Text := Format('%s > %s', [Grupo.Nome, Produto.SubGrupo.Nome]);
	finally
		Grupo.DisposeOf;
	end;
end;

procedure TFrmCadProdutos.BuscaTipoItem(Tipo: string);
var
	Texto: string;
begin
	if Tipo.IsEmpty then
		Exit;
	case Tipo.ToInteger of
		0:
			Texto := '00 - Mercadoria para Revenda';
		1:
			Texto := '01 - Matéria-Prima';
		2:
			Texto := '02 - Embalagem';
		3:
			Texto := '03 - Produto em Processo';
		4:
			Texto := '04 - Produto Acabado';
		5:
			Texto := '05 - Subproduto';
		6:
			Texto := '06 - Produto Intermediário';
		7:
			Texto := '07 - Material de Uso e Consumo';
		8:
			Texto := '08 - Ativo Imobilizado';
		9:
			Texto := '09 - Serviços';
		10:
			Texto := '10 - Outros insumos';
		99:
			Texto := '99 - Outras';
	end;
	CbxTipoItem.ItemIndex := CbxTipoItem.Items.IndexOf(Texto);
end;

procedure TFrmCadProdutos.BuscaTotalizador(CodTotalizador: integer);
var
	Totalizador: TTotalizadores;
begin
	Totalizador                := TTotalizadores.Create.Get<TTotalizadores>(CodTotalizador);
	CbxTotalizadores.ItemIndex := CbxTotalizadores.Items.IndexOf(Totalizador.Descricao);
end;

procedure TFrmCadProdutos.BuscaUnidadeMedida(CodUnidadeMedida: integer);
var
	UnidadeMedida: TUnidadeMedida;
begin
	UnidadeMedida              := TUnidadeMedida.Create.Get<TUnidadeMedida>(CodUnidadeMedida);
	CbxUnidadeMedida.ItemIndex := CbxUnidadeMedida.Items.IndexOf(UnidadeMedida.Descricao);
end;

procedure TFrmCadProdutos.EdtFornecedoresKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	inherited;
	if (Key = VK_DOWN) then
	begin
		if not(FormRTTI.TipoOperacao in [TTipoOperacao.Insercao, TTipoOperacao.Edicao]) then
		begin
			ShowMessage('O cadastro não está em edição!');
			Exit;
		end;
		if FrmGrid = nil then
			FrmGrid                := TFrmGrid.Create(Self);
		FrmGrid.DoisPorcentagens := True;
		FrmGrid.Recurso          := '/fornecedores';
		if (FrmGrid.ShowModal = mrOk) and (DMPrincipal.CodigoPesquisado > 0) then
		begin
			BuscaFornecedor(DMPrincipal.CodigoPesquisado);
		end;
	end;
end;

procedure TFrmCadProdutos.EdtGrupoSubGrupoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	if (Key = VK_DOWN) then
	begin
		if (FormRTTI.TipoOperacao in [TTipoOperacao.Insercao, TTipoOperacao.Edicao]) then
			EdtGrupoSubGrupoRightButtonClick(Sender);
	end;
end;

procedure TFrmCadProdutos.EdtGrupoSubGrupoKeyPress(Sender: TObject; var Key: Char);
begin
	inherited;
	if Key = #13 then
	begin
		if (not String(EdtGrupoSubGrupo.Text).IsEmpty) and (FormRTTI.TipoOperacao in [TTipoOperacao.Insercao, TTipoOperacao.Edicao]) then
			EdtNome.Text := String(EdtGrupoSubGrupo.Text).Replace(' > ', ' ');
	end;
end;

procedure TFrmCadProdutos.EdtGrupoSubGrupoRightButtonClick(Sender: TObject);
begin
	if not(FormRTTI.TipoOperacao in [TTipoOperacao.Insercao, TTipoOperacao.Edicao]) then
	begin
		ShowMessage('O cadastro não está em edição!');
		Exit;
	end;
	if FrmGrid = nil then
		FrmGrid                := TFrmGrid.Create(Self);
	FrmGrid.DoisPorcentagens := True;
	FrmGrid.Recurso          := '/grupo_subgrupo';
	FrmGrid.Filtros          := ['descricao'];
	if (FrmGrid.ShowModal = mrOk) and (DMPrincipal.CodigoPesquisado > 0) then
	begin
		BuscaSubGrupo(DMPrincipal.CodigoPesquisado);
	end;
end;

procedure TFrmCadProdutos.FormCreate(Sender: TObject);
var
	Codigo: integer;
begin
	inherited;
  ExibePanelPrincipal := True;
	Codigo  := DMPrincipal.GeraCodigo('PRODUTOS', 'PRO_CODIGO') - 1;
	Produto := TProdutos.Create.Get<TProdutos>(Codigo);
	FormRTTI.SetTabela(Produto);
	/// /
	MensagemUsuario('Aguarde, buscando Fornecedores...', 1, False, False);
	CbxFornecedor.Clear;
	CbxFornecedor.Items := TFornecedores.Create.GetDataComboBox<TFornecedores>('nome');
	/// /
  MensagemUsuario('Aguarde, buscando Totalizadores...', 1, False, False);
	CbxTotalizadores.Clear;
	CbxTotalizadores.Items := TTotalizadores.Create.GetDataComboBox<TTotalizadores>('descricao');
	/// /
  MensagemUsuario('Aguarde, buscando Unidades de Medidas...', 1, False, False);	
	CbxUnidadeMedida.Clear;
	CbxUnidadeMedida.Items := TUnidadeMedida.Create.GetDataComboBox<TUnidadeMedida>('descricao');
end;

procedure TFrmCadProdutos.FormDestroy(Sender: TObject);
begin
	inherited;
	Produto.DisposeOf;
	FrmCadProdutos := nil;
  if ExibePanelPrincipal then
  	FrmPrincipal.HabilitaMenu(True);
end;

procedure TFrmCadProdutos.FormShow(Sender: TObject);
begin
	inherited;
	BuscaDadosProduto(Produto.Codigo);
end;

procedure TFrmCadProdutos.ImgFotoClick(Sender: TObject);
begin
	inherited;
	if FrmAmpliaFoto = nil then
		FrmAmpliaFoto                      := TFrmAmpliaFoto.Create(nil);
	FrmAmpliaFoto.Image1.Picture.Graphic := ImgFoto.Picture.Graphic;
	FrmAmpliaFoto.ShowModal;
end;

procedure TFrmCadProdutos.LogUpload(msg: string);
begin
	Application.MessageBox(PWideChar(msg), 'Msg Upload Arquivo', MB_OK + MB_ICONINFORMATION);
end;

end.
