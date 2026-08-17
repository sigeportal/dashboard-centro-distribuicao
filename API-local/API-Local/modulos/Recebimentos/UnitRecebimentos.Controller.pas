unit UnitRecebimentos.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json;

type
  TRecebimentosController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse);
//    class procedure Post(Req: THorseRequest; Res: THorseResponse);
//    class procedure Put(Req: THorseRequest; Res: THorseResponse);
//    class procedure Delete(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

{ TRecebimentosController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitRecebimentos.Model,
  UnitConstants,
  UnitTabela.Helpers,
  System.DateUtils;

{class procedure TRecebimentosController.Delete(Req: THorseRequest; Res: THorseResponse);
var Recebimentos: TRecebimentos;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Recebimentos := TRecebimentos.Create(TDatabase.Connection);
    Recebimentos.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Recebimentos.DisposeOf;
  end;
end;}

class procedure TRecebimentosController.Get(Req: THorseRequest;
  Res: THorseResponse);
var
  Recebimentos: TRecebimentos;
  aJson: TJSONArray;
  Query: iQuery;
  Filtros: TStringList;
  ParamName, ParamValue, QueryParams: string;
  Limite: Integer;
  Pagina: Integer;
  Pular: Integer;
  SQLBase: string;
  WhereClause: string;
  LResponseJSON: TJSONObject;
  LMetaJSON: TJSONObject;
  LTotalRegistros: Integer;
  LPaginas: Integer;
  StartDateParam: string;
  EndDateParam: string;
  LItemJSON: TJSONObject;
begin
  LMetaJSON := nil;
  LResponseJSON := nil;
  aJson := nil;
  Recebimentos := nil;
  Filtros := nil;
  try
    LMetaJSON := TJSONObject.Create;
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;
    Recebimentos := TRecebimentos.Create(TDatabase.Connection);
    Recebimentos.CriaTabela;
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
    // Movimentações necessita de junção com REC_PGM para extração de data do pagamento
    if Limite > 0 then
      SQLBase :=
        Format('SELECT FIRST %d SKIP %d r.REC_CODIGO, MAX(p.RP_DATAPGM) AS RP_DATAPGM FROM RECEBIMENTOS r '
        + 'INNER JOIN REC_PGM p ON p.RP_REC = r.REC_CODIGO', [Limite, Pular])
    else
      SQLBase := 'SELECT r.REC_CODIGO, MAX(p.RP_DATAPGM) AS RP_DATAPGM FROM RECEBIMENTOS r ' +
        'INNER JOIN REC_PGM p ON p.RP_REC = r.REC_CODIGO';

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

      // Busca global em múltiplos campos
      if ParamName = 'SEARCH' then
      begin
        if not ParamValue.IsEmpty then
        begin
          Filtros.Add(Format('(r.REC_DUPLICATA LIKE %0:s OR r.REC_OBS LIKE %0:s)',
            [QuotedStr('%' + ParamValue + '%')]));
        end;
        Continue;
      end;

      // Data inicial de filtragem
      if ParamName = 'STARTDATE' then
      begin
        if not ParamValue.IsEmpty then
        begin
          StartDateParam := ParamValue;
        end;
        Continue;
      end;

      // Data final de filtragem
      if ParamName = 'ENDDATE' then
      begin
        if not ParamValue.IsEmpty then
        begin
          EndDateParam := ParamValue;
        end;
        Continue;
      end;

      // Adiciona filtro com LIKE para texto genérico
      if not ParamValue.IsEmpty then
        Filtros.Add(Format('%s LIKE %s',
          [ParamName, QuotedStr('%' + ParamValue + '%')]));
    end;

    // Data default caso nao informada
    if StartDateParam.IsEmpty then
      StartDateParam := FormatDateTime('yyyy-mm-dd', IncDay(Date, -30));
    if EndDateParam.IsEmpty then
      EndDateParam := FormatDateTime('yyyy-mm-dd', Date);

    // Monta a cláusula WHERE unificada antes de contar os registros e selecionar
    WhereClause := 'WHERE (p.RP_DATAPGM BETWEEN :DATE1 AND :DATE2)';
    if Filtros.Count > 0 then
    begin
      WhereClause := WhereClause + ' AND (' + String.Join(' OR ', Filtros.ToStringArray) + ')';
    end;

    // Buscar a quantidade de dados armazenados usando o WHERE completo e parâmetros de data
    Query.Clear;
    Query.Add('SELECT COUNT (DISTINCT r.REC_CODIGO) AS TOTAL FROM RECEBIMENTOS r ' +
              'INNER JOIN REC_PGM p ON p.RP_REC = r.REC_CODIGO ' + WhereClause);
    Query.AddParam('DATE1', StartDateParam);
    Query.AddParam('DATE2', EndDateParam);
    Query.Open;

    if not Query.Dataset.IsEmpty then
      LTotalRegistros := Query.Dataset.Fields[0].AsInteger
    else
      LTotalRegistros := 0; // Valor padrão caso não haja nada

    if Limite > 0 then
    begin
      LPaginas := LTotalRegistros div Limite;

      // Verifica se há registros sobrando
      if (LTotalRegistros mod Limite) > 0 then
        LPaginas := LPaginas + 1; // Adiciona mais uma página
    end
    else
      LPaginas := 1;

    // Indicar para o dashboard criar uma página, mesmo que vazia
    if LPaginas = 0 then
      LPaginas := 1;

    LMetaJSON.AddPair('total', TJSONNumber.Create(LTotalRegistros));
    LMetaJSON.AddPair('pages', TJSONNumber.Create(LPaginas));
    LMetaJSON.AddPair('currentPage', TJSONNumber.Create(Pagina));
    LMetaJSON.AddPair('limit', TJSONNumber.Create(Limite));

    // Monta SQL final reutilizando a mesma cláusula WHERE e parâmetros de data
    Query.Clear;
    Query.Add(SQLBase);
    Query.Add(WhereClause);
    Query.AddParam('DATE1', StartDateParam);
    Query.AddParam('DATE2', EndDateParam);
    Query.Add('GROUP BY r.REC_CODIGO');
    Query.Add('ORDER BY r.REC_CODIGO DESC');
    Query.Open;

    // Monta JSON de retorno
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Recebimentos.BuscaDadosTabela(Query.Dataset.FieldByName('REC_CODIGO')
        .AsInteger);
      LItemJSON := TJSONObject.ParseJSONValue(Recebimentos.ToJson) as TJSONObject;
      try
        if not Query.Dataset.FieldByName('RP_DATAPGM').IsNull then
          LItemJSON.AddPair('datapgm', FormatDateTime('yyyy-mm-dd', Query.Dataset.FieldByName('RP_DATAPGM').AsDateTime))
        else
          LItemJSON.AddPair('datapgm', TJSONNull.Create);

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
    Recebimentos.DisposeOf;
    aJson.Free;
    LMetaJSON.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TRecebimentosController.GetForID(Req: THorseRequest;
  Res: THorseResponse);
var
  Recebimentos: TRecebimentos;
  id: Integer;
  QueryPgm: iQuery;
  LResponseJSON: TJSONObject;
begin
  id := Req.Params.Items['id'].ToInteger();
  QueryPgm := TDatabase.Query;
  LResponseJSON := nil;
  try
    Recebimentos := TRecebimentos.Create(TDatabase.Connection);
    Recebimentos.CriaTabela;
    Recebimentos.BuscaDadosTabela(id);
    if Recebimentos.Codigo = 0 then
    begin
      Res.Send('').Status(THTTPStatus.NotFound);
      Exit;
    end;
    
    LResponseJSON := TJSONObject.ParseJSONValue(Recebimentos.ToJson) as TJSONObject;
    try
      if Assigned(LResponseJSON) then
      begin
        QueryPgm.Clear;
        QueryPgm.Add('SELECT MAX(RP_DATAPGM) AS RP_DATAPGM FROM REC_PGM WHERE RP_REC = :REC');
        QueryPgm.AddParam('REC', id);
        QueryPgm.Open;
        
        if not QueryPgm.Dataset.IsEmpty and not QueryPgm.Dataset.FieldByName('RP_DATAPGM').IsNull then
          LResponseJSON.AddPair('datapgm', FormatDateTime('yyyy-mm-dd', QueryPgm.Dataset.FieldByName('RP_DATAPGM').AsDateTime))
        else
          LResponseJSON.AddPair('datapgm', TJSONNull.Create);
      end;
        
      Res.Send<TJSONObject>(LResponseJSON);
      LResponseJSON := nil;
    finally
      LResponseJSON.Free;
    end;
  finally
    Recebimentos.DisposeOf;
  end;
end;

{class procedure TRecebimentosController.Post(Req: THorseRequest; Res: THorseResponse);
var Recebimentos: TRecebimentos;
begin
  try
    Recebimentos := TRecebimentos.Create(TDatabase.Connection).fromJson<TRecebimentos>(Req.Body);
    Recebimentos.CriaTabela;
    if Recebimentos.Codigo = 0 then
        Recebimentos.Codigo := GeraCodigo('RECEBIMENTOS', 'REC_CODIGO');
    Recebimentos.SalvaNoBanco(1);
    Res.Send<TJSONObject>(Recebimentos.ToJsonObject);
  finally
    Recebimentos.DisposeOf;
  end;
end;

class procedure TRecebimentosController.Put(Req: THorseRequest; Res: THorseResponse);
var Recebimentos: TRecebimentos;
begin
  try
    Recebimentos := TRecebimentos.Create(TDatabase.Connection).fromJson<TRecebimentos>(Req.Body);
    Recebimentos.CriaTabela;
    Recebimentos.SalvaNoBanco(1);
    Res.Send<TJSONObject>(Recebimentos.ToJsonObject);
  finally
    Recebimentos.DisposeOf;
  end;
end;}

class procedure TRecebimentosController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/recebimentos')
          .Get(Get)
//          .Post(Post)
//          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/recebimentos/:id')
          .Get(GetForID)
//          .Delete(Delete)
        .&End
end;

initialization
    Swagger
	.BasePath('v1')
    .Path('recebimentos')
      .Tag('Recebimentos')
      .GET('Lista Todos(as)', 'Lista todos(as) os(as) Recebimentoss')
        .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TRecebimentos)
          .IsArray(True)
        .&End
        .AddResponse(400).&End
        .AddResponse(500).&End
      .&End
      {.POST('Criar Recebimentos', 'Cria um(a) novo(a) Recebimentos')
        .AddParamBody('Dados do(a) Recebimentos', 'Recebimentos')
          .Required(True)
          .Schema(TRecebimentos)
        .&End
        .AddResponse(201, 'Created')
          .Schema(TRecebimentos)
        .&End
        .AddResponse(400, 'BadRequest')
          .Schema(TAPIError)
        .&End
        .AddResponse(500).&End
      .&End
      .PUT('Atualiza Recebimentos', 'Atualiza os dados de um(a) Recebimentos')
        .AddParamBody('Dados do(a) Recebimentos', 'Recebimentos')
          .Required(True)
          .Schema(TRecebimentos)
        .&End
        .AddResponse(200, 'Ok')
          .Schema(TRecebimentos)
        .&End
        .AddResponse(400, 'BadRequest')
          .Schema(TAPIError)
        .&End
        .AddResponse(500).&End
      .&End}
    .&End
  .&End
  .BasePath('v1')
    .Path('recebimentos/{id}')
      .Tag('Recebimentos')
      .GET('Obtem um(a) Recebimentos')
        .AddParamPath('id', 'Id do(a) Recebimentos para buscar')
          .Required(True)
          .Schema(SWAG_INTEGER)
        .&End
        .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TRecebimentos)
        .&End
        .AddResponse(404, 'Recebimentos não encontrado(a)').&End
        .AddResponse(400, 'BadRequest')
          .Schema(TAPIError)
        .&End
        .AddResponse(500).&End
      .&End
      {.DELETE('Apagar um(a) Recebimentos')
        .AddParamPath('id', 'id do(a) Recebimentos para deletar')
          .Required(True)
          .Schema(SWAG_INTEGER)
        .&End
        .AddResponse(404, 'Recebimentos não encontrado(a)').&End
        .AddResponse(400, 'BadRequest')
          .Schema(TAPIError)
        .&End
        .AddResponse(500).&End
      .&End}
    .&End
  .&End

end.
