unit UnitBuscaPedidoRemoto;

interface

uses
	Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
	Vcl.Controls, Vcl.Forms, Vcl.Dialogs, UnitFormBase, System.Actions,
	Vcl.ActnList, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.ToolWin, Vcl.StdCtrls, Data.DB,
	FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
	FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
	FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.Grids, Vcl.DBGrids, Vcl.Menus;

type
	TFrmBuscaPedidoRemoto = class(TFrmBase)
		Panel2: TPanel;
		Panel3: TPanel;
		DBGrid1: TDBGrid;
		Panel4: TPanel;
		DBGrid2: TDBGrid;
		MemPedidos: TFDMemTable;
		DSPedidos: TDataSource;
		MemPedEst: TFDMemTable;
		DSPedEst: TDataSource;
		Label3: TLabel;
		MemPedidosCODIGO: TIntegerField;
		MemPedidosDATA: TDateField;
		MemPedidosVALOR: TCurrencyField;
		MemPedEstNOME: TStringField;
		MemPedEstQUANTIDADE: TFloatField;
		MemPedEstVALOR: TCurrencyField;
		MemPedEstVALOR_UNIT: TCurrencyField;
		actSelecionarVendedor: TAction;
		MemPedEstCOD_PRO: TIntegerField;
		PopupMenu1: TPopupMenu;
		Excluir1: TMenuItem;
    RGBuscaPedidos: TRadioGroup;
		MemPedidosFORNECEDOR: TStringField;
		MemPedEstCODIGO: TIntegerField;
		MemPedEstCOD_PEDIDO: TIntegerField;
    MemPedEstCOD_BARRAS: TStringField;
    MemPedEstTAM_SIGLA: TStringField;
		procedure FormDestroy(Sender: TObject);
		procedure FormShow(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure DBGrid2DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
		procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
		procedure DSPedidosDataChange(Sender: TObject; Field: TField);
		procedure DBGrid2KeyPress(Sender: TObject; var Key: Char);
		procedure actSairExecute(Sender: TObject);
		procedure Excluir1Click(Sender: TObject);
		procedure RGBuscaPedidosClick(Sender: TObject);
    procedure EdtBuscaFornecedorKeyPress(Sender: TObject; var Key: Char);
	private
		FBuscarFinalizados: Boolean;
		{ Private declarations }
		procedure BuscaPedidos;
		procedure LimparMemTable(MemTable: TFDMemTable);
	public
		{ Public declarations }
		property BuscarFinalizados: Boolean read FBuscarFinalizados write FBuscarFinalizados;
	end;

var
	FrmBuscaPedidoRemoto: TFrmBuscaPedidoRemoto;

implementation

{$R *.dfm}

uses
	UnitTabela.Helpers,
	UnitDMPrincipal,
	UnitGrid,
	UnitPedidoRemoto.Model,
	System.Generics.Collections,
	UnitPedEstRemoto.Model,
	UnitFuncoes,
	UnitConfiguracaoServidor.Singleton,
	System.Json,
	UnitClientREST.Model,
	UnitClientREST.Model.Interfaces, 
  UnitArquivosIni.Model;

procedure TFrmBuscaPedidoRemoto.actSairExecute(Sender: TObject);
begin
	inherited;
	DMPrincipal.CodigoPesquisado := -1;
	ModalResult                  := mrCancel;
end;

procedure TFrmBuscaPedidoRemoto.BuscaPedidos;
var
	ListaPedidoRemoto: TList<TPedidoRemotoResponse>;
	Pedido      : TPedidoRemotoResponse;
	Item        : TPedEstRemoto;
	Response    : TClientResult;
	aJson       : TJSONArray;
	Json        : TJSONValue;
  BaseURL: string;
  aItens: TJSONArray;
  i: Integer;
begin                        
	LimparMemTable(MemPedEst);
	LimparMemTable(MemPedidos);
	try
		MensagemUsuario('Aguarde, buscando Pedidos...', 1, False, False);
    if BuscarFinalizados then
    	BaseURL := TConfiguracaoServidor.BaseURL + '/pedidos?estado=FINALIZADO'
    else
    	BaseURL := TConfiguracaoServidor.BaseURL + '/pedidos';    
		Response := TClientRest.New(BaseURL)
    											 .AddHeader('Content-Type', 'application/json')
                           .Get();
		if Response.StatusCode = 200 then
		begin
			aJson        := TJSONObject.ParseJSONValue(Response.Content) as TJSONArray;
			ListaPedidoRemoto := TList<TPedidoRemotoResponse>.Create;
			for Json in aJson do
			begin
      	Pedido := TPedidoRemotoResponse.Create.fromJson<TPedidoRemotoResponse>(Json.ToJSON);        
				ListaPedidoRemoto.Add(Pedido);
			end;
			for Pedido in ListaPedidoRemoto do
			begin      	
				MemPedidos.Append;
				MemPedidosCODIGO.Value     := Pedido.Codigo;
				MemPedidosDATA.Value       := Pedido.Data;
				MemPedidosVALOR.Value      := Pedido.Valor;
				MemPedidosFORNECEDOR.Value := Pedido.Nome;
				MemPedidos.Post;
				if Length(Pedido.Itens) > 0 then
				begin
					for Item in TArray<TPedEstRemoto>(Pedido.Itens) do
					begin
						MemPedEst.Append;
						MemPedEstCODIGO.Value     := Item.Codigo;
						MemPedEstCOD_PRO.Value    := Item.CodPro;
            MemPedEstCOD_BARRAS.Value := Item.CodBarras;
						MemPedEstNOME.Value       := Item.Nome;
						MemPedEstQUANTIDADE.Value := Item.Quantidade;
						MemPedEstVALOR_UNIT.Value := Item.ValorC / Item.Quantidade;
						MemPedEstVALOR.Value      := Item.ValorC;
						MemPedEstCOD_PEDIDO.Value := Item.CodPed;
            MemPedEstTAM_SIGLA.Value  := Item.Grade.Tamanho.Sigla;
						MemPedEst.Post;
					end;
				end;
			end;
		end;
	finally
		ListaPedidoRemoto.DisposeOf;
		DBGrid2.SetFocus;
	end;
end;

procedure TFrmBuscaPedidoRemoto.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
	inherited;
	GridPadrao(DSPedEst.DataSet.RecNo, DBGrid1, Rect, Column, State);
end;

procedure TFrmBuscaPedidoRemoto.DBGrid2DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
	inherited;
	GridPadrao(DSPedidos.DataSet.RecNo, DBGrid2, Rect, Column, State);
end;

procedure TFrmBuscaPedidoRemoto.DBGrid2KeyPress(Sender: TObject; var Key: Char);
begin
	inherited;
	if Key = #13 then
	begin
		DMPrincipal.CodigoPesquisado := MemPedidosCODIGO.AsInteger;
		ModalResult                  := mrOk;
	end;
end;

procedure TFrmBuscaPedidoRemoto.DSPedidosDataChange(Sender: TObject; Field: TField);
begin
	inherited;
	MemPedEst.Filtered := False;
	MemPedEst.Filter   := Format('COD_PEDIDO = %d', [MemPedidosCODIGO.AsInteger]);
	MemPedEst.Filtered := True;
end;

procedure TFrmBuscaPedidoRemoto.EdtBuscaFornecedorKeyPress(Sender: TObject;
  var Key: Char);
begin
  inherited;
	BuscaPedidos;
end;

procedure TFrmBuscaPedidoRemoto.Excluir1Click(Sender: TObject);
var
	Response: TClientResult;
  Pedido: TPedidoRemoto;
begin
	inherited;
	if Application.MessageBox('Deseja realmente excluir este Pedido?', 'Excluir', MB_YESNO + MB_ICONQUESTION) = mrYes then
	begin
    try
    	Pedido := TPedidoRemoto.Create();
      Response := Pedido.Delete(MemPedidosCODIGO.AsInteger);
      if Response.StatusCode = 204 then
      begin
        Application.MessageBox('Pedido excluido com sucesso!', 'Sucesso', MB_OK + MB_ICONINFORMATION);
      end
      else
        Application.MessageBox(PWideChar('Falha ao excluir Pedido!' + sLineBreak + Response.Content + sLineBreak + Response.Error), 'Erro', MB_OK + MB_ICONERROR);
      BuscaPedidos();
    finally
      Pedido.DisposeOf;
    end;
	end;
end;

procedure TFrmBuscaPedidoRemoto.FormCreate(Sender: TObject);
begin
	inherited;
	MemPedidos.Close;
	MemPedidos.CreateDataSet;
	MemPedEst.Close;
	MemPedEst.CreateDataSet;
end;

procedure TFrmBuscaPedidoRemoto.FormDestroy(Sender: TObject);
begin
	inherited;
	FrmBuscaPedidoRemoto := nil;
end;

procedure TFrmBuscaPedidoRemoto.FormShow(Sender: TObject);
begin
	inherited;
	BuscaPedidos();
	if BuscarFinalizados then
		RGBuscaPedidos.ItemIndex := 1;
	DBGrid2.SetFocus;
end;

procedure TFrmBuscaPedidoRemoto.LimparMemTable(MemTable: TFDMemTable);
begin
	if MemTable.IsEmpty then
		Exit;
	MemTable.DisableControls;
	try
		MemTable.Close;
		MemTable.CreateDataSet;
	finally
		MemTable.EnableControls;
	end;
end;

procedure TFrmBuscaPedidoRemoto.RGBuscaPedidosClick(Sender: TObject);
begin
	inherited;
	BuscarFinalizados := RGBuscaPedidos.ItemIndex = 1;
	BuscaPedidos();
end;

end.
