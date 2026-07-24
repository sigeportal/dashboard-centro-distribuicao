unit UnitClientes.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json;

type
  TClientesController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse);
    class procedure GetValorDevedorForID(Req: THorseRequest; Res: THorseResponse);
    // class procedure Post(Req: THorseRequest; Res: THorseResponse);
    // class procedure Put(Req: THorseRequest; Res: THorseResponse);
    // class procedure Delete(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

{ TClientesController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitClientes.Model,
  UnitConstants,
  UnitTabela.Helpers;

{ class procedure TClientesController.Delete(Req: THorseRequest; Res: THorseResponse);
  var Clientes: TClientes;
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
  end; }

class procedure TClientesController.Get(Req: THorseRequest;
  Res: THorseResponse);
var
  Clientes: TClientes;
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
  LItemJSON: TJSONObject;
  LTotalRegistros: Integer;
  LPaginas: Integer;
begin
  LMetaJSON := nil;
  LResponseJSON := nil;
  aJson := nil;
  Clientes := nil;
  Filtros := nil;
  try
    LMetaJSON := TJSONObject.Create;
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;
    Clientes := TClientes.Create(TDatabase.Connection);
    Clientes.CriaTabela;
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
        Format('SELECT FIRST %d SKIP %d DISTINCT cl.CLI_CODIGO, c.CID_NOME'
        + ' FROM CLIENTES cl'
        + ' INNER JOIN CIDADES c ON c.CID_CODIGO = cl.CLI_CID', [Limite, Pular])
    else
      SQLBase := 'SELECT DISTINCT cl.CLI_CODIGO, c.CID_NOME'
        + ' FROM CLIENTES cl'
        + ' INNER JOIN CIDADES c ON c.CID_CODIGO = cl.CLI_CID';

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
            (Format('(CLI_NOME LIKE %0:s OR CLI_CELULAR LIKE %0:s OR CLI_EMAIL LIKE %0:s OR CLI_CIDADE LIKE %0:s OR CLI_UF LIKE %0:s)',
            [QuotedStr('%' + ParamValue + '%')]));
        end;
        Continue;
      end;

      // Adiciona filtro com LIKE para texto genérico
      if not ParamValue.IsEmpty then
        Filtros.Add(Format('%s LIKE %s',
          [ParamName, QuotedStr('%' + ParamValue + '%')]));
    end;

    // Monta a cláusula WHERE unificada antes de contar os registros e selecionar
    WhereClause := '';
    if Filtros.Count > 0 then
    begin
      WhereClause := 'WHERE ' + String.Join(' OR ', Filtros.ToStringArray);
    end;

    // Buscar a quantidade de dados armazenados usando o WHERE completo
    Query.Clear;
    Query.Open('SELECT COUNT (DISTINCT CLI_CODIGO) AS TOTAL FROM CLIENTES ' +
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

    // Monta SQL final reutilizando a mesma cláusula WHERE
    Query.Clear;
    Query.Add(SQLBase);
    if not WhereClause.IsEmpty then
    begin
      Query.Add(WhereClause);
    end;
    Query.Add('ORDER BY CLI_CODIGO');
    Query.Open;

    // Monta JSON de retorno
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Clientes.BuscaDadosTabela(Query.Dataset.FieldByName('CLI_CODIGO')
        .AsInteger);

      LItemJSON := TJSONObject.ParseJSONValue(Clientes.ToJson) as TJSONObject;
      try
        if not Query.Dataset.FieldByName('CID_NOME').IsNull then
          LItemJSON.AddPair('cidade',
            Query.Dataset.FieldByName('CID_NOME').AsString)
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
    Clientes.DisposeOf;
    aJson.Free;
    LMetaJSON.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TClientesController.GetForID(Req: THorseRequest;
  Res: THorseResponse);
var
  Clientes: TClientes;
  id: Integer;
  LResponseJSON: TJSONObject;
begin
  id := Req.Params.Items['id'].ToInteger();
  Clientes := TClientes.Create(TDatabase.Connection);
  try
    Clientes.CriaTabela;
    Clientes.BuscaDadosTabela(id);
    if Clientes.Codigo = 0 then
      Res.Send('').Status(THTTPStatus.NotFound)
    else
    begin
      LResponseJSON := Clientes.ToJsonObject;
      try
        Res.Send<TJSONObject>(LResponseJSON);
        LResponseJSON := nil;
      finally
        LResponseJSON.Free;
      end;
    end;
  finally
    Clientes.DisposeOf;
  end;
end;

class procedure TClientesController.GetValorDevedorForID(Req: THorseRequest;
  Res: THorseResponse);
var
  id: Integer;
  Query: iQuery;
  LItemJSON: TJSONObject;
  LValor: Double;
begin
  Query := TDatabase.Query;
  LItemJSON := nil;
  try
    id := Req.Params.Items['id'].ToInteger();

    // Verifica se o cliente existe
    Query.Add('SELECT CLI_CODIGO FROM CLIENTES WHERE CLI_CODIGO = :CLIENTE');
    Query.AddParam('CLIENTE', id);
    Query.Open();
    if Query.Dataset.IsEmpty then
    begin
      Res.Send('').Status(THTTPStatus.NotFound);
      Exit;
    end;

    // Obtem o valor devedor
    Query.Clear;
    Query.Add('SELECT SUM(r.REC_VALOR + r.REC_JUROS - r.REC_DESCONTOS) AS VALOR'
        + ' FROM FATURAMENTOS f'
        + ' JOIN RECEBIMENTOS r ON f.FAT_CODIGO = r.REC_FAT AND (r.REC_SITUACAO >= 0 AND r.REC_SITUACAO < 3) AND r.REC_ESTADO < 3'
        + ' WHERE f.FAT_CLI = :CLIENTE');
    Query.AddParam('CLIENTE', id);
    Query.Open();

    if not Query.Dataset.FieldByName('VALOR').IsNull then
      LValor := Query.Dataset.FieldByName('VALOR').AsFloat
    else
      LValor := 0;

    LItemJSON := TJSONObject.Create;
    LItemJSON.AddPair('vlr_devedor', TJSONNumber.Create(LValor));
    Res.Send<TJSONObject>(LItemJSON);
    LItemJSON := nil;
  finally
    LItemJSON.Free;
  end;
end;

{ class procedure TClientesController.Post(Req: THorseRequest; Res: THorseResponse);
  var Clientes: TClientes;
  begin
  try
  Clientes := TClientes.Create(TDatabase.Connection).fromJson<TClientes>(Req.Body);
  Clientes.CriaTabela;
  if Clientes.Codigo = 0 then
  Clientes.Codigo := GeraCodigo('CLIENTES', 'CLI_CODIGO');
  Clientes.SalvaNoBanco(1);
  Res.Send<TJSONObject>(Clientes.ToJsonObject);
  finally
  Clientes.DisposeOf;
  end;
  end; }

{ class procedure TClientesController.Put(Req: THorseRequest; Res: THorseResponse);
  var Clientes: TClientes;
  begin
  try
  Clientes := TClientes.Create(TDatabase.Connection).fromJson<TClientes>(Req.Body);
  Clientes.CriaTabela;
  Clientes.SalvaNoBanco(1);
  Res.Send<TJSONObject>(Clientes.ToJsonObject);
  finally
  Clientes.DisposeOf;
  end;
  end; }

class procedure TClientesController.Router;
begin
  THorse.Group.Prefix('/v1').Route('/clientes').Get(Get)
  // .Post(Post)
  // .Put(Put)
    .&End.Group.Prefix('/v1').Route('/clientes/:id').Get(GetForID)
  // .Delete(Delete)
    .&End.Group.Prefix('/v1').Route('/clientes/:id/valor-devedor').Get(GetValorDevedorForID)
    .&End;
end;

initialization

Swagger.BasePath('v1').Path('clientes').Tag('Clientes').Get('Lista Todos(as)',
  'Lista todos(as) os(as) Clientes').AddResponse(200, 'Operação bem Sucedida')
  .Schema(TClientes).IsArray(True).&End.AddResponse(400)
  .&End.AddResponse(500).&End.&End
{ .POST('Criar Clientes', 'Cria um(a) novo(a) Clientes')
  .AddParamBody('Dados do(a) Clientes', 'Clientes')
  .Required(True)
  .Schema(TClientes)
  .&End
  .AddResponse(201, 'Created')
  .Schema(TClientes)
  .&End
  .AddResponse(400, 'BadRequest')
  .Schema(TAPIError)
  .&End
  .AddResponse(500).&End
  .&End
  .PUT('Atualiza Clientes', 'Atualiza os dados de um(a) Clientes')
  .AddParamBody('Dados do(a) Clientes', 'Clientes')
  .Required(True)
  .Schema(TClientes)
  .&End
  .AddResponse(200, 'Ok')
  .Schema(TClientes)
  .&End
  .AddResponse(400, 'BadRequest')
  .Schema(TAPIError)
  .&End
  .AddResponse(500).&End
  .&End }
  .&End.&End.BasePath('v1').Path('clientes/{id}').Tag('Clientes')
  .Get('Obtem um(a) Clientes').AddParamPath('id',
  'Id do(a) Clientes para buscar').Required(True).Schema(SWAG_INTEGER)
  .&End.AddResponse(200, 'Operação bem Sucedida').Schema(TClientes)
  .&End.AddResponse(404, 'Clientes não encontrado(a)').&End.AddResponse(400,
  'BadRequest').Schema(TAPIError).&End.AddResponse(500).&End.&End
  .&End.&End.BasePath('v1').Path('clientes/{id}/valor-devedor').Tag('Clientes')
  .Get('Obtem valor devedor de um cliente').AddParamPath('id',
  'Id do(a) Clientes para buscar').Required(True).Schema(SWAG_INTEGER)
  .&End.AddResponse(200, 'Operação bem Sucedida')
  .&End.AddResponse(404, 'Clientes não encontrado(a)').&End.AddResponse(400,
  'BadRequest').Schema(TAPIError).&End.AddResponse(500).&End.&End
{ .DELETE('Apagar um(a) Clientes')
  .AddParamPath('id', 'id do(a) Clientes para deletar')
  .Required(True)
  .Schema(SWAG_INTEGER)
  .&End
  .AddResponse(404, 'Clientes não encontrado(a)').&End
  .AddResponse(400, 'BadRequest')
  .Schema(TAPIError)
  .&End
  .AddResponse(500).&End
  .&End }
  .&End.&End

end.
