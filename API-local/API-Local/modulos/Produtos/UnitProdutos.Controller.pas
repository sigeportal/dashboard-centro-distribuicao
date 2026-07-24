unit UnitProdutos.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json;

type
  TProdutosController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse);
    // class procedure Post(Req: THorseRequest; Res: THorseResponse);
    // class procedure Put(Req: THorseRequest; Res: THorseResponse);
    // class procedure Delete(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

{ TProdutosController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitProdutos.Model,
  UnitConstants,
  UnitTabela.Helpers;

{ class procedure TProdutosController.Delete(Req: THorseRequest; Res: THorseResponse);
  var Produtos: TProdutos;
  id: Integer;
  begin
  try
  id := Req.Params.Items['id'].ToInteger();
  Produtos := TProdutos.Create(TDatabase.Connection);
  Produtos.Apagar(id);
  Res.Send('').Status(THTTPStatus.NoContent);
  finally
  Produtos.DisposeOf;
  end;
  end; }

class procedure TProdutosController.Get(Req: THorseRequest;
  Res: THorseResponse);
var
  Produtos: TProdutos;
  aJson: TJSONArray;
  Query: iQuery;
  Filtros: TStringList;
  ParamName, ParamValue, QueryParams: string;
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
  LStockParam: string;
  LItemJSON: TJSONObject;
begin
  LMetaJSON := nil;
  LResponseJSON := nil;
  aJson := nil;
  Produtos := nil;
  Filtros := nil;
  try
    LMetaJSON := TJSONObject.Create;
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;
    Produtos := TProdutos.Create(TDatabase.Connection);
    Produtos.CriaTabela;
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
      SQLBase :=
        Format('SELECT FIRST %d SKIP %d DISTINCT PRO_CODIGO FROM PRODUTOS',
        [Limite, Pular])
    else
      SQLBase := 'SELECT DISTINCT PRO_CODIGO FROM PRODUTOS';

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
          Filtros.Add
            (Format('(PRO_NOME LIKE %0:s OR PRO_FABRICANTE LIKE %0:s OR PRO_CODBARRA LIKE %0:s)',
            [QuotedStr('%' + ParamValue + '%')]));
        end;
        Continue;
      end;

      // Parâmetro de filtragem de estado do produto
      if ParamName = 'STOCKSTATUS' then
      begin
        if not ParamValue.IsEmpty then
        begin
          LStockParam := ParamValue.ToUpper;
        end;
        Continue;
      end;

      // Adiciona filtro com LIKE para texto genérico
      if not ParamValue.IsEmpty then
        Filtros.Add(Format('%s LIKE %s',
          [ParamName, QuotedStr('%' + ParamValue + '%')]));
    end;

    // Buscar a quantidade de dados armazenados e calcula quantidade de páginas
    Query.Clear;
    // Filtra Produtos que estão sem estoque
    if LStockParam = 'SEM_ESTOQUE' then
    begin
      WhereClause := 'WHERE (PRO_QUANTIDADE <= 0) AND ';
    end
    else
    begin
      // Filtra Produtos que estão quase sem estoque
      if LStockParam = 'ACABANDO' then
      begin
        WhereClause :=
          'WHERE (PRO_QUANTIDADE > 0 AND PRO_QUANTIDADE <= PRO_QUANTIDADEM) AND ';
      end
      else
        WhereClause := 'WHERE ';
    end;

    if Filtros.Count > 0 then
    begin
      WhereClause := WhereClause + '(' + String.Join(' OR ',
        Filtros.ToStringArray) + ') AND ';
    end;

    // Ignorar produtos marcados como inativo
    WhereClause := WhereClause + 'PRO_ESTADO = ''ATIVO''';

    // Buscar a quantidade de dados armazenados usando o WHERE completo
    Query.Clear;
    Query.Open('SELECT COUNT (DISTINCT PRO_CODIGO) AS TOTAL FROM PRODUTOS ' +
      WhereClause);

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

    // Monta SQL final
    Query.Clear;
    Query.Add(SQLBase);
    Query.Add(WhereClause);
    Query.Add('ORDER BY PRO_CODIGO');
    Query.Open;

    // Monta JSON de retorno
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Produtos.BuscaDadosTabela(Query.Dataset.FieldByName('PRO_CODIGO')
        .AsInteger);
      LItemJSON := TJSONObject.ParseJSONValue(Produtos.ToJson) as TJSONObject;
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
    Produtos.DisposeOf;
    aJson.Free;
    LMetaJSON.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TProdutosController.GetForID(Req: THorseRequest;
  Res: THorseResponse);
var
  Produtos: TProdutos;
  id: Integer;
  LResponseJSON: TJSONObject;
begin
  id := Req.Params.Items['id'].ToInteger();
  Produtos := TProdutos.Create(TDatabase.Connection);
  try
    Produtos.CriaTabela;
    Produtos.BuscaDadosTabela(id);
    if (Produtos.Codigo = 0) or (Produtos.Estado <> 'ATIVO') then
      Res.Send('').Status(THTTPStatus.NotFound)
    else
    begin
      LResponseJSON := Produtos.ToJsonObject;
      try
        Res.Send<TJSONObject>(LResponseJSON);
        LResponseJSON := nil;
      finally
        LResponseJSON.Free;
      end;
    end;
  finally
    Produtos.DisposeOf;
  end;
end;

{ class procedure TProdutosController.Post(Req: THorseRequest; Res: THorseResponse);
  var Produtos: TProdutos;
  begin
  try
  Produtos := TProdutos.Create(TDatabase.Connection).fromJson<TProdutos>(Req.Body);
  Produtos.CriaTabela;
  if Produtos.Codigo = 0 then
  Produtos.Codigo := GeraCodigo('PRODUTOS', 'PRO_CODIGO');
  Produtos.SalvaNoBanco(1);
  Res.Send<TJSONObject>(Produtos.ToJsonObject);
  finally
  Produtos.DisposeOf;
  end;
  end;

  class procedure TProdutosController.Put(Req: THorseRequest; Res: THorseResponse);
  var Produtos: TProdutos;
  begin
  try
  Produtos := TProdutos.Create(TDatabase.Connection).fromJson<TProdutos>(Req.Body);
  Produtos.CriaTabela;
  Produtos.SalvaNoBanco(1);
  Res.Send<TJSONObject>(Produtos.ToJsonObject);
  finally
  Produtos.DisposeOf;
  end;
  end; }

class procedure TProdutosController.Router;
begin
  THorse.Group.Prefix('/v1').Route('/produtos').Get(Get)
  // .Post(Post)
  // .Put(Put)
    .&End.Group.Prefix('/v1').Route('/produtos/:id').Get(GetForID)
  // .Delete(Delete)
    .&End
end;

initialization

Swagger.BasePath('v1').Path('produtos').Tag('Produtos').Get('Lista Todos(as)',
  'Lista todos(as) os(as) Produtoss').AddResponse(200, 'Operação bem Sucedida')
  .Schema(TProdutos).IsArray(True).&End.AddResponse(400)
  .&End.AddResponse(500).&End.&End
{ .POST('Criar Produtos', 'Cria um(a) novo(a) Produtos')
  .AddParamBody('Dados do(a) Produtos', 'Produtos')
  .Required(True)
  .Schema(TProdutos)
  .&End
  .AddResponse(201, 'Created')
  .Schema(TProdutos)
  .&End
  .AddResponse(400, 'BadRequest')
  .Schema(TAPIError)
  .&End
  .AddResponse(500).&End
  .&End
  .PUT('Atualiza Produtos', 'Atualiza os dados de um(a) Produtos')
  .AddParamBody('Dados do(a) Produtos', 'Produtos')
  .Required(True)
  .Schema(TProdutos)
  .&End
  .AddResponse(200, 'Ok')
  .Schema(TProdutos)
  .&End
  .AddResponse(400, 'BadRequest')
  .Schema(TAPIError)
  .&End
  .AddResponse(500).&End
  .&End }
  .&End.&End.BasePath('v1').Path('produtos/{id}').Tag('Produtos')
  .Get('Obtem um(a) Produtos').AddParamPath('id',
  'Id do(a) Produtos para buscar').Required(True).Schema(SWAG_INTEGER)
  .&End.AddResponse(200, 'Operação bem Sucedida').Schema(TProdutos)
  .&End.AddResponse(404, 'Produtos não encontrado(a)').&End.AddResponse(400,
  'BadRequest').Schema(TAPIError).&End.AddResponse(500).&End.&End
{ .DELETE('Apagar um(a) Produtos')
  .AddParamPath('id', 'id do(a) Produtos para deletar')
  .Required(True)
  .Schema(SWAG_INTEGER)
  .&End
  .AddResponse(404, 'Produtos não encontrado(a)').&End
  .AddResponse(400, 'BadRequest')
  .Schema(TAPIError)
  .&End
  .AddResponse(500).&End
  .&End }
  .&End.&End

end.
