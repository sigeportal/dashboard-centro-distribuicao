unit UnitCadGrades;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Buttons, Grids, DBGrids, StdCtrls, Mask, DBCtrls, ExtCtrls, Db,
	Variants, JvExStdCtrls, JvCombobox, JvColorCombo, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, IBX.IBCustomDataSet,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, UnitPortalQueryREST.Component,
  System.RTTI, UnitFormRTTI.Model, UnitFormRTTI.Interfaces, 
  UnitGrades.Model, IBX.IBQuery, JvValidateEdit, JvEdit;

type
	TFrmCadGrades = class(TForm)
		BtnIncluir: TSpeedButton;
		BtnExcluir: TSpeedButton;
		BtnConfirmar: TSpeedButton;
		BtnCancelar: TSpeedButton;
		BtnEditar: TSpeedButton;
		DBGrid1: TDBGrid;
		Label22: TLabel;
		Label19: TLabel;
    IBQRGrade: TPortalQueryREST;
		DSGrade: TDataSource;
		IBQRGradeGRA_CODIGO: TIntegerField;
		IBQRGradeTAM_TAMANHO: TIBStringField;
		IBQRGradeGRA_VALOR: TIBBCDField;
		Label2: TLabel;
		IBQRGradeGRA_QUANTIDADE: TIBBCDField;
		IBQRGradeGRA_TAM: TIntegerField;
		IBQRGradeGRA_CODBARRA: TIBStringField;
		IBQRGradeGRA_COR: TIBStringField;
    IBQRTamanhos: TPortalQueryREST;
    IBQRTamanhosTAM_CODIGO: TIntegerField;
    IBQRTamanhosTAM_PRO: TIntegerField;
    IBQRTamanhosTAM_TAMANHO: TIBStringField;
    IBQRTamanhosTAM_SIGLA: TIBStringField;
    IBQRTamanhosTAM_VALOR: TIBBCDField;
    DSTamanhos: TDataSource;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Tamanho: TLabel;
    Label3: TLabel;
    [TLigarCampos('GRA_CODIGO', true)]
    lbCodigo: TLabel;
    Shape6: TShape;
    Label4: TLabel;
    Shape1: TShape;
    Label5: TLabel;
    Shape2: TShape;
    Label6: TLabel;
    [TLigarCampos('GRA_VALOR')]
    EdtValor: TJvValidateEdit;
    DBLookupComboBox1: TDBLookupComboBox;
    [TLigarCampos('GRA_QUANTIDADE')]
    EdtQuantidade: TJvValidateEdit;
    [TLigarCampos('GRA_CODBARRA')]
    EdtCodBarras: TEdit;
    CbxCor: TJvColorComboBox;
		procedure FormShow(Sender: TObject);
		procedure BtnIncluirClick(Sender: TObject);
		procedure BtnExcluirClick(Sender: TObject);
		procedure BtnConfirmarClick(Sender: TObject);
		procedure BtnCancelarClick(Sender: TObject);
		procedure BtnEditarClick(Sender: TObject);
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
		procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure FormKeyPress(Sender: TObject; var Key: Char);
		procedure FormDestroy(Sender: TObject);
		procedure EdtValorKeyPress(Sender: TObject; var Key: Char);
		procedure EdtCodBarraKeyPress(Sender: TObject; var Key: Char);
		procedure FormCreate(Sender: TObject);
		procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DSGradeDataChange(Sender: TObject; Field: TField);
    procedure CbxCorKeyPress(Sender: TObject; var Key: Char);
    procedure DBGrid1CellClick(Column: TColumn);
	private
		{ Private declarations }
    procedure HabilitarAcoes(TipoOperacao: TTipoOperacao);
	public
		Produto  : Integer;
		Pro_Valor: Currency;
		Codigo   : string;
    FormRTTI: iFormRTTI;
    Grades: TGrades;
		{ Public declarations }
	end;

var
	FrmCadGrades: TFrmCadGrades;
	ListS       : TStrings;

implementation

uses 
	UnitDMPrincipal,
  UnitTabela.Helper.JSON,	 
  UnitPrincipal, 
  UnitPesquisa,
	UnitCadProduto, UnitFuncoesUtils;
{$R *.DFM}

function RetZero(ZEROS: string; QUANT: Integer): String;
var
	I, Tamanho: Integer;
	aux       : string;
begin
	aux     := ZEROS;
	Tamanho := length(ZEROS);
	ZEROS   := '';
	for I   := 1 to QUANT - Tamanho do
		ZEROS := ZEROS + '0';
	aux     := ZEROS + aux;
	RetZero := aux;
end;

procedure TFrmCadGrades.CbxCorKeyPress(Sender: TObject; var Key: Char);
begin
	if key = #13 then
  	EdtValor.SetFocus;
end;

procedure TFrmCadGrades.FormShow(Sender: TObject);
begin
	HabilitarAcoes(TTipoOperacao.Inicio);
	IBQRTamanhos.Close;
  IBQRTamanhos.Open;
  IBQRTamanhos.Last;
	IBQRGrade.Close;
	IBQRGrade.ParamByName('PRODUTO').Value := Produto;
	IBQRGrade.Open;
  IBQRGrade.Last;
  Grades := Grades.Get<TGrades>(IBQRGradeGRA_CODIGO.AsInteger);
  FormRTTI.SetTabela(Grades);
  FormRTTI.BindForm(Self);
  DBGrid1.SetFocus;
end;

procedure TFrmCadGrades.HabilitarAcoes(TipoOperacao: TTipoOperacao);
var
  logico: boolean;
begin
  logico               := (TipoOperacao = TTipoOperacao.Insercao) or (TipoOperacao = TTipoOperacao.Edicao);
  BtnCancelar.Enabled  := logico;
  BtnConfirmar.Enabled := logico;
  BtnExcluir.Enabled   := not logico;
  BtnIncluir.Enabled   := not logico;
  BtnEditar.Enabled    := not logico;
end;

procedure TFrmCadGrades.BtnIncluirClick(Sender: TObject);
begin
	DBLookupComboBox1.Enabled := True;
	DBLookupComboBox1.SetFocus;
	FormRTTI.Inserir;
	Grades.Codigo     := DMPrincipal.GeraCodigo('GRADES', 'GRA_CODIGO');
	Grades.Pro        := Produto;
	Grades.Valor      := Pro_Valor;
	Grades.Quantidade := 0;
  Codigo            := '18960000' + RetZero(IntToStr(	Grades.Codigo), 6); // no lugar do 1 colocar campo cod_produto
  Grades.Codbarra   := '189600' + RetZero(IntToStr(	Grades.Codigo), 6) + GeraDVEAN(Codigo);
  FormRTTI.BindForm(Self);
end;

procedure TFrmCadGrades.BtnExcluirClick(Sender: TObject);
begin
	try
		if (messagedlg('Deseja realmente excluir este registro?', mtConfirmation, [mbYes, mbNo], 0)) = mrYes then
		begin
			FormRTTI.Excluir(Grades.Codigo);
			IBQRGrade.Close;
			IBQRGrade.ParamByName('PRODUTO').Value := Produto;
			IBQRGrade.Open;
		end;
	except
		on EDatabaseError do
			showmessage('Este dado não pode ser Excluído');
	end;
end;

procedure TFrmCadGrades.BtnConfirmarClick(Sender: TObject);
var
	Valor   : Currency;
	StrValor: String;
begin
	ListS := TStringList.Create;
	ListS.Clear;
	if (DBLookupComboBox1.Text = '') then
		ListS.Add('Tamanho');
	if (EdtValor.Text = '') then
		ListS.Add('Valor');
	if (ListS.Count > 0) then
	begin
		CamposObrigatorios(ListS);
		FrmCadGrades.BringToFront;
	end
	else
	begin				
		Grades.Cor := CbxCor.Items[CbxCor.ItemIndex];
    Grades.Tam := DBLookupComboBox1.KeyValue; 
		FormRTTI.Confirmar;
		IBQRGrade.Close;
		IBQRGrade.ParamByName('PRODUTO').Value := Produto;
		IBQRGrade.Open;
	end;
end;

procedure TFrmCadGrades.BtnCancelarClick(Sender: TObject);
begin
	FormRTTI.Cancelar;
end;

procedure TFrmCadGrades.BtnEditarClick(Sender: TObject);
begin
	FormRTTI.Editar;
	DBLookupComboBox1.SetFocus;
end;

procedure TFrmCadGrades.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	Action := caFree;
end;

procedure TFrmCadGrades.FormCreate(Sender: TObject);
begin
	Grades := TGrades.Create.Get<TGrades>(1);	
	FormRTTI := TFormRTTI.New;
  FormRTTI.SetEventoTipoOperacao(HabilitarAcoes);
end;

procedure TFrmCadGrades.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	if Key = 27 then
	begin
		if Application.MessageBox('Deseja fechar o cadastro de Grades?', 'Confirmar', MB_YesNo + MB_ICONQUESTION) = IDYes then
		begin
			Close;
		end;
	end;
	if Key = vk_f9 then
	begin
		if FrmPesquisa = nil then
			FrmPesquisa        := TFrmPesquisa.Create(nil);
		FrmPesquisa.Pesquisa := 'Grades';
		FrmPesquisa.ShowModal;
	end;
	if Key = Vk_F10 then
	begin
		if Application.MessageBox('Deseja gerar código de barras para todas as grades?', 'Confirmar', MB_YesNo + MB_ICONQUESTION) = mrYes then
		begin
			if not IBQRGrade.IsEmpty then
			begin
				try
					IBQRGrade.First;
					while not IBQRGrade.Eof do
					begin
						Codigo := '18960000' + RetZero(IntToStr(IBQRGradeGRA_CODIGO.AsInteger), 6); // no lugar do 1 colocar campo cod_produto
            Grades.BuscaDadosTabela(IBQRGradeGRA_CODIGO.AsInteger);
            Grades.Codbarra := '189600' + RetZero(IntToStr(IBQRGradeGRA_CODIGO.AsInteger), 6) + GeraDVEAN(Codigo);
            Grades.SalvaNoBanco();
            IBQRGrade.Next;            
					end;
					IBQRGrade.Close;
					IBQRGrade.Params[0].Value := Produto;
					IBQRGrade.Open;
					showmessage('Cod. de Barras das Grades gerado com sucesso!');
				except
					on E: Exception do
					begin
						showmessage('Erro ao gerar Cod. Barras! ' + E.Message);
					end;
				end;
			end;
		end;
	end;
end;

procedure TFrmCadGrades.FormKeyPress(Sender: TObject; var Key: Char);
begin
	if Key = #13 then
	begin
		if (Sender is TDBGrid) then
			TDBGrid(Sender).Perform(WM_KeyDown, VK_Tab, 0)
		else
			Perform(Wm_NextDlgCtl, 0, 0);
	end;
end;

procedure TFrmCadGrades.DSGradeDataChange(Sender: TObject; Field: TField);
begin
	if not (FormRTTI.TipoOperacao in [TTipoOperacao.Insercao, TTipoOperacao.Edicao]) then	  
  begin
		CbxCor.ItemIndex := CbxCor.Items.IndexOf(IBQRGradeGRA_COR.AsString);
  	DBLookupComboBox1.KeyValue := IBQRGradeGRA_TAM.AsInteger;
  end;
end;

procedure TFrmCadGrades.FormDestroy(Sender: TObject);
begin
	Grades.DisposeOf;
	FrmCadGrades := nil;
end;

procedure TFrmCadGrades.EdtValorKeyPress(Sender: TObject; var Key: Char);
begin
	if Key = #13 then
	begin
		if FormRTTI.TipoOperacao in [TTipoOperacao.Insercao, TTipoOperacao.Edicao] then
		begin
      BtnConfirmarClick(Sender);
      IBQRGrade.Last;
      DBGrid1.SetFocus;
		end;
	end;
end;

procedure TFrmCadGrades.DBGrid1CellClick(Column: TColumn);
begin
	Grades := Grades.Get<TGrades>(IBQRGradeGRA_CODIGO.AsInteger);
  FormRTTI.BindForm(Self)
end;

procedure TFrmCadGrades.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  index: integer;
begin
	with DBGrid1 do
	begin
		with Canvas do
		begin    	
    	index := CbxCor.Items.IndexOf(IBQRGradeGRA_COR.AsString);
      if index <= 0 then
      	index := 0;
			Brush.Color := CbxCor.Colors[index]; // Cor da celula
      Font.Color  := clWhite;                  // cor fonte
			FillRect(Rect); // Pinta a ceula
		end;              // with Canvas
		DefaultDrawDataCell(Rect, Column.Field, State)
	end;
end;

procedure TFrmCadGrades.EdtCodBarraKeyPress(Sender: TObject; var Key: Char);
begin
	if Key = #13 then
	begin
		if FormRTTI.TipoOperacao in [TTipoOperacao.Insercao, TTipoOperacao.Edicao] then
		begin
			BtnConfirmarClick(Sender);
		end;
	end;
end;

end.
