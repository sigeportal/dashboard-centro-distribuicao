unit UnitMovimentacoes.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json;

type
  TMovimentacoesController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse);
    class procedure GetContas(Req: THorseRequest; Res: THorseResponse);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse);
    // class procedure Post(Req: THorseRequest; Res: THorseResponse);
    // class procedure Put(Req: THorseRequest; Res: THorseResponse);
    // class procedure Delete(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

{ TMovimentacoesController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitMovimentacoes.Model,
  UnitConstants,
  UnitTabela.Helpers;

{ class procedure TMovimentacoesController.Delete(Req: THorseRequest; Res: THorseResponse);
  var Movimentacoes: TMovimentacoes;
  id: Integer;
  begin
  try
  id := Req.Params.Items['id'].ToInteger();
  Movimentacoes := TMovimentacoes.Create(TDatabase.Connection);
  Movimentacoes.Apagar(id);
  Res.Send('').Status(THTTPStatus.NoContent);
  finally
  Movimentacoes.DisposeOf;
  end;
  end; }

class procedure TMovimentacoesController.Get(Req: THorseRequest;
  Res: THorseResponse);
var
  Movimentacoes: TMovimentacoes;
  aJson: TJSONArray;
  Query: iQuery;
  Filtros: TStringList;
  WhereList: TStringList;
  ParamName, ParamValue, QueryParams: string;
  StartDateParam, EndDateParam, ConParam: string;
  i: Integer;
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
  Movimentacoes := nil;
  Filtros := nil;
  WhereList := nil;
  try
    LMetaJSON := TJSONObject.Create;
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;
    Movimentacoes := TMovimentacoes.Create(TDatabase.Connection);
    Movimentacoes.CriaTabela;
    Filtros := TStringList.Create;
    WhereList := TStringList.Create;
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
      SQLBase :=
        Format('SELECT FIRST %d SKIP %d DISTINCT MOV_CODIGO FROM MOVIMENTACOES',
        [Limite, Pular])
    else
      SQLBase := 'SELECT DISTINCT MOV_CODIGO FROM MOVIMENTACOES';

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
          Filtros.Add(Format('(MOV_DESCRICAO LIKE %0:s OR MOV_NOME LIKE %0:s)',
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

      // Filtragem por conta
      if ParamName = 'CON' then
      begin
        if not ParamValue.IsEmpty then
        begin
          ConParam := ParamValue;
        end;
        Continue;
      end;

      // Adiciona filtro com LIKE para texto genérico
      if not ParamValue.IsEmpty then
        Filtros.Add(Format('%s LIKE %s',
          [ParamName, QuotedStr('%' + ParamValue + '%')]));
    end;

    // Monta a cláusula WHERE unificada antes de contar os registros e selecionar
    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
      WhereList.Add('(MOV_DATA BETWEEN :DATE1 AND :DATE2)');

    if not ConParam.IsEmpty then
      WhereList.Add('MOV_CON = :CON');

    if Filtros.Count > 0 then
      WhereList.Add('(' + String.Join(' OR ', Filtros.ToStringArray) + ')');

    WhereClause := '';
    if WhereList.Count > 0 then
      WhereClause := ' WHERE ' + String.Join(' AND ', WhereList.ToStringArray);

    // Buscar a quantidade de dados armazenados usando o WHERE completo e parâmetros de data
    Query.Clear;
    Query.Add('SELECT COUNT (DISTINCT MOV_CODIGO) AS TOTAL FROM MOVIMENTACOES' + WhereClause);

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end;

    if not ConParam.IsEmpty then
      Query.AddParam('CON', ConParam);

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

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end;

    if not ConParam.IsEmpty then
      Query.AddParam('CON', ConParam);

    Query.Add('ORDER BY MOV_CODIGO DESC');
    Query.Open;

    // Monta JSON de retorno
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Movimentacoes.BuscaDadosTabela(Query.Dataset.FieldByName('MOV_CODIGO')
        .AsInteger);
      LItemJSON := TJSONObject.ParseJSONValue(Movimentacoes.ToJson) as TJSONObject;
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
    WhereList.Free;
    Filtros.Free;
    Movimentacoes.DisposeOf;
    aJson.Free;
    LMetaJSON.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TMovimentacoesController.GetContas(Req: THorseRequest;
  Res: THorseResponse);
var
  Query: iQuery;
  LResponseJSON: TJSONObject;
begin
  Query := TDatabase.Query;
  LResponseJSON := nil;
  try
    LResponseJSON := TJSONObject.Create;
    Query.Add('SELECT 0 CODIGO, ''CAIXA'' NOME FROM CONTAS'
      + ' UNION SELECT CON_CODIGO CODIGO, CON_DESCRICAO NOME FROM CONTAS');
    Query.Open();

    Query.DataSet.First;
    while not Query.DataSet.Eof do
    begin
      LResponseJSON.AddPair(Query.DataSet.FieldByName('CODIGO').AsString,
                            Query.DataSet.FieldByName('NOME').AsString);

      Query.DataSet.Next;
    end;

    Res.Send<TJSONObject>(LResponseJSON);

    LResponseJSON := nil;
  finally
    if Assigned(LResponseJSON) then
      LResponseJSON.Free;
  end;
end;

class procedure TMovimentacoesController.GetForID(Req: THorseRequest;
  Res: THorseResponse);
var
  Movimentacoes: TMovimentacoes;
  id: Integer;
  LResponseJSON: TJSONObject;
begin
  id := Req.Params.Items['id'].ToInteger();
  try
    Movimentacoes := TMovimentacoes.Create(TDatabase.Connection);
    Movimentacoes.CriaTabela;
    Movimentacoes.BuscaDadosTabela(id);
    if Movimentacoes.Codigo = 0 then
      Res.Send('').Status(THTTPStatus.NotFound)
    else
    begin
      LResponseJSON := Movimentacoes.ToJsonObject;
      try
        Res.Send<TJSONObject>(LResponseJSON);
        LResponseJSON := nil;
      finally
        LResponseJSON.Free;
      end;
    end;
  finally
    Movimentacoes.DisposeOf;
  end;
end;

{ class procedure TMovimentacoesController.Post(Req: THorseRequest; Res: THorseResponse);
  var Movimentacoes: TMovimentacoes;
  begin
  try
  Movimentacoes := TMovimentacoes.Create(TDatabase.Connection).fromJson<TMovimentacoes>(Req.Body);
  Movimentacoes.CriaTabela;
  if Movimentacoes.Codigo = 0 then
  Movimentacoes.Codigo := GeraCodigo('MOVIMENTACOES', 'MOV_CODIGO');
  Movimentacoes.SalvaNoBanco(1);
  Res.Send<TJSONObject>(Movimentacoes.ToJsonObject);
  finally
  Movimentacoes.DisposeOf;
  end;
  end; }

{ class procedure TMovimentacoesController.Put(Req: THorseRequest; Res: THorseResponse);
  var Movimentacoes: TMovimentacoes;
  begin
  try
  Movimentacoes := TMovimentacoes.Create(TDatabase.Connection).fromJson<TMovimentacoes>(Req.Body);
  Movimentacoes.CriaTabela;
  Movimentacoes.SalvaNoBanco(1);
  Res.Send<TJSONObject>(Movimentacoes.ToJsonObject);
  finally
  Movimentacoes.DisposeOf;
  end;
  end; }

class procedure TMovimentacoesController.Router;
begin
  THorse.Group.Prefix('/v1').Route('/movimentacoes').Get(Get)
  // .Post(Post)
  // .Put(Put)
    .&End
    .Group.Prefix('/v1')
    .Route('/movimentacoes/:id').Get(GetForID).&End
    .Group.Prefix('/v1')
    .Route('/movimentacoes/contas').Get(GetContas).&End
  // .Delete(Delete)
end;

initialization

Swagger.BasePath('v1').Path('movimentacoes').Tag('Movimentacoes')
  .Get('Lista Todos(as)', 'Lista todos(as) os(as) Movimentacoess')
  .AddResponse(200, 'Operação bem Sucedida').Schema(TMovimentacoes)
  .IsArray(True).&End.AddResponse(400).&End.AddResponse(500).&End.&End
{ .POST('Criar Movimentacoes', 'Cria um(a) novo(a) Movimentacoes')
  .AddParamBody('Dados do(a) Movimentacoes', 'Movimentacoes')
  .Required(True)
  .Schema(TMovimentacoes)
  .&End
  .AddResponse(201, 'Created')
  .Schema(TMovimentacoes)
  .&End
  .AddResponse(400, 'BadRequest')
  .Schema(TAPIError)
  .&End
  .AddResponse(500).&End
  .&End
  .PUT('Atualiza Movimentacoes', 'Atualiza os dados de um(a) Movimentacoes')
  .AddParamBody('Dados do(a) Movimentacoes', 'Movimentacoes')
  .Required(True)
  .Schema(TMovimentacoes)
  .&End
  .AddResponse(200, 'Ok')
  .Schema(TMovimentacoes)
  .&End
  .AddResponse(400, 'BadRequest')
  .Schema(TAPIError)
  .&End
  .AddResponse(500).&End
  .&End }
  .&End.&End.BasePath('v1').Path('movimentacoes/{id}').Tag('Movimentacoes')
  .Get('Obtem um(a) Movimentacoes').AddParamPath('id',
  'Id do(a) Movimentacoes para buscar').Required(True).Schema(SWAG_INTEGER)
  .&End.AddResponse(200, 'Operação bem Sucedida').Schema(TMovimentacoes)
  .&End.AddResponse(404, 'Movimentacoes não encontrado(a)')
  .&End.AddResponse(400, 'BadRequest').Schema(TAPIError)
  .&End.AddResponse(500).&End.&End
{ .DELETE('Apagar um(a) Movimentacoes')
  .AddParamPath('id', 'id do(a) Movimentacoes para deletar')
  .Required(True)
  .Schema(SWAG_INTEGER)
  .&End
  .AddResponse(404, 'Movimentacoes não encontrado(a)').&End
  .AddResponse(400, 'BadRequest')
  .Schema(TAPIError)
  .&End
  .AddResponse(500).&End
  .&End }
  .&End.&End

end.
