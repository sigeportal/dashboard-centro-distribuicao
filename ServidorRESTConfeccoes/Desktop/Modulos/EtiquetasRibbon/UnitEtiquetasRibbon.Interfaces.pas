unit UnitEtiquetasRibbon.Interfaces;

interface
 type
   {$SCOPEDENUMS ON}
   TTipoImpressoraRibbon = (Bematech, Zebra);
   {$SCOPEDENUMS OFF}

  type
    TProduto = record
      Codigo: integer;
      Nome: string;
      NumCopias: integer;
      PrecoVista: Double;
      PrecoPrazo: Double;
      CodBarras: string;
    end;

    iEtiquetaRibbon = interface
      ['{2DAA868A-F3D8-4350-8C76-F9D342A57637}']
      function SetPorta(Value: string): iEtiquetaRibbon;
      function SetInverter(Value: Boolean): iEtiquetaRibbon;
      function AddProdutos(Value: TProduto): iEtiquetaRibbon;
      function Imprimir: iEtiquetaRibbon;
      function Limpar: iEtiquetaRibbon;
      function SetDensidade(Value: integer): iEtiquetaRibbon;
    end;

implementation

end.

