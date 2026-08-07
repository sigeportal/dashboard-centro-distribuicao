unit UnitHisPro.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  FireDAC.Comp.Client;

type
  THisProController = class
    class procedure Router;
    class procedure GetHistorico(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure EnsureHisProTable;
    class procedure RegistrarMovimentacao(
      AProCodigo: Integer;
      AData: TDateTime;
      AOrigem, ADoc: string;
      AQtd, AValC, AValV, AValCM, AValOP, AValM: Double;
      ATipo: string;
      ATipo2: Integer;
      AQtdAnterior: Double
    );
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitHisPro.Model;

class procedure THisProController.EnsureHisProTable;
var
  LHisPro: THisPro;
begin
  try
    LHisPro := THisPro.Create(TDatabase.Connection);
    try
      LHisPro.CriaTabela;
    finally
      LHisPro.DisposeOf;
    end;
  except
    on E: Exception do
      Writeln('-> Erro ao verificar/criar tabela HIS_PRO: ' + E.Message);
  end;
end;

class procedure THisProController.RegistrarMovimentacao(
  AProCodigo: Integer;
  AData: TDateTime;
  AOrigem, ADoc: string;
  AQtd, AValC, AValV, AValCM, AValOP, AValM: Double;
  ATipo: string;
  ATipo2: Integer;
  AQtdAnterior: Double
);
var
  LHisPro: THisPro;
  LNewId: Integer;
begin
  EnsureHisProTable;
  try
    LNewId := GeraCodigo('HIS_PRO', 'HP_CODIGO');
    LHisPro := THisPro.Create(TDatabase.Connection);
    try
      LHisPro.codigo := LNewId;
      LHisPro.data := AData;
      LHisPro.pro := AProCodigo;
      LHisPro.origem := Copy(AOrigem, 1, 30);
      LHisPro.doc := Copy(ADoc, 1, 15);
      LHisPro.quantidade := AQtd;
      LHisPro.valorc := AValC;
      LHisPro.valorv := AValV;
      LHisPro.valorcm := AValCM;
      LHisPro.valorop := AValOP;
      LHisPro.valorm := AValM;
      LHisPro.tipo := Copy(ATipo, 1, 2);
      LHisPro.tipo2 := ATipo2;
      LHisPro.quantidadea := AQtdAnterior;

      LHisPro.SalvaNoBanco;
    finally
      LHisPro.DisposeOf;
    end;
  except
    on E: Exception do
      Writeln('-> Erro ao registrar histórico de estoque HIS_PRO: ' + E.Message);
  end;
end;

class procedure THisProController.GetHistorico(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LResponseObj, LMetaObj, LObj: TJSONObject;
  LDataArr: TJSONArray;
  QueryCount, QueryData, QueryTransf: iQuery;
  LPage, LLimit, LOffset, LTotalRecords, LTotalPages, LProCodigo, LTrId: Integer;
  LDoc, LOrigemStr, LTipoStr, LNomeOri, LNomeDest: string;
begin
  EnsureHisProTable;
  LDataArr := TJSONArray.Create;
  QueryCount := TDatabase.Query;
  QueryData := TDatabase.Query;
  try
    LProCodigo := StrToIntDef(Req.Query.Items['pro_codigo'], StrToIntDef(Req.Query.Items['pro'], StrToIntDef(Req.Params.Items['pro_codigo'], 0)));
    LPage := StrToIntDef(Req.Query.Items['page'], 1);
    if LPage < 1 then LPage := 1;

    LLimit := StrToIntDef(Req.Query.Items['limit'], 20);
    if LLimit < 1 then LLimit := 20;
    if LLimit > 200 then LLimit := 200;

    LOffset := (LPage - 1) * LLimit;

    if LProCodigo > 0 then
    begin
      QueryCount.Open(Format('SELECT COUNT(*) AS TOTAL FROM HIS_PRO WHERE HP_PRO = %d', [LProCodigo]));
      QueryData.Open(Format('SELECT FIRST %d SKIP %d HP_CODIGO, HP_DATA, HP_PRO, HP_ORIGEM, HP_DOC, HP_QUANTIDADE, HP_VALORC, HP_VALORV, HP_VALORCM, HP_VALOROP, HP_VALORM, HP_TIPO, HP_TIPO2, HP_QUANTIDADEA FROM HIS_PRO WHERE HP_PRO = %d ORDER BY HP_CODIGO DESC', [LLimit, LOffset, LProCodigo]));
    end
    else
    begin
      QueryCount.Open('SELECT COUNT(*) AS TOTAL FROM HIS_PRO');
      QueryData.Open(Format('SELECT FIRST %d SKIP %d HP_CODIGO, HP_DATA, HP_PRO, HP_ORIGEM, HP_DOC, HP_QUANTIDADE, HP_VALORC, HP_VALORV, HP_VALORCM, HP_VALOROP, HP_VALORM, HP_TIPO, HP_TIPO2, HP_QUANTIDADEA FROM HIS_PRO ORDER BY HP_CODIGO DESC', [LLimit, LOffset]));
    end;

    LTotalRecords := QueryCount.Dataset.FieldByName('TOTAL').AsInteger;
    if LLimit > 0 then
      LTotalPages := (LTotalRecords + LLimit - 1) div LLimit
    else
      LTotalPages := 1;

    QueryData.Dataset.First;
    while not QueryData.Dataset.Eof do
    begin
      LObj := TJSONObject.Create;
      LDoc := QueryData.Dataset.FieldByName('HP_DOC').AsString;
      LOrigemStr := QueryData.Dataset.FieldByName('HP_ORIGEM').AsString;
      LTipoStr := QueryData.Dataset.FieldByName('HP_TIPO').AsString;

      LTrId := StrToIntDef(LDoc, 0);
      if (LTrId > 0) and ((SameText(LTipoStr, 'T')) or (LOrigemStr.Contains('TRANSFERENCIA')) or (LOrigemStr.Contains('TRANSF'))) then
      begin
        try
          QueryTransf := TDatabase.Query;
          QueryTransf.Open(Format(
            'SELECT T.TR_ORIGEM, T.TR_DESTINO, ' +
            '       E_ORI.EMP_FANTASIA AS ORI_FANTASIA, E_ORI.EMP_RAZAO_SOCIAL AS ORI_RAZAO, ' +
            '       E_DEST.EMP_FANTASIA AS DEST_FANTASIA, E_DEST.EMP_RAZAO_SOCIAL AS DEST_RAZAO ' +
            'FROM TRANSFERENCIA T ' +
            'LEFT JOIN EMPRESA E_ORI ON (T.TR_ORIGEM = E_ORI.EMP_CODIGO) ' +
            'LEFT JOIN EMPRESA E_DEST ON (T.TR_DESTINO = E_DEST.EMP_CODIGO) ' +
            'WHERE T.TR_ID = %d', [LTrId]));
          if not QueryTransf.DataSet.Eof then
          begin
            LNomeOri := QueryTransf.DataSet.FieldByName('ORI_FANTASIA').AsString;
            if LNomeOri.IsEmpty then LNomeOri := QueryTransf.DataSet.FieldByName('ORI_RAZAO').AsString;
            if LNomeOri.IsEmpty then LNomeOri := 'UNIDADE #' + IntToStr(QueryTransf.DataSet.FieldByName('TR_ORIGEM').AsInteger);

            LNomeDest := QueryTransf.DataSet.FieldByName('DEST_FANTASIA').AsString;
            if LNomeDest.IsEmpty then LNomeDest := QueryTransf.DataSet.FieldByName('DEST_RAZAO').AsString;
            if LNomeDest.IsEmpty then LNomeDest := 'UNIDADE #' + IntToStr(QueryTransf.DataSet.FieldByName('TR_DESTINO').AsInteger);

            LOrigemStr := 'TRANSF: ' + LNomeOri + ' -> ' + LNomeDest;
            LObj.AddPair('unidade_origem', LNomeOri);
            LObj.AddPair('unidade_destino', LNomeDest);
          end;
        except
        end;
      end;

      LObj.AddPair('hp_codigo', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_CODIGO').AsInteger));
      LObj.AddPair('hp_data', FormatDateTime('yyyy-mm-dd', QueryData.Dataset.FieldByName('HP_DATA').AsDateTime));
      LObj.AddPair('hp_pro', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_PRO').AsInteger));
      LObj.AddPair('hp_origem', LOrigemStr);
      LObj.AddPair('hp_doc', LDoc);
      LObj.AddPair('hp_quantidade', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_QUANTIDADE').AsFloat));
      LObj.AddPair('hp_valorc', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_VALORC').AsFloat));
      LObj.AddPair('hp_valorv', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_VALORV').AsFloat));
      LObj.AddPair('hp_valorcm', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_VALORCM').AsFloat));
      LObj.AddPair('hp_valorop', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_VALOROP').AsFloat));
      LObj.AddPair('hp_valorm', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_VALORM').AsFloat));
      LObj.AddPair('hp_tipo', LTipoStr);
      LObj.AddPair('hp_tipo2', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_TIPO2').AsInteger));
      LObj.AddPair('hp_quantidadea', TJSONNumber.Create(QueryData.Dataset.FieldByName('HP_QUANTIDADEA').AsFloat));

      LDataArr.AddElement(LObj);
      QueryData.Dataset.Next;
    end;

    LResponseObj := TJSONObject.Create;
    LMetaObj := TJSONObject.Create;

    LMetaObj.AddPair('page', TJSONNumber.Create(LPage));
    LMetaObj.AddPair('limit', TJSONNumber.Create(LLimit));
    LMetaObj.AddPair('total', TJSONNumber.Create(LTotalRecords));
    LMetaObj.AddPair('pages', TJSONNumber.Create(LTotalPages));

    LResponseObj.AddPair('data', LDataArr);
    LResponseObj.AddPair('meta', LMetaObj);

    Res.Send<TJSONObject>(LResponseObj);
  except
    on E: Exception do
    begin
      LResponseObj := TJSONObject.Create;
      LMetaObj := TJSONObject.Create;
      LMetaObj.AddPair('page', TJSONNumber.Create(1));
      LMetaObj.AddPair('limit', TJSONNumber.Create(20));
      LMetaObj.AddPair('total', TJSONNumber.Create(0));
      LMetaObj.AddPair('pages', TJSONNumber.Create(1));

      LResponseObj.AddPair('data', TJSONArray.Create);
      LResponseObj.AddPair('meta', LMetaObj);
      Res.Send<TJSONObject>(LResponseObj);
    end;
  end;
end;

class procedure THisProController.Router;
begin
  THorse.Group.Prefix('/v1')
    .Route('/historico-estoque')
      .Get(GetHistorico)
    .&End;

  THorse.Group.Prefix('/v1')
    .Route('/historico-estoque/:pro_codigo')
      .Get(GetHistorico)
    .&End;
end;

end.
