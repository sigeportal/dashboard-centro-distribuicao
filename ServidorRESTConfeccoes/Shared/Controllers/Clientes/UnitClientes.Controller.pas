unit UnitClientes.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.JSON,
  FireDAC.Comp.Client;

type
  TClientesController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetValorDevedor(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitClientes.Model,
  UnitTabela.Helpers;

{ TClientesController }

class procedure TClientesController.Router;
begin
  THorse.Group
    .Prefix('/v1')
    .Route('/clientes')
      .Get(Get)
      .Post(Post)
      .Put(Put)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/clientes/:id')
      .Get(GetForID)
      .Delete(Delete)
    .&End
    .Group
    .Prefix('/v1')
    .Route('/clientes/:id/valor-devedor')
      .Get(GetValorDevedor)
    .&End;
end;

class procedure TClientesController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  aJson: TJSONArray;
  LResponseObj, LMetaObj, LItem: TJSONObject;
  QueryCount, QueryData: iQuery;
  LSearch, LWhereClause: string;
  LPage, LLimit, LOffset, LTotalRecords, LTotalPages: Integer;
begin
  aJson := TJSONArray.Create;
  QueryCount := TDatabase.Query;
  QueryData := TDatabase.Query;
  try
    LPage := StrToIntDef(Req.Query.Items['page'], 1);
    if LPage < 1 then LPage := 1;

    LLimit := StrToIntDef(Req.Query.Items['limit'], 10);
    if Req.Query.ContainsKey('total') then
      LLimit := StrToIntDef(Req.Query.Items['total'], LLimit);

    if LLimit < 1 then LLimit := 10;
    if LLimit > 500 then LLimit := 500;

    LOffset := (LPage - 1) * LLimit;

    LWhereClause := '';
    if Req.Query.ContainsKey('search') and not Req.Query.Items['search'].IsEmpty then
    begin
      LSearch := Trim(Req.Query.Items['search'].Replace('''', ''));
      LWhereClause := Format(
        'WHERE (UPPER(CLI_NOME) LIKE UPPER(%s) OR UPPER(CLI_CELULAR) LIKE UPPER(%s) OR UPPER(CLI_FONE) LIKE UPPER(%s) OR UPPER(CLI_CIDADE) LIKE UPPER(%s) OR CLI_CODIGO = %d)',
        [QuotedStr('%' + LSearch + '%'), QuotedStr('%' + LSearch + '%'), QuotedStr('%' + LSearch + '%'), QuotedStr('%' + LSearch + '%'), StrToIntDef(LSearch, -1)]
      );
    end;

    QueryCount.Clear;
    QueryCount.Add('SELECT COUNT(*) AS TOTAL FROM CLIENTES ' + LWhereClause);
    QueryCount.Open;
    LTotalRecords := QueryCount.DataSet.FieldByName('TOTAL').AsInteger;
    LTotalPages := (LTotalRecords + LLimit - 1) div LLimit;
    if LTotalPages < 1 then LTotalPages := 1;

    QueryData.Clear;
    QueryData.Add(Format(
      'SELECT FIRST %d SKIP %d CLI_CODIGO, CLI_NOME, CLI_CELULAR, CLI_FONE, CLI_EMAIL, CLI_CIDADE, CLI_UF, CLI_ENDERECO, CLI_BAIRRO, CLI_CEP, CLI_CNPJ_CPF, CLI_RG, CLI_LIMITE FROM CLIENTES %s ORDER BY CLI_CODIGO',
      [LLimit, LOffset, LWhereClause]
    ));
    QueryData.Open;

    while not QueryData.DataSet.Eof do
    begin
      LItem := TJSONObject.Create;
      LItem.AddPair('codigo', TJSONNumber.Create(QueryData.DataSet.FieldByName('CLI_CODIGO').AsInteger));
      LItem.AddPair('nome', QueryData.DataSet.FieldByName('CLI_NOME').AsString);
      LItem.AddPair('celular', QueryData.DataSet.FieldByName('CLI_CELULAR').AsString);
      LItem.AddPair('telefone', QueryData.DataSet.FieldByName('CLI_FONE').AsString);
      LItem.AddPair('email', QueryData.DataSet.FieldByName('CLI_EMAIL').AsString);
      LItem.AddPair('cidade', QueryData.DataSet.FieldByName('CLI_CIDADE').AsString);
      LItem.AddPair('uf', QueryData.DataSet.FieldByName('CLI_UF').AsString);
      LItem.AddPair('endereco', QueryData.DataSet.FieldByName('CLI_ENDERECO').AsString);
      LItem.AddPair('bairro', QueryData.DataSet.FieldByName('CLI_BAIRRO').AsString);
      LItem.AddPair('cep', QueryData.DataSet.FieldByName('CLI_CEP').AsString);
      LItem.AddPair('cnpj_cpf', QueryData.DataSet.FieldByName('CLI_CNPJ_CPF').AsString);
      LItem.AddPair('cpf_cnpj', QueryData.DataSet.FieldByName('CLI_CNPJ_CPF').AsString);
      LItem.AddPair('rg', QueryData.DataSet.FieldByName('CLI_RG').AsString);
      LItem.AddPair('limite', TJSONNumber.Create(QueryData.DataSet.FieldByName('CLI_LIMITE').AsFloat));
      aJson.AddElement(LItem);
      QueryData.DataSet.Next;
    end;

    LMetaObj := TJSONObject.Create;
    LMetaObj.AddPair('page', TJSONNumber.Create(LPage));
    LMetaObj.AddPair('limit', TJSONNumber.Create(LLimit));
    LMetaObj.AddPair('total', TJSONNumber.Create(LTotalRecords));
    LMetaObj.AddPair('pages', TJSONNumber.Create(LTotalPages));

    LResponseObj := TJSONObject.Create;
    LResponseObj.AddPair('data', aJson);
    LResponseObj.AddPair('meta', LMetaObj);

    Res.Send<TJSONObject>(LResponseObj);
  except
    on E: Exception do
    begin
      aJson.Free;
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
    end;
  end;
end;

class procedure TClientesController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Clientes: TClientes;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Clientes := TClientes.Create(TDatabase.Connection);
    Clientes.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Clientes.ToJson) as TJSONObject);
  finally
    Clientes.DisposeOf;
  end;
end;

class procedure TClientesController.GetValorDevedor(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LId: Integer;
  LQuery: iQuery;
  LValDevedor: Double;
  LObj: TJSONObject;
begin
  LId := StrToIntDef(Req.Params.Items['id'], 0);
  LQuery := TDatabase.Query;
  try
    LQuery.Clear;
    LQuery.Add(Format('SELECT COALESCE(SUM(RP_VALORD - RP_VALORP), 0) AS DEVEDOR FROM REC_PGM WHERE RP_CLIENTE = %d AND (RP_DATAPGM IS NULL OR RP_VALORP < RP_VALORD)', [LId]));
    LQuery.Open;
    LValDevedor := LQuery.DataSet.FieldByName('DEVEDOR').AsFloat;

    LObj := TJSONObject.Create;
    LObj.AddPair('vlr_devedor', TJSONNumber.Create(LValDevedor));
    Res.Send<TJSONObject>(LObj);
  except
    on E: Exception do
      Res.Status(THTTPStatus.InternalServerError).Send('{"error": "' + E.Message + '"}');
  end;
end;

class procedure TClientesController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Clientes: TClientes;
begin
  try
    Clientes := TClientes.Create(TDatabase.Connection).fromJson<TClientes>(Req.Body);
    Clientes.Cadastrar := 'S';
    Clientes.SalvaNoBanco(0);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Clientes.ToJson) as TJSONObject).Status(THTTPStatus.Created);
  finally
    Clientes.DisposeOf;
  end;
end;

class procedure TClientesController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Clientes: TClientes;
begin
  try
    Clientes := TClientes.Create(TDatabase.Connection).fromJson<TClientes>(Req.Body);
    Clientes.Cadastrar := 'S';
    Clientes.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Clientes.ToJson) as TJSONObject);
  finally
    Clientes.DisposeOf;
  end;
end;

class procedure TClientesController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Clientes: TClientes;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Clientes := TClientes.Create(TDatabase.Connection);
    Clientes.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Clientes.DisposeOf;
  end;
end;

end.
