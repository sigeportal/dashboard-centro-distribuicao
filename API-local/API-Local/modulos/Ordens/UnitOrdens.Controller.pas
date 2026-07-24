unit UnitOrdens.Controller;

interface

uses
  Horse,
//  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json;

type
  TOrdensController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse);
//    class procedure Post(Req: THorseRequest; Res: THorseResponse);
//    class procedure Put(Req: THorseRequest; Res: THorseResponse);
//    class procedure Delete(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

{ TOrdensController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
//  UnitFunctions,
  UnitOrdens.Model,
  UnitConstants,
  UnitTabela.Helpers;

class procedure TOrdensController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/os')
          .Get(Get)
//          .Post(Post)
//          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/os/:id')
          .Get(GetForID)
//          .Delete(Delete)
        .&End
end;

class procedure TOrdensController.Get(Req: THorseRequest; Res: THorseResponse);
var
  Ordens: TOrdens;
  aJson: TJSONArray;
  Query: iQuery;
  Filtros: TStringList;
  ParamName, ParamValue, QueryParams: string;
  StartDateParam, EndDateParam: string;
  Limite: Integer;
  Pagina: Integer;
  Pular: Integer;
  SQLBase: string;
  WhereClause: string;
  LResponseJSON: TJSONObject;
  LMetaJSON: TJSONObject;
  LTotalRegistros: Integer;
  LPaginas: Integer;
  LItemJSON: TJSONObject;
begin
  LMetaJSON := nil;
  LResponseJSON := nil;
  aJson := nil;
  Ordens := nil;
  Filtros := nil;
  StartDateParam := '';
  EndDateParam := '';
  try
    LMetaJSON := TJSONObject.Create;
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;
    Ordens := TOrdens.Create(TDatabase.Connection);
    Ordens.CriaTabela;
    Filtros := TStringList.Create;

    // Obtem parametros de paginacao (page e limit)
    Limite := 10; // Valor padrao
    Pagina := 1; // Valor padrao (primeira pagina)

    if Req.Query.ContainsKey('limit') then
      Limite := Req.Query.Items['limit'].ToInteger();

    if Req.Query.ContainsKey('page') then
      Pagina := Req.Query.Items['page'].ToInteger();

    // Calcula o SKIP baseado na pagina e limite
    if Pagina < 1 then
      Pagina := 1;
    Pular := (Pagina - 1) * Limite;

    // Monta SELECT com paginacao
    if Limite > 0 then
      SQLBase := Format('SELECT FIRST %d SKIP %d DISTINCT ORD_CODIGO FROM ORDENS', [Limite, Pular])
    else
      SQLBase := 'SELECT DISTINCT ORD_CODIGO FROM ORDENS';

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parametros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

      // Busca global em multiplos campos
      if ParamName = 'SEARCH' then
      begin
        if not ParamValue.IsEmpty then
        begin
          Filtros.Add(Format('(CAST(ORD_CODIGO AS VARCHAR(10)) LIKE %0:s OR ORD_FUN IN (SELECT FUN_CODIGO FROM FUNCIONARIOS WHERE FUN_NOME LIKE %0:s) OR ORD_CLI IN (SELECT CLI_CODIGO FROM CLIENTES WHERE CLI_NOME LIKE %0:s))',
            [QuotedStr('%' + ParamValue + '%')]));
        end;
        Continue;
      end;

      // Data inicial de filtragem
      if ParamName = 'STARTDATE' then
      begin
        if not ParamValue.IsEmpty then
          StartDateParam := ParamValue;
        Continue;
      end;

      // Data final de filtragem
      if ParamName = 'ENDDATE' then
      begin
        if not ParamValue.IsEmpty then
          EndDateParam := ParamValue;
        Continue;
      end;

      // Adiciona filtro com LIKE para texto generico
      if not ParamValue.IsEmpty then
        Filtros.Add(Format('%s LIKE %s', [ParamName, QuotedStr('%' + ParamValue + '%')]));
    end;

    // Monta a clausula WHERE unificada antes de contar os registros e selecionar
    WhereClause := ' WHERE ORD_DATAC = ''01/01/1900''';
    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
      WhereClause := WhereClause + ' AND (ORD_DATA BETWEEN :DATE1 AND :DATE2)';

    if Filtros.Count > 0 then
      WhereClause := WhereClause + ' AND (' + String.Join(' OR ', Filtros.ToStringArray) + ')';

    // Buscar a quantidade de dados armazenados usando o WHERE completo e parametros de data
    Query.Clear;
    Query.Add('SELECT COUNT (DISTINCT ORD_CODIGO) AS TOTAL FROM ORDENS' + WhereClause);
    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end;
    Query.Open;

    if not Query.Dataset.IsEmpty then
      LTotalRegistros := Query.Dataset.Fields[0].AsInteger
    else
      LTotalRegistros := 0;

    if Limite > 0 then
    begin
      LPaginas := LTotalRegistros div Limite;
      if (LTotalRegistros mod Limite) > 0 then
        LPaginas := LPaginas + 1;
    end
    else
      LPaginas := 1;

    if LPaginas = 0 then
      LPaginas := 1;

    LMetaJSON.AddPair('total', TJSONNumber.Create(LTotalRegistros));
    LMetaJSON.AddPair('pages', TJSONNumber.Create(LPaginas));
    LMetaJSON.AddPair('currentPage', TJSONNumber.Create(Pagina));
    LMetaJSON.AddPair('limit', TJSONNumber.Create(Limite));

    // Monta SQL final reutilizando a mesma clausula WHERE e parametros de data
    Query.Clear;
    Query.Add(SQLBase);
    if not WhereClause.IsEmpty then
      Query.Add(WhereClause);
    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end;
    Query.Add('ORDER BY ORD_CODIGO DESC');
    Query.Open;

    // Monta JSON de retorno
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Ordens.BuscaDadosTabela(Query.Dataset.FieldByName('ORD_CODIGO').AsInteger);
      LItemJSON := TJSONObject.ParseJSONValue(Ordens.ToJson) as TJSONObject;
      try
        aJson.Add(LItemJSON);
        LItemJSON := nil;
      finally
        LItemJSON.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    LResponseJSON.AddPair('meta', LMetaJSON);
    LMetaJSON := nil;

    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    Filtros.Free;
    Ordens.DisposeOf;
    aJson.Free;
    LMetaJSON.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TOrdensController.GetForID(Req: THorseRequest; Res: THorseResponse);
var
  Ordens: TOrdens;
  id: Integer;
  LResponseJSON: TJSONObject;
begin
  id := Req.Params.Items['id'].ToInteger();
  Ordens := nil;
  LResponseJSON := nil;
  try
    Ordens := TOrdens.Create(TDatabase.Connection);
    Ordens.CriaTabela;
    Ordens.BuscaDadosTabela(id);
    LResponseJSON := Ordens.ToJsonObject;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    LResponseJSON.Free;
    Ordens.DisposeOf;
  end;
end;

//class procedure TOrdensController.Post(Req: THorseRequest; Res: THorseResponse);
//var
//  Ordens: TOrdens;
//begin
//  Ordens := nil;
//  try
//    Ordens := TOrdens.Create(TDatabase.Connection).fromJson<TOrdens>(Req.Body);
//    Ordens.CriaTabela;
//    if Ordens.Codigo = 0 then
//      Ordens.Codigo := GeraCodigo('ORDENS', 'ORD_CODIGO');
//    Ordens.SalvaNoBanco(1);
//    Res.Send<TJSONObject>(Ordens.ToJsonObject);
//  finally
//    Ordens.DisposeOf;
//  end;
//end;

//class procedure TOrdensController.Put(Req: THorseRequest; Res: THorseResponse);
//var
//  Ordens: TOrdens;
//begin
//  Ordens := nil;
//  try
//    Ordens := TOrdens.Create(TDatabase.Connection).fromJson<TOrdens>(Req.Body);
//    Ordens.CriaTabela;
//    Ordens.SalvaNoBanco(1);
//    Res.Send<TJSONObject>(Ordens.ToJsonObject);
//  finally
//    Ordens.DisposeOf;
//  end;
//end;

//class procedure TOrdensController.Delete(Req: THorseRequest; Res: THorseResponse);
//var
//  Ordens: TOrdens;
//  id: Integer;
//begin
//  Ordens := nil;
//  try
//    id := Req.Params.Items['id'].ToInteger();
//    Ordens := TOrdens.Create(TDatabase.Connection);
//    Ordens.Apagar(id);
//    Res.Send('').Status(THTTPStatus.NoContent);
//  finally
//    Ordens.DisposeOf;
//  end;
//end;

initialization
  Swagger
    .BasePath('v1')
    .Path('os')
      .Tag('Ordens')
      .GET('Lista Todos(as)', 'Lista todos(as) os(as) Ordens')
        .AddResponse(200, 'Operacao bem Sucedida')
          .Schema(TOrdens)
          .IsArray(True)
        .&End
        .AddResponse(400).&End
        .AddResponse(500).&End
      .&End
//      .POST('Criar Ordens', 'Cria um(a) novo(a) Ordens')
//        .AddParamBody('Dados do(a) Ordens', 'Ordens')
//          .Required(True)
//          .Schema(TOrdens)
//        .&End
//        .AddResponse(201, 'Created')
//          .Schema(TOrdens)
//        .&End
//        .AddResponse(400, 'BadRequest')
//          .Schema(TAPIError)
//        .&End
//        .AddResponse(500).&End
//      .&End
//      .PUT('Atualiza Ordens', 'Atualiza os dados de um(a) Ordens')
//        .AddParamBody('Dados do(a) Ordens', 'Ordens')
//          .Required(True)
//          .Schema(TOrdens)
//        .&End
//        .AddResponse(200, 'Ok')
//          .Schema(TOrdens)
//        .&End
//        .AddResponse(400, 'BadRequest')
//          .Schema(TAPIError)
//        .&End
//        .AddResponse(500).&End
//      .&End
    .&End
  .&End
  .BasePath('v1')
    .Path('os/{id}')
      .Tag('Ordens')
      .GET('Obtem um(a) Ordens')
        .AddParamPath('id', 'Id do(a) Ordens para buscar')
          .Required(True)
          .Schema(SWAG_INTEGER)
        .&End
        .AddResponse(200, 'Operacao bem Sucedida')
          .Schema(TOrdens)
        .&End
        .AddResponse(404, 'Ordens nao encontrado(a)').&End
        .AddResponse(400, 'BadRequest')
          .Schema(TAPIError)
        .&End
        .AddResponse(500).&End
      .&End
//      .DELETE('Apagar um(a) Ordens')
//        .AddParamPath('id', 'id do(a) Ordens para deletar')
//          .Required(True)
//          .Schema(SWAG_INTEGER)
//        .&End
//        .AddResponse(404, 'Ordens nao encontrado(a)').&End
//        .AddResponse(400, 'BadRequest')
//          .Schema(TAPIError)
//        .&End
//        .AddResponse(500).&End
//      .&End
    .&End
  .&End

end.
