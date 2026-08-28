unit UnitModelos.Controller;

interface

uses
  Horse,
  Horse.Commons,
  System.Classes,
  System.SysUtils,
  System.JSON;

type
  TModelosController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitModelos.Model,
  UnitTabela.Helpers;

{ TModelosController }

class procedure TModelosController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LModel: TModelos;
  LId: Integer;
begin
  try
    LId := StrToIntDef(Req.Params.Items['id'], 0);
    LModel := TModelos.Create(TDatabase.Connection);
    LModel.Apagar(LId);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    LModel.DisposeOf;
  end;
end;

class procedure TModelosController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LModel: TModelos;
  LArrJson: TJSONArray;
  LQuery: iQuery;
  LSearch: string;
begin
  LArrJson := TJSONArray.Create;
  LQuery := TDatabase.Query;
  try
    LModel := TModelos.Create(TDatabase.Connection);
    LSearch := Trim(Req.Query.Items['search']);
    if LSearch.IsEmpty then
      LSearch := Trim(Req.Query.Items['busca']);

    if not LSearch.IsEmpty then
    begin
      LQuery.Open(Format(
        'SELECT MOD_CODIGO, MOD_NOME FROM MODELOS WHERE UPPER(MOD_NOME) LIKE %s ORDER BY MOD_NOME',
        [QuotedStr('%' + UpperCase(LSearch) + '%')]
      ));
    end
    else
    begin
      LQuery.Open('SELECT MOD_CODIGO, MOD_NOME FROM MODELOS ORDER BY MOD_NOME');
    end;

    LQuery.Dataset.First;
    while not LQuery.Dataset.Eof do
    begin
      LModel.BuscaDadosTabela(LQuery.Dataset.FieldByName('MOD_CODIGO').AsInteger);
      LArrJson.Add(TJSONObject.ParseJSONValue(LModel.ToJson) as TJSONObject);
      LQuery.Dataset.Next;
    end;
    Res.Send<TJSONArray>(LArrJson);
  finally
    LModel.DisposeOf;
  end;
end;

class procedure TModelosController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LModel: TModelos;
  LId: Integer;
begin
  LId := StrToIntDef(Req.Params.Items['id'], 0);
  try
    LModel := TModelos.Create(TDatabase.Connection);
    LModel.BuscaDadosTabela(LId);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(LModel.ToJson) as TJSONObject);
  finally
    LModel.DisposeOf;
  end;
end;

class procedure TModelosController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LModel: TModelos;
begin
  try
    LModel := TModelos.Create(TDatabase.Connection).fromJson<TModelos>(Req.Body);
    if LModel.Codigo <= 0 then
      LModel.Codigo := GeraCodigo('MODELOS', 'MOD_CODIGO');
    LModel.Cadastrar := 'S';
    LModel.SalvaNoBanco(0);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(LModel.ToJson) as TJSONObject).Status(THTTPStatus.Created);
  finally
    LModel.DisposeOf;
  end;
end;

class procedure TModelosController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LModel: TModelos;
begin
  try
    LModel := TModelos.Create(TDatabase.Connection).fromJson<TModelos>(Req.Body);
    LModel.Cadastrar := 'S';
    LModel.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(LModel.ToJson) as TJSONObject);
  finally
    LModel.DisposeOf;
  end;
end;

class procedure TModelosController.Router;
begin
  THorse.Group
    .Prefix('/v1')
    .Route('/modelos')
      .Get(Get)
      .Post(Post)
      .Put(Put)
    .&End
    .Group
        .Prefix('/v1')
    .Route('/modelos/:id')
      .Get(GetForID)
      .Delete(Delete)
    .&End;
end;

end.
