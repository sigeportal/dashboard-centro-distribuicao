unit UnitEtiquetaBematech3Colunas.Model;

interface

uses
  UnitEtiquetasRibbon.Interfaces,
  System.Generics.Collections, System.SysUtils;
  
type
	TEtiquetaBematech3Colunas = class(TInterfacedObject, iEtiquetaRibbon, iEtiqueta)
  private
  	FNome: string;
    FValor: currency;
    FCodBarras: string;
    FPorta: string;
    FNumCopias: integer;
    FInverter: Boolean;
    FTitulo: string;
    FListaProdutos: TList<TProduto>;
  public
  	function SetTitulo(Value: string): iEtiquetaRibbon;
    function SetNome(Value: string): iEtiquetaRibbon;
    function SetValor(Value: currency): iEtiquetaRibbon;
    function SetCodBarras(Value: string): iEtiquetaRibbon;
    function SetPorta(Value: string): iEtiquetaRibbon;
    function SetNumCopias(Value: integer): iEtiquetaRibbon;
    function SetInverter(Value: Boolean): iEtiquetaRibbon;
    function Imprimir: iEtiquetaRibbon;
    class function New: iEtiqueta;
    function AddProdutos(Value: TProduto): iEtiqueta;    
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TEtiquetaBematech3Colunas }

function TEtiquetaBematech3Colunas.AddProdutos(Value: TProduto): iEtiqueta;
begin
  Result := Self;
  FListaProdutos.Add(Value)
end;

constructor TEtiquetaBematech3Colunas.Create;
begin
  FListaProdutos := TList<TProduto>.Create;
end;

destructor TEtiquetaBematech3Colunas.Destroy;
begin
	FListaProdutos.DisposeOf;
  inherited;
end;

function TEtiquetaBematech3Colunas.Imprimir: iEtiquetaRibbon;
var F : TextFile;
    QtdEtiq : integer;
    EnviarImpressao : boolean;
	  i: Integer;
begin
	Result := Self;
  AssignFile(F, FPorta);
  Rewrite(F);
  WriteLn(F, 'SIZE 104 mm,22 mm');//Altura e largura da etiqueta
  WriteLn(F, 'GAP 2 mm,0');
  WriteLn(F, 'DIRECTION 1,0');//Direção da etiqueta - 1,0: invertido verticalmente
  WriteLn(F, 'REFERENCE 0,0');//Ponto de referência da etiqueta
  WriteLn(F, 'OFFSET 0 mm');
  WriteLn(F, 'SET PEEL OFF');
  WriteLn(F, 'SET CUTTER OFF');
  WriteLn(F, 'CODEPAGE 1252');//CodePage Internacional 1252 = Latin I
  //                +-Coordenação X
  //                | +-Coordenação Y
  //                | |  +-Fonte - 0 a 8
  //                | |  |  +-Ângulo de rotação
  //                | |  |  | +-Multiplicação Horizontal
  //                | |  |  | | +-Multiplicação Vertical
  //                | |  |  | | |         +-Conteúdo
  //                | |  |  | | |         |
  //                | |  |  | | |         |
  EnviarImpressao := False;
  QtdEtiq := FListaProdutos.First.NumCopias;
  for i := 0 to Pred(FListaProdutos.Count) do
  begin
    WriteLn(F, 'CLS');//Apaga qualquer imagem que esteja na memória da impressora
    while (QtdEtiq <= 0) and (i <> FListaProdutos.Count) do
    begin
      QtdEtiq := FListaProdutos[i].NumCopias;
    end;
    if QtdEtiq > 0 then
    begin
      //1ª Etiqueta
      WriteLn(F, 'TEXT 50,20,"0",0,8,12,"'+'À VISTA: R$ "');
      WriteLn(F, 'TEXT 160,17,"0",0,10,14,"'+FormatFloat(',0.00', FListaProdutos[i].PrecoVista)+'"');
      WriteLn(F, 'TEXT 30,55,"0",0,8,12,"PARCELADO: R$ "');
      WriteLn(F, 'TEXT 175,52,"0",0,10,14,"'+FormatFloat(',0.00', FListaProdutos[i].PrecoPrazo)+'"');
      WriteLn(F, 'BARCODE 45,90,"EAN13",25,1,0,2,4,"'+FListaProdutos[i].+'"');
      WriteLn(F, 'TEXT 10,145,"2",0,1,2,"'+Centralizar(CDSEtiquetasCODIGO.AsString, 20)+'"');
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
      //2ª Etiqueta
      WriteLn(F, 'TEXT 330,20,"0",0,8,12,"'+'À VISTA: R$ "');
      WriteLn(F, 'TEXT 440,17,"0",0,10,14,"'+FormatFloat(',0.00',CDSEtiquetasVLR_VISTA.AsCurrency)+'"');
      WriteLn(F, 'TEXT 310,55,"0",0,8,12,"PARCELADO: R$ "');
      WriteLn(F, 'TEXT 455,52,"0",0,10,14,"'+FormatFloat(',0.00',CDSEtiquetasVLR_PRAZO.AsCurrency)+'"');
      WriteLn(F, 'BARCODE 325,90,"EAN13",25,1,0,2,4,"'+CDSEtiquetasCOD_BARRA.AsString+'"');
      WriteLn(F, 'TEXT 290,145,"2",0,1,2,"'+Centralizar(CDSEtiquetasCODIGO.AsString, 20)+'"');
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
      //3ª Etiqueta
      WriteLn(F, 'TEXT 610,20,"0",0,8,12,"'+'À VISTA: R$ "');
      WriteLn(F, 'TEXT 720,17,"0",0,10,14,"'+FormatFloat(',0.00',CDSEtiquetasVLR_VISTA.AsCurrency)+'"');
      WriteLn(F, 'TEXT 590,55,"0",0,8,12,"PARCELADO: R$ "');
      WriteLn(F, 'TEXT 735,52,"0",0,10,14,"'+FormatFloat(',0.00',CDSEtiquetasVLR_PRAZO.AsCurrency)+'"');
      WriteLn(F, 'BARCODE 605,90,"EAN13",25,1,0,2,4,"'+CDSEtiquetasCOD_BARRA.AsString+'"');
      WriteLn(F, 'TEXT 570,145,"2",0,1,2,"'+Centralizar(CDSEtiquetasCODIGO.AsString, 20)+'"');
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

class function TEtiquetaBematech3Colunas.New: iEtiqueta;
begin
	Result := Self.Create;
end;

function TEtiquetaBematech3Colunas.SetCodBarras(Value: string): iEtiquetaRibbon;
begin
  Result := Self;
  FCodBarras := Value;
end;

function TEtiquetaBematech3Colunas.SetInverter(Value: Boolean): iEtiquetaRibbon;
begin
  Result := Self;
  FInverter := Value;
end;

function TEtiquetaBematech3Colunas.SetNome(Value: string): iEtiquetaRibbon;
begin
  Result := Self;
  FNome := Value;
end;

function TEtiquetaBematech3Colunas.SetNumCopias(
  Value: integer): iEtiquetaRibbon;
begin
	Result := Self;
  FNumCopias := Value;
end;

function TEtiquetaBematech3Colunas.SetPorta(Value: string): iEtiquetaRibbon;
begin
  Result := Self;
  FPorta := Value;
end;

function TEtiquetaBematech3Colunas.SetTitulo(Value: string): iEtiquetaRibbon;
begin
  Result := Self;
  FTitulo := Value;
end;

function TEtiquetaBematech3Colunas.SetValor(Value: currency): iEtiquetaRibbon;
begin
  Result := Self;
  FValor := Value;
end;

end.
