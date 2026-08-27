unit UnitEstados.Controller;

interface

uses
  Horse,
  Horse.Commons,
  System.Classes,
  System.SysUtils,
  System.JSON;

type
  TEstadosController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitEstados.Model,
  UnitTabela.Helpers;

{ TEstadosController }

class procedure TEstadosController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LArrJson: TJSONArray;
  LObj: TJSONObject;
  LQuery: iQuery;
begin
  LArrJson := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LQuery.Open('SELECT EST_CODIGO, EST_SIGLA, EST_NOME, EST_CODIGO_IBGE FROM ESTADOS ORDER BY EST_SIGLA');
    LQuery.Dataset.First;
    while not LQuery.Dataset.Eof do
    begin
      LObj := TJSONObject.Create;
      LObj.AddPair('codigo', TJSONNumber.Create(LQuery.Dataset.FieldByName('EST_CODIGO').AsInteger));
      LObj.AddPair('sigla', LQuery.Dataset.FieldByName('EST_SIGLA').AsString);
      LObj.AddPair('nome', LQuery.Dataset.FieldByName('EST_NOME').AsString);
      LObj.AddPair('codigo_ibge', TJSONNumber.Create(LQuery.Dataset.FieldByName('EST_CODIGO_IBGE').AsInteger));
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

class procedure TEstadosController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LObj: TJSONObject;
  LQuery: iQuery;
  LId: Integer;
begin
  LId := StrToIntDef(Req.Params.Items['id'], 0);
  LQuery := TDatabase.Query;
  try
    LQuery.Open('SELECT EST_CODIGO, EST_SIGLA, EST_NOME, EST_CODIGO_IBGE FROM ESTADOS WHERE EST_CODIGO = ' + LId.ToString);
    if LQuery.Dataset.IsEmpty then
    begin
      Res.Status(THTTPStatus.NotFound).Send('{"error": "Estado nao encontrado"}');
      Exit;
    end;

    LObj := TJSONObject.Create;
    LObj.AddPair('codigo', TJSONNumber.Create(LQuery.Dataset.FieldByName('EST_CODIGO').AsInteger));
    LObj.AddPair('sigla', LQuery.Dataset.FieldByName('EST_SIGLA').AsString);
    LObj.AddPair('nome', LQuery.Dataset.FieldByName('EST_NOME').AsString);
    LObj.AddPair('codigo_ibge', TJSONNumber.Create(LQuery.Dataset.FieldByName('EST_CODIGO_IBGE').AsInteger));

    Res.Send<TJSONObject>(LObj);
  except
    on E: Exception do
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
  end;
end;

class procedure TEstadosController.Router;
begin
  THorse.Group
    .Prefix('/v1')
    .Route('/estados')
      .Get(Get)
    .&End
    .Prefix('/v1')
    .Route('/estados/:id')
      .Get(GetForID)
    .&End;
end;

end.
