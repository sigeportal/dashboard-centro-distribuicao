unit UnitGrid;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Grids, DBGrids, StdCtrls, db, IBCustomDataSet, IBQuery, ExtCtrls, DBCtrls, System.Actions, Vcl.ActnList, Vcl.ComCtrls, Vcl.ToolWin,
	UnitClientREST.Model.Interfaces, System.Threading, DataSet.Serialize,
	Datasnap.DBClient, UnitComponentes.Model.Interfaces, System.Json, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error,
	FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
	TFrmGrid = class(TForm)
		DBGrid1: TDBGrid;
		Edt: TEdit;
		IBQRVerifica: TIBQuery;
		IBQRVerificaRF_RES: TIntegerField;
		IBQRVerificaCLI_NOME: TIBStringField;
		Timer1: TTimer;
		DSGrid: TDataSource;
		ToolBar2: TToolBar;
		ToolButton3: TToolButton;
		ToolButton4: TToolButton;
		ToolButton5: TToolButton;
		ToolButton1: TToolButton;
		ToolButton2: TToolButton;
		ActionList1: TActionList;
		actSelecionar: TAction;
		actSair: TAction;
		Panel1: TPanel;
		FDMemTableGrid: TFDMemTable;
		procedure DBGrid1KeyPress(Sender: TObject; var Key: Char);
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
		procedure FormShow(Sender: TObject);
		procedure EdtKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure DBGrid1DblClick(Sender: TObject);
		procedure EdtKeyPress(Sender: TObject; var Key: Char);
		procedure Timer1Timer(Sender: TObject);
		procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
		procedure actSelecionarExecute(Sender: TObject);
		procedure actSairExecute(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure DSGridDataChange(Sender: TObject; Field: TField);
	private
		{ Private declarations }
		procedure BuscaDadosServidor(Recurso: string);
		function PreparaFiltros: string;
		procedure LimparMemTable;
	public
		{ Public declarations }
		SQL1, SQL2      : string;
		DoisPorcentagens: boolean;
		Recurso         : string;
		Filtros         : TArray<string>;
		Ordenacao       : string;
		TotalRegistros  : Integer;
	end;

var
	FrmGrid: TFrmGrid;

implementation

uses
	UnitDMPrincipal,
	UnitPrincipal,
	UnitLogin,
	UnitFuncoesUtils,
	UnitClientREST.Model,
	UnitConfiguracaoServidor.Singleton,
	UnitFactoryComponentes.Model;
{$R *.DFM}

procedure TFrmGrid.DBGrid1KeyPress(Sender: TObject; var Key: Char);
begin
	if Key = #13 then
		actSelecionar.Execute;
	if Key = #27 then
		actSair.Execute;
end;

procedure TFrmGrid.DSGridDataChange(Sender: TObject; Field: TField);
begin
	if Assigned(Field) then
	begin
		try
			if Field.FieldName.Contains('DATA') then
			begin
				Field.Value := FormatDateTime('dd/mm/yyyy', StrToDate(ConverteData(Field.Value)));
			end;
		except

		end;
	end;
end;

procedure TFrmGrid.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	Self.GravaEstadoForm([DBGrid1], Recurso.Replace('/', ''));
	Action := caFree;
end;

procedure TFrmGrid.FormDestroy(Sender: TObject);
begin
	FrmGrid := nil;
end;

procedure TFrmGrid.FormShow(Sender: TObject);
begin
	BuscaDadosServidor(Recurso);
	Edt.SetFocus;
end;

procedure TFrmGrid.LimparMemTable;
begin
	if FDMemTableGrid.IsEmpty then
		Exit;		
	FDMemTableGrid.DisableControls;
	try
		FDMemTableGrid.First;
		while not FDMemTableGrid.Eof do
		begin
			FDMemTableGrid.Delete;
			FDMemTableGrid.Next;
		end;
  finally
    FDMemTableGrid.EnableControls;
  end;
end;

function TFrmGrid.PreparaFiltros: string;
var
	TextoFiltro: TArray<string>;
	i: Integer;
begin
	Result := '';
	if not String(Edt.Text).IsEmpty then
	begin
		SetLength(TextoFiltro, High(Filtros) + 1);
		for i := 0 to High(Filtros) do
		begin
			TextoFiltro[i] := Filtros[i] + '=' + String(Edt.Text).QuotedString;
		end;
		Result := ''.Join('&', TextoFiltro);
	end;
end;

procedure TFrmGrid.EdtKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	if (Key = 38) then
	begin
		if (not DBGrid1.DataSource.DataSet.Bof) then
		begin
			DBGrid1.DataSource.DataSet.Prior;
		end;
		Key := 0;
	end;
	if (Key = 40) then
	begin
		if (not DBGrid1.DataSource.DataSet.Eof) then
		begin
			DBGrid1.DataSource.DataSet.Next;
		end;
		Key := 0;
	end;
end;

procedure TFrmGrid.actSairExecute(Sender: TObject);
begin
	DMPrincipal.CodigoPesquisado := -1;
	ModalResult                  := mrCancel;
end;

procedure TFrmGrid.actSelecionarExecute(Sender: TObject);
begin
	DMPrincipal.CodigoPesquisado := DSGrid.DataSet.Fields[0].AsInteger;
	ModalResult                  := mrOk;
end;

procedure TFrmGrid.BuscaDadosServidor(Recurso: string);
var
	FutureResponse: IFuture<TClientResult>;
	aJson         : TJSONArray;
	aValue        : TJSONValue;
	oJson         : TJSONObject;
	Data          : string;
	IndexOrdenacao: TIndexDef;
begin
	try
		FutureResponse := TTask.Future<TClientResult>(
			function: TClientResult
			var
				Filtragem: string;
			begin
				Filtragem := PreparaFiltros;
				if TotalRegistros > 0 then
					Result := TClientREST.New(TConfiguracaoServidor.BaseURL + Recurso + '?total=' + TotalRegistros.ToString + '&' + Filtragem).Get()
				else if (not filtragem.IsEmpty) then             
					Result := TClientREST.New(TConfiguracaoServidor.BaseURL + Recurso + '?' + Filtragem).Get()
        else
        	Result := TClientREST.New(TConfiguracaoServidor.BaseURL + Recurso).Get()
			end);
		if FutureResponse.Value.StatusCode = 200 then
		begin
			aJson := TJSONObject.ParseJSONValue(FutureResponse.Value.Content) as TJSONArray;
			LimparMemTable;
			FDMemTableGrid.LoadFromJSON(aJson);
			Self.InicializaEstadoForm([DBGrid1], Recurso.Replace('/', ''));
		end
		else
			raise Exception.Create('Erro ao buscar dados servidor!' + sLineBreak + FutureResponse.Value.Content);
	except
		on E: Exception do
			raise Exception.Create('Erro ao buscar dados servidor!' + sLineBreak + E.Message);
	end;
end;

procedure TFrmGrid.DBGrid1DblClick(Sender: TObject);
const
	ENTER: Char = #13;
begin
	EdtKeyPress(Sender, ENTER);
end;

procedure TFrmGrid.EdtKeyPress(Sender: TObject; var Key: Char);
begin
	Timer1.Enabled := False;
	Timer1.Enabled := True;
	if (Key = #13) then
	begin
		DMPrincipal.CodigoPesquisado := DSGrid.DataSet.Fields[0].AsInteger;
		ModalResult                  := mrOk;
	end;
	if (Key = #27) then
	begin
		DMPrincipal.CodigoPesquisado := -1;
		ModalResult                  := mrCancel;
	end;
end;

procedure TFrmGrid.Timer1Timer(Sender: TObject);
var
	i          : Integer;
	TextoFiltro: TArray<string>;
begin
	Timer1.Enabled          := False;
	DSGrid.DataSet.Filtered := False;
	if not String(Edt.Text).IsEmpty then
	begin
		SetLength(TextoFiltro, High(Filtros) + 1);
		for i := 0 to High(Filtros) do
		begin
			TextoFiltro[i] := Filtros[i] + ' like ' + QuotedStr('%' + Edt.Text + '%');
		end;
		DSGrid.DataSet.Filter   := ''.Join(' or ', TextoFiltro);
		DSGrid.DataSet.Filtered := True;
	end;
	/// /
	// dispara a busca somente quando for digitado mais de 3 caracteres
	if String(Edt.Text).Length > 2 then
		BuscaDadosServidor(Recurso);
end;

procedure TFrmGrid.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
	GridPadrao(DSGrid.DataSet.RecNo, DBGrid1, Rect, Column, State);
end;

end.
