unit UnitVendas.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json;

type
  TVendasController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse);
    class procedure GetVendaResumoForID(Req: THorseRequest; Res: THorseResponse);
//    class procedure Post(Req: THorseRequest; Res: THorseResponse);
//    class procedure Put(Req: THorseRequest; Res: THorseResponse);
//    class procedure Delete(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

{ TVendasController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitVendas.Model,
  UnitConstants,
  UnitTabela.Helpers;

//class procedure TVendasController.Delete(Req: THorseRequest; Res: THorseResponse);
//var Vendas: TVendas;
//  id: Integer;
//begin
//  try
//    id := Req.Params.Items['id'].ToInteger();
//    Vendas := TVendas.Create(TDatabase.Connection);
//    Vendas.Apagar(id);
//    Res.Send('').Status(THTTPStatus.NoContent);
//  finally
//    Vendas.DisposeOf;
//  end;
//end;

class procedure TVendasController.Get(Req: THorseRequest; Res: THorseResponse);
var
  Vendas: TVendas;
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
  Vendas := nil;
  Filtros := nil;
  try
    LMetaJSON := TJSONObject.Create;
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;
    Vendas := TVendas.Create(TDatabase.Connection);
    Vendas.CriaTabela;
    Filtros := TStringList.Create;
    // Obtem parametros de paginacao (page e limit)
    Limite := 10; // Valor padrao
    Pagina := 1;  // Valor padrao (primeira pagina)

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
      SQLBase := Format('SELECT FIRST %d SKIP %d DISTINCT VEN_CODIGO FROM VENDAS', [Limite, Pular])
    else
      SQLBase := 'SELECT DISTINCT VEN_CODIGO FROM VENDAS';

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
          Filtros.Add(Format('(CAST(VEN_CODIGO AS VARCHAR(10)) LIKE %0:s OR CAST(VEN_VENDEDOR AS VARCHAR(10)) LIKE %0:s OR VEN_FUN IN (SELECT FUN_CODIGO FROM FUNCIONARIOS WHERE FUN_NOME LIKE %0:s) OR VEN_VENDEDOR IN (SELECT FUN_CODIGO FROM FUNCIONARIOS WHERE FUN_NOME LIKE %0:s))',
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
        Filtros.Add(Format('%s LIKE %s', [ParamName, QuotedStr('%' + ParamValue + '%')]));
    end;

    // Monta a cláusula WHERE unificada antes de contar os registros e selecionar
    WhereClause := ' WHERE VEN_DATAC = ''01/01/1900''';
    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      WhereClause := WhereClause + ' AND (VEN_DATA BETWEEN :DATE1 AND :DATE2)';
    end;

    if Filtros.Count > 0 then
    begin
      WhereClause := WhereClause + ' AND (' + String.Join(' OR ', Filtros.ToStringArray) + ')'
    end;

    // Buscar a quantidade de dados armazenados usando o WHERE completo e parâmetros de data
    Query.Clear;
    Query.Add('SELECT COUNT (DISTINCT VEN_CODIGO) AS TOTAL FROM VENDAS' + WhereClause);
    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end;
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
    if not WhereClause.IsEmpty then
      Query.Add(WhereClause);
    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end;
    Query.Add('ORDER BY VEN_CODIGO DESC');
    Query.Open;

    // Monta JSON de retorno
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Vendas.BuscaDadosTabela(Query.Dataset.FieldByName('VEN_CODIGO').AsInteger);
      LItemJSON := TJSONObject.ParseJSONValue(Vendas.ToJson) as TJSONObject;
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
    Vendas.DisposeOf;
    aJson.Free;
    LMetaJSON.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TVendasController.GetForID(Req: THorseRequest; Res: THorseResponse);
var
  Vendas: TVendas;
  id: Integer;
  LResponseJSON: TJSONObject;
begin
  id := Req.Params.Items['id'].ToInteger();
  Vendas := TVendas.Create(TDatabase.Connection);
  try
    Vendas.CriaTabela;
    Vendas.BuscaDadosTabela(id);
    LResponseJSON := Vendas.ToJsonObject;
    try
      Res.Send<TJSONObject>(LResponseJSON);
      LResponseJSON := nil;
    finally
      LResponseJSON.Free;
    end;
  finally
    Vendas.DisposeOf;
  end;
end;

class procedure TVendasController.GetVendaResumoForID(Req: THorseRequest;
  Res: THorseResponse);
var
  id: Integer;
  Query: iQuery;
  aJson: TJSONArray;
  LItemJSON: TJSONObject;
begin
  Query := TDatabase.Query;
  aJson := nil;
  try
    aJson := TJSONArray.Create;
    id := Req.Params.Items['id'].ToInteger();
    Query.Add('SELECT PF_DATA, PP_DUPLICATA, PP_VENCIMENTO, TP_DESCRICAO, PP_VALOR+PP_JUROS-PP_DESCONTOS VALOR'
      + ' FROM VENDAS'
      + ' JOIN PED_FAT ON VEN_CODIGO = PF_COD_PED'
      + ' JOIN PF_PARCELA ON PP_PF = PF_CODIGO'
      + ' JOIN TIPO_PGM ON PP_TP = TP_CODIGO'
      + ' WHERE PF_TABELA = ''VENDAS'' AND VEN_DATAC = ''01/01/1900'' AND VEN_CODIGO = :VENDA'
      + ' ORDER BY PP_VENCIMENTO');
    Query.AddParam('VENDA', id);
    Query.Open();
    while not Query.Dataset.Eof do
    begin
      LItemJSON := TJSONObject.Create;
      try
        LItemJSON.AddPair('data_pf', FormatDateTime('yyyy-mm-dd', Query.Dataset.FieldByName('PF_DATA').AsDateTime));
        LItemJSON.AddPair('duplicata', Query.Dataset.FieldByName('PP_DUPLICATA').AsString);
        LItemJSON.AddPair('vencimento', FormatDateTime('yyyy-mm-dd', Query.Dataset.FieldByName('PP_VENCIMENTO').AsDateTime));
        LItemJSON.AddPair('tipo_pgm', Query.Dataset.FieldByName('TP_DESCRICAO').AsString);
        LItemJSON.AddPair('valor', TJSONNumber.Create(Query.Dataset.FieldByName('VALOR').AsFloat));
        aJson.Add(LItemJSON);
        LItemJSON := nil;
      finally
        LItemJSON.Free;
      end;
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
    aJson := nil;
  finally
    aJson.Free;
  end;
end;

//class procedure TVendasController.Post(Req: THorseRequest; Res: THorseResponse);
//var Vendas: TVendas;
//begin
//  try
//    Vendas := TVendas.Create(TDatabase.Connection).fromJson<TVendas>(Req.Body);
//    Vendas.CriaTabela;
//    if Vendas.Codigo = 0 then
//      Vendas.Codigo := GeraCodigo('VENDAS', 'VEN_CODIGO');
//    Vendas.SalvaNoBanco(1);
//    Res.Send<TJSONObject>(Vendas.ToJsonObject);
//  finally
//    Vendas.DisposeOf;
//  end;
//end;

//class procedure TVendasController.Put(Req: THorseRequest; Res: THorseResponse);
//var Vendas: TVendas;
//begin
//  try
//    Vendas := TVendas.Create(TDatabase.Connection).fromJson<TVendas>(Req.Body);
//    Vendas.CriaTabela;
//    Vendas.SalvaNoBanco(1);
//    Res.Send<TJSONObject>(Vendas.ToJsonObject);
//  finally
//    Vendas.DisposeOf;
//  end;
//end;

class procedure TVendasController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/vendas')
          .Get(Get)
//          .Post(Post)
//          .Put(Put)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/vendas/:id')
          .Get(GetForID)
//          .Delete(Delete)
        .&End
        .Group
        .Prefix('/v1')
        .Route('/vendas/:id/resumo')
          .Get(GetVendaResumoForID)
        .&End
end;

initialization
  Swagger
    .BasePath('v1')
    .Path('vendas')
      .Tag('Vendas')
      .GET('Lista Todos(as)', 'Lista todos(as) os(as) Vendass')
        .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TVendas)
          .IsArray(True)
        .&End
        .AddResponse(400).&End
        .AddResponse(500).&End
      .&End
//      .POST('Criar Vendas', 'Cria um(a) novo(a) Vendas')
//        .AddParamBody('Dados do(a) Vendas', 'Vendas')
//          .Required(True)
//          .Schema(TVendas)
//        .&End
//        .AddResponse(201, 'Created')
//          .Schema(TVendas)
//        .&End
//        .AddResponse(400, 'BadRequest')
//          .Schema(TAPIError)
//        .&End
//        .AddResponse(500).&End
//      .&End
//      .PUT('Atualiza Vendas', 'Atualiza os dados de um(a) Vendas')
//        .AddParamBody('Dados do(a) Vendas', 'Vendas')
//          .Required(True)
//          .Schema(TVendas)
//        .&End
//        .AddResponse(200, 'Ok')
//          .Schema(TVendas)
//        .&End
//        .AddResponse(400, 'BadRequest')
//          .Schema(TAPIError)
//        .&End
//        .AddResponse(500).&End
//      .&End
    .&End
  .&End
  .BasePath('v1')
    .Path('vendas/{id}')
      .Tag('Vendas')
      .GET('Obtem um(a) Vendas')
        .AddParamPath('id', 'Id do(a) Vendas para buscar')
          .Required(True)
          .Schema(SWAG_INTEGER)
        .&End
        .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TVendas)
        .&End
        .AddResponse(404, 'Vendas não encontrado(a)').&End
        .AddResponse(400, 'BadRequest')
          .Schema(TAPIError)
        .&End
        .AddResponse(500).&End
      .&End
//      .DELETE('Apagar um(a) Vendas')
//        .AddParamPath('id', 'id do(a) Vendas para deletar')
//          .Required(True)
//          .Schema(SWAG_INTEGER)
//        .&End
//        .AddResponse(404, 'Vendas não encontrado(a)').&End
//        .AddResponse(400, 'BadRequest')
//          .Schema(TAPIError)
//        .&End
//        .AddResponse(500).&End
//      .&End
    .&End
  .&End

end.
