unit UnitGridCliente;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, DBGrids, StdCtrls, db, IBCustomDataSet, IBQuery, ExtCtrls, DBCtrls,
  Mask, Vcl.ComCtrls, Vcl.ToolWin, System.Actions, Vcl.ActnList;

type
  TFrmGridCliente = class(TForm)
    DBGrid1: TDBGrid;
    Timer1: TTimer;
    DSGrid: TDataSource;
    IBQRGrid: TIBQuery;
    Label2: TLabel;
    Label3: TLabel;
    DBText2: TDBText;
    DBText3: TDBText;
    RadioGroup1: TRadioGroup;
    Label4: TLabel;
    DBText4: TDBText;
    EDT: TMaskEdit;
    IBQRGridCODIGO: TIntegerField;
    IBQRGridNOME: TIBStringField;
    IBQRGridCPF_CNPJ: TIBStringField;
    IBQRGridRG: TIBStringField;
    IBQRGridENDERECO: TIBStringField;
    IBQRGridCLI_SITUACAO: TIBStringField;
    IBQRGridCLI_PLANO: TSmallintField;
    IBQRGridCLI_NOTA: TIBStringField;
    IBQRGridCELULAR: TIBStringField;
    IBQRGridFONE: TIBStringField;
    panel3: TPanel;
    Panel1: TPanel;
    ActionList1: TActionList;
    actSelecionarCliente: TAction;
    actSair: TAction;
    actAlternarFiltro: TAction;
    ToolBar2: TToolBar;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton6: TToolButton;
    ToolButton7: TToolButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure EdtKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure EdtKeyPress(Sender: TObject; var Key: Char);
    procedure Timer1Timer(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure RadioGroup1Click(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormDestroy(Sender: TObject);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure actSelecionarClienteExecute(Sender: TObject);
    procedure actSairExecute(Sender: TObject);
    procedure actAlternarFiltroExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmGridCliente: TFrmGridCliente;

implementation

uses UnitDMPrincipal, UnitFuncoes;
{$R *.DFM}

const
  SQL1: string = 'SELECT CLI_CODIGO AS CODIGO, CLI_NOME AS NOME, CLI_CNPJ_CPF AS CPF_CNPJ, CLI_RG AS RG, CLI_FONE AS FONE, CLI_CELULAR AS CELULAR, CLI_ENDERECO AS ENDERECO, CLI_SITUACAO, CLI_PLANO, CLI_NOTA FROM CLIENTES ';

const
  SQL2: array [0 .. 5] of string = ('WHERE CLI_CODIGO LIKE :CODIGO ORDER BY CLI_CODIGO', 'WHERE CLI_NOME LIKE :NOME ORDER BY NOME', 'WHERE CLI_CNPJ_CPF LIKE :CPF ORDER BY CLI_CNPJ_CPF', 'WHERE CLI_RG LIKE :RG ORDER BY CLI_RG', 'WHERE CLI_FONE LIKE :FONE ORDER BY CLI_FONE',
    'WHERE CLI_CELULAR LIKE :CEL ORDER BY CLI_CELULAR');

procedure TFrmGridCliente.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmGridCliente.FormShow(Sender: TObject);
begin
  Timer1Timer(Sender);
  EDT.SetFocus;
end;

procedure TFrmGridCliente.EdtKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
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

procedure TFrmGridCliente.DBGrid1DblClick(Sender: TObject);
begin
  DMPrincipal.CodigoPesquisado := IBQRGrid.Fields[0].AsInteger;
  ModalResult := mrOK;
end;

procedure TFrmGridCliente.EdtKeyPress(Sender: TObject; var Key: Char);
begin
  Timer1.Enabled := False;
  Timer1.Enabled := True;
end;

procedure TFrmGridCliente.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  IBQRGrid.Close;
  IBQRGrid.SQL.Clear;
  IBQRGrid.SQL.Add(SQL1 + SQL2[RadioGroup1.ItemIndex]);
  IBQRGrid.Params[0].Value := '%' + EDT.Text + '%';
  IBQRGrid.Open;
end;

procedure TFrmGridCliente.actAlternarFiltroExecute(Sender: TObject);
begin
  if RadioGroup1.ItemIndex < 5 then
    RadioGroup1.ItemIndex := RadioGroup1.ItemIndex + 1
  else
    RadioGroup1.ItemIndex := 0;
end;

procedure TFrmGridCliente.actSairExecute(Sender: TObject);
begin
  DMPrincipal.CodigoPesquisado := 0;
  ModalResult := MrCancel;
end;

procedure TFrmGridCliente.actSelecionarClienteExecute(Sender: TObject);
begin
  DMPrincipal.CodigoPesquisado := IBQRGrid.Fields[0].AsInteger;
  ModalResult := mrOK;
end;

procedure TFrmGridCliente.ComboBox1Change(Sender: TObject);
begin
  Timer1.Enabled := False;
  Timer1.Enabled := True;
end;

procedure TFrmGridCliente.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #13) then
    actSelecionarCliente.Execute;
  if (Key = #27) then
    actSair.Execute;
end;

procedure TFrmGridCliente.RadioGroup1Click(Sender: TObject);
begin
  { if RadioGroup1.ItemIndex = 3 then
    begin
    DBGrid1.Columns[1].FieldName := 'RG';
    DBText1.DataField := 'NOME';
    Label1.Caption := 'Nome';
    end else
    if RadioGroup1.ItemIndex = 4 then
    begin
    DBGrid1.Columns[1].FieldName := 'INSCE';
    DBText1.DataField := 'NOME';
    Label1.Caption := 'Nome';
    end else
    if RadioGroup1.ItemIndex = 5 then
    begin
    DBGrid1.Columns[1].FieldName := 'INSCM';
    DBText1.DataField := 'NOME';
    Label1.Caption := 'Nome';
    end else
    if RadioGroup1.ItemIndex = 6 then
    begin
    DBGrid1.Columns[1].FieldName := 'RAZAO';
    DBText1.DataField := 'NOME';
    Label1.Caption := 'Nome';
    end else
    begin
    DBGrid1.Columns[1].FieldName := 'NOME';
    DBText1.DataField := 'RAZAO';
    Label1.Caption := 'Raz�o Social';
    end; }
  EDT.SetFocus;
end;

procedure TFrmGridCliente.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = vk_f2 then
    actAlternarFiltro.Execute;
end;

procedure TFrmGridCliente.FormDestroy(Sender: TObject);
begin
  FrmGridCliente := nil;
end;

procedure TFrmGridCliente.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if IBQRGrid.FieldByName('CLI_SITUACAO').Value = 'Livre' then
  begin
    DBGrid1.Canvas.Brush.Color := $00C1FFFF;
    DBGrid1.Canvas.Font.Color := clBlack;
    DBGrid1.Canvas.FillRect(Rect);
  end
  else if IBQRGrid.FieldByName('CLI_SITUACAO').Value = 'Observação' then
  begin
    DBGrid1.Canvas.Brush.Color := $00BFFFBF;
    DBGrid1.Canvas.Font.Color := clBlack;
    DBGrid1.Canvas.FillRect(Rect);
  end
  else if IBQRGrid.FieldByName('CLI_SITUACAO').Value = 'Bloqueado' then
  begin
    DBGrid1.Canvas.Brush.Color := $00AAAAFF;
    DBGrid1.Canvas.Font.Color := clBlack;
    DBGrid1.Canvas.FillRect(Rect);
  end
  else if IBQRGrid.FieldByName('CLI_SITUACAO').Value = 'Cadastro' then
  begin
    DBGrid1.Canvas.Brush.Color := clwhite;
    DBGrid1.Canvas.Font.Color := clblack;
    DBGrid1.Canvas.FillRect(Rect);
  end
  else if IBQRGrid.FieldByName('CLI_SITUACAO').Value = 'Duplicata' then
  begin
    DBGrid1.Canvas.Brush.Color := clGray;
    DBGrid1.Canvas.Font.Color := clWhite;
    DBGrid1.Canvas.FillRect(Rect);
  end; // coloque aqui a cor desejada
  DBGrid1.DefaultDrawDataCell(Rect, DBGrid1.columns[DataCol].field, State);
  GridPadrao(DSGrid.DataSet.RecNo, DBGrid1, Rect, Column, State);
end;

end.
