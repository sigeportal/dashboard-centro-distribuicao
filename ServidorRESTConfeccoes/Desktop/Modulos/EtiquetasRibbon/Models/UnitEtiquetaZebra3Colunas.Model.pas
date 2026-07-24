unit UnitEtiquetaZebra3Colunas.Model;


interface

uses
	UnitEtiquetasRibbon.Interfaces,
	ACBrBase,
	ACBrETQ,
	System.Generics.Collections;

type
	TEtiquetaZebra3Colunas = class(TInterfacedObject, iEtiquetaRibbon)
	private
		FPorta        : string;
		FACBrETQ      : TACBrETQ;
		FInverter     : Boolean;
		FListaProdutos: TList<TProduto>;
    FDensidade: integer;
		procedure AtivarEtiqueta;
		procedure ImprimeColuna(Produto: TProduto; PosicaoHorizontal: integer);
	public
		constructor Create;
		destructor Destroy; override;
		function SetPorta(Value: string): iEtiquetaRibbon;
		function SetInverter(Value: Boolean): iEtiquetaRibbon;
		class function New: iEtiquetaRibbon;
		function Imprimir: iEtiquetaRibbon;
		function AddProdutos(Value: TProduto): iEtiquetaRibbon;
		function Limpar: iEtiquetaRibbon;
    function SetDensidade(Value: Integer): iEtiquetaRibbon;
	end;

implementation

uses
	System.SysUtils, ACBrDevice, ACBrETQClass, UnitFuncoesUtils, UnitDMPrincipal;

{ TProduto }

function TEtiquetaZebra3Colunas.AddProdutos(Value: TProduto): iEtiquetaRibbon;
begin
	Result := Self;
	FListaProdutos.Add(Value);
end;

procedure TEtiquetaZebra3Colunas.AtivarEtiqueta;
begin
	FACBrETQ.Desativar;
	// FACBrETQ.DPI           := TACBrETQDPI(cbDPI.ItemIndex);
	FACBrETQ.Modelo        := etqZPLII; // TACBrETQModelo(cbModelo.ItemIndex);
	FACBrETQ.Porta         := FPorta;
	FACBrETQ.LimparMemoria := True;
  FACBrETQ.DPI := TACBrETQDPI.dpi203;
  FACBrETQ.Temperatura := 15;
	// FACBrETQ.Temperatura   := StrToInt(eTemperatura.Text);
	// FACBrETQ.Velocidade    := StrToInt(eVelocidade.Text);
	// FACBrETQ.BackFeed      := TACBrETQBackFeed.bfOn;
	FACBrETQ.Unidade := etqDecimoDeMilimetros;
	FACBrETQ.Ativar;
end;

constructor TEtiquetaZebra3Colunas.Create;
begin
	FACBrETQ       := TACBrETQ.Create(nil);
	FListaProdutos := TList<TProduto>.Create;
end;

destructor TEtiquetaZebra3Colunas.Destroy;
begin
	FreeAndNil(FACBrETQ);
	FListaProdutos.DisposeOf;
	inherited;
end;

procedure TEtiquetaZebra3Colunas.ImprimeColuna(Produto: TProduto; PosicaoHorizontal: integer);
begin
	FACBrETQ.ImprimirTexto(orNormal, '0', 20, 30, 25, PosicaoHorizontal, Centralizar('Á VISTA: '+ FormatCurr('R$ ,0.00', Produto.PrecoVista), 25));
  FACBrETQ.ImprimirTexto(orNormal, '0', 20, 30, 65, PosicaoHorizontal, Centralizar('PARCELADO: ' + FormatCurr('R$ ,0.00', Produto.PrecoPrazo), 22));
	FACBrETQ.ImprimirBarras(orNormal, barEAN13, 2, 2, 110, PosicaoHorizontal+10, Produto.CodBarras, 40, becSIM);
	FACBrETQ.ImprimirTexto(orNormal, '0', 30, 30, 190, PosicaoHorizontal, Centralizar(Produto.Codigo.ToString, 22));	
end;

function TEtiquetaZebra3Colunas.Imprimir: iEtiquetaRibbon;
var
	Linhas   : TList<String>;
	Linha    : string;
	Produto  : TProduto;
	Etiquetas: TList<TProduto>.TEnumerator;
	i        : integer;
begin
	Result := Self;
	AtivarEtiqueta;
	Etiquetas := FListaProdutos.GetEnumerator;
	while Etiquetas.MoveNext do
	begin
		Produto := Etiquetas.Current;
		ImprimeColuna(Produto, 30);
		if Etiquetas.MoveNext then // vai para o proximo Produto
		begin
			Produto := Etiquetas.Current;
			ImprimeColuna(Produto, 380);
		end;
		if Etiquetas.MoveNext then // vai para o proximo Produto
		begin
			Produto := Etiquetas.Current;
			ImprimeColuna(Produto, 735);
		end;
		FACBrETQ.Imprimir(1, 680);
	end;
	FACBrETQ.Desativar;
end;

function TEtiquetaZebra3Colunas.Limpar: iEtiquetaRibbon;
begin
	Result := Self;
	FListaProdutos.Clear;
end;

class function TEtiquetaZebra3Colunas.New: iEtiquetaRibbon;
begin
	Result := Self.Create;
end;

function TEtiquetaZebra3Colunas.SetDensidade(Value: Integer): iEtiquetaRibbon;
begin
  Result := Self;
  FDensidade := Value;
end;

function TEtiquetaZebra3Colunas.SetInverter(Value: Boolean): iEtiquetaRibbon;
begin
	Result    := Self;
	FInverter := Value;
end;

function TEtiquetaZebra3Colunas.SetPorta(Value: string): iEtiquetaRibbon;
begin
	Result := Self;
	FPorta := Value;
end;

end.
