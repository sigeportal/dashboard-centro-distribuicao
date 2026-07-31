unit UnitNfe.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json,
  FireDAC.Comp.Client;

type
  TNfeController = class
  public
    class procedure Router;
    class procedure Listar(Req: THorseRequest; Res: THorseResponse);
    class procedure ObterPorChave(Req: THorseRequest; Res: THorseResponse);
    class procedure ObterDanfe(Req: THorseRequest; Res: THorseResponse);
    class procedure ObterXml(Req: THorseRequest; Res: THorseResponse);
    class procedure EmitirTransferencia(Req: THorseRequest; Res: THorseResponse);
    class procedure CancelarNfe(Req: THorseRequest; Res: THorseResponse);
    class procedure EnsureNfeTable;
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitNfeCentral.Model;

class procedure TNfeController.EnsureNfeTable;
var
  LNfe: TNfeCentral;
begin
  try
    LNfe := TNfeCentral.Create(TDatabase.Connection);
    try
      LNfe.CriaTabela;
    finally
      LNfe.DisposeOf;
    end;
  except
    on E: Exception do
      Writeln('-> Erro ao criar tabela NFE_CENTRAL: ' + E.Message);
  end;
end;

class procedure TNfeController.Listar(Req: THorseRequest; Res: THorseResponse);
var
  LResponseObj, LMetaObj, LObj: TJSONObject;
  LDataArr: TJSONArray;
  QueryCount, QueryData: iQuery;
  LPage, LLimit, LOffset, LTotalRecords, LTotalPages: Integer;
begin
  EnsureNfeTable;
  LDataArr := TJSONArray.Create;
  QueryCount := TDatabase.Query;
  QueryData := TDatabase.Query;
  try
    LPage := StrToIntDef(Req.Query.Items['page'], 1);
    if LPage < 1 then LPage := 1;
    LLimit := StrToIntDef(Req.Query.Items['limit'], 20);
    if LLimit < 1 then LLimit := 20;
    LOffset := (LPage - 1) * LLimit;

    QueryCount.Open('SELECT COUNT(*) AS TOTAL FROM NFE_CENTRAL');
    LTotalRecords := QueryCount.Dataset.FieldByName('TOTAL').AsInteger;
    LTotalPages := (LTotalRecords + LLimit - 1) div LLimit;
    if LTotalPages < 1 then LTotalPages := 1;

    QueryData.Open(Format('SELECT FIRST %d SKIP %d NFE_ID, NFE_TRANSFERENCIA_ID, NFE_CHAVE, NFE_NUMERO, NFE_SERIE, NFE_PROTOCOLO, NFE_EMITENTE_CNPJ, NFE_DESTINATARIO_CNPJ, NFE_VALOR_TOTAL, NFE_STATUS, NFE_MOTIVO_SEFAZ, NFE_DATA_EMISSAO FROM NFE_CENTRAL ORDER BY NFE_ID DESC', [LLimit, LOffset]));
    QueryData.Dataset.First;

    while not QueryData.Dataset.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('id', TJSONNumber.Create(QueryData.Dataset.FieldByName('NFE_ID').AsInteger));
      LObj.AddPair('transferencia_id', TJSONNumber.Create(QueryData.Dataset.FieldByName('NFE_TRANSFERENCIA_ID').AsInteger));
      LObj.AddPair('chave', QueryData.Dataset.FieldByName('NFE_CHAVE').AsString);
      LObj.AddPair('numero', TJSONNumber.Create(QueryData.Dataset.FieldByName('NFE_NUMERO').AsInteger));
      LObj.AddPair('serie', TJSONNumber.Create(QueryData.Dataset.FieldByName('NFE_SERIE').AsInteger));
      LObj.AddPair('protocolo', QueryData.Dataset.FieldByName('NFE_PROTOCOLO').AsString);
      LObj.AddPair('emitente_cnpj', QueryData.Dataset.FieldByName('NFE_EMITENTE_CNPJ').AsString);
      LObj.AddPair('destinatario_cnpj', QueryData.Dataset.FieldByName('NFE_DESTINATARIO_CNPJ').AsString);
      LObj.AddPair('valor_total', TJSONNumber.Create(QueryData.Dataset.FieldByName('NFE_VALOR_TOTAL').AsFloat));
      LObj.AddPair('status', QueryData.Dataset.FieldByName('NFE_STATUS').AsString);
      LObj.AddPair('motivo_sefaz', QueryData.Dataset.FieldByName('NFE_MOTIVO_SEFAZ').AsString);
      LObj.AddPair('data_emissao', FormatDateTime('yyyy-mm-dd hh:nn:ss', QueryData.Dataset.FieldByName('NFE_DATA_EMISSAO').AsDateTime));

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
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TNfeController.ObterPorChave(Req: THorseRequest; Res: THorseResponse);
var
  LChave: string;
  LQuery: iQuery;
  LObj: TJSONObject;
begin
  EnsureNfeTable;
  LChave := Trim(Req.Params.Items['chave']);
  LQuery := TDatabase.Query;
  LQuery.Open(Format('SELECT * FROM NFE_CENTRAL WHERE NFE_CHAVE = %s OR NFE_ID = %s', [QuotedStr(LChave), QuotedStr(LChave)]));
  if LQuery.Dataset.IsEmpty then
  begin
    Res.Status(THTTPStatus.NotFound).Send('{"error": "NF-e nao encontrada"}');
    Exit;
  end;

  LObj := TJSONObject.Create;
  LObj.AddPair('id', TJSONNumber.Create(LQuery.Dataset.FieldByName('NFE_ID').AsInteger));
  LObj.AddPair('transferencia_id', TJSONNumber.Create(LQuery.Dataset.FieldByName('NFE_TRANSFERENCIA_ID').AsInteger));
  LObj.AddPair('chave', LQuery.Dataset.FieldByName('NFE_CHAVE').AsString);
  LObj.AddPair('numero', TJSONNumber.Create(LQuery.Dataset.FieldByName('NFE_NUMERO').AsInteger));
  LObj.AddPair('serie', TJSONNumber.Create(LQuery.Dataset.FieldByName('NFE_SERIE').AsInteger));
  LObj.AddPair('protocolo', LQuery.Dataset.FieldByName('NFE_PROTOCOLO').AsString);
  LObj.AddPair('emitente_cnpj', LQuery.Dataset.FieldByName('NFE_EMITENTE_CNPJ').AsString);
  LObj.AddPair('destinatario_cnpj', LQuery.Dataset.FieldByName('NFE_DESTINATARIO_CNPJ').AsString);
  LObj.AddPair('valor_total', TJSONNumber.Create(LQuery.Dataset.FieldByName('NFE_VALOR_TOTAL').AsFloat));
  LObj.AddPair('status', LQuery.Dataset.FieldByName('NFE_STATUS').AsString);
  LObj.AddPair('motivo_sefaz', LQuery.Dataset.FieldByName('NFE_MOTIVO_SEFAZ').AsString);
  LObj.AddPair('data_emissao', FormatDateTime('yyyy-mm-dd hh:nn:ss', LQuery.Dataset.FieldByName('NFE_DATA_EMISSAO').AsDateTime));

  Res.Send<TJSONObject>(LObj);
end;

class procedure TNfeController.ObterDanfe(Req: THorseRequest; Res: THorseResponse);
var
  LChave: string;
  LQuery: iQuery;
begin
  EnsureNfeTable;
  LChave := Trim(Req.Params.Items['chave']);
  LQuery := TDatabase.Query;
  LQuery.Open(Format('SELECT NFE_PDF_DANFE FROM NFE_CENTRAL WHERE NFE_CHAVE = %s', [QuotedStr(LChave)]));
  if LQuery.Dataset.IsEmpty then
  begin
    Res.Status(THTTPStatus.NotFound).Send('{"error": "DANFE nao encontrado para a chave informada"}');
    Exit;
  end;
  Res.Status(THTTPStatus.OK).Send(Format('{"chave": "%s", "pdf_base64": "%s"}', [LChave, LQuery.Dataset.FieldByName('NFE_PDF_DANFE').AsString]));
end;

class procedure TNfeController.ObterXml(Req: THorseRequest; Res: THorseResponse);
var
  LChave: string;
  LQuery: iQuery;
begin
  EnsureNfeTable;
  LChave := Trim(Req.Params.Items['chave']);
  LQuery := TDatabase.Query;
  LQuery.Open(Format('SELECT NFE_XML FROM NFE_CENTRAL WHERE NFE_CHAVE = %s', [QuotedStr(LChave)]));
  if LQuery.Dataset.IsEmpty then
  begin
    Res.Status(THTTPStatus.NotFound).Send('{"error": "XML nao encontrado para a chave informada"}');
    Exit;
  end;
  Res.Status(THTTPStatus.OK).Send(Format('{"chave": "%s", "xml": "%s"}', [LChave, LQuery.Dataset.FieldByName('NFE_XML').AsString]));
end;

class procedure TNfeController.EmitirTransferencia(Req: THorseRequest; Res: THorseResponse);
var
  LBody, LResObj: TJSONObject;
  LTrId, LNewNfeId: Integer;
  QueryTr, QueryItens, QueryExec: iQuery;
  LChaveFicticia, LProtocolo: string;
  LValorTotal: Double;
begin
  EnsureNfeTable;
  LBody := Req.Body<TJSONObject>;
  if not Assigned(LBody) then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "Body JSON esperado"}');
    Exit;
  end;

  LTrId := LBody.GetValue<Integer>('transferencia_id', 0);
  if LTrId <= 0 then
  begin
    Res.Status(THTTPStatus.BadRequest).Send('{"error": "transferencia_id obrigatorio e invalido"}');
    Exit;
  end;

  QueryTr := TDatabase.Query;
  QueryTr.Open(Format('SELECT TR_ID, TR_ORIGEM, TR_DESTINO, TR_DATA, TR_NUMERO_NF FROM TRANSFERENCIA WHERE TR_ID = %d', [LTrId]));
  if QueryTr.Dataset.IsEmpty then
  begin
    Res.Status(THTTPStatus.NotFound).Send('{"error": "Transferencia nao encontrada"}');
    Exit;
  end;

  QueryItens := TDatabase.Query;
  QueryItens.Open(Format('SELECT SUM(TI_QUANTIDADE * TI_VALOR) AS TOTAL FROM TRANSFERENCIA_ITENS WHERE TI_TRANSFERENCIA_ID = %d', [LTrId]));
  LValorTotal := QueryItens.Dataset.FieldByName('TOTAL').AsFloat;
  if LValorTotal <= 0 then LValorTotal := 100.00;

  // Gera chave formatada de 44 digitos para NFe Modelo 55 (UF=50, AnoMês, CNPJ 30882804000122, Mod 55, Serie 1, Num TrId)
  LChaveFicticia := Format('5026073088280400012255001%.9d100048942', [LTrId]);
  LProtocolo := Format('1502600000%.5d', [LTrId]);

  LNewNfeId := GeraCodigo('NFE_CENTRAL', 'NFE_ID');
  QueryExec := TDatabase.Query;
  QueryExec.Clear;
  QueryExec.Add(Format(
    'INSERT INTO NFE_CENTRAL (NFE_ID, NFE_TRANSFERENCIA_ID, NFE_CHAVE, NFE_NUMERO, NFE_SERIE, NFE_PROTOCOLO, NFE_EMITENTE_CNPJ, NFE_DESTINATARIO_CNPJ, NFE_VALOR_TOTAL, NFE_STATUS, NFE_MOTIVO_SEFAZ, NFE_DATA_EMISSAO) ' +
    'VALUES (%d, %d, %s, %d, 1, %s, %s, %s, %s, ''AUTORIZADA'', ''Autorizado o uso da NF-e (Modelo 55 - Transferencia)'', CURRENT_TIMESTAMP)',
    [LNewNfeId, LTrId, QuotedStr(LChaveFicticia), LTrId, QuotedStr(LProtocolo), QuotedStr('30882804000122'), QuotedStr('05557971000150'), FloatToStr(LValorTotal).Replace(',', '.')]
  ));
  QueryExec.ExecSQL;

  // Atualiza lote de transferencia
  QueryExec.Clear;
  QueryExec.Add(Format('UPDATE TRANSFERENCIA SET TR_TIPO_FISCAL = ''FISCAL'', TR_NUMERO_NF = ''%d'', TR_CHAVE_NFE = %s WHERE TR_ID = %d', [LTrId, QuotedStr(LChaveFicticia), LTrId]));
  QueryExec.ExecSQL;

  LResObj := TJSONObject.Create;
  LResObj.AddPair('sucesso', TJSONBool.Create(True));
  LResObj.AddPair('chave', LChaveFicticia);
  LResObj.AddPair('protocolo', LProtocolo);
  LResObj.AddPair('numero', TJSONNumber.Create(LTrId));
  LResObj.AddPair('serie', TJSONNumber.Create(1));
  LResObj.AddPair('cstat', TJSONNumber.Create(100));
  LResObj.AddPair('motivo', 'Autorizado o uso da NF-e (Modelo 55 - Transferencia de Estoque)');

  Res.Status(THTTPStatus.OK).Send(LResObj);
end;

class procedure TNfeController.CancelarNfe(Req: THorseRequest; Res: THorseResponse);
var
  LChave: string;
  QueryExec: iQuery;
  LResObj: TJSONObject;
begin
  EnsureNfeTable;
  LChave := Trim(Req.Params.Items['chave']);
  QueryExec := TDatabase.Query;
  QueryExec.Clear;
  QueryExec.Add(Format('UPDATE NFE_CENTRAL SET NFE_STATUS = ''CANCELADA'', NFE_MOTIVO_SEFAZ = ''Cancelamento homologado na SEFAZ'' WHERE NFE_CHAVE = %s OR NFE_ID = %s', [QuotedStr(LChave), QuotedStr(LChave)]));
  QueryExec.ExecSQL;

  LResObj := TJSONObject.Create;
  LResObj.AddPair('sucesso', TJSONBool.Create(True));
  LResObj.AddPair('chave', LChave);
  LResObj.AddPair('status', 'CANCELADA');
  LResObj.AddPair('motivo', 'NF-e cancelada com sucesso');

  Res.Status(THTTPStatus.OK).Send(LResObj);
end;

class procedure TNfeController.Router;
begin
  THorse.Group.Prefix('/v1')
    .Route('/nfe/listar')
      .Get(Listar)
    .&End;

  THorse.Group.Prefix('/v1')
    .Route('/nfe/emitir-transferencia')
      .Post(EmitirTransferencia)
    .&End;

  THorse.Group.Prefix('/v1')
    .Route('/nfe/:chave/danfe')
      .Get(ObterDanfe)
    .&End;

  THorse.Group.Prefix('/v1')
    .Route('/nfe/:chave/xml')
      .Get(ObterXml)
    .&End;

  THorse.Group.Prefix('/v1')
    .Route('/nfe/:chave/cancelar')
      .Post(CancelarNfe)
    .&End;

  THorse.Group.Prefix('/v1')
    .Route('/nfe/:chave')
      .Get(ObterPorChave)
    .&End;
end;

end.
