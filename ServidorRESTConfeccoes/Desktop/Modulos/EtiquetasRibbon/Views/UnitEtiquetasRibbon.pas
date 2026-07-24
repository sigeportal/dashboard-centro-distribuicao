unit UnitEtiquetasRibbon;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, StdCtrls, Buttons, Printers, ComCtrls, ExtCtrls,
	Registry, DB, DBClient, Grids, DBGrids, Menus, IBCustomDataSet,
	IBQuery, 
  System.Threading,
  UnitEtiquetasRibbon.Interfaces,
	UnitEtiquetaZebra3Colunas.Model, 
  UnitProdutos.Model;

type
	TFrmEtiquetasRibbon = class(TForm)
		Label1: TLabel;
		Label5: TLabel;
		Label8: TLabel;
		Shape5: TShape;
		Shape1: TShape;
		Shape3: TShape;
		EdtValorPrazo: TEdit;
		EdtCodigo: TEdit;
		EdtNEtiquetas: TEdit;
		Label2: TLabel;
		Shape2: TShape;
		EdtValorVista: TEdit;
		BtnImprimir: TBitBtn;
		Shape4: TShape;
		EdtCaminho: TEdit;
		Label4: TLabel;
		Shape6: TShape;
		EdtNome: TEdit;
		Label3: TLabel;
		DBGrid1: TDBGrid;
		CDSEtiquetas: TClientDataSet;
		CDSEtiquetasCODIGO: TIntegerField;
		CDSEtiquetasNOME: TStringField;
		CDSEtiquetasVLR_VISTA: TCurrencyField;
		CDSEtiquetasVLR_PRAZO: TCurrencyField;
		CDSEtiquetasQTD_ETIQ: TIntegerField;
		DSEtiquetas: TDataSource;
		CDSEtiquetasCOD_BARRA: TStringField;
		PopupMenu1: TPopupMenu;
		Excluir1: TMenuItem;
		BtnAlternaFiltro: TSpeedButton;
		IBQRCompra: TIBQuery;
		IBQRCompraPRO_CODIGO: TIntegerField;
		IBQRCompraPRO_NOME: TIBStringField;
		IBQRCompraPRO_VALORV: TIBBCDField;
		IBQRCompraPRO_VALORV_PRAZO: TIBBCDField;
		IBQRCompraCE_QUANTIDADE: TIBBCDField;
		IBQRCompraPRO_CODBARRA: TIBStringField;
		Label6: TLabel;
		CbxModeloImpressora: TComboBox;
		procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure EdtCodigoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure EdtCodigoKeyPress(Sender: TObject; var Key: Char);
		procedure EdtNEtiquetasKeyPress(Sender: TObject; var Key: Char);
		procedure FormShow(Sender: TObject);
		procedure BtnImprimirClick(Sender: TObject);
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
		procedure FormDestroy(Sender: TObject);
		procedure FormKeyPress(Sender: TObject; var Key: Char);
		procedure CDSEtiquetasAfterScroll(DataSet: TDataSet);
		procedure Excluir1Click(Sender: TObject);
		procedure DBGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure DBGrid1KeyPress(Sender: TObject; var Key: Char);
		procedure CDSEtiquetasAfterPost(DataSet: TDataSet);
		procedure BtnAlternaFiltroClick(Sender: TObject);
    procedure CbxModeloImpressoraChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
	private
		{ Private declarations }
    procedure ImprimeEtiquetaBematech;
    procedure LeConfiguracao(ConfigInicial: Boolean);
	public
		{ Public declarations }
    Produto: TProdutos;		
	end;

var
	FrmEtiquetasRibbon: TFrmEtiquetasRibbon;

implementation

uses 
	UnitDMPrincipal, 
  UnitGridProduto, 
  UnitPrincipal, 
  Math,
  UnitFuncoesUtils,
	StrUtils, 
  UnitLogin,
  UnitTabela.Helper.Json;

{$R *.dfm}

procedure TFrmEtiquetasRibbon.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	if Key = 27 then
		Close;
end;

procedure TFrmEtiquetasRibbon.EdtCodigoKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	if (Key = 40) and (Label5.Caption = 'Código') then
	begin
		FrmGridProduto := TFrmGridProduto.Create(self);
		if (FrmGridProduto.ShowModal = mrOk) and (DMPrincipal.CodigoPesquisado > 0) then
		begin
			TEdit(Sender).Text := IntToStr(DMPrincipal.CodigoPesquisado);
		end;
	end;
end;

procedure TFrmEtiquetasRibbon.EdtCodigoKeyPress(Sender: TObject; var Key: Char);
begin
	if (Key = #13) and (Label5.Caption = 'Código') then
	begin
		if EdtCodigo.Text = '' then
		begin
			if CDSEtiquetas.IsEmpty then
				EdtCodigo.SetFocus
			else
				BtnImprimir.SetFocus;
		end
		else
		begin
			Produto := Produto.Get<TProdutos>(StrToInt(EdtCodigo.Text));
			if Produto.Codigo = 0 then
			begin
				showmessage('Registro não encontrado!!');
				EdtCodigo.Clear;
				EdtCodigo.SetFocus;
			end
			else
			begin
				EdtValorVista.Text := FormatFloat(',0.00', Produto.Valorv);
				EdtValorPrazo.Text := FormatFloat(',0.00', Produto.Valorp);
				EdtNome.Text       := Trim(Produto.Nome);
				EdtNEtiquetas.SetFocus;
			end;
		end;
	end
	else if (Key = #13) and (Label5.Caption = 'Fatura') then
	begin
		IBQRCompra.Close;
		IBQRCompra.ParamByName('FATURA').Value := EdtCodigo.Text;
		IBQRCompra.Open;
		if IBQRCompra.IsEmpty then
		begin
			showmessage('Compra não encontrada!');
			EdtCodigo.SetFocus;
			Exit;
		end;
		CDSEtiquetas.Close;
		CDSEtiquetas.CreateDataSet;
		IBQRCompra.First;
		while not IBQRCompra.Eof do
		begin
			CDSEtiquetas.Append;
			CDSEtiquetasCODIGO.Value    := IBQRCompraPRO_CODIGO.AsInteger;
			CDSEtiquetasNOME.Value      := IBQRCompraPRO_NOME.AsString;
			CDSEtiquetasVLR_VISTA.Value := IBQRCompraPRO_VALORV.AsCurrency;
			CDSEtiquetasVLR_PRAZO.Value := IBQRCompraPRO_VALORV_PRAZO.AsCurrency;
			CDSEtiquetasQTD_ETIQ.Value  := IBQRCompraCE_QUANTIDADE.AsInteger;
			CDSEtiquetasCOD_BARRA.Value := IBQRCompraPRO_CODBARRA.AsString;
			CDSEtiquetas.Post;
			IBQRCompra.Next;
		end;
		BtnImprimir.SetFocus;
	end;
	if not(Key in ['0' .. '9', chr(vk_back)]) then
		Key := #0;
end;

procedure TFrmEtiquetasRibbon.EdtNEtiquetasKeyPress(Sender: TObject; var Key: Char);
begin
	if Key = #13 then
	begin
		if Produto.Codigo = 0 then
		begin
			showmessage('Escolha um Produto!');
			EdtCodigo.SetFocus;
			Exit;
		end;
		if EdtNEtiquetas.Text = '' then
		begin
			showmessage('Insira uma quantidade!');
			EdtNEtiquetas.SetFocus;
			Exit;
		end;
		if CDSEtiquetas.IsEmpty then
		begin
			CDSEtiquetas.Close;
			CDSEtiquetas.CreateDataSet;
		end;
		if CDSEtiquetas.Locate('CODIGO', EdtCodigo.Text, []) then
		begin
			if Application.MessageBox('Este Produto já está na lista.'#13'Deseja somar a quantidade de etiquetas?', 'Produto na lista', MB_YESNO + MB_ICONQUESTION) = MrYes then
			begin
				CDSEtiquetas.Edit;
				CDSEtiquetasQTD_ETIQ.Value := CDSEtiquetasQTD_ETIQ.AsInteger + StrToInt(EdtNEtiquetas.Text);
				CDSEtiquetas.Post;
			end;
		end
		else
		begin
			CDSEtiquetas.Append;
			CDSEtiquetasCODIGO.AsString    := EdtCodigo.Text;
			CDSEtiquetasNOME.Value         := EdtNome.Text;
			CDSEtiquetasVLR_VISTA.AsString := EdtValorVista.Text;
			CDSEtiquetasVLR_PRAZO.AsString := EdtValorPrazo.Text;
			CDSEtiquetasQTD_ETIQ.AsString  := EdtNEtiquetas.Text;
			CDSEtiquetasCOD_BARRA.Value    := Produto.Codbarra;
			CDSEtiquetas.Post;
		end;

		EdtCodigo.Clear;
		EdtNome.Clear;
		EdtValorVista.Clear;
		EdtValorPrazo.Clear;
		EdtNEtiquetas.Text := '1';
		EdtCodigo.SetFocus;
	end;
	if not(Key in ['0' .. '9', chr(vk_back)]) then
		Key := #0;
end;

procedure TFrmEtiquetasRibbon.LeConfiguracao(ConfigInicial: Boolean);
var
	Reg  : TRegistry;	
begin
  try
    Reg         := TRegistry.Create;
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    Reg.OpenKey('\Software\Config_Impressoras_Ribbon', True);
    if ConfigInicial then
    	CbxModeloImpressora.ItemIndex := Reg.ReadInteger('Modelo_Impressora');
    case TTipoImpressoraRibbon(CbxModeloImpressora.ItemIndex)  of
      TTipoImpressoraRibbon.Bematech: EdtCaminho.Text := Reg.ReadString('Caminho_Impressora_Bematech');
      TTipoImpressoraRibbon.Zebra: EdtCaminho.Text := Reg.ReadString('Caminho_Impressora_Zebra');  
    end;                                                                                      	
    Reg.CloseKey;
  finally
    Reg.Free;
  end;
end;

procedure TFrmEtiquetasRibbon.FormShow(Sender: TObject);
var
	ENTER: Char;
begin
	LeConfiguracao(True);
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
	EdtCodigo.SetFocus;
end;

procedure TFrmEtiquetasRibbon.BtnImprimirClick(Sender: TObject);
var
	EtiquetaZebra: iEtiquetaRibbon;
	Produto      : TProduto;
  i: Integer;
begin
	if CDSEtiquetas.IsEmpty then
	begin
		showmessage('Insira ao menos um Produto para imprimir!');
		EdtCodigo.SetFocus;
		Exit;
	end;
	if Trim(EdtCaminho.Text) = '' then
	begin
		showmessage('Preencha o caminho da Impressora!');
		EdtCaminho.SetFocus;
		Exit;
	end;
	case TTipoImpressoraRibbon(CbxModeloImpressora.ItemIndex) of
		TTipoImpressoraRibbon.Bematech:
    begin
      ImprimeEtiquetaBematech;
    end;
		TTipoImpressoraRibbon.Zebra:
    begin
      EtiquetaZebra := TEtiquetaZebra3Colunas.New;
      // configurações
      EtiquetaZebra.SetPorta(EdtCaminho.Text);
      /// /
      CDSEtiquetas.First;
      while not CDSEtiquetas.Eof do
      begin
        for i := 0 to Pred(CDSEtiquetasQTD_ETIQ.AsInteger) do
        begin
          Produto.Codigo     := CDSEtiquetasCODIGO.AsInteger;
          Produto.Nome       := CDSEtiquetasNOME.AsString;
          Produto.CodBarras  := CDSEtiquetasCOD_BARRA.AsString;
          Produto.NumCopias  := 1;
          Produto.PrecoVista := CDSEtiquetasVLR_VISTA.AsCurrency;
          Produto.PrecoPrazo := CDSEtiquetasVLR_PRAZO.AsCurrency;
          EtiquetaZebra.AddProdutos(Produto);
        end;
        CDSEtiquetas.Next;
      end;
      // imprime
      EtiquetaZebra.Imprimir;
    end;
	end;
end;

procedure TFrmEtiquetasRibbon.ImprimeEtiquetaBematech;
var
	F              : TextFile;
	QtdEtiq        : integer;
	EnviarImpressao: boolean;
begin
	AssignFile(F, EdtCaminho.Text);
	Rewrite(F);
	WriteLn(F, 'SIZE 104 mm,22 mm'); // Altura e largura da etiqueta
	WriteLn(F, 'GAP 2 mm,0');
	WriteLn(F, 'DIRECTION 1,0'); // Direção da etiqueta - 1,0: invertido verticalmente
	WriteLn(F, 'REFERENCE 0,0'); // Ponto de referência da etiqueta
	WriteLn(F, 'OFFSET 0 mm');
	WriteLn(F, 'SET PEEL OFF');
	WriteLn(F, 'SET CUTTER OFF');
	WriteLn(F, 'CODEPAGE 1252'); // CodePage Internacional 1252 = Latin I
	// +-Coordenação X
	// | +-Coordenação Y
	// | |  +-Fonte - 0 a 8
	// | |  |  +-Ângulo de rotação
	// | |  |  | +-Multiplicação Horizontal
	// | |  |  | | +-Multiplicação Vertical
	// | |  |  | | |         +-Conteúdo
	// | |  |  | | |         |
	// | |  |  | | |         |
	CDSEtiquetas.First;
	EnviarImpressao := False;
	QtdEtiq         := CDSEtiquetasQTD_ETIQ.AsInteger;
	while (not CDSEtiquetas.Eof) do
	begin
		WriteLn(F, 'CLS'); // Apaga qualquer imagem que esteja na memória da impressora
		while (QtdEtiq <= 0) and (CDSEtiquetas.RecNo <> CDSEtiquetas.RecordCount) do
		begin
			CDSEtiquetas.Next;
			QtdEtiq := CDSEtiquetasQTD_ETIQ.AsInteger;
		end;
		if QtdEtiq > 0 then
		begin
			// 1ª Etiqueta
			WriteLn(F, 'TEXT 50,20,"0",0,8,12,"' + 'À VISTA: R$ "');
			WriteLn(F, 'TEXT 160,17,"0",0,10,14,"' + FormatFloat(',0.00', CDSEtiquetasVLR_VISTA.AsCurrency) + '"');
			WriteLn(F, 'TEXT 30,55,"0",0,8,12,"PARCELADO: R$ "');
			WriteLn(F, 'TEXT 175,52,"0",0,10,14,"' + FormatFloat(',0.00', CDSEtiquetasVLR_PRAZO.AsCurrency) + '"');
			WriteLn(F, 'BARCODE 45,90,"EAN13",25,1,0,2,4,"' + CDSEtiquetasCOD_BARRA.AsString + '"');
			WriteLn(F, 'TEXT 10,145,"2",0,1,2,"' + Centralizar(CDSEtiquetasCODIGO.AsString, 20) + '"');
			Dec(QtdEtiq, 1);
			EnviarImpressao := True;
		end;
		while (QtdEtiq <= 0) and (CDSEtiquetas.RecNo <> CDSEtiquetas.RecordCount) do
		begin
			CDSEtiquetas.Next;
			QtdEtiq := CDSEtiquetasQTD_ETIQ.AsInteger;
		end;
		if QtdEtiq > 0 then
		begin
			// 2ª Etiqueta
			WriteLn(F, 'TEXT 330,20,"0",0,8,12,"' + 'À VISTA: R$ "');
			WriteLn(F, 'TEXT 440,17,"0",0,10,14,"' + FormatFloat(',0.00', CDSEtiquetasVLR_VISTA.AsCurrency) + '"');
			WriteLn(F, 'TEXT 310,55,"0",0,8,12,"PARCELADO: R$ "');
			WriteLn(F, 'TEXT 455,52,"0",0,10,14,"' + FormatFloat(',0.00', CDSEtiquetasVLR_PRAZO.AsCurrency) + '"');
			WriteLn(F, 'BARCODE 325,90,"EAN13",25,1,0,2,4,"' + CDSEtiquetasCOD_BARRA.AsString + '"');
			WriteLn(F, 'TEXT 290,145,"2",0,1,2,"' + Centralizar(CDSEtiquetasCODIGO.AsString, 20) + '"');
			Dec(QtdEtiq, 1);
			EnviarImpressao := True;
		end;

		while (QtdEtiq <= 0) and (CDSEtiquetas.RecNo <> CDSEtiquetas.RecordCount) do
		begin
			CDSEtiquetas.Next;
			QtdEtiq := CDSEtiquetasQTD_ETIQ.AsInteger;
		end;
		if QtdEtiq > 0 then
		begin
			// 3ª Etiqueta
			WriteLn(F, 'TEXT 610,20,"0",0,8,12,"' + 'À VISTA: R$ "');
			WriteLn(F, 'TEXT 720,17,"0",0,10,14,"' + FormatFloat(',0.00', CDSEtiquetasVLR_VISTA.AsCurrency) + '"');
			WriteLn(F, 'TEXT 590,55,"0",0,8,12,"PARCELADO: R$ "');
			WriteLn(F, 'TEXT 735,52,"0",0,10,14,"' + FormatFloat(',0.00', CDSEtiquetasVLR_PRAZO.AsCurrency) + '"');
			WriteLn(F, 'BARCODE 605,90,"EAN13",25,1,0,2,4,"' + CDSEtiquetasCOD_BARRA.AsString + '"');
			WriteLn(F, 'TEXT 570,145,"2",0,1,2,"' + Centralizar(CDSEtiquetasCODIGO.AsString, 20) + '"');
			Dec(QtdEtiq, 1);
			if (QtdEtiq <= 0) and (CDSEtiquetas.RecNo = CDSEtiquetas.RecordCount) then
				WriteLn(F, 'SET TEAR ON')
			else
				WriteLn(F, 'SET TEAR OFF');

			WriteLn(F, 'PRINT 1,1');
			EnviarImpressao := False;
		end;
		if (QtdEtiq <= 0) and (CDSEtiquetas.RecNo = CDSEtiquetas.RecordCount) then
			CDSEtiquetas.Next;
	end;
	if EnviarImpressao then
	begin
		WriteLn(F, 'SET TEAR ON');
		WriteLn(F, 'PRINT 1,1');
	end;
	CloseFile(F);
end;

procedure TFrmEtiquetasRibbon.FormClose(Sender: TObject; var Action: TCloseAction);
var
	Reg: TRegistry;
begin
	Reg         := TRegistry.Create;
	Reg.RootKey := HKEY_LOCAL_MACHINE;
	Reg.OpenKey('\Software\Config_Impressoras_Ribbon', True);
	Reg.WriteInteger('Modelo_Impressora', CbxModeloImpressora.ItemIndex);
	case TTipoImpressoraRibbon(CbxModeloImpressora.ItemIndex)  of
  	TTipoImpressoraRibbon.Bematech: Reg.WriteString('Caminho_Impressora_Bematech', EdtCaminho.Text);
    TTipoImpressoraRibbon.Zebra: Reg.WriteString('Caminho_Impressora_Zebra',  EdtCaminho.Text);  
  end;                                                                                      	
  Reg.CloseKey;
	Reg.Free;
	Action := CaFree;
end;

procedure TFrmEtiquetasRibbon.FormCreate(Sender: TObject);
begin
	Produto := TProdutos.Create();
end;

procedure TFrmEtiquetasRibbon.FormDestroy(Sender: TObject);
begin
	Produto.DisposeOf;
	FrmEtiquetasRibbon := nil;
end;

procedure TFrmEtiquetasRibbon.FormKeyPress(Sender: TObject; var Key: Char);
begin
	if Key = #13 then
		Perform(Wm_NextDlgCtl, 0, 0);
end;

procedure TFrmEtiquetasRibbon.CDSEtiquetasAfterScroll(DataSet: TDataSet);
begin
	// CJVBarcode.Texto := CDSEtiquetasCOD_BARRA.AsString;
end;

procedure TFrmEtiquetasRibbon.Excluir1Click(Sender: TObject);
begin
	if CDSEtiquetas.IsEmpty then
		Exit;
	EdtCodigo.Text := CDSEtiquetasCODIGO.AsString;
	CDSEtiquetas.Delete;
	EdtCodigo.SetFocus;
end;

procedure TFrmEtiquetasRibbon.DBGrid1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	if Key = VK_DELETE then
	begin
		if CDSEtiquetas.IsEmpty then
			Exit;
		CDSEtiquetas.Edit;
		CDSEtiquetasQTD_ETIQ.Value := 0;
		CDSEtiquetas.Post;
	end;
end;

procedure TFrmEtiquetasRibbon.DBGrid1KeyPress(Sender: TObject; var Key: Char);
begin
	if Key = '+' then
	begin
		if CDSEtiquetas.IsEmpty then
			Exit;
		CDSEtiquetas.Edit;
		CDSEtiquetasQTD_ETIQ.Value := CDSEtiquetasQTD_ETIQ.AsInteger + 1;
		CDSEtiquetas.Post;
	end
	else if Key = '-' then
	begin
		if CDSEtiquetas.IsEmpty then
			Exit;
		if CDSEtiquetasQTD_ETIQ.AsFloat > 0 then
		begin
			CDSEtiquetas.Edit;
			CDSEtiquetasQTD_ETIQ.Value := CDSEtiquetasQTD_ETIQ.AsInteger - 1;
			CDSEtiquetas.Post;
		end;
	end
	else if Key in ['0' .. '9'] then
	begin
		if CDSEtiquetas.IsEmpty then
			Exit;
		if (Key = '0') and (CDSEtiquetasQTD_ETIQ.AsString = '0') then
			Exit;
		CDSEtiquetas.Edit;
		CDSEtiquetasQTD_ETIQ.AsString := CDSEtiquetasQTD_ETIQ.AsString + Key;
		CDSEtiquetas.Post;
	end
	else if Key = chr(vk_back) then
	begin
		if CDSEtiquetas.IsEmpty then
			Exit;
		if CDSEtiquetasQTD_ETIQ.AsInteger > 0 then
		begin
			CDSEtiquetas.Edit;
			CDSEtiquetasQTD_ETIQ.AsString := LeftStr(CDSEtiquetasQTD_ETIQ.AsString, Length(CDSEtiquetasQTD_ETIQ.AsString) - 1);
			CDSEtiquetas.Post;
		end;
	end;
end;

procedure TFrmEtiquetasRibbon.CbxModeloImpressoraChange(Sender: TObject);
begin
	LeConfiguracao(False);
end;

procedure TFrmEtiquetasRibbon.CDSEtiquetasAfterPost(DataSet: TDataSet);
begin
	// CJVBarcode.Texto := CDSEtiquetasCOD_BARRA.AsString;
end;

procedure TFrmEtiquetasRibbon.BtnAlternaFiltroClick(Sender: TObject);
begin
	EdtCodigo.Clear;
	EdtNome.Clear;
	EdtValorVista.Clear;
	EdtValorPrazo.Clear;
	EdtNEtiquetas.Text := '1';
	if Label5.Caption = 'Código' then
	begin
		Label5.Caption        := 'Fatura';
		BtnAlternaFiltro.Hint := 'Alternar para Código de Produto';
	end
	else
	begin
		Label5.Caption        := 'Código';
		BtnAlternaFiltro.Hint := 'Alternar para Fatura de Compra';
	end;
	EdtCodigo.SetFocus;
end;

end.
