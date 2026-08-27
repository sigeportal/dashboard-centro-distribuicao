unit ConciliacaoFiscal.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json,
  DB,
  UnitConnection.Model.Interfaces,
  System.Generics.Collections;

type
  TConciliacaoFiscalGroup = class
  public
    MasterCode: Integer;
    MasterNome: string;
    EstoqueContabil: Double;
    TotalEstoqueFisicoVinculados: Double;
    GerarFiscal: string;
    Vinculados: TJSONArray;
    constructor Create;
    destructor Destroy; override;
  end;

  TConciliacaoFiscalController = class
  public
    class procedure Registrar;
    class procedure GetComparativo(Req: THorseRequest; Res: THorseResponse; Next: TProc); static;
    class procedure PostVincular(Req: THorseRequest; Res: THorseResponse; Next: TProc); static;
    class procedure PostDesvincular(Req: THorseRequest; Res: THorseResponse; Next: TProc); static;
    class procedure GetProdutosFiscais(Req: THorseRequest; Res: THorseResponse; Next: TProc); static;
  end;

implementation

uses
  UnitDatabase,
  UnitProdutos.Model,
  UnitFunctions;

{ TConciliacaoFiscalGroup }

constructor TConciliacaoFiscalGroup.Create;
begin
  inherited Create;
  MasterCode := 0;
  MasterNome := '';
  EstoqueContabil := 0.0;
  TotalEstoqueFisicoVinculados := 0.0;
  GerarFiscal := 'S';
  Vinculados := TJSONArray.Create;
end;

destructor TConciliacaoFiscalGroup.Destroy;
begin
  if Assigned(Vinculados) then
    Vinculados.Free;
  inherited Destroy;
end;

{ TConciliacaoFiscalController }

class procedure TConciliacaoFiscalController.Registrar;
begin
  THorse.Get('/v1/conciliacao/comparativo', GetComparativo);
  THorse.Post('/v1/conciliacao/vincular', PostVincular);
  THorse.Post('/v1/conciliacao/desvincular', PostDesvincular);
  THorse.Get('/v1/conciliacao/fiscais', GetProdutosFiscais);
end;

class procedure TConciliacaoFiscalController.GetComparativo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Query: iQuery;
  QueryMaster: iQuery;
  GroupsMap: TObjectDictionary<Integer, TConciliacaoFiscalGroup>;
  Group: TConciliacaoFiscalGroup;
  GroupKey: Integer;
  Cod, CodFiscal, MasterCode: Integer;
  Nome, FiscalGerar, CodBarra: string;
  Estoque, ValorV: Double;
  ResArray: TJSONArray;
  GroupObj, ItemObj: TJSONObject;
  KeysList: TList<Integer>;
  i: Integer;
  TotalEstoqueFisico, DifEstoque: Double;
begin
  GroupsMap := TObjectDictionary<Integer, TConciliacaoFiscalGroup>.Create([doOwnsValues]);
  KeysList := TList<Integer>.Create;
  ResArray := TJSONArray.Create;
  try
    Query := TDatabase.Query;
    Query.Clear;
    Query.Add('SELECT PRO_CODIGO, PRO_NOME, PRO_CODBARRA, COALESCE(PRO_VALORV, 0) AS PRO_VALORV,');
    Query.Add('COALESCE(PRO_QUANTIDADE, 0) AS PRO_QUANTIDADE,');
    Query.Add('COALESCE(PRO_COD_FISCAL, 0) AS PRO_COD_FISCAL,');
    Query.Add('COALESCE(PRO_FISCAL_GERAR, ''S'') AS PRO_FISCAL_GERAR');
    Query.Add('FROM PRODUTOS WHERE COALESCE(PRO_ESTADO, ''ATIVO'') = ''ATIVO'' ORDER BY PRO_CODIGO');
    Query.Open;

    Query.DataSet.First;
    while not Query.DataSet.Eof do
    begin
      Cod := Query.DataSet.FieldByName('PRO_CODIGO').AsInteger;
      Nome := Query.DataSet.FieldByName('PRO_NOME').AsString;
      CodBarra := Query.DataSet.FieldByName('PRO_CODBARRA').AsString;
      Estoque := Query.DataSet.FieldByName('PRO_QUANTIDADE').AsFloat;
      ValorV := Query.DataSet.FieldByName('PRO_VALORV').AsFloat;
      CodFiscal := Query.DataSet.FieldByName('PRO_COD_FISCAL').AsInteger;
      FiscalGerar := Query.DataSet.FieldByName('PRO_FISCAL_GERAR').AsString;
      if Trim(FiscalGerar) = '' then
        FiscalGerar := 'S';

      if CodFiscal > 0 then
        MasterCode := CodFiscal
      else
        MasterCode := Cod;

      if not GroupsMap.TryGetValue(MasterCode, Group) then
      begin
        Group := TConciliacaoFiscalGroup.Create;
        Group.MasterCode := MasterCode;
        GroupsMap.Add(MasterCode, Group);
        KeysList.Add(MasterCode);
      end;

      Group.TotalEstoqueFisicoVinculados := Group.TotalEstoqueFisicoVinculados + Estoque;

      ItemObj := TJSONObject.Create;
      ItemObj.AddPair('codigo', TJSONNumber.Create(Cod));
      ItemObj.AddPair('nome', Nome);
      ItemObj.AddPair('codbarra', CodBarra);
      ItemObj.AddPair('valorv', TJSONNumber.Create(ValorV));
      ItemObj.AddPair('estoqueFisico', TJSONNumber.Create(Estoque));
      ItemObj.AddPair('codFiscal', TJSONNumber.Create(CodFiscal));
      ItemObj.AddPair('fiscalGerar', FiscalGerar);
      Group.Vinculados.AddElement(ItemObj);

      Query.DataSet.Next;
    end;

    // Second pass: fill master product details
    for i := 0 to Pred(KeysList.Count) do
    begin
      GroupKey := KeysList[i];
      if GroupsMap.TryGetValue(GroupKey, Group) then
      begin
        QueryMaster := TDatabase.Query;
        QueryMaster.Clear;
        QueryMaster.Add('SELECT PRO_CODIGO, PRO_NOME, COALESCE(PRO_QUANTIDADE, 0) AS PRO_QUANTIDADE,');
        QueryMaster.Add('COALESCE(PRO_FISCAL_GERAR, ''S'') AS PRO_FISCAL_GERAR FROM PRODUTOS WHERE PRO_CODIGO = :COD');
        QueryMaster.AddParam('COD', Group.MasterCode);
        QueryMaster.Open;

        if not QueryMaster.DataSet.IsEmpty then
        begin
          Group.MasterNome := QueryMaster.DataSet.FieldByName('PRO_NOME').AsString;
          Group.EstoqueContabil := QueryMaster.DataSet.FieldByName('PRO_QUANTIDADE').AsFloat;
          Group.GerarFiscal := QueryMaster.DataSet.FieldByName('PRO_FISCAL_GERAR').AsString;
          if Trim(Group.GerarFiscal) = '' then
            Group.GerarFiscal := 'S';
        end
        else if Group.Vinculados.Count > 0 then
        begin
          ItemObj := TJSONObject(Group.Vinculados.Items[0]);
          if ItemObj.GetValue('nome') <> nil then
            Group.MasterNome := ItemObj.GetValue('nome').Value;
          Group.EstoqueContabil := Group.TotalEstoqueFisicoVinculados;
        end;

        TotalEstoqueFisico := Group.TotalEstoqueFisicoVinculados;
        DifEstoque := Group.EstoqueContabil - TotalEstoqueFisico;

        GroupObj := TJSONObject.Create;
        GroupObj.AddPair('codigoFiscal', TJSONNumber.Create(Group.MasterCode));
        GroupObj.AddPair('nomeFiscal', Group.MasterNome);
        GroupObj.AddPair('descFiscal', Group.MasterNome);
        GroupObj.AddPair('estoqueContabil', TJSONNumber.Create(Group.EstoqueContabil));
        GroupObj.AddPair('totalEstoqueFisicoVinculados', TJSONNumber.Create(TotalEstoqueFisico));
        GroupObj.AddPair('estoqueFisicoTotal', TJSONNumber.Create(TotalEstoqueFisico));
        GroupObj.AddPair('diferencaEstoque', TJSONNumber.Create(DifEstoque));
        GroupObj.AddPair('diferencaTotal', TJSONNumber.Create(DifEstoque));
        GroupObj.AddPair('gerarFiscal', Group.GerarFiscal);

        // vinculados array
        GroupObj.AddPair('vinculados', TJSONObject.ParseJSONValue(Group.Vinculados.ToJSON) as TJSONArray);
        GroupObj.AddPair('itens', TJSONObject.ParseJSONValue(Group.Vinculados.ToJSON) as TJSONArray);

        ResArray.AddElement(GroupObj);
      end;
    end;

    Res.Send<TJSONArray>(ResArray).Status(THTTPStatus.OK);
  finally
    KeysList.Free;
    GroupsMap.Free;
  end;
end;

class procedure TConciliacaoFiscalController.PostVincular(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  BodyObj: TJSONObject;
  JsonVal: TJSONValue;
  CodProduto, CodFiscal: Integer;
  Query: iQuery;
  ResObj: TJSONObject;
begin
  JsonVal := nil;
  BodyObj := nil;
  if Req.Body <> '' then
  begin
    JsonVal := TJSONObject.ParseJSONValue(Req.Body);
    if (JsonVal <> nil) and (JsonVal is TJSONObject) then
      BodyObj := TJSONObject(JsonVal);
  end;

  if BodyObj = nil then
  begin
    ResObj := TJSONObject.Create;
    ResObj.AddPair('sucesso', TJSONBool.Create(False));
    ResObj.AddPair('mensagem', 'Payload JSON invalido');
    Res.Send<TJSONObject>(ResObj).Status(THTTPStatus.BadRequest);
    Exit;
  end;

  try
    CodProduto := 0;
    CodFiscal := 0;

    if BodyObj.GetValue('codigo') <> nil then
      CodProduto := BodyObj.GetValue<Integer>('codigo')
    else if BodyObj.GetValue('pro_codigo') <> nil then
      CodProduto := BodyObj.GetValue<Integer>('pro_codigo');

    if BodyObj.GetValue('codFiscal') <> nil then
      CodFiscal := BodyObj.GetValue<Integer>('codFiscal')
    else if BodyObj.GetValue('pro_cod_fiscal') <> nil then
      CodFiscal := BodyObj.GetValue<Integer>('pro_cod_fiscal');

    if CodProduto <= 0 then
    begin
      ResObj := TJSONObject.Create;
      ResObj.AddPair('sucesso', TJSONBool.Create(False));
      ResObj.AddPair('mensagem', 'codigo do produto obrigatorio');
      Res.Send<TJSONObject>(ResObj).Status(THTTPStatus.BadRequest);
      Exit;
    end;

    Query := TDatabase.Query;
    Query.Clear;
    Query.Add('UPDATE PRODUTOS SET PRO_COD_FISCAL = :COD_FISCAL WHERE PRO_CODIGO = :CODIGO');
    Query.AddParam('COD_FISCAL', CodFiscal);
    Query.AddParam('CODIGO', CodProduto);
    Query.ExecSQL;

    ResObj := TJSONObject.Create;
    ResObj.AddPair('sucesso', TJSONBool.Create(True));
    ResObj.AddPair('mensagem', 'Produto vinculado ao fiscal com sucesso');
    ResObj.AddPair('codigo', TJSONNumber.Create(CodProduto));
    ResObj.AddPair('codFiscal', TJSONNumber.Create(CodFiscal));
    Res.Send<TJSONObject>(ResObj).Status(THTTPStatus.OK);
  finally
    if JsonVal <> nil then
      JsonVal.Free;
  end;
end;

class procedure TConciliacaoFiscalController.PostDesvincular(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  BodyObj: TJSONObject;
  JsonVal: TJSONValue;
  CodProduto: Integer;
  Query: iQuery;
  ResObj: TJSONObject;
begin
  JsonVal := nil;
  BodyObj := nil;
  if Req.Body <> '' then
  begin
    JsonVal := TJSONObject.ParseJSONValue(Req.Body);
    if (JsonVal <> nil) and (JsonVal is TJSONObject) then
      BodyObj := TJSONObject(JsonVal);
  end;

  if BodyObj = nil then
  begin
    ResObj := TJSONObject.Create;
    ResObj.AddPair('sucesso', TJSONBool.Create(False));
    ResObj.AddPair('mensagem', 'Payload JSON invalido');
    Res.Send<TJSONObject>(ResObj).Status(THTTPStatus.BadRequest);
    Exit;
  end;

  try
    CodProduto := 0;
    if BodyObj.GetValue('codigo') <> nil then
      CodProduto := BodyObj.GetValue<Integer>('codigo')
    else if BodyObj.GetValue('pro_codigo') <> nil then
      CodProduto := BodyObj.GetValue<Integer>('pro_codigo');

    Query := TDatabase.Query;
    Query.Clear;
    Query.Add('UPDATE PRODUTOS SET PRO_COD_FISCAL = 0 WHERE PRO_CODIGO = :CODIGO');
    Query.AddParam('CODIGO', CodProduto);
    Query.ExecSQL;

    ResObj := TJSONObject.Create;
    ResObj.AddPair('sucesso', TJSONBool.Create(True));
    ResObj.AddPair('mensagem', 'Produto desvinculado com sucesso');
    Res.Send<TJSONObject>(ResObj).Status(THTTPStatus.OK);
  finally
    if JsonVal <> nil then
      JsonVal.Free;
  end;
end;

class procedure TConciliacaoFiscalController.GetProdutosFiscais(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Query: iQuery;
  ResArray: TJSONArray;
  Obj: TJSONObject;
  LBusca: string;
begin
  ResArray := TJSONArray.Create;
  try
    LBusca := '';
    if Req.Query.ContainsKey('busca') then
      LBusca := Trim(Req.Query.Items['busca'])
    else if Req.Query.ContainsKey('termo') then
      LBusca := Trim(Req.Query.Items['termo']);

    Query := TDatabase.Query;
    Query.Clear;
    Query.Add('SELECT PRO_CODIGO, PRO_NOME, PRO_CODBARRA, PRO_NCM, PRO_CFOP, PRO_CEST,');
    Query.Add('COALESCE(PRO_QUANTIDADE, 0) AS PRO_QUANTIDADE,');
    Query.Add('COALESCE(PRO_VALORV, 0) AS PRO_VALORV');
    Query.Add('FROM PRODUTOS');
    Query.Add('WHERE COALESCE(PRO_ESTADO, ''ATIVO'') = ''ATIVO''');
    Query.Add('AND (COALESCE(PRO_COD_FISCAL, 0) = 0 OR PRO_COD_FISCAL = PRO_CODIGO)');
    if LBusca <> '' then
    begin
      Query.Add('AND (UPPER(PRO_NOME) LIKE :BUSCA OR PRO_CODBARRA LIKE :BUSCA2');
      if StrToIntDef(LBusca, 0) > 0 then
        Query.Add('OR PRO_CODIGO = ' + LBusca);
      Query.Add(')');
      Query.AddParam('BUSCA', '%' + UpperCase(LBusca) + '%');
      Query.AddParam('BUSCA2', '%' + LBusca + '%');
    end;
    Query.Add('ORDER BY PRO_CODIGO');
    Query.Open;

    Query.DataSet.First;
    while not Query.DataSet.Eof do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('codigo', TJSONNumber.Create(Query.DataSet.FieldByName('PRO_CODIGO').AsInteger));
      Obj.AddPair('nome', Query.DataSet.FieldByName('PRO_NOME').AsString);
      Obj.AddPair('codbarra', Query.DataSet.FieldByName('PRO_CODBARRA').AsString);
      Obj.AddPair('ncm', Query.DataSet.FieldByName('PRO_NCM').AsString);
      Obj.AddPair('cfop', Query.DataSet.FieldByName('PRO_CFOP').AsString);
      Obj.AddPair('cest', Query.DataSet.FieldByName('PRO_CEST').AsString);
      Obj.AddPair('quantidade', TJSONNumber.Create(Query.DataSet.FieldByName('PRO_QUANTIDADE').AsFloat));
      Obj.AddPair('valorv', TJSONNumber.Create(Query.DataSet.FieldByName('PRO_VALORV').AsFloat));
      ResArray.AddElement(Obj);
      Query.DataSet.Next;
    end;

    Res.Send<TJSONArray>(ResArray).Status(THTTPStatus.OK);
  finally
  end;
end;

initialization
  Swagger
    .BasePath('v1')
      .Path('conciliacao/comparativo')
        .Tag('ConciliacaoFiscal')
        .GET('Comparativo Fiscal vs Fisico', 'Relatorio comparativo de estoque contabilidade fiscal versus estoque fisico real')
          .AddResponse(200, 'Operacao bem Sucedida')
          .&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
      .&End
    .&End
    .BasePath('v1')
      .Path('conciliacao/fiscais')
        .Tag('ConciliacaoFiscal')
        .GET('Produtos Fiscais Mestre', 'Lista produtos que atuam como mestres na base fiscal')
          .AddResponse(200, 'Operacao bem Sucedida')
          .&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
      .&End
    .&End
    .BasePath('v1')
      .Path('conciliacao/vincular')
        .Tag('ConciliacaoFiscal')
        .POST('Vincular Produto ao Fiscal', 'Vincula o produto ao codigo mestre fiscal (PRO_COD_FISCAL)')
          .AddResponse(200, 'Ok')
          .&End
          .AddResponse(400, 'BadRequest').&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
      .&End
    .&End
    .BasePath('v1')
      .Path('conciliacao/desvincular')
        .Tag('ConciliacaoFiscal')
        .POST('Desvincular Produto do Fiscal', 'Remove o vinculo fiscal do produto, tornando-o independente')
          .AddResponse(200, 'Ok')
          .&End
          .AddResponse(400, 'BadRequest').&End
          .AddResponse(500, 'InternalServerError').&End
        .&End
      .&End
    .&End;

end.
