unit UnitPesquisa;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Grids, DBGrids, ExtCtrls, Buttons, Db, IBCustomDataSet,
  IBStoredProc, IBQuery, DateUtils, System.Actions, Vcl.ActnList, Vcl.ComCtrls, Vcl.ToolWin;

type
  TFrmPesquisa = class(TForm)
    DBGrid1: TDBGrid;
    DSPesquisa: TDataSource;
    IBQRPesquisa: TIBQuery;
    Timer1: TTimer;
    ToolBar2: TToolBar;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    ActionList1: TActionList;
    actNovaPesquisa: TAction;
    actSair: TAction;
    actAlternarIndice: TAction;
    Panel1: TPanel;
    Label22: TLabel;
    Label2: TLabel;
    EditLocalizar: TEdit;
    ComboBox1: TComboBox;
    procedure FormShow(Sender: TObject);
    procedure EditLocalizarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure EditLocalizarKeyPress(Sender: TObject; var Key: Char);
    procedure ComboBox1Change(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure actSairExecute(Sender: TObject);
    procedure actAlternarIndiceExecute(Sender: TObject);
    procedure actNovaPesquisaExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Pesquisa: string;
  end;

var
  FrmPesquisa: TFrmPesquisa;

implementation

uses UnitFuncoesUtils, UnitDMPrincipal;

{$R *.DFM}

procedure TFrmPesquisa.FormShow(Sender: TObject);
begin
  IBQRPesquisa.Close;
  if Pesquisa = 'Produto' then
    ComboBox1.ItemIndex := 0
  else
    ComboBox1.ItemIndex := 1;

  FrmPesquisa.EditLocalizar.SetFocus;
  FrmPesquisa.EditLocalizar.Text := '';
end;

procedure TFrmPesquisa.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  GridPadrao(DSPesquisa.DataSet.RecNo, DBGrid1, Rect, Column, State);
end;

procedure TFrmPesquisa.EditLocalizarKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (DBGrid1.DataSource = DSPesquisa) then
  begin
    if (Key = 38) then
    begin
      if (not IBQRPesquisa.BOF) then
      begin
        IBQRPesquisa.Prior;
      end;
    end;
    if (Key = 40) then
    begin
      if (not IBQRPesquisa.EOF) then
      begin
        IBQRPesquisa.Next;
      end;
    end;
  end;
end;

procedure TFrmPesquisa.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  DSPesquisa.Enabled := True;
  if Pesquisa = 'Cliente' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT CLI_CODIGO AS CODIGO, CLI_NOME AS NOME FROM CLIENTES WHERE CLI_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY CLI_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT CLI_CODIGO AS CODIGO, CLI_NOME AS NOME FROM CLIENTES WHERE CLI_NOME LIKE ''' + EditLocalizar.Text + '%'' ORDER BY CLI_NOME');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'Fornecedor' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT FOR_CODIGO AS CODIGO, FOR_NOME AS CODIGO FROM FORNECEDORES WHERE FOR_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY FOR_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT FOR_CODIGO AS CODIGO, FOR_NOME AS NOME FROM FORNECEDORES WHERE FOR_NOME LIKE ''' + EditLocalizar.Text + '%'' ORDER BY FOR_NOME');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'Funcionario' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT FUN_CODIGO AS CODIGO, FUN_NOME AS NOME FROM FUNCIONARIOS WHERE FUN_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY FUN_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT FUN_CODIGO AS CODIGO, FUN_NOME AS NOME FROM FUNCIONARIOS WHERE FUN_NOME LIKE ''' + EditLocalizar.Text + '%'' ORDER BY FUN_NOME');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'Usuario' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT U.USU_CODIGO AS CODIGO, F.FUN_NOME AS NOME, U.USU_LOGIN AS LOGIN FROM USUARIOS U, FUNCIONARIOS F WHERE F.FUN_CODIGO = U.USU_FUN AND F.FUN_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY F.FUN_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT U.USU_CODIGO AS CODIGO, F.FUN_NOME AS NOME, U.USU_LOGIN AS LOGIN FROM USUARIOS U, FUNCIONARIOS F WHERE F.FUN_CODIGO = U.USU_FUN AND F.FUN_NOME LIKE ''' + EditLocalizar.Text + '%'' ORDER BY F.FUN_NOME');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'Grupo' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT G1_CODIGO AS CODIGO, G1_NOME AS NOME FROM GRUPO_1 WHERE G1_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY G1_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT G1_CODIGO AS CODIGO, G1_NOME AS NOME FROM GRUPO_1 WHERE G1_NOME LIKE ''' + EditLocalizar.Text + '%'' ORDER BY G1_NOME');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'SubGrupo' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT GRU_CODIGO AS CODIGO, GRU_NOME AS NOME FROM GRUPOS WHERE GRU_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY GRU_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT GRU_CODIGO AS CODIGO, GRU_NOME AS NOME FROM GRUPOS WHERE GRU_NOME LIKE ''' + EditLocalizar.Text + '%'' ORDER BY GRU_NOME');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'Produto' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT P.PRO_CODIGO AS CODIGO, P.PRO_DESCRICAO "COD. FABRICANTE", E.EST_NOME AS NOME, E.EST_CODIGO AS COD FROM ESTOQUE E, PRODUTOS P WHERE E.EST_CODIGO = P.PRO_EST AND P.PRO_DESCRICAO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY P.PRO_DESCRICAO');
      IBQRPesquisa.Open;

    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT P.PRO_CODIGO AS CODIGO, E.EST_NOME AS NOME, P.PRO_DESCRICAO "COD. FABRICANTE", E.EST_CODIGO AS COD FROM ESTOQUE E, PRODUTOS P WHERE P.PRO_EST = E.EST_CODIGO AND EST_NOME LIKE ''' + EditLocalizar.Text + '%'' ORDER BY EST_NOME');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'Tipo' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT TIP_CODIGO AS CODIGO, TIP_DESCRICAO AS DESCRICAO FROM TIPO WHERE TIP_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY TIP_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT TIP_CODIGO AS CODIGO, TIP_DESCRICAO AS DESCRICAO FROM TIPO WHERE TIP_DESCRICAO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY TIP_DESCRICAO');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'MaqImp' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT M.MI_CODIGO AS CODIGO, M.MI_DESCRICAO AS DESCRICAO, T.TIP_DESCRICAO AS TIPO FROM MAQ_IMP M, TIPO T WHERE M.MI_TIP = T.TIP_CODIGO AND MI_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY MI_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT M.MI_CODIGO AS CODIGO, M.MI_DESCRICAO AS DESCRICAO, T.TIP_DESCRICAO AS TIPO FROM MAQ_IMP M, TIPO T WHERE M.MI_TIP = T.TIP_CODIGO AND MI_DESCRICAO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY MI_DESCRICAO');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'NCM_IBPT' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT NI_CODIGO CODIGO, NI_NCM NCM, NI_EXCECAO EXCECAO, NI_TABELA TABELA, NI_DESCRICAO DESCRICAO FROM NCM_IBPT WHERE NI_NCM LIKE ''' + EditLocalizar.Text + '%'' ORDER BY NI_NCM');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT NI_CODIGO CODIGO, NI_NCM NCM, NI_EXCECAO EXCECAO, NI_TABELA TABELA, NI_DESCRICAO DESCRICAO FROM NCM_IBPT WHERE ((NI_NCM LIKE ''' + EditLocalizar.Text + '%'') OR (NI_DESCRICAO LIKE ''' + EditLocalizar.Text + '%'')) ORDER BY NI_DESCRICAO');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'Cidade' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT CID_CODIGO CODIGO, CID_NOME NOME FROM CIDADES WHERE CID_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY CID_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT CID_CODIGO CODIGO, CID_NOME NOME FROM CIDADES WHERE CID_NOME LIKE ''%' + EditLocalizar.Text + '%'' ORDER BY CID_NOME');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'AdminEstrategica' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT AE_CODIGO CODIGO, AE_DATA DATA, CAST(AE_MISSAO AS VARCHAR(4096)) AS MISSAO FROM ADMINISTRACAO_ESTRATEGICA WHERE AE_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY AE_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT AE_CODIGO CODIGO, AE_DATA DATA, CAST(AE_MISSAO AS VARCHAR(4096)) AS MISSAO FROM ADMINISTRACAO_ESTRATEGICA WHERE AE_MISSAO LIKE ''%' + EditLocalizar.Text + '%'' ORDER BY AE_MISSAO');
      IBQRPesquisa.Open;
    end;
  end
  else if Pesquisa = 'Promocoes' then
  begin
    if ComboBox1.ItemIndex = 0 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT PRO_CODIGO CODIGO, PRO_DATA DATA, PRO_DESCRICAO AS DESCRICAO, PRO_RESULTADO RESULTADO FROM PROMOCOES_ASSOCIACAO WHERE PRO_CODIGO LIKE ''' + EditLocalizar.Text + '%'' ORDER BY PRO_CODIGO');
      IBQRPesquisa.Open;
    end
    else if ComboBox1.ItemIndex = 1 then
    begin
      IBQRPesquisa.Close;
      IBQRPesquisa.SQL.Clear;
      IBQRPesquisa.SQL.Add('SELECT PRO_CODIGO CODIGO, PRO_DATA DATA, PRO_DESCRICAO AS DESCRICAO, PRO_RESULTADO RESULTADO FROM PROMOCOES_ASSOCIACAO WHERE PRO_DESCRICAO LIKE ''%' + EditLocalizar.Text + '%'' ORDER BY PRO_DESCRICAO');
      IBQRPesquisa.Open;
    end;
  end;
end;

procedure TFrmPesquisa.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = vk_f2 then
    actAlternarIndice.Execute;
  if Key = vk_F1 then
    actNovaPesquisa.Execute;
end;

procedure TFrmPesquisa.FormKeyPress(Sender: TObject; var Key: Char);
var
  Dias: Integer;
begin
  if Key = #27 then
    actSair.Execute;
  if Key = #13 then
  begin
    if IBQRPesquisa.Fields[0].IsNull then
    begin
      showmessage('Registro Não encontrado!');
      EditLocalizar.SetFocus;
    end
    else
    begin
      DMPrincipal.CodigoPesquisado := IBQRPesquisa.Fields[0].AsInteger;
      Modalresult := mrOk;
    end;
    DSPesquisa.Enabled := False;
  end;
end;

procedure TFrmPesquisa.EditLocalizarKeyPress(Sender: TObject; var Key: Char);
begin
  Timer1.Enabled := False;
  Timer1.Enabled := True;
end;

procedure TFrmPesquisa.actAlternarIndiceExecute(Sender: TObject);
begin
  if ComboBox1.ItemIndex = 0 then
    ComboBox1.ItemIndex := 1
  else
    ComboBox1.ItemIndex := 0;
  EditLocalizar.SetFocus;
end;

procedure TFrmPesquisa.actNovaPesquisaExecute(Sender: TObject);
begin
  EditLocalizar.SetFocus;
end;

procedure TFrmPesquisa.actSairExecute(Sender: TObject);
begin
  Modalresult := MrCancel;
end;

procedure TFrmPesquisa.ComboBox1Change(Sender: TObject);
begin
  EditLocalizar.SetFocus;
end;

end.
