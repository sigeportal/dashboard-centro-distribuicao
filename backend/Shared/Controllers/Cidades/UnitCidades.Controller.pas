unit UnitCidades.Controller;

interface

uses
  Horse,
  Horse.Commons,
  System.Classes,
  System.SysUtils,
  System.JSON;

type
  TCidadesController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitCidades.Model,
  UnitTabela.Helpers;

{ TCidadesController }

class procedure TCidadesController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LArrJson: TJSONArray;
  LObj: TJSONObject;
  LQuery: iQuery;
  LSearch, LUF: string;
  LLimit: Integer;
begin
  LArrJson := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LSearch := Trim(Req.Query.Items['search']);
    if LSearch.IsEmpty then
      LSearch := Trim(Req.Query.Items['busca']);
    LUF := Trim(Req.Query.Items['uf']);
    LLimit := StrToIntDef(Req.Query.Items['limit'], 100);

    LQuery.Clear;
    LQuery.Add('SELECT FIRST ' + LLimit.ToString + ' C.CID_CODIGO, C.CID_NOME, C.CID_UF, C.CID_CODIGO_IBGE, C.CID_EST ');
    LQuery.Add('FROM CIDADES C WHERE 1=1 ');

    if not LUF.IsEmpty then
      LQuery.Add('AND UPPER(C.CID_UF) = ' + QuotedStr(UpperCase(LUF)) + ' ');

    if not LSearch.IsEmpty then
      LQuery.Add('AND (UPPER(C.CID_NOME) LIKE ' + QuotedStr('%' + UpperCase(LSearch) + '%') + ' OR CAST(C.CID_CODIGO AS VARCHAR(10)) = ' + QuotedStr(LSearch) + ') ');

    LQuery.Add('ORDER BY C.CID_UF, C.CID_NOME');
    LQuery.Open;

    LQuery.Dataset.First;
    while not LQuery.Dataset.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('codigo', TJSONNumber.Create(LQuery.Dataset.FieldByName('CID_CODIGO').AsInteger));
      LObj.AddPair('nome', LQuery.Dataset.FieldByName('CID_NOME').AsString);
      LObj.AddPair('uf', LQuery.Dataset.FieldByName('CID_UF').AsString);
      LObj.AddPair('codigo_ibge', TJSONNumber.Create(LQuery.Dataset.FieldByName('CID_CODIGO_IBGE').AsInteger));
      LObj.AddPair('est_codigo', TJSONNumber.Create(LQuery.Dataset.FieldByName('CID_EST').AsInteger));
      LArrJson.AddElement(LObj);
      LQuery.Dataset.Next;
    end;

    Res.Send<TJSONArray>(LArrJson);
  except
    on E: Exception do
    begin
      LArrJson.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TCidadesController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LObj: TJSONObject;
  LQuery: iQuery;
  LId: Integer;
begin
  LId := StrToIntDef(Req.Params.Items['id'], 0);
  LQuery := TDatabase.Query;
  try
    LQuery.Open('SELECT CID_CODIGO, CID_NOME, CID_UF, CID_CODIGO_IBGE, CID_EST FROM CIDADES WHERE CID_CODIGO = ' + LId.ToString);
    if LQuery.Dataset.IsEmpty then
    begin
      Res.Status(THTTPStatus.NotFound).Send('{"error": "Cidade nao encontrada"}');
      Exit;
    end;

    LObj := TJSONObject.Create;
    LObj.AddPair('codigo', TJSONNumber.Create(LQuery.Dataset.FieldByName('CID_CODIGO').AsInteger));
    LObj.AddPair('nome', LQuery.Dataset.FieldByName('CID_NOME').AsString);
    LObj.AddPair('uf', LQuery.Dataset.FieldByName('CID_UF').AsString);
    LObj.AddPair('codigo_ibge', TJSONNumber.Create(LQuery.Dataset.FieldByName('CID_CODIGO_IBGE').AsInteger));
    LObj.AddPair('est_codigo', TJSONNumber.Create(LQuery.Dataset.FieldByName('CID_EST').AsInteger));

    Res.Send<TJSONObject>(LObj);
  except
    on E: Exception do
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
  end;
end;

class procedure TCidadesController.Router;
begin
  THorse.Group
    .Prefix('/v1')
    .Route('/cidades')
      .Get(Get)
    .&End
    .Prefix('/v1')
    .Route('/cidades/:id')
      .Get(GetForID)
    .&End;
end;

end.
