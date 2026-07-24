unit UnitConsultaCliente;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, DB, IBCustomDataSet, IBQuery, Grids, DBGrids, StdCtrls, DBCtrls, DateUtils,
  Menus, System.Actions, Vcl.ActnList, Vcl.ComCtrls, Vcl.ToolWin, Vcl.ExtCtrls;

type
  TFrmConsultaCliente = class(TForm)
    GroupBox3: TGroupBox;
    DBGrid2: TDBGrid;
    GroupBox1: TGroupBox;
    DBGrid1: TDBGrid;
    IBQRFaturada: TIBQuery;
    DSFaturada: TDataSource;
    IBQRFaturadaFAT_CODIGO: TIntegerField;
    IBQRFaturadaCLI_CODIGO: TIntegerField;
    IBQRFaturadaCLI_NOME: TIBStringField;
    IBQRFaturadaCLI_ENDERECO: TIBStringField;
    IBQRFaturadaCLI_PLANO: TSmallintField;
    IBQRFaturadaCLI_LIMITE: TIBBCDField;
    IBQRFaturadaCLI_SITUACAO: TIBStringField;
    IBQRFaturadaREC_CODIGO: TIntegerField;
    IBQRFaturadaREC_DUPLICATA: TIBStringField;
    IBQRFaturadaREC_VENCIMENTO: TDateField;
    IBQRFaturadaREC_JUROS: TIBBCDField;
    IBQRFaturadaREC_DESCONTOS: TIBBCDField;
    IBQRFaturadaREC_VALOR: TIBBCDField;
    IBQRFaturadaREC_TIPO: TIBStringField;
    IBQRFaturadaREC_CON: TSmallintField;
    IBQRFaturadaREC_DATAR: TDateField;
    IBQRFaturadaREC_FPG: TSmallintField;
    IBQRFaturadaREC_DESCONTADO: TIBStringField;
    IBQRFaturadaREC_OBS: TIBStringField;
    IBQRFaturadaSUM: TIBBCDField;
    Label1: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    IBQRFaturadaCLI_FIDELIDADE: TIBStringField;
    IBQRFaturadaCLI_INADIMPLENCIA: TSmallintField;
    IBQRFaturadaCLI_DESCONTO: TIBBCDField;
    DBText1: TDBText;
    DBText2: TDBText;
    DBText3: TDBText;
    DBText4: TDBText;
    DBText5: TDBText;
    DBText7: TDBText;
    DBText8: TDBText;
    DBText9: TDBText;
    DBText10: TDBText;
    DBText11: TDBText;
    DBText12: TDBText;
    IBQRFaturadaCLI_CNPJ_CPF: TIBStringField;
    IBQRNFaturada: TIBQuery;
    DSNFaturada: TDataSource;
    IBQRNFaturadaPF_CODIGO: TIntegerField;
    IBQRNFaturadaPF_DATA: TDateField;
    IBQRNFaturadaPF_CLIENTE: TIBStringField;
    IBQRNFaturadaPF_COD_CLI: TIntegerField;
    IBQRNFaturadaPF_FUN: TSmallintField;
    IBQRNFaturadaCLI_PLANO: TSmallintField;
    IBQRNFaturadaPF_FAT: TIntegerField;
    IBQRNFaturadaPF_PARCELAS: TSmallintField;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    IBQRFaturadaCLI_NOTA: TIBStringField;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    IBQRFaturadaFAT_DATA: TDateField;
    IBQRVen_Est: TIBQuery;
    IBQRVen_EstFAT_CODIGO: TIntegerField;
    IBQRVen_EstPRO_CODIGO: TIntegerField;
    IBQRVen_EstFAT_TIPOPGM: TSmallintField;
    IBQRVen_EstVEN_FUN: TSmallintField;
    IBQRVen_EstVEN_CLI: TIntegerField;
    IBQRVen_EstPRO_DESCRICAO: TIBStringField;
    IBQRVen_EstVEN_DATA: TDateField;
    IBQRVen_EstVEN_CODIGO: TIntegerField;
    IBQRVen_EstVE_VALOR: TIBBCDField;
    IBQRVen_EstVE_QUANTIDADE: TIBBCDField;
    IBQRVen_Est2: TIBQuery;
    IBQRVen_Est2PRO_CODIGO: TIntegerField;
    IBQRVen_Est2VEN_FUN: TSmallintField;
    IBQRVen_Est2VEN_CLI: TIntegerField;
    IBQRVen_Est2PRO_DESCRICAO: TIBStringField;
    IBQRVen_Est2VEN_DATA: TDateField;
    IBQRVen_Est2VEN_CODIGO: TIntegerField;
    IBQRVen_Est2VE_VALOR: TIBBCDField;
    IBQRVen_Est2VE_QUANTIDADE: TIBBCDField;
    IBQRVen_Est2PF_VALOR: TIBBCDField;
    IBQRVen_Est2PF_VALORPG: TIBBCDField;
    IBQRNFaturadaPP_JUROS: TIBBCDField;
    IBQRNFaturadaPP_DESCONTOS: TIBBCDField;
    IBQRNFaturadaPP_DUPLICATA: TIBStringField;
    IBQRNFaturadaPP_VENCIMENTO: TDateField;
    IBQRNFaturadaTP_DESCRICAO: TIBStringField;
    IBQRNFaturadaPP_VALOR: TIBBCDField;
    IBQRNFaturadaPP_VALORPG: TIBBCDField;
    IBQRFaturadaCLI_CELULAR: TIBStringField;
    IBQRFaturadaCLI_FONE: TIBStringField;
    PopupMenu1: TPopupMenu;
    Imprimir1: TMenuItem;
    Label30: TLabel;
    Label31: TLabel;
    IBQRFaturadaTP_NOME: TIBStringField;
    IBQRNFaturadaTP_NOME: TIBStringField;
    Label32: TLabel;
    Label33: TLabel;
    Label34: TLabel;
    Label35: TLabel;
    IBQRFaturadaVALOR_TOTAL: TCurrencyField;
    IBQRNFaturadaVALOR_TOTAL: TCurrencyField;
    ToolBar2: TToolBar;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton17: TToolButton;
    ToolButton18: TToolButton;
    ActionList1: TActionList;
    actSair: TAction;
    actPesquisa: TAction;
    ToolButton1: TToolButton;
    actImprimirProdutos: TAction;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    ToolButton2: TToolButton;
    Panel4: TPanel;
    Label21: TLabel;
    Label7: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    IBQRVen_EstPRO_NOME: TIBStringField;
    IBQRVen_EstVE_ESTADO: TIBStringField;
    IBQRVen_Est2PRO_NOME: TIBStringField;
    IBQRVen_Est2VE_ESTADO: TIBStringField;
    IBQRVen_EstVE_QTD_DEVOLVIDA: TIBBCDField;
    IBQRVen_Est2VE_QTD_DEVOLVIDA: TIBBCDField;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure IBQRFaturadaCalcFields(DataSet: TDataSet);
    procedure IBQRNFaturadaCalcFields(DataSet: TDataSet);
    procedure DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure DBGrid2DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure actSairExecute(Sender: TObject);
    procedure actPesquisaExecute(Sender: TObject);
    procedure actImprimirProdutosExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmConsultaCliente: TFrmConsultaCliente;
  F: TextFile;

implementation

uses UnitPrincipal, UnitDMPrincipal, UnitGridCliente, UnitQRListaProduto,
  UnitQRListaProduto2, UnitFuncoes, QRPrntr;

{$R *.dfm}

procedure TFrmConsultaCliente.actImprimirProdutosExecute(Sender: TObject);
begin
  if QReportListaProduto = nil then
    QReportListaProduto := TQReportListaProduto.Create(nil);
  if Application.MessageBox('Deseja imprimir itens com codigo?', 'Confirmar', MB_YesNo + MB_ICONQUESTION) = IDYes then
    QReportListaProduto.Tip_Codigo := 1
  else
    QReportListaProduto.Tip_Codigo := 2;
  QReportListaProduto.PrevInitialZoom := qrZoomToWidth;
  QReportListaProduto.PreviewInitialState := wsMaximized;
  QReportListaProduto.Prepare;
  QReportListaProduto.Preview;
end;

procedure TFrmConsultaCliente.actPesquisaExecute(Sender: TObject);
var
  SubTotalF, SubTotalN, ValorAtrsado, Juros, Cheque, ChequeN: currency;
  Dias: Integer;
begin
  FrmGridCliente := TFrmGridCliente.Create(nil);
  if (FrmGridCliente.ShowModal = mrOk) and (DMPrincipal.CodigoPesquisado > 0) then
  begin
    DMPrincipal.GridCliente.Close;
    DMPrincipal.GridCliente.Params[0].Value := DMPrincipal.CodigoPesquisado;
    DMPrincipal.GridCliente.Open;
  end;

  IBQRFaturada.Close;
  IBQRFaturada.Params[0].Value := DMPrincipal.GridClienteCLI_CODIGO.AsInteger;
  IBQRFaturada.Open;

  IBQRFaturada.First;
  SubTotalF := 0;
  ValorAtrsado := 0;
  Juros := 0;
  Cheque := 0;
  DMPrincipal.IBQRConfiguracao.Open;
  DMPrincipal.IBQRConfiguracao.Last;
  while not IBQRFaturada.Eof do
  begin
    if ((IBQRFaturadaREC_DATAR.Value) < Date) then
    begin
      Dias := Daysbetween(Date, IBQRFaturadaREC_DATAR.Value);
      Juros := Juros + ((IBQRFaturadaREC_VALOR.Value + IBQRFaturadaREC_JUROS.Value - IBQRFaturadaREC_DESCONTOS.Value) - IBQRFaturadaSUM.Value) * (((DMPrincipal.IBQRConfiguracaoCONF_JUROSM.Value / 100) / 30) * (Dias));
    end
    else
      Juros := Juros + IBQRFaturadaREC_JUROS.Value;
    if IBQRFaturadaREC_VENCIMENTO.Value < Date then
      ValorAtrsado := ValorAtrsado + (IBQRFaturadaREC_VALOR.AsCurrency + IBQRFaturadaREC_JUROS.AsCurrency - IBQRFaturadaREC_DESCONTOS.AsCurrency - IBQRFaturadaSUM.AsCurrency);
    SubTotalF := SubTotalF + (IBQRFaturadaREC_VALOR.AsCurrency + IBQRFaturadaREC_JUROS.AsCurrency - IBQRFaturadaREC_DESCONTOS.AsCurrency - IBQRFaturadaSUM.AsCurrency);
    if IBQRFaturadaTP_NOME.Value = 'CH' then
      Cheque := Cheque + IBQRFaturadaREC_VALOR.AsCurrency + IBQRFaturadaREC_JUROS.AsCurrency - IBQRFaturadaREC_DESCONTOS.AsCurrency;
    IBQRFaturada.Next;
  end;
  DMPrincipal.IBQRConfiguracao.Close;
  Label28.Caption := formatfloat('R$,0.00;-R$,0.00', SubTotalF);
  Label25.Caption := formatfloat('R$,0.00;-R$,0.00', Juros);
  Label31.Caption := formatfloat('R$,0.00;-R$,0.00', Cheque);
  Label17.Caption := formatfloat('R$,0.00;-R$,0.00', SubTotalF + Juros - Cheque);
  IBQRNFaturada.Close;
  IBQRNFaturada.Params[0].Value := DMPrincipal.GridClienteCLI_CODIGO.AsInteger;
  IBQRNFaturada.Open;

  IBQRNFaturada.First;
  SubTotalN := 0;
  ChequeN := 0;
  while not IBQRNFaturada.Eof do
  begin
    if IBQRNFaturadaPP_VENCIMENTO.Value < Date then
      ValorAtrsado := ValorAtrsado + (IBQRNFaturadaPP_VALOR.AsCurrency + IBQRNFaturadaPP_JUROS.AsCurrency - IBQRNFaturadaPP_DESCONTOS.AsCurrency - IBQRNFaturadaPP_VALORPG.AsCurrency);
    SubTotalN := SubTotalN + (IBQRNFaturadaPP_VALOR.AsCurrency + IBQRNFaturadaPP_JUROS.AsCurrency - IBQRNFaturadaPP_DESCONTOS.AsCurrency - IBQRNFaturadaPP_VALORPG.AsCurrency);
    if IBQRNFaturadaTP_NOME.Value = 'CH' then
      ChequeN := ChequeN + IBQRNFaturadaPP_VALOR.AsCurrency + IBQRNFaturadaPP_JUROS.AsCurrency - IBQRNFaturadaPP_DESCONTOS.AsCurrency;
    IBQRNFaturada.Next;
  end;
  Label35.Caption := formatfloat('R$,0.00;-R$,0.00', SubTotalN);
  Label33.Caption := formatfloat('R$,0.00;-R$,0.00', ChequeN);
  Label18.Caption := formatfloat('R$,0.00;-R$,0.00', SubTotalN - ChequeN);

  Label20.Caption := formatfloat('R$,0.00;-R$,0.00', SubTotalF + SubTotalN - ChequeN + Juros - Cheque);
  Label21.Caption := formatfloat('R$,0.00;-R$,0.00', ValorAtrsado);
  Label23.Caption := formatfloat('R$,0.00;-R$,0.00', (SubTotalF + SubTotalN) - ValorAtrsado);
end;

procedure TFrmConsultaCliente.actSairExecute(Sender: TObject);
begin
  if Application.MessageBox('Deseja sair da consulta?', 'Confirmar', MB_YesNo + MB_ICONQUESTION) = IDYes then
  begin
    Close;
  end;
end;

procedure TFrmConsultaCliente.DBGrid1DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  GridPadrao(DSFaturada.DataSet.RecNo, DBGrid1, Rect, Column, State);
end;

procedure TFrmConsultaCliente.DBGrid2DrawColumnCell(Sender: TObject; const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  GridPadrao(DSNFaturada.DataSet.RecNo, DBGrid2, Rect, Column, State);
end;

procedure TFrmConsultaCliente.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := cafree;
  FrmPrincipal.HabilitaMenu(True);
end;

procedure TFrmConsultaCliente.FormDestroy(Sender: TObject);
begin
  FrmConsultaCliente := nil;
end;

procedure TFrmConsultaCliente.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then
    actSair.Execute;
  if Key = vk_F5 then
    actImprimirProdutos.Execute;
  if Key = vk_F9 then
    actPesquisa.Execute;
end;

procedure TFrmConsultaCliente.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    if (Sender is TDBGrid) then
      TDBGrid(Sender).Perform(WM_KeyDown, VK_Tab, 0)
    else
      Perform(Wm_NextDlgCtl, 0, 0);
  end;

end;

procedure TFrmConsultaCliente.FormShow(Sender: TObject);
begin
  if DMPrincipal.IBTransPrincipal.Active = False then
    DMPrincipal.IBTransPrincipal.StartTransaction;
end;

procedure TFrmConsultaCliente.IBQRFaturadaCalcFields(DataSet: TDataSet);
begin
  IBQRFaturadaVALOR_TOTAL.Value := IBQRFaturadaREC_VALOR.AsCurrency + IBQRFaturadaREC_JUROS.AsCurrency - IBQRFaturadaREC_DESCONTOS.AsCurrency;
end;

procedure TFrmConsultaCliente.IBQRNFaturadaCalcFields(DataSet: TDataSet);
begin
  IBQRNFaturadaVALOR_TOTAL.Value := IBQRNFaturadaPP_VALOR.AsCurrency + IBQRNFaturadaPP_JUROS.AsCurrency - IBQRNFaturadaPP_DESCONTOS.AsCurrency;
end;

end.
