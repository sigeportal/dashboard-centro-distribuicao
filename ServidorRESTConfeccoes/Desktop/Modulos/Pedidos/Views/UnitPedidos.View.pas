unit UnitPedidos.View;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
	Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UnitFormBase, Data.DB,
	FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
	FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
	System.ImageList, Vcl.ImgList, Vcl.Menus, FireDAC.Comp.DataSet,
	FireDAC.Comp.Client, Vcl.ButtonGroup, UnitFrameRelogioPortal, Vcl.Grids,
	Vcl.DBGrids, Vcl.StdCtrls, Vcl.Buttons, JvExStdCtrls, JvEdit, JvValidateEdit,
	Vcl.ComCtrls, Vcl.Imaging.pngimage, Vcl.ExtCtrls, System.Actions,
	Vcl.ActnList, Vcl.ToolWin, UnitClientREST.Model.Interfaces, System.JSON,
	UnitProdutos.Model, System.Generics.Collections, UnitEmpresa.Model,
  UnitFornecedores.Model;

type
	TFrmPedidos = class(TFrmBase)
		Panel2: TPanel;
		Panel3: TPanel;
		Label1: TLabel;
		Label2: TLabel;
		Label4: TLabel;
		lbCodigo: TLabel;
		Image1: TImage;
		Image2: TImage;
		EdtData: TDateTimePicker;
		PnlTitulo: TPanel;
		GroupBox1: TGroupBox;
		PnlProdutos: TPanel;
		DBGrid1: TDBGrid;
		Panel4: TPanel;
		Label9: TLabel;
		EdtValorProdutos: TJvValidateEdit;
		FrameRelogioPortal1: TFrameRelogioPortal;
		Panel5: TPanel;
		ButtonGroup1: TButtonGroup;
		BitBtn1: TBitBtn;
		DSItens: TDataSource;
		CDSItens: TFDMemTable;
		CDSItensCODIGO: TIntegerField;
		CDSItensDESCRICAO: TStringField;
		CDSItensQUANTIDADE: TFloatField;
		CDSItensCOD_PRO: TIntegerField;
		CDSItensCOD_BARRA: TStringField;
		PopupMenu1: TPopupMenu;
		Excluir1: TMenuItem;
		ImageList1: TImageList;
		Label5: TLabel;
		Label6: TLabel;
		Label7: TLabel;
		Label8: TLabel;
		EdtCodigo: TEdit;
		EdtDescricao: TEdit;
		EdtValorCusto: TJvValidateEdit;
		EdtQuantidade: TJvValidateEdit;
		BtnInserir: TBitBtn;
		actInserirProduto: TAction;
		actSalvar: TAction;
		EdtFornecedor: TEdit;
		actBuscarPedido: TAction;
		actCadProduto: TAction;
		CaddesteProduto1: TMenuItem;
		CDSItensCADASTRAR: TStringField;
		Label3: TLabel;
		EdtPrecoVista: TJvValidateEdit;
		Label10: TLabel;
		EdtPrecoPrazo: TJvValidateEdit;
		CDSItensVALORC: TCurrencyField;
		CDSItensPRECO_VISTA: TCurrencyField;
		CDSItensPRECO_PRAZO: TCurrencyField;
    CDSItensCOD_GRADE: TIntegerField;
    CDSItensTAM_SIGLA: TStringField;
		procedure FormDestroy(Sender: TObject);
		procedure FormShow(Sender: TObject);
		procedure EdtCodigoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure EdtCodigoKeyPress(Sender: TObject; var Key: Char);
		procedure actInserirProdutoExecute(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure actSalvarExecute(Sender: TObject);
		procedure actBuscarPedidoExecute(Sender: TObject);
		procedure actCadProdutoExecute(Sender: TObject);
		procedure CaddesteProduto1Click(Sender: TObject);
		procedure Excluir1Click(Sender: TObject);
		procedure BitBtn1Click(Sender: TObject);
    procedure EdtFornecedorKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
	private
		FProduto: TProdutos;
		Empresa : TEmpresa;
		FTotal  : Currency;
    CodGrade: integer;
    Fornecedor: TFornecedores;
		procedure SetTotal(const Value: Currency);
		procedure CalculaTotal;
		procedure SalvarPedido;
		procedure BuscaDadosPedido(CodPedido: Integer);
		procedure ExcluirItemNoServidor(Codigo: Integer);
		procedure GerarEtiquetasLazer;
    procedure GerarEtiquetasRibbon;
		{ Private declarations }
	public
		{ Public declarations }
		CodPedidoBuscado: Integer;
		property Produto: TProdutos read FProduto write FProduto;
		property Total  : Currency read FTotal write SetTotal;
	end;

var
	FrmPedidos: TFrmPedidos;

implementation

{$R *.dfm}

uses
	UnitFuncoesUtils,
	UnitTabela.Helper.JSON,
	UnitDMPrincipal,
	UnitGridProduto, UnitClientREST.Model, UnitConfiguracaoServidor.Singleton,
	UnitPrincipal, UnitPedEstRemoto.Model, UnitPedidoRemoto.Model, UnitBuscaPedidoRemoto,
	UnitCadProduto, System.Threading, UnitCodBarra, UnitGridGrade,
  UnitGrades.Model, UnitGrid, UnitEscolhaImpressora, UnitEtiquetasRibbon;

procedure TFrmPedidos.actBuscarPedidoExecute(Sender: TObject);
begin
	inherited;
	if FrmBuscaPedidoRemoto = nil then
		FrmBuscaPedidoRemoto                 := TFrmBuscaPedidoRemoto.Create(nil);
	FrmBuscaPedidoRemoto.BuscarFinalizados := False;
	if (FrmBuscaPedidoRemoto.ShowModal = mrOk) and (DMPrincipal.CodigoPesquisado > 0) then
	begin
		BuscaDadosPedido(DMPrincipal.CodigoPesquisado);
	end;
end;

procedure TFrmPedidos.BitBtn1Click(Sender: TObject);
begin
	inherited;
	actSalvar.Execute;
end;

procedure TFrmPedidos.BuscaDadosPedido(CodPedido: Integer);
var
	Pedido: TPedidoRemotoResponse;
	Itens : TPedEstRemoto;
begin
	CDSItens.Close;
	CDSItens.CreateDataSet;
	CodPedidoBuscado := CodPedido;
	try
		MensagemUsuario('Aguarde buscando dados do Pedido...', 1, False, False);
		Pedido                 := TPedidoRemotoResponse.Create.Get<TPedidoRemotoResponse>(CodPedido);
		lbCodigo.Caption       := Pedido.Codigo.ToString;
		EdtData.DateTime       := Pedido.Data;
		EdtValorProdutos.Value := Pedido.Valor;
		Fornecedor.Get<TFornecedores>(Pedido.CodCliFor);
		EdtFornecedor.Text     := Fornecedor.Nome;
    if Length(Pedido.Itens) > 0 then
		begin
			for Itens in TArray<TPedEstRemoto>(Pedido.Itens) do
			begin
				CDSItens.Append;
				CDSItensCODIGO.Value      := Itens.Codigo;
				CDSItensCOD_PRO.Value     := Itens.CodPro;
				CDSItensCOD_BARRA.Value   := Itens.CodBarras;
				CDSItensDESCRICAO.Value   := Itens.Nome;
				CDSItensQUANTIDADE.Value  := Itens.Quantidade;
				CDSItensVALORC.Value      := Itens.ValorC;
				CDSItensPRECO_VISTA.Value := Itens.PrecoVista;
				CDSItensPRECO_PRAZO.Value := Itens.PrecoPrazo;
        CDSItensCOD_GRADE.Value   := Itens.CodGrade;
        CDSItensTAM_SIGLA.Value   := Itens.Grade.Tamanho.Sigla;
				CDSItens.Post;
			end;
		end;
	finally
		Pedido.DisposeOf;
	end;
end;

procedure TFrmPedidos.actCadProdutoExecute(Sender: TObject);
begin
	inherited;
	if FrmCadProdutos = nil then
		FrmCadProdutos                   := TFrmCadProdutos.Create(nil);
	FrmCadProdutos.ExibePanelPrincipal := False;
	FrmCadProdutos.ShowModal;
end;

procedure TFrmPedidos.actInserirProdutoExecute(Sender: TObject);
var
	i: Integer;
  Grade: TGrades;
begin
	inherited;
	if not Assigned(Produto) then
		Exit;
	if EdtQuantidade.AsFloat = 0 then
		Exit;
	CDSItens.Append;
	CDSItensCODIGO.Value      := DMPrincipal.InscrementaGenerator('GEN_PE');
	CDSItensCOD_BARRA.Value   := Produto.Codbarra;
	CDSItensCOD_PRO.Value     := Produto.Codigo;
	CDSItensDESCRICAO.Value   := EdtDescricao.Text;
	CDSItensVALORC.Value      := EdtValorCusto.AsCurrency * EdtQuantidade.AsFloat;
	CDSItensPRECO_VISTA.Value := EdtPrecoVista.AsCurrency;
	CDSItensPRECO_PRAZO.Value := EdtPrecoPrazo.AsCurrency;
	CDSItensQUANTIDADE.Value  := EdtQuantidade.AsFloat;
	CDSItensCADASTRAR.Value   := Produto.Cadastrar;
  CDSItensCOD_GRADE.Value   := CodGrade;
  if CodGrade > 0 then
  begin
    try
      Grade := TGrades.Create.Get<TGrades>(CodGrade);
      CDSItensTAM_SIGLA.Value := Grade.Tamanho.Sigla;
    finally
      Grade.Free;
    end;
  end;
	CDSItens.Post;
	/// /
	CalculaTotal;
	///
	EdtCodigo.Clear;
	EdtDescricao.Clear;
	EdtQuantidade.Clear;
	EdtValorCusto.Clear;
	EdtPrecoVista.Clear;
	EdtPrecoPrazo.Clear;
	EdtCodigo.SetFocus;
end;

procedure TFrmPedidos.actSalvarExecute(Sender: TObject);
begin
	if CDSItens.IsEmpty then
		Exit;
	if Application.MessageBox('Deseja salvar este Pedido?', 'Salvar', MB_YESNO + MB_ICONQUESTION) = mrYes then
	begin
		SalvarPedido;
		if Application.MessageBox('Deseja imprimir etiquetas a partir deste pedido?', 'Imprimir etiquetas', MB_YESNO + MB_ICONQUESTION) = mrYes then
		begin
    	if FrmEscolhaImpressora = nil then
        FrmEscolhaImpressora := TFrmEscolhaImpressora.Create(nil);
      if FrmEscolhaImpressora.ShowModal = mrOk then
      begin    
      	case FrmEscolhaImpressora.TipoImpressora of
        	Lazer:	GerarEtiquetasLazer;
          Ribbon: GerarEtiquetasRibbon;
        end;      	
				
      end;
		end;
		Self.Close;
	end;
end;

procedure TFrmPedidos.GerarEtiquetasLazer;
begin
	CDSItens.DisableControls;
	try
		if FrmCodBarra = nil then
			FrmCodBarra := TFrmCodBarra.Create(nil);
		FrmCodBarra.CDSProdutos.Close;
		FrmCodBarra.CDSProdutos.CreateDataSet;
		CDSItens.First;
		while not CDSItens.Eof do
		begin
			FrmCodBarra.CDSProdutos.Append;
			FrmCodBarra.CDSProdutosCODIGO.Value        := CDSItensCOD_PRO.AsInteger;
			FrmCodBarra.CDSProdutosNOME.Value          := CDSItensDESCRICAO.AsString;
			FrmCodBarra.CDSProdutosCOD_BARRA.Value     := CDSItensCOD_BARRA.AsString;
			FrmCodBarra.CDSProdutosQUANT.Value         := CDSItensQUANTIDADE.AsInteger;
			FrmCodBarra.CDSProdutosVLR_VISTA.Value     := CDSItensPRECO_VISTA.AsCurrency;
			FrmCodBarra.CDSProdutosVLR_PARCELADO.Value := CDSItensPRECO_PRAZO.AsCurrency;
			FrmCodBarra.CDSProdutos.Post;
			CDSItens.Next;
		end;
		FrmCodBarra.ShowModal;
	finally
		CDSItens.EnableControls;
	end;
end;

procedure TFrmPedidos.GerarEtiquetasRibbon;
begin
  CDSItens.DisableControls;
	try
		if FrmEtiquetasRibbon = nil then
			FrmEtiquetasRibbon := TFrmEtiquetasRibbon.Create(nil);
		FrmEtiquetasRibbon.CDSEtiquetas.Close;
		FrmEtiquetasRibbon.CDSEtiquetas.CreateDataSet;
		CDSItens.First;
		while not CDSItens.Eof do
		begin
			FrmEtiquetasRibbon.CDSEtiquetas.Append;
			FrmEtiquetasRibbon.CDSEtiquetasCODIGO.Value    := CDSItensCOD_PRO.AsInteger;
			FrmEtiquetasRibbon.CDSEtiquetasNOME.Value      := CDSItensDESCRICAO.AsString;
			FrmEtiquetasRibbon.CDSEtiquetasCOD_BARRA.Value := CDSItensCOD_BARRA.AsString;
			FrmEtiquetasRibbon.CDSEtiquetasQTD_ETIQ.Value  := CDSItensQUANTIDADE.AsInteger;
			FrmEtiquetasRibbon.CDSEtiquetasVLR_VISTA.Value := CDSItensPRECO_VISTA.AsCurrency;
			FrmEtiquetasRibbon.CDSEtiquetasVLR_PRAZO.Value := CDSItensPRECO_PRAZO.AsCurrency;
			FrmEtiquetasRibbon.CDSEtiquetas.Post;
			CDSItens.Next;
		end;
		FrmEtiquetasRibbon.ShowModal;
	finally
		CDSItens.EnableControls;
	end;
end;

procedure TFrmPedidos.SalvarPedido;
var
	Item    : TPedEstRemoto;
	Response: TClientResult;
	Itens   : TList<TPedEstRemoto>;
	Pedido  : TPedidoRemoto;
	aJson   : TJSONArray;
begin
	Pedido := TPedidoRemoto.Create;
	try
		if CodPedidoBuscado > 0 then
			Pedido.Codigo := CodPedidoBuscado
		else
			Pedido.Codigo  := DMPrincipal.GeraCodigo('PEDIDOS_REMOTO', 'PED_CODIGO');
		Pedido.Data      := EdtData.DateTime;
		Pedido.Nome      := Fornecedor.Nome;
		Pedido.CodCliFor := 1;
		Pedido.Valor     := EdtValorProdutos.AsCurrency;
    Pedido.CodCliFor := Fornecedor.Codigo;
		// itens
		Itens := TList<TPedEstRemoto>.Create;
		CDSItens.DisableControls;
		try
			CDSItens.First;
			while not CDSItens.Eof do
			begin
				Item             := TPedEstRemoto.Create;
				Item.Codigo      := CDSItensCODIGO.AsInteger;
				Item.CodPro      := CDSItensCOD_PRO.AsInteger;
				Item.CodBarras   := CDSItensCOD_BARRA.AsString;
				Item.CodPed      := Pedido.Codigo;
				Item.Nome        := CDSItensDESCRICAO.AsString;
				Item.Quantidade  := CDSItensQUANTIDADE.AsFloat;
				Item.ValorC      := CDSItensVALORC.AsCurrency;
				Item.PrecoVista  := CDSItensPRECO_VISTA.AsCurrency;
				Item.PrecoPrazo  := CDSItensPRECO_PRAZO.AsCurrency;
				Item.DataCriacao := Now;
				Item.Cadastrar   := CDSItensCADASTRAR.AsString;
        Item.CodGrade    := CDSItensCOD_GRADE.AsInteger;
				Itens.Add(Item);
				CDSItens.Next;
			end;
		finally
			CDSItens.EnableControls;
		end;
		MensagemUsuario('Aguarde, salvando itens do pedido...', 1, False, False);
		// enviando para o servidor
		Response := Pedido.Post;
		// salva os itens
		aJson := TJSONArray.Create;
		for Item in Itens do
		begin
			Response := Item.Post;
			if Response.StatusCode <> 200 then
				raise Exception.Create('Erro ao salvar itens do Pedido!' + sLineBreak + Response.Content);
		end;
		if Response.StatusCode = 200 then
		begin
			MensagemUsuario('Pedido Salvo com sucesso!', 1, False, False);
		end
		else
		begin
			Application.MessageBox(PWideChar('Falha ao salvar Pedido!' + sLineBreak + Response.Content + sLineBreak + Response.Error), 'Erro', MB_OK + MB_ICONERROR);
		end;
	finally
		Pedido.DisposeOf;
	end;
end;

procedure TFrmPedidos.CaddesteProduto1Click(Sender: TObject);
begin
	inherited;
	if FrmCadProdutos = nil then
		FrmCadProdutos := TFrmCadProdutos.Create(nil);
	FrmCadProdutos.BuscaDadosProduto(CDSItensCOD_PRO.AsInteger);
	FrmCadProdutos.ExibePanelPrincipal := False;
	FrmCadProdutos.ShowModal;
end;

procedure TFrmPedidos.CalculaTotal;
begin
	Total := 0;
	CDSItens.DisableControls;
	try
		CDSItens.First;
		while not CDSItens.Eof do
		begin
			Total := Total + CDSItensVALORC.AsCurrency;
			CDSItens.Next;
		end;
	finally
		CDSItens.EnableControls;
	end;
end;

procedure TFrmPedidos.EdtCodigoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	inherited;
	if Key = VK_DOWN then
	begin
		if FrmGridProduto = nil then
			FrmGridProduto := TFrmGridProduto.Create(nil);
		if (FrmGridProduto.ShowModal = mrOk) and (DMPrincipal.CodigoPesquisado > 0) then
		begin
			TEdit(Sender).Text := DMPrincipal.CodigoPesquisado.ToString;
		end;
	end;
end;

procedure TFrmPedidos.EdtCodigoKeyPress(Sender: TObject; var Key: Char);
var
	Response         : TClientResult;
	aJson            : TJSONArray;
	BuscaPorCodBarras: Boolean;
begin
	inherited;
	if Key = #13 then
	begin
		if EdtCodigo.Text = '' then
		begin
			if CDSItens.IsEmpty then
			begin
				ShowMessage('Insira um código!!');
				EdtCodigo.SetFocus;
			end
			else
			begin
				EdtValorProdutos.SetFocus;
			end;
		end
		else
		begin
			BuscaPorCodBarras := False;
			Produto           := TProdutos.Create;
			if Length(EdtCodigo.Text) < 7 then
			begin
				// busca por codigo
				Produto := TProdutos.Create.Get<TProdutos>(StrToInt(EdtCodigo.Text));
			end
			else
			begin
				// busca por codbarras
				Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/produtos?codbarra=' + EdtCodigo.Text).AddHeader('Content-Type', 'application/json').Get();
				if Response.StatusCode = 200 then
				begin
					aJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONArray;
					if aJson.Count > 0 then
					begin
						Produto           := TProdutos.Create.fromJson<TProdutos>(aJson.Items[0].ToString);
						BuscaPorCodBarras := True;
					end;
				end;
			end;
			if Produto.Codigo = 0 then
			begin
				ShowMessage('Registro não encontrado!!');
				EdtCodigo.Clear;
				EdtCodigo.SetFocus;
			end
			else
			begin
      	// busca por grade
				Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/grades/produto/' + Produto.Codigo.ToString)
        											 .AddHeader('Content-Type', 'application/json')
                               .Get();
				if Response.StatusCode = 200 then
				begin
					aJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONArray;
					if aJson.Count > 0 then
					begin
						// Habilita a escolha de grades       
            if FrmGridGrade = nil then
              FrmGridGrade           := TFrmGridGrade.Create(nil);
            FrmGridGrade.Cod_Produto := Produto.Codigo;
            if (FrmGridGrade.ShowModal = mrOk) and (DMPrincipal.Cod_Grade > 0) then
            	CodGrade := DMPrincipal.Cod_Grade;
					end;
				end;
        EdtDescricao.Text        := Trim(Produto.Nome);
        EdtValorCusto.AsCurrency := Produto.ValorC;          
        EdtPrecoVista.AsCurrency := Produto.Valorv; 
        EdtPrecoPrazo.AsCurrency := Produto.Valorp; 
        EdtQuantidade.Value      := 1;
				if BuscaPorCodBarras then
					actInserirProduto.Execute
				else
					EdtValorCusto.SetFocus;
			end;
		end;
	end;
	if not(Key in ['0' .. '9', chr(vk_back)]) then
		Key := #0;
end;

procedure TFrmPedidos.EdtFornecedorKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  inherited;
	if FrmGrid = nil then
    FrmGrid := TFrmGrid.Create(nil);
  FrmGrid.Recurso := '/fornecedores';
  FrmGrid.TotalRegistros := 10;
  FrmGrid.Filtros := ['codigo', 'nome'];
  if (FrmGrid.ShowModal = mrOk) and (DMPrincipal.CodigoPesquisado > 0) then
  begin
  	Fornecedor.Get<TFornecedores>(DMPrincipal.CodigoPesquisado);
  	EdtFornecedor.Text := Fornecedor.Nome;
  end;
end;

procedure TFrmPedidos.Excluir1Click(Sender: TObject);
begin
	inherited;
	if Application.MessageBox('Deseja realmente excluir este item?', 'Excluir', MB_YESNO + MB_ICONQUESTION) = mrYes then
	begin
		// exclui no servidor
		ExcluirItemNoServidor(CDSItensCODIGO.AsInteger);
		///
		CDSItens.Delete;
		///
		CalculaTotal;
	end;
end;

procedure TFrmPedidos.ExcluirItemNoServidor(Codigo: Integer);
var
	oJson: TJSONObject;
begin
	TTask.Run(
		procedure
		var
			Response: TClientResult;
		begin
			Response := TPedEstRemoto.Create().Delete(Codigo);
			if Response.StatusCode <> 204 then
			begin
				raise Exception.Create('Erro ao deletar no servidor!');
			end;
		end);
end;

procedure TFrmPedidos.FormCreate(Sender: TObject);
var
	Pedido: TPedidoRemoto;
begin
	inherited;
	CDSItens.Close;
	CDSItens.CreateDataSet;
	Empresa := TEmpresa.Create();
	Produto := TProdutos.Create();
  Produto.Get<TProdutos>(1);
	try
		Pedido := TPedidoRemoto.Create.Get<TPedidoRemoto>(1);
	finally
		Pedido.DisposeOf;
	end;
  Fornecedor := TFornecedores.Create();
  Fornecedor.Get<TFornecedores>(1);  
end;

procedure TFrmPedidos.FormDestroy(Sender: TObject);
begin
	inherited;
	Empresa.DisposeOf;
	if Assigned(Produto) then
		Produto.DisposeOf;
	Self.GravaEstadoForm([DBGrid1]);
	FrmPedidos := nil;
	FrmPrincipal.HabilitaMenu(True);
end;

procedure TFrmPedidos.FormShow(Sender: TObject);
begin
	inherited;
	Self.InicializaEstadoForm([DBGrid1]);
	EdtData.DateTime  := Date;
	lbCodigo.Caption  := DMPrincipal.GeraCodigo('PEDIDOS_REMOTO', 'PED_CODIGO').ToString;
	Empresa           := Empresa.Get<TEmpresa>(1);
	PnlTitulo.Caption := Empresa.Titulo1;
end;

procedure TFrmPedidos.SetTotal(const Value: Currency);
begin
	FTotal                      := Value;
	EdtValorProdutos.AsCurrency := FTotal;
end;

end.
