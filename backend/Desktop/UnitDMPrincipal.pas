unit UnitDMPrincipal;

interface

uses
	Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
	Db, IBCustomDataSet, IBStoredProc, IBDatabase, IBQuery, System.ImageList, Vcl.ImgList,
	UnitObserver.Model.Interfaces, System.Generics.Collections, UnitUsuarios.Model,
	UnitEmpresa.Model, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, UnitPortalQueryREST.Component;

type
	TDMPrincipal = class(TDataModule, iSujeito, iLimparObservadores)
		Icones_Brancos: TImageList;
		Icones_Pretos: TImageList;
    IBQRPrincipal: TPortalQueryREST;
		procedure DataModuleDestroy(Sender: TObject);
		procedure DataModuleCreate(Sender: TObject);
	private
		{ Private declarations }
		FListaObservadores: TList<iObservador>;
	public
		{ Public declarations }
		Empresa                : TEmpresa;
		Pesquisa               : string;
		UsuarioLogado          : TUsuarios;
		Unidade_Sige           : word;
		XML                    : WideString;
		CodigoPesquisado, CodNF: integer;
    Cod_Grade: integer;
		function AddObservador(Value: iObservador): iSujeito;
		function RemoveObservador(Value: iObservador): iSujeito;
		function Notificar(Value: TNotificacao): iSujeito;
		function GeraCodigo(Tabela, Campo: string): integer;
		function InscrementaGenerator(Generator: string): integer;
	end;

var
	DMPrincipal: TDMPrincipal;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

uses
	UnitPrincipal, 
	UnitFuncoesUtils, 
	System.Threading,
	UnitClientREST.Model.Interfaces, 
	UnitClientREST.Model,
	UnitConfiguracaoServidor.Singleton, 
	System.JSON,
	UnitTabela.Helper.Json;

{$R *.DFM}

function TDMPrincipal.Notificar(Value: TNotificacao): iSujeito;
var
	i: integer;
begin
	Result := Self;
	for i  := 0 to Pred(FListaObservadores.Count) do
		FListaObservadores[i].Atualizar(Value);
end;

function TDMPrincipal.RemoveObservador(Value: iObservador): iSujeito;
begin
	FListaObservadores.Remove(Value);
end;

procedure TDMPrincipal.DataModuleCreate(Sender: TObject);
begin
	UsuarioLogado      := TUsuarios.Create;
	FListaObservadores := TList<iObservador>.Create;
	Empresa            := TEmpresa.Create;
end;

procedure TDMPrincipal.DataModuleDestroy(Sender: TObject);
begin
	FreeAndNil(FListaObservadores);
	Empresa.DisposeOf;
	UsuarioLogado.DisposeOf;
end;

function TDMPrincipal.GeraCodigo(Tabela, Campo: string): integer;
var
	FutureCodigo: iFuture<integer>;
	oJson       : TJSONObject;
begin
	FutureCodigo := TTask.Future<integer>(
		function: integer
		var
			Response: TClientResult;
		begin
			Result := 0;
			Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/gera_codigo').AddHeader('Content-Type', 'application/json').AddBody(TJSONObject.Create.AddPair('tabela', Tabela).AddPair('campo', Campo)).Post();
			if Response.StatusCode = 200 then
			begin
				oJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONObject;
				Result := oJson.GetValue<integer>('codigo');
			end;
		end);
	// aguarda a requisicao e obtem a resposta via REST API
	Result := FutureCodigo.Value;
end;

function TDMPrincipal.InscrementaGenerator(Generator: string): integer;
var
	FutureCodigo: iFuture<integer>;
	oJson       : TJSONObject;
begin
	FutureCodigo := TTask.Future<integer>(
		function: integer
		var
			Response: TClientResult;
		begin
			Result := 0;
			Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/incrementa_generator').AddHeader('Content-Type', 'application/json')
														 .AddBody(TJSONObject.Create.AddPair('generator', Generator))
														 .Post();
			if Response.StatusCode = 200 then
			begin
				oJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONObject;
				Result := oJson.GetValue<integer>('codigo');
			end;
		end);
	// aguarda a requisicao e obtem a resposta via REST API
	Result := FutureCodigo.Value;
end;

function TDMPrincipal.AddObservador(Value: iObservador): iSujeito;
begin
	Result := Self;
	FListaObservadores.Add(Value);
end;

end.
