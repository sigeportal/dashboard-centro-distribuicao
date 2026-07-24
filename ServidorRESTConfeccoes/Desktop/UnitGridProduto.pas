unit UnitGridProduto;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, DBGrids, StdCtrls, db, IBCustomDataSet, IBQuery, ExtCtrls, DBCtrls, Registry,
  System.ImageList, Vcl.ImgList, System.Actions, Vcl.ActnList, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.Buttons, IBX.IBDatabase, Vcl.Menus, Datasnap.DBClient,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, UnitPortalQueryREST.Component,
  Vcl.Imaging.pngimage;

type
  TFrmGridProduto = class(TForm)
    Timer1: TTimer;
    DSGrid: TDataSource;
    IBQRGrid: TPortalQueryREST;
    ToolBar1: TToolBar;
    BtnSair: TToolButton;
    ToolButton2: TToolButton;
    BtnSelecionar: TToolButton;
    BtnAlternarFiltro: TToolButton;
    ToolButton1: TToolButton;
    BtnCadastro: TToolButton;
    ToolButton3: TToolButton;
    Panel1: TPanel;
    Edt: TEdit;
    RadioGroup1: TRadioGroup;
    Panel2: TPanel;
    DBGrid1: TDBGrid;
    Panel3: TPanel;
    Shape31: TShape;
    ImgFoto: TImage;
    RadioGroup2: TRadioGroup;
    GroupBox2: TGroupBox;
    DBGrid2: TDBGrid;
    BtnAplicar: TBitBtn;
    CDSCampos: TClientDataSet;
    CDSCamposCAMPO: TStringField;
    CDSCamposLARGURA: TSmallintField;
    CDSCamposCOLUNA: TSmallintField;
    CDSCamposEXIBIR: TStringField;
    DSCampos: TDataSource;
    IBQRGridPRO_URL_IMAGEM: TStringField;
    ImageList1: TImageList;
    ActionList1: TActionList;
    ActSair: TAction;
    ActSelecionar: TAction;
    ActAlternarFiltro: TAction;
    ActCadastro: TAction;
    IBQRGridCODIGO: TIntegerField;
    IBQRGridQUANT: TIBBCDField;
    IBQRGridVALORV: TIBBCDField;
    IBQRGridCODBARRA: TIBStringField;
    IBQRGridNOME: TIBStringField;
    ToolButton4: TToolButton;
    Image1: TImage;
    Image2: TImage;
    IBQRGridICONE: TStringField;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure EdtKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure EdtKeyPress(Sender: TObject; var Key: Char);
    procedure Timer1Timer(Sender: TObject);
    procedure ComboGrupoChange(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormDestroy(Sender: TObject);
    procedure SetaFiltroBusca;
    procedure DBGrid1DrawColumnCell(Sender: TObject; const [Ref] Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure ImgFotoClick(Sender: TObject);
    procedure ActAlternarFiltroExecute(Sender: TObject);
    procedure ActSairExecute(Sender: TObject);
    procedure ActSelecionarExecute(Sender: TObject);
    procedure ActCadastroExecute(Sender: TObject);
    procedure BtnAplicarClick(Sender: TObject);
    procedure DBGrid2CellClick(Column: TColumn);
    procedure DBGrid2DrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure RadioGroup1Click(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
  private
    { Private declarations }
  public
    { Public declarations }
    ModuloBD : String;
  end;

var
  FrmGridProduto: TFrmGridProduto;

implementation

uses 
	UnitDMPrincipal, 
  UnitPrincipal, 
  QRPrntr, 
  System.StrUtils, 
  UnitAmpliaFoto,
  Bitmap.HelperClass,
  UnitCadProduto, 
  UnitFuncoesUtils;
  
{$R *.DFM}

const
  SQL: array [0 .. 3] of string =  ('SELECT FIRST 100 PRO_CODIGO AS CODIGO, PRO_QUANTIDADE AS QUANT, PRO_VALORV AS VALORV, PRO_NOME AS NOME, PRO_CODBARRA AS "COD BARRA", PRO_ESTADO, PRO_URL_IMAGEM '+
                                    'FROM PRODUTOS, GRUPOS, FORNECEDORES '+
                                    'WHERE PRO_ESTADO = ''ATIVO'' AND PRO_GRU = GRU_CODIGO AND PRO_FOR = FOR_CODIGO '+
                                    'AND PRO_CODIGO LIKE :CODIGO ORDER BY PRO_CODIGO',
                                    'SELECT FIRST 100 PRO_CODIGO AS CODIGO, PRO_QUANTIDADE AS QUANT, PRO_VALORV AS VALORV, PRO_NOME AS NOME, PRO_CODBARRA AS "COD BARRA", PRO_ESTADO, PRO_URL_IMAGEM '+
                                    'FROM PRODUTOS, GRUPOS, FORNECEDORES '+
                                    'WHERE PRO_ESTADO = ''ATIVO'' AND PRO_GRU = GRU_CODIGO AND PRO_FOR = FOR_CODIGO '+
                                    'AND PRO_CODBARRA LIKE :BARRAS ORDER BY PRO_CODIGO',
                                    'SELECT FIRST 100 PRO_CODIGO AS CODIGO, PRO_QUANTIDADE AS QUANT, PRO_VALORV AS VALORV, PRO_NOME AS NOME, PRO_CODBARRA AS "COD BARRA", PRO_ESTADO, PRO_URL_IMAGEM '+
                                    'FROM PRODUTOS, GRUPOS, FORNECEDORES '+
                                    'WHERE PRO_ESTADO = ''ATIVO'' AND PRO_GRU = GRU_CODIGO AND PRO_FOR = FOR_CODIGO '+
                                    'AND CAST(LEFT(PRO_NOME, 200) AS VARCHAR(200) CHARACTER SET ISO8859_1) COLLATE PT_BR LIKE :NOME ORDER BY PRO_NOME',
                                    'SELECT FIRST 100 PRO_CODIGO AS CODIGO, PRO_QUANTIDADE AS QUANT, PRO_VALORV AS VALORV, PRO_NOME AS NOME, PRO_CODBARRA AS "COD BARRA", PRO_ESTADO, PRO_URL_IMAGEM '+
                                    'FROM PRODUTOS, GRUPOS, FORNECEDORES ' +
                                    'WHERE PRO_ESTADO = ''ATIVO'' AND PRO_GRU = GRU_CODIGO AND PRO_FOR = FOR_CODIGO '+
                                    'AND GRU_NOME LIKE :GRUPO ORDER BY GRU_NOME');

const
  SQL2: array [0 .. 3] of string = ('SELECT FIRST 100 PRO_CODIGO AS CODIGO, PRO_QUANTIDADE AS QUANT, PRO_VALORV AS VALORV, PRO_NOME AS NOME, PRO_CODBARRA AS "COD BARRA", PRO_ESTADO, PRO_URL_IMAGEM ' +
                                    'FROM PRODUTOS, GRUPOS, FORNECEDORES ' +
                                    'WHERE PRO_GRU = GRU_CODIGO AND PRO_FOR = FOR_CODIGO ' +
                                    'AND PRO_CODIGO LIKE :CODIGO ORDER BY PRO_CODIGO',
                                    'SELECT FIRST 100 PRO_CODIGO AS CODIGO, PRO_QUANTIDADE AS QUANT, PRO_VALORV AS VALORV, PRO_NOME AS NOME, PRO_CODBARRA AS "COD BARRA", PRO_ESTADO, PRO_URL_IMAGEM ' +
                                    'FROM PRODUTOS, GRUPOS, FORNECEDORES ' +
                                    'WHERE PRO_GRU = GRU_CODIGO AND PRO_FOR = FOR_CODIGO ' +
                                    'AND PRO_CODBARRA LIKE :BARRAS ORDER BY PRO_CODIGO',
                                    'SELECT FIRST 100 PRO_CODIGO AS CODIGO, PRO_QUANTIDADE AS QUANT, PRO_VALORV AS VALORV, PRO_NOME AS NOME, PRO_CODBARRA AS "COD BARRA", PRO_ESTADO, PRO_URL_IMAGEM ' +
                                    'FROM PRODUTOS, GRUPOS, FORNECEDORES ' +
                                    'WHERE PRO_GRU = GRU_CODIGO AND PRO_FOR = FOR_CODIGO ' +
                                    'AND CAST(LEFT(PRO_NOME, 200) AS VARCHAR(200) CHARACTER SET ISO8859_1) COLLATE PT_BR LIKE :NOME ORDER BY PRO_NOME',
                                    'SELECT FIRST 100 PRO_CODIGO AS CODIGO, PRO_QUANTIDADE AS QUANT, PRO_VALORV AS VALORV, PRO_NOME AS NOME, PRO_CODBARRA AS "COD BARRA", PRO_ESTADO, PRO_URL_IMAGEM ' +
                                    'FROM PRODUTOS, GRUPOS, FORNECEDORES ' +
                                    'WHERE PRO_GRU = GRU_CODIGO AND PRO_FOR = FOR_CODIGO ' +
                                    'AND GRU_NOME LIKE :GRUPO ORDER BY GRU_NOME');

procedure TFrmGridProduto.FormClose(Sender: TObject; var Action: TCloseAction);
var
  Reg: TRegistry;
  i, j: smallint;
begin
  // guardo no registro o ultimo filtro de busca usado
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.OpenKey('SOFTWARE\PORTAL.COM\' + ExtractFileName(Application.ExeName), True);
  Reg.WriteInteger('FiltroBuscaProduto', RadioGroup1.ItemIndex);
  Reg.WriteInteger('TipoBuscaProduto', RadioGroup2.ItemIndex);
  Reg.CloseKey;
  // Posicionamento da Tela
  Reg.OpenKey('SOFTWARE\PORTAL.COM\' + ExtractFileName(Application.ExeName) + '\GridProduto', True);
  try
    Reg.WriteBool('Maximizado', FrmGridProduto.WindowState = wsMaximized);
    Reg.WriteInteger('Altura', Height);
    Reg.WriteInteger('Largura', Width);
    Reg.WriteInteger('Topo', Top);
    Reg.WriteInteger('Esquerda', Left);
    for i := 0 to DBGrid1.Columns.Count-1 do
    begin
      if DBGrid1.Columns[i].Width > 0 then
      begin
        Reg.WriteString('Coluna'+IntToStr(j), DBGrid1.Columns[i].FieldName+'|'+IntToStr(DBGrid1.Columns[i].Width));
        Inc(j, 1);
      end;
    end;
    for i := j to DBGrid1.Columns.Count-1 do
      Reg.WriteString('Coluna'+IntToStr(i), 'NAO_USAR|-1');
  except
  end;
  Reg.Free;
  Action := caFree;
end;

procedure TFrmGridProduto.FormShow(Sender: TObject);
var
  Reg: TRegistry;
  Maximizado: boolean;
  Altura, Largura, Topo, Esquerda, i, LargCampo: smallint;
  Campo, CampoAux: string;
begin
   CDSCampos.Close;
   CDSCampos.CreateDataSet;
   for i := 0 to DBGrid1.Columns.Count-1 do
   begin
     CDSCampos.Append;
     CDSCamposCOLUNA.Value := i;
     CDSCamposCAMPO.Value := DBGrid1.Columns[i].FieldName;
     CDSCamposEXIBIR.Value := 'N';
     CDSCampos.Post;
   end;
  // -------------Posicionamento da Tela------------------
  // Apenas zero as variaveis
  Maximizado := False;
  Altura := 0;
  Largura := 0;
  Topo := 0;
  Esquerda := 0;
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.OpenKey('SOFTWARE\PORTAL.COM\' + ExtractFileName(Application.ExeName) + '\GridProduto', True);
  try
    Maximizado := Reg.ReadBool('Maximizado');
    Altura := Reg.ReadInteger('Altura');
    Largura := Reg.ReadInteger('Largura');
    Topo := Reg.ReadInteger('Topo');
    Esquerda := Reg.ReadInteger('Esquerda');
    for i := 0 to DBGrid1.Columns.Count-1 do
    begin
      if Reg.ValueExists('Coluna'+IntToStr(i)) then
      begin
        CampoAux := Reg.ReadString('Coluna'+IntToStr(i));
        Campo := Copy(CampoAux, 1, Pos('|',CampoAux)-1);
        LargCampo := StrToInt(Copy(CampoAux, Pos('|',CampoAux)+1, 5));
        if CDSCampos.Locate('CAMPO', Campo, []) then
        begin
          CDSCampos.Edit;
          CDSCamposCOLUNA.Value := i;
          CDSCamposLARGURA.Value := LargCampo;
          CDSCamposEXIBIR.Value := IfThen(LargCampo > 0, 'S', 'N');
          CDSCampos.Post;
        end;
      end;
    end;
  except
  end;
  Reg.Free;
  if Largura > 0 then
  begin
    if Maximizado then
    begin
      WindowState := wsMaximized;
    end else
    begin
      Left := Esquerda;
      Top := Topo;
      Width := Largura;
      Height := Altura;
    end;
    if CDSCampos.Locate('EXIBIR', 'S', []) then
    begin
      for i := 0 to DBGrid1.Columns.Count-1 do
        DBGrid1.Columns[i].Visible := False;
      CDSCampos.First;
      while not CDSCampos.Eof do
      begin
        if CDSCamposEXIBIR.AsString = 'S' then
        begin
          DBGrid1.Columns[CDSCamposCOLUNA.AsInteger].FieldName := CDSCamposCAMPO.AsString;
          DBGrid1.Columns[CDSCamposCOLUNA.AsInteger].Visible := True;
          DBGrid1.Columns[CDSCamposCOLUNA.AsInteger].Width := CDSCamposLARGURA.AsInteger;
        end;
        CDSCampos.Next;
      end;
    end;
  end;
  Edt.SetFocus;
  // usado para buscar o ultimo filtro de busca utilizado
  SetaFiltroBusca;
  Timer1Timer(Sender);
end;

procedure TFrmGridProduto.ImgFotoClick(Sender: TObject);
begin
  if FrmAmpliaFoto = nil then
    FrmAmpliaFoto := TFrmAmpliaFoto.Create(nil);
  FrmAmpliaFoto.Image1.Picture.Graphic := ImgFoto.Picture.Graphic;
  FrmAmpliaFoto.ShowModal;
end;

procedure TFrmGridProduto.RadioGroup1Click(Sender: TObject);
begin
	Edt.SetFocus;
  Edt.SelectAll;
end;

procedure TFrmGridProduto.EdtKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  NumLinhas: Integer;
begin
  if (Key = 38) then
  begin
    Key := 0;
    if (not DBGrid1.DataSource.DataSet.Bof) then
    begin
      DBGrid1.DataSource.DataSet.Prior;
    end;
  end;
  if (Key = 40) then
  begin
    Key := 0;
    if (not DBGrid1.DataSource.DataSet.Eof) then
    begin
      DBGrid1.DataSource.DataSet.Next;
    end;
  end;
  if Key = 33 then // Page UP
  begin
    // Conta quantas linhas estão sendo exibidas no grid
    NumLinhas := TStringGrid(DBGrid1).RowCount;
    // Pula o numero de linhas exibidas menos dois acima
    IBQRGrid.MoveBy(-(NumLinhas - 2));
  end;
  if Key = 34 then // Page Down
  begin
    // Conta quantas linhas estão sendo exibidas no grid
    NumLinhas := TStringGrid(DBGrid1).RowCount;
    // Pula o numero de linhas exibidas menos dois abaixo
    IBQRGrid.MoveBy(NumLinhas - 2);
  end;
end;

procedure TFrmGridProduto.DBGrid1CellClick(Column: TColumn);
var
  Url: string;
begin
	// Foto
  Url := IBQRGridPRO_URL_IMAGEM.AsString;
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

procedure TFrmGridProduto.DBGrid1DblClick(Sender: TObject);
begin
  // mudando as opcoes do dbgrid
  DBGrid1.Options := DBGrid1.Options - [dgRowSelect] + [dgEditing];
end;

procedure TFrmGridProduto.DBGrid1DrawColumnCell(Sender: TObject; const [Ref] Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
	if Column.FieldName = 'ICONE' then
	begin
		DBGrid1.Canvas.FillRect(Rect);
		if IBQRGridPRO_URL_IMAGEM.AsString.IsEmpty then
			DBGrid1.Canvas.Draw(Rect.Left + Round((Column.Width - Image2.Picture.Width) / 2), Rect.Top + 1, Image2.Picture.Graphic)
		else
			DBGrid1.Canvas.Draw(Rect.Left + Round((Column.Width - Image1.Picture.Width) / 2), Rect.Top + 1, Image1.Picture.Graphic);
	end else	
	  GridPadrao(DSGrid.DataSet.RecNo, DBGrid1, Rect, Column, State);
end;

procedure TFrmGridProduto.DBGrid2CellClick(Column: TColumn);
begin
  CDSCampos.Edit;
  if CDSCamposEXIBIR.AsString = 'S' then
    CDSCamposEXIBIR.Value := 'N'
  else
    CDSCamposEXIBIR.Value := 'S';
  CDSCampos.Post;
end;

procedure TFrmGridProduto.DBGrid2DrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if CDSCamposEXIBIR.AsString = 'S' then
    Dbgrid2.Canvas.Brush.Color:= $006FFFB7
  else
    Dbgrid2.Canvas.Brush.Color:= $005E5EFF;
  Dbgrid2.Canvas.Font.Color:= clBlack;
  DBGrid2.Canvas.FillRect(Rect);
  Dbgrid2.DefaultDrawDataCell(Rect, DBGrid2.Columns[datacol].Field, State);
end;

procedure TFrmGridProduto.EdtKeyPress(Sender: TObject; var Key: Char);
begin
//  if RadioGroup1.ItemIndex = 1 then
//  begin
//    if Key = #13 then
//    begin
//      Timer1Timer(Sender);
//    end;
//  end
//  else
//  begin
    Timer1.Enabled := False;
    Timer1.Enabled := True;
//  end;
end;

procedure TFrmGridProduto.Timer1Timer(Sender: TObject);
var
  Key: Char;
begin
  Timer1.Enabled := False;
  IBQRGrid.Close;
  IBQRGrid.Params.Clear;
  IBQRGrid.SQL.Clear;
  if FrmCadProdutos <> nil then
    IBQRGrid.SQL.Add(SQL2[RadioGroup1.ItemIndex])
  else
    IBQRGrid.SQL.Add(SQL[RadioGroup1.ItemIndex]);
  if RadioGroup2.ItemIndex = 0 then
    IBQRGrid.Params[0].Value := StringReplace(Edt.Text, '+', '%', [rfReplaceAll]) + '%'
  else
    IBQRGrid.Params[0].Value := '%' + StringReplace(Edt.Text, '+', '%', [rfReplaceAll]) + '%';
  IBQRGrid.Open;
//  // tratamento para codigo de barras no leitor
//  if RadioGroup1.ItemIndex = 1 then
//  begin
//    Key := #13;
//    FormKeyPress(Sender, Key);
//  end;
end;

procedure TFrmGridProduto.ActAlternarFiltroExecute(Sender: TObject);
begin
  if RadioGroup1.ItemIndex < 3 then
    RadioGroup1.ItemIndex := RadioGroup1.ItemIndex + 1
  else
    RadioGroup1.ItemIndex := 0;
end;

procedure TFrmGridProduto.ActCadastroExecute(Sender: TObject);
var
  ProdutoFocado: Integer;
begin
  if IBQRGrid.IsEmpty then
    Exit;
  if FrmCadProdutos = nil then
    FrmCadProdutos := TFrmCadProdutos.Create(nil);
  FrmCadProdutos.FormStyle := fsNormal;
  FrmCadProdutos.Visible := False;
  FrmCadProdutos.ShowModal;
  ProdutoFocado := IBQRGridCODIGO.AsInteger;
  Timer1Timer(Timer1);
  IBQRGrid.Locate('CODIGO', ProdutoFocado, []);
end;

procedure TFrmGridProduto.ActSairExecute(Sender: TObject);
begin
  if dgEditing in DBGrid1.Options then
  begin
    DBGrid1.Options := DBGrid1.Options + [dgRowSelect];
    Edt.SetFocus;
    Exit;
  end;
  DMPrincipal.CodigoPesquisado := -1;
  Modalresult := MrCancel;
end;

procedure TFrmGridProduto.ActSelecionarExecute(Sender: TObject);
begin
  DMPrincipal.CodigoPesquisado := IBQRGrid.Fields[0].AsInteger;
  Modalresult := mrOk;
end;

procedure TFrmGridProduto.BtnAplicarClick(Sender: TObject);
var i, j : smallint;
begin
    CDSCampos.First;
    i := 0;
    while not CDSCampos.Eof do
    begin
      if (CDSCamposEXIBIR.AsString = 'S') then
      begin
        DBGrid1.Columns[i].FieldName := CDSCamposCAMPO.AsString;
        DBGrid1.Columns[i].Width := CDSCamposLARGURA.AsInteger;
        DBGrid1.Columns[i].Visible := True;
        if (DBGrid1.Columns[i].Visible) and (DBGrid1.Columns[i].Width <= 0) then
          DBGrid1.Columns[i].Width := 100;
        Inc(i, 1);
      end;
      CDSCampos.Next;
    end;
    for J := i to DBGrid1.Columns.Count-1 do
      DBGrid1.Columns[j].Visible := False;
end;

procedure TFrmGridProduto.ComboGrupoChange(Sender: TObject);
begin
  Timer1.Enabled := False;
  Timer1.Enabled := True;
end;

procedure TFrmGridProduto.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
  begin
    BtnSelecionar.Click;
  end;
end;

procedure TFrmGridProduto.FormDestroy(Sender: TObject);
begin
  FrmGridProduto := nil;
end;

procedure TFrmGridProduto.SetaFiltroBusca;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  Reg.OpenKey('SOFTWARE\PORTAL.COM\' + ExtractFileName(Application.ExeName), True);
  try
    RadioGroup1.ItemIndex := Reg.ReadInteger('FiltroBuscaProduto');
    RadioGroup2.ItemIndex := Reg.ReadInteger('TipoBuscaProduto');
  Except
    RadioGroup1.ItemIndex := 0;
  end;
  Reg.Free;
end;

end.
