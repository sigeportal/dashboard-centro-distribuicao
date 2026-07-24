unit UnitDashboard.Controller;

interface

uses
  Horse,
  Horse.Commons,
  Horse.GBSwagger,
  Classes,
  SysUtils,
  System.Json;

type
  TDashboardClientesCidade = class
  private
    Fcidade: string;
    Fclientes: Integer;
  public
    property cidade: string read Fcidade write Fcidade;
    property clientes: Integer read Fclientes write Fclientes;
  end;

  TDashboardProdutosEstoque = class
  private
    Fnome: string;
    Ffabricante: string;
    Fquantidade: Double;
    Fvalorv: Double;
  public
    property nome: string read Fnome write Fnome;
    property fabricante: string read Ffabricante write Ffabricante;
    property quantidade: Double read Fquantidade write Fquantidade;
    property valorv: Double read Fvalorv write Fvalorv;
  end;

  TDashboardMovimentacoes = class
  private
    Fdata: string;
    Fcredito: Double;
    Fdebito: Double;
  public
    property data: string read Fdata write Fdata;
    property credito: Double read Fcredito write Fcredito;
    property debito: Double read Fdebito write Fdebito;
  end;

  TDashboardRecebimentosStatus = class
  private
    Fdata: string;
    Fvalor: Double;
  public
    property data: string read Fdata write Fdata;
    property valor: Double read Fvalor write Fvalor;
  end;

  TDashboardVendasData = class
  private
    Fdata: string;
    Fvalor: Double;
    Fvalor_alt: Double;
    Fquantidade: Integer;
  public
    property data: string read Fdata write Fdata;
    property valor: Double read Fvalor write Fvalor;
    property valor_alt: Double read Fvalor_alt write Fvalor_alt;
    property quantidade: Integer read Fquantidade write Fquantidade;
  end;

  TDashboardTiposPagamentos = class
  private
    Ftipo_pagamento: string;
    Fvalor: Double;
  public
    property tipo_pagamento: string read Ftipo_pagamento write Ftipo_pagamento;
    property valor: Double read Fvalor write Fvalor;
  end;

  TDashboardVendasDiariasHora = class
  private
    Fhora: string;
    Fvalor: Double;
  public
    property hora: string read Fhora write Fhora;
    property valor: Double read Fvalor write Fvalor;
  end;

  TDashboardController = class
    class procedure Router;
    class procedure ClientesCidade(Req: THorseRequest; Res: THorseResponse);
    class procedure Movimentacoes(Req: THorseRequest; Res: THorseResponse);
    class procedure DespesasPorTipoPagamento(Req: THorseRequest; Res: THorseResponse);
    class procedure LucroVendasPorGrupo(Req: THorseRequest; Res: THorseResponse);
//    class procedure OsLucroServico(Req: THorseRequest; Res: THorseResponse);
//    class procedure RecebimentosStatus(Req: THorseRequest; Res: THorseResponse);
    class procedure VendasDiarias(Req: THorseRequest; Res: THorseResponse);
    class procedure VendasDiariasHora(Req: THorseRequest; Res: THorseResponse);
    class procedure OsDiarias(Req: THorseRequest; Res: THorseResponse);
    class procedure VendasPorMargemLucro(Req: THorseRequest; Res: THorseResponse);
    class procedure OsMargemLucro(Req: THorseRequest; Res: THorseResponse);
    class procedure TiposPagamentosVendas(Req: THorseRequest; Res: THorseResponse);
    class procedure TiposPagamentosCompras(Req: THorseRequest; Res: THorseResponse);
    class procedure TiposPagamentosRecebimentos(Req: THorseRequest; Res: THorseResponse);
    class procedure TiposPagamentosPagamentos(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase, UnitVenEst.Model;

class procedure TDashboardController.ClientesCidade(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem: TJSONObject;
  Query: iQuery;
begin
  LResponseJSON := nil;
  aJson := nil;
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    Query.Open
      ('SELECT CID_NOME as cidade, COUNT(CLI_CODIGO) as clientes FROM CLIENTES cli'
      + ' INNER JOIN CIDADES cid ON cli.CLI_CID = cid.CID_CODIGO' +
      ' WHERE CLI_CID IS NOT NULL GROUP BY CID_NOME ORDER BY 2 DESC');

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('cidade').IsNull then
          LItem.AddPair('cidade', Query.Dataset.FieldByName('cidade').AsString)
        else
          LItem.AddPair('cidade', '');
        LItem.AddPair('clientes',
          TJSONNumber.Create(Query.Dataset.FieldByName('clientes').AsInteger));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TDashboardController.DespesasPorTipoPagamento(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem, LMetaJSON: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
  HasDateFilter: Boolean;
begin
  LResponseJSON := nil;
  aJson := nil;
  LMetaJSON := nil;
  StartDateParam := '';
  EndDateParam := '';
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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
    end;

    HasDateFilter := (not StartDateParam.IsEmpty) and (not EndDateParam.IsEmpty);

    Query.Clear();
    Query.Add('SELECT');
    Query.Add('    TIPO_OPERACAO,');
    Query.Add('    SUM(VALORPG) AS VALOR,');
    Query.Add('    FORMA_PAGTO AS TIPO_PAGAMENTO');
    Query.Add('FROM (');

    // 1. DESPESAS
    Query.Add('    SELECT');
    Query.Add('        ''DESPESA'' AS TIPO_OPERACAO,');
    Query.Add('        (PP_DINHEIRO + PP_CHEQUE) AS VALORPG,');
    Query.Add('        TP_DESCRICAO AS FORMA_PAGTO');
    Query.Add('    FROM SUB_DES, CUSTOS, PAGAMENTOS, FATURAMENTO2, PAG_PGM, TIPO_PGM');
    Query.Add('    WHERE SUD_ESTADO = ''ATIVO'' AND CUST_SUD = SUD_CODIGO AND CUST_FAT2 = FAT2_CODIGO AND FAT2_CODIGO = PAG_FAT2');
    Query.Add('    AND PAG_CODIGO = PP_PAG AND PAG_ESTADO = 3 AND (PAG_SITUACAO >= 0 AND PAG_SITUACAO < 3) AND CUST_TIPO = ''D''');
    Query.Add('    AND TP_CODIGO = PAG_CON');
    if HasDateFilter then
      Query.Add('    AND PP_DATAPGM BETWEEN :DATA1 AND :DATA2');

    Query.Add('    UNION ALL');

    // 2. CUSTOS
    Query.Add('    SELECT');
    Query.Add('        ''CUSTO'' AS TIPO_OPERACAO,');
    Query.Add('        (PP_DINHEIRO + PP_CHEQUE) AS VALORPG,');
    Query.Add('        TP_DESCRICAO AS FORMA_PAGTO');
    Query.Add('    FROM SUB_CUS, CUSTOS, PAGAMENTOS, FATURAMENTO2, PAG_PGM, TIPO_PGM');
    Query.Add('    WHERE CUST_SUD = SUC_CODIGO AND CUST_FAT2 = FAT2_CODIGO AND FAT2_CODIGO = PAG_FAT2');
    Query.Add('    AND PAG_CODIGO = PP_PAG AND PAG_ESTADO = 3 AND (PAG_SITUACAO >= 0 AND PAG_SITUACAO < 3) AND CUST_TIPO = ''C''');
    Query.Add('    AND TP_CODIGO = PAG_CON');
    if HasDateFilter then
      Query.Add('    AND PP_DATAPGM BETWEEN :DATA1 AND :DATA2');

    Query.Add('    UNION ALL');

    // 3. IMPOSTOS
    Query.Add('    SELECT');
    Query.Add('        ''IMPOSTO'' AS TIPO_OPERACAO,');
    Query.Add('        (PP_DINHEIRO + PP_CHEQUE) AS VALORPG,');
    Query.Add('        TP_DESCRICAO AS FORMA_PAGTO');
    Query.Add('    FROM IMPOSTOS, PAGAMENTOS, FATURAMENTO2, PAG_PGM, TRIBUTACOES, TIPO_PGM');
    Query.Add('    WHERE TRI_IMP = IMP_CODIGO AND TRI_FAT2 = FAT2_CODIGO AND FAT2_CODIGO = PAG_FAT2 AND PAG_CODIGO = PP_PAG AND PAG_ESTADO = 3');
    Query.Add('    AND TP_CODIGO = PAG_CON AND (PAG_SITUACAO >= 0 AND PAG_SITUACAO < 3)');
    if HasDateFilter then
      Query.Add('    AND PP_DATAPGM BETWEEN :DATA1 AND :DATA2');

    Query.Add('    UNION ALL');

    // 4. COMPRAS
    Query.Add('    SELECT');
    Query.Add('        ''COMPRA'' AS TIPO_OPERACAO,');
    Query.Add('        (PP_DINHEIRO + PP_CHEQUE) AS VALORPG,');
    Query.Add('        TP_DESCRICAO AS FORMA_PAGTO');
    Query.Add('    FROM FORNECEDORES, PAGAMENTOS, FATURAMENTO2, PAG_PGM, COMPRAS, TIPO_PGM');
    Query.Add('    WHERE COM_FOR = FOR_CODIGO AND COM_FAT2 = FAT2_CODIGO AND FAT2_CODIGO = PAG_FAT2 AND PAG_CODIGO = PP_PAG AND PAG_ESTADO = 3');
    Query.Add('    AND TP_CODIGO = PAG_CON AND (PAG_SITUACAO >= 0 AND PAG_SITUACAO < 3)');
    if HasDateFilter then
      Query.Add('    AND PP_DATAPGM BETWEEN :DATA1 AND :DATA2');

    Query.Add('    UNION ALL');

    // 5. LANÇAMENTOS RECEITA/CUSTO
    Query.Add('    SELECT');
    Query.Add('        ''LANCAMENTO REC CUSTO'' AS TIPO_OPERACAO,');
    Query.Add('        (PP_DINHEIRO + PP_CHEQUE) AS VALORPG,');
    Query.Add('        TP_DESCRICAO AS FORMA_PAGTO');
    Query.Add('    FROM FORNECEDORES, PAGAMENTOS, FATURAMENTO2, PAG_PGM, LANCAMENTO_REC_CUS, TIPO_PGM');
    Query.Add('    WHERE LRC_CLI_FOR = FOR_CODIGO AND LRC_FAT2 = FAT2_CODIGO AND FAT2_CODIGO = PAG_FAT2 AND PAG_CODIGO = PP_PAG AND PAG_ESTADO = 3');
    Query.Add('    AND TP_CODIGO = PAG_CON AND (PAG_SITUACAO >= 0 AND PAG_SITUACAO < 3)');
    if HasDateFilter then
      Query.Add('    AND PP_DATAPGM BETWEEN :DATA1 AND :DATA2');

    Query.Add('    UNION ALL');

    // 6. FRETES
    Query.Add('    SELECT');
    Query.Add('        ''FRETE'' AS TIPO_OPERACAO,');
    Query.Add('        (PP_DINHEIRO + PP_CHEQUE) AS VALORPG,');
    Query.Add('        TP_DESCRICAO AS FORMA_PAGTO');
    Query.Add('    FROM TRANSPORTADORAS, PAGAMENTOS, FATURAMENTO2, PAG_PGM, FRETES, TIPO_PGM');
    Query.Add('    WHERE FRE_TRA = TRA_CODIGO AND FRE_FAT2 = FAT2_CODIGO AND FAT2_CODIGO = PAG_FAT2 AND PAG_CODIGO = PP_PAG AND PAG_ESTADO = 3');
    Query.Add('    AND TP_CODIGO = PAG_CON AND (PAG_SITUACAO >= 0 AND PAG_SITUACAO < 3)');
    if HasDateFilter then
      Query.Add('    AND PP_DATAPGM BETWEEN :DATA1 AND :DATA2');

    Query.Add('    UNION ALL');

    // 7. EMPRÉSTIMOS / FINANCIAMENTOS
    Query.Add('    SELECT');
    Query.Add('        ''EMPRESTIMO'' AS TIPO_OPERACAO,');
    Query.Add('        (PP_DINHEIRO + PP_CHEQUE) AS VALORPG,');
    Query.Add('        TP_DESCRICAO AS FORMA_PAGTO');
    Query.Add('    FROM FINANCIAMENTOS, PAGAMENTOS, FATURAMENTO2, PAG_PGM, TIPO_PGM');
    Query.Add('    WHERE FIN_FAT2 = FAT2_CODIGO AND FAT2_CODIGO = PAG_FAT2 AND PAG_CODIGO = PP_PAG AND PAG_ESTADO = 3');
    Query.Add('    AND TP_CODIGO = PAG_CON AND (PAG_SITUACAO >= 0 AND PAG_SITUACAO < 3)');
    if HasDateFilter then
      Query.Add('    AND PP_DATAPGM BETWEEN :DATA1 AND :DATA2');

    Query.Add('    UNION ALL');

    // 8. FOLHA DE PAGAMENTO
    Query.Add('    SELECT');
    Query.Add('        ''FOLHA PAGAMENTO'' AS TIPO_OPERACAO,');
    Query.Add('        FOL_VALORSAL AS VALORPG,');
    Query.Add('        TP_DESCRICAO AS FORMA_PAGTO');
    Query.Add('    FROM FOLHA_PAGAMENTOS, FUNCIONARIOS , FATURAMENTO2, PAGAMENTOS, TIPO_PGM');
    Query.Add('    WHERE FOL_FUN = FUN_CODIGO AND FOL_ESTADO = ''ATIVO'' AND FOL_FAT2 = FAT2_CODIGO');
    Query.Add('    AND PAG_FAT2 = FOL_FAT2 AND TP_CODIGO = PAG_CON');
    if HasDateFilter then
      Query.Add('    AND FOL_VENCIMENTO BETWEEN :DATA1 AND :DATA2');

    Query.Add('    UNION ALL');

    // 9. LANÇAMENTOS DIVERSOS
    Query.Add('    SELECT');
    Query.Add('        ''LANCAMENTO DIVERSO'' AS TIPO_OPERACAO,');
    Query.Add('        (PP_DINHEIRO + PP_CHEQUE) AS VALORPG,');
    Query.Add('        TP_DESCRICAO AS FORMA_PAGTO');
    Query.Add('    FROM LANCAMENTO_DIV, PAGAMENTOS, FATURAMENTO2, PAG_PGM, TIPO_PGM');
    Query.Add('    WHERE LD_FAT2 = FAT2_CODIGO AND FAT2_CODIGO = PAG_FAT2 AND PAG_CODIGO = PP_PAG AND PAG_ESTADO = 3');
    Query.Add('    AND TP_CODIGO = PAG_CON AND (PAG_SITUACAO >= 0 AND PAG_SITUACAO < 3)');
    if HasDateFilter then
      Query.Add('    AND PP_DATAPGM BETWEEN :DATA1 AND :DATA2');

    Query.Add(')');
    Query.Add('GROUP BY TIPO_OPERACAO, FORMA_PAGTO');
    Query.Add('ORDER BY 2 DESC;');

    // Passa parâmetros de data se houver filtro ativo
    if HasDateFilter then
    begin
      Query.AddParam('DATA1', StartDateParam);
      Query.AddParam('DATA2', EndDateParam);
    end;

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('tipo_operacao').IsNull then
          LItem.AddPair('tipo_operacao', Query.Dataset.FieldByName('tipo_operacao').AsString)
        else
          LItem.AddPair('tipo_operacao', '');

        if not Query.Dataset.FieldByName('tipo_pagamento').IsNull then
          LItem.AddPair('tipo_pagamento', Query.Dataset.FieldByName('tipo_pagamento').AsString)
        else
          LItem.AddPair('tipo_pagamento', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));

        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
    LMetaJSON.Free;
  end;
end;

class procedure TDashboardController.LucroVendasPorGrupo(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
  VenEst : TVenEst;
begin
  // Cria VEN_EST
  try
    VenEst := TVenEst.Create(TDatabase.Connection);
    VenEst.CriaTabela;
  finally
    VenEst.DisposeOf;
  end;

  LResponseJSON := nil;
  aJson := nil;
  StartDateParam := '';
  EndDateParam := '';
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    if StartDateParam.IsEmpty then
      StartDateParam := '1900-01-01';
    if EndDateParam.IsEmpty then
      EndDateParam := '2100-12-31';

    Query.Add('SELECT G1_NOME NOME, SUM(VE.VE_VALOR) AS VALOR, SUM(VE.VE_LUCRO) AS LUCRO'
              + ' FROM VENDAS V, VEN_EST VE, PRODUTOS P, GRUPOS, GRUPO_1'
              + ' WHERE V.VEN_CODIGO = VE.VE_VEN AND VE.VE_PRO = P.PRO_CODIGO AND GRU_CODIGO = P.PRO_GRU AND V.VEN_DEVOLUCAO_P <> ''S'''
              + ' AND G1_CODIGO = GRU_G1 AND V.VEN_DATAC = ''01/01/1900'' AND V.VEN_DATA BETWEEN :DATA1 AND :DATA2 AND VE_ESTADO = ''I'''
              + ' GROUP BY G1_NOME');
    Query.AddParam('DATA1', StartDateParam);
    Query.AddParam('DATA2', EndDateParam);
    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        LItem.AddPair('nome', Query.DataSet.FieldByName('nome').AsString);
        LItem.AddPair('valor',
            TJSONNumber.Create(Query.DataSet.FieldByName('valor').AsFloat));
        LItem.AddPair('lucro',
            TJSONNumber.Create(Query.DataSet.FieldByName('lucro').AsFloat));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TDashboardController.Movimentacoes(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  StartDateParam := '';
  EndDateParam := '';
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    if StartDateParam.IsEmpty then
      StartDateParam := '1900-01-01';
    if EndDateParam.IsEmpty then
      EndDateParam := '2100-12-31';

    Query.Add(
      'SELECT CAST(MOV_DATA AS DATE) AS data, SUM(COALESCE(MOV_CREDITO, 0)) as credito, SUM(COALESCE(MOV_DEBITO, 0)) as debito FROM MOVIMENTACOES WHERE MOV_DATA BETWEEN :DATE1 and :DATE2 GROUP BY 1 ORDER BY 1');
    Query.AddParam('DATE1', StartDateParam);
    Query.AddParam('DATE2', EndDateParam);
    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('data').IsNull then
          LItem.AddPair('data', FormatDateTime('yyyy-mm-dd',
            Query.Dataset.FieldByName('data').AsDateTime))
        else
          LItem.AddPair('data', '');

        LItem.AddPair('credito',
          TJSONNumber.Create(Query.Dataset.FieldByName('credito').AsFloat));
        LItem.AddPair('debito',
          TJSONNumber.Create(Query.Dataset.FieldByName('debito').AsFloat));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
  end;
end;

//class procedure TDashboardController.RecebimentosStatus(Req: THorseRequest;
//  Res: THorseResponse);
//var
//  aJson: TJSONArray;
//  LResponseJSON, LItem: TJSONObject;
//  Query: iQuery;
//  QueryParams, ParamName, ParamValue: string;
//  Filtros: TStringList;
//  StartDateParam, EndDateParam: string;
//begin
//  LResponseJSON := TJSONObject.Create;
//  aJson := TJSONArray.Create;
//  Query := TDatabase.Query;
//
//  // Monta filtros dinamicos
//  for QueryParams in Req.Query.Dictionary.Keys do
//  begin
//    ParamName := QueryParams.ToUpper;
//    ParamValue := Req.Query.Items[QueryParams].Replace('''', '');
//
//    // Ignora parâmetros de controle
//    if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
//      Continue;
//
//    // Data inicial de filtragem
//    if ParamName = 'STARTDATE' then
//    begin
//      if not ParamValue.IsEmpty then
//      begin
//        StartDateParam := ParamValue;
//      end;
//      Continue;
//    end;
//
//    // Data final de filtragem
//    if ParamName = 'ENDDATE' then
//    begin
//      if not ParamValue.IsEmpty then
//      begin
//        EndDateParam := ParamValue;
//      end;
//      Continue;
//    end;
//
//  end;
//
//  if StartDateParam.IsEmpty then
//    StartDateParam := '1900-01-01';
//  if EndDateParam.IsEmpty then
//    EndDateParam := '2100-12-31';
//
//  Query.Add(
//    'SELECT CAST(p.RP_DATAPGM AS DATE) AS data, SUM(COALESCE(r.REC_VALOR, 0)) as valor FROM RECEBIMENTOS r INNER JOIN REC_PGM p ON p.RP_REC = r.REC_CODIGO WHERE p.RP_DATAPGM BETWEEN :DATE1 and :DATE2 GROUP BY 1 ORDER BY 1');
//  Query.AddParam('DATE1', StartDateParam);
//  Query.AddParam('DATE2', EndDateParam);
//  Query.Open();
//
//  Query.Dataset.First;
//  while not Query.Dataset.Eof do
//  begin
//    LItem := TJSONObject.Create;
//    if not Query.Dataset.FieldByName('data').IsNull then
//      LItem.AddPair('data', FormatDateTime('yyyy-mm-dd',
//        Query.Dataset.FieldByName('data').AsDateTime))
//    else
//      LItem.AddPair('data', '');
//
//    LItem.AddPair('valor', TJSONNumber.Create(Query.Dataset.FieldByName('valor')
//      .AsFloat));
//    aJson.Add(LItem);
//    Query.Dataset.Next;
//  end;
//
//  LResponseJSON.AddPair('data', aJson);
//  Res.Send<TJSONObject>(LResponseJSON);
//end;

class procedure TDashboardController.TiposPagamentosCompras(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem, LMetaJSON: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  LMetaJSON := nil;
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    Query.Clear();
    Query.Add('SELECT tp.TP_DESCRICAO AS tipo_pagamento, SUM(COALESCE(pp.PP_VALOR, 0) + COALESCE(pp.PP_JUROS, 0) - COALESCE(pp.PP_DESCONTOS, 0)) AS valor'
      + ' FROM COMPRAS c'
      + ' JOIN PED_FAT pf ON c.COM_CODIGO = pf.PF_COD_PED'
      + ' JOIN PF_PARCELA pp ON pp.PP_PF = pf.PF_CODIGO'
      + ' JOIN TIPO_PGM tp ON pp.PP_TP = tp.TP_CODIGO'
      + ' WHERE pf.PF_TABELA = ''COMPRAS'' AND (c.COM_DATAC = ''01/01/1900'' OR c.COM_DATAC IS NULL)');

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.Add('AND c.COM_DATA BETWEEN :DATE1 and :DATE2');
      Query.Add('GROUP BY tp.TP_DESCRICAO ORDER BY 2 DESC');
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end
    else
    begin
      Query.Add('GROUP BY tp.TP_DESCRICAO ORDER BY 2 DESC');
    end;

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('tipo_pagamento').IsNull then
          LItem.AddPair('tipo_pagamento', Query.Dataset.FieldByName('tipo_pagamento').AsString)
        else
          LItem.AddPair('tipo_pagamento', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
    LMetaJSON.Free;
  end;
end;

class procedure TDashboardController.TiposPagamentosPagamentos(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem, LMetaJSON: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  LMetaJSON := nil;
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    Query.Clear();
    Query.Add('SELECT tp.TP_DESCRICAO AS tipo_pagamento, SUM(COALESCE(pag.PAG_VALOR, 0) + COALESCE(pag.PAG_JUROS, 0) - COALESCE(pag.PAG_DESCONTOS, 0)) AS valor'
      + ' FROM PAGAMENTOS pag'
      + ' JOIN FATURAMENTO2 f ON f.FAT2_CODIGO = pag.PAG_FAT2'
      + ' JOIN TIPO_PGM tp ON tp.TP_CODIGO = pag.PAG_CON'
      + ' WHERE (pag.PAG_SITUACAO >= 0 AND pag.PAG_SITUACAO < 3)');

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.Add(' AND f.FAT2_DATA BETWEEN :DATE1 and :DATE2');
      Query.Add(' GROUP BY tp.TP_DESCRICAO ORDER BY 2 DESC');
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end
    else
    begin
      Query.Add('GROUP BY tp.TP_DESCRICAO ORDER BY 2 DESC');
    end;

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('tipo_pagamento').IsNull then
          LItem.AddPair('tipo_pagamento', Query.Dataset.FieldByName('tipo_pagamento').AsString)
        else
          LItem.AddPair('tipo_pagamento', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
    LMetaJSON.Free;
  end;
end;

class procedure TDashboardController.TiposPagamentosRecebimentos(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem, LMetaJSON: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  LMetaJSON := nil;
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    Query.Clear();
    Query.Add('SELECT tp.TP_DESCRICAO AS tipo_pagamento, SUM(COALESCE(r.REC_VALOR, 0) + COALESCE(r.REC_JUROS, 0) - COALESCE(r.REC_DESCONTOS, 0)) AS valor'
      + ' FROM RECEBIMENTOS r'
      + ' JOIN FATURAMENTOS f ON f.FAT_CODIGO = r.REC_FAT'
      + ' JOIN TIPO_PGM tp ON r.REC_CON = tp.TP_CODIGO'
      + ' WHERE (r.REC_SITUACAO >= 0 AND r.REC_SITUACAO < 3)');

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.Add('AND f.FAT_DATA BETWEEN :DATE1 and :DATE2');
      Query.Add('GROUP BY tp.TP_DESCRICAO ORDER BY 2 DESC');
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end
    else
    begin
      Query.Add('GROUP BY tp.TP_DESCRICAO ORDER BY 2 DESC');
    end;

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('tipo_pagamento').IsNull then
          LItem.AddPair('tipo_pagamento', Query.Dataset.FieldByName('tipo_pagamento').AsString)
        else
          LItem.AddPair('tipo_pagamento', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
    LMetaJSON.Free;
  end;
end;

class procedure TDashboardController.TiposPagamentosVendas(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem, LMetaJSON: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  LMetaJSON := nil;
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    Query.Clear();
    Query.Add('SELECT tp.TP_DESCRICAO AS tipo_pagamento, SUM(COALESCE(pp.PP_VALOR, 0) + COALESCE(pp.PP_JUROS, 0) - COALESCE(pp.PP_DESCONTOS, 0)) AS valor'
      + ' FROM VENDAS v'
      + ' JOIN PED_FAT pf ON v.VEN_CODIGO = pf.PF_COD_PED'
      + ' JOIN PF_PARCELA pp ON pp.PP_PF = pf.PF_CODIGO'
      + ' JOIN TIPO_PGM tp ON pp.PP_TP = tp.TP_CODIGO'
      + ' WHERE pf.PF_TABELA = ''VENDAS'' AND (v.VEN_DATAC = ''01/01/1900'' OR v.VEN_DATAC IS NULL)');

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.Add('AND v.VEN_DATA BETWEEN :DATE1 and :DATE2');
      Query.Add('GROUP BY tp.TP_DESCRICAO ORDER BY 2 DESC');
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end
    else
    begin
      Query.Add('GROUP BY tp.TP_DESCRICAO ORDER BY 2 DESC');
    end;

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('tipo_pagamento').IsNull then
          LItem.AddPair('tipo_pagamento', Query.Dataset.FieldByName('tipo_pagamento').AsString)
        else
          LItem.AddPair('tipo_pagamento', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
    LMetaJSON.Free;
  end;
end;

class procedure TDashboardController.VendasDiarias(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  StartDateParam := '';
  EndDateParam := '';
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.Add(
        'SELECT CAST(VEN_DATA AS DATE) AS data, SUM(COALESCE(VE_VALOR, 0)) as valor, '
        + 'MAX(COALESCE(VE_VALOR, 0)) as maior_venda, COUNT(DISTINCT(VEN_CODIGO)) as quantidade'
        + ' FROM VENDAS v'
        + ' JOIN VEN_EST ve ON ve.VE_VEN = v.VEN_CODIGO'
        + ' WHERE VEN_DATA BETWEEN :DATE1 and :DATE2 AND VEN_DEVOLUCAO_P <> ''S'''
        + ' GROUP BY 1'
        + ' ORDER BY 1');
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end
    else
      Query.Add(
        'SELECT CAST(VEN_DATA AS DATE) AS data, SUM(COALESCE(VE_VALOR, 0)) as valor, '
        + 'MAX(COALESCE(VE_VALOR, 0)) as maior_venda, COUNT(DISTINCT(VEN_CODIGO)) as quantidade'
        + ' FROM VENDAS v'
        + ' JOIN VEN_EST ve ON ve.VE_VEN = v.VEN_CODIGO'
        + ' WHERE VEN_DEVOLUCAO_P <> ''S'''
        + ' GROUP BY 1'
        + ' ORDER BY 1');

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('data').IsNull then
          LItem.AddPair('data', FormatDateTime('yyyy-mm-dd',
            Query.Dataset.FieldByName('data').AsDateTime))
        else
          LItem.AddPair('data', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));
        LItem.AddPair('maior_venda',
          TJSONNumber.Create(Query.Dataset.FieldByName('maior_venda').AsFloat));
        LItem.AddPair('quantidade',
          TJSONNumber.Create(Query.Dataset.FieldByName('quantidade').AsInteger));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TDashboardController.VendasDiariasHora(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  StartDateParam := '';
  EndDateParam := '';
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.Add(
        'SELECT CAST(VEN_HORA AS TIME) AS hora, SUM(COALESCE(VE_VALOR, 0)) as valor'
        + ' FROM VENDAS v'
        + ' JOIN VEN_EST ve ON ve.VE_VEN = v.VEN_CODIGO'
        + ' WHERE VEN_DATA BETWEEN :DATE1 and :DATE2 AND VEN_DEVOLUCAO_P <> ''S'''
        + ' GROUP BY 1'
        + ' ORDER BY 1');
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end
    else
      Query.Add(
        'SELECT CAST(VEN_HORA AS TIME) AS hora, SUM(COALESCE(VE_VALOR, 0)) as valor'
        + ' FROM VENDAS v'
        + ' JOIN VEN_EST ve ON ve.VE_VEN = v.VEN_CODIGO'
        + ' WHERE VEN_DEVOLUCAO_P <> ''S'''
        + ' GROUP BY 1'
        + ' ORDER BY 1');

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('hora').IsNull then
          LItem.AddPair('hora', FormatDateTime('hh:mm:ss',
            Query.Dataset.FieldByName('hora').AsDateTime))
        else
          LItem.AddPair('data', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TDashboardController.VendasPorMargemLucro(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  StartDateParam := '';
  EndDateParam := '';
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.Add(
        'SELECT CAST(v.VEN_DATA AS DATE) AS data, SUM(COALESCE(ve.VE_VALOR, 0)) as valor,'
        + ' SUM(COALESCE(VE_LUCRO, 0)) as margem_lucro'
        + ' FROM VENDAS v'
        + ' JOIN VEN_EST ve ON ve.VE_VEN = v.VEN_CODIGO'
        + ' WHERE VEN_DATA BETWEEN :DATE1 and :DATE2 AND VEN_DEVOLUCAO_P <> ''S'''
        + ' GROUP BY 1'
        + ' ORDER BY 1');
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end
    else
      Query.Add(
        'SELECT CAST(v.VEN_DATA AS DATE) AS data, SUM(COALESCE(ve.VE_VALOR, 0)) as valor'
        + ' SUM(COALESCE(VE_LUCRO, 0)) as margem_lucro'
        + ' FROM VENDAS v'
        + ' JOIN VEN_EST ve ON ve.VE_VEN = v.VEN_CODIGO'
        + ' WHERE VEN_DEVOLUCAO_P <> ''S'''
        + ' GROUP BY 1'
        + ' ORDER BY 1');

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('data').IsNull then
          LItem.AddPair('data', FormatDateTime('yyyy-mm-dd',
            Query.Dataset.FieldByName('data').AsDateTime))
        else
          LItem.AddPair('data', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));
        LItem.AddPair('margem_lucro',
          TJSONNumber.Create(Query.Dataset.FieldByName('margem_lucro').AsFloat));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TDashboardController.OsDiarias(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  StartDateParam := '';
  EndDateParam := '';
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.Add(
        'SELECT CAST(ORD_DATA AS DATE) AS data, SUM(COALESCE(ORD_VALOR, 0)) as valor, '
        + 'MAX(COALESCE(ORD_VALOR, 0)) as maior_venda, COUNT(DISTINCT(ORD_CODIGO)) as quantidade'
        + ' FROM ORDENS'
        + ' WHERE ORD_DATAC = ''01/01/1900'' AND COALESCE(ORD_DEVOLUCAO_P, '''') <> ''S'''
        + ' AND ORD_DATA BETWEEN :DATE1 and :DATE2'
        + ' GROUP BY 1'
        + ' ORDER BY 1');
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end
    else
      Query.Add(
        'SELECT CAST(ORD_DATA AS DATE) AS data, SUM(COALESCE(ORD_VALOR, 0)) as valor, '
        + 'MAX(COALESCE(ORD_VALOR, 0)) as maior_venda, COUNT(DISTINCT(ORD_CODIGO)) as quantidade'
        + ' FROM ORDENS'
        + ' WHERE ORD_DATAC = ''01/01/1900'' AND COALESCE(ORD_DEVOLUCAO_P, '''') <> ''S'''
        + ' GROUP BY 1'
        + ' ORDER BY 1');

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('data').IsNull then
          LItem.AddPair('data', FormatDateTime('yyyy-mm-dd',
            Query.Dataset.FieldByName('data').AsDateTime))
        else
          LItem.AddPair('data', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));
        LItem.AddPair('maior_os',
          TJSONNumber.Create(Query.Dataset.FieldByName('maior_venda').AsFloat));
        LItem.AddPair('quantidade',
          TJSONNumber.Create(Query.Dataset.FieldByName('quantidade').AsInteger));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
  end;
end;

//class procedure TDashboardController.OsLucroServico(Req: THorseRequest;
//  Res: THorseResponse);
//var
//  aJson: TJSONArray;
//  LResponseJSON, LItem: TJSONObject;
//  Query: iQuery;
//  StartDateParam, EndDateParam: string;
//  ParamName, ParamValue, QueryParams: string;
//begin
//  LResponseJSON := nil;
//  aJson := nil;
//  StartDateParam := '';
//  EndDateParam := '';
//  try
//    LResponseJSON := TJSONObject.Create;
//    aJson := TJSONArray.Create;
//    Query := TDatabase.Query;
//
//    // Monta filtros dinamicos
//    for QueryParams in Req.Query.Dictionary.Keys do
//    begin
//      ParamName := QueryParams.ToUpper;
//      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');
//
//      // Ignora parâmetros de controle
//      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
//        Continue;
//
//      // Data inicial de filtragem
//      if ParamName = 'STARTDATE' then
//      begin
//        if not ParamValue.IsEmpty then
//        begin
//          StartDateParam := ParamValue;
//        end;
//        Continue;
//      end;
//
//      // Data final de filtragem
//      if ParamName = 'ENDDATE' then
//      begin
//        if not ParamValue.IsEmpty then
//        begin
//          EndDateParam := ParamValue;
//        end;
//        Continue;
//      end;
//
//    end;
//
//    if StartDateParam.IsEmpty then
//      StartDateParam := '1900-01-01';
//    if EndDateParam.IsEmpty then
//      EndDateParam := '2100-12-31';
//
//    Query.Add('SELECT OS.OS_NOME NOME, SUM(COALESCE(OS.OS_VALOR, 0)) AS VALOR,'
//              + ' SUM(COALESCE(OS.OS_VALOR, 0) - COALESCE(OS.OS_VALORR, 0)) AS LUCRO'
//              + ' FROM ORDENS O'
//              + ' JOIN ORD_SER OS ON OS.OS_ORD = O.ORD_CODIGO'
//              + ' WHERE O.ORD_DATAC = ''01/01/1900'' AND COALESCE(O.ORD_DEVOLUCAO_P, '''') <> ''S'''
//              + ' AND O.ORD_DATA BETWEEN :DATA1 AND :DATA2'
//              + ' GROUP BY OS.OS_NOME');
//    Query.AddParam('DATA1', StartDateParam);
//    Query.AddParam('DATA2', EndDateParam);
//    Query.Open();
//
//    Query.Dataset.First;
//    while not Query.Dataset.Eof do
//    begin
//      LItem := TJSONObject.Create;
//      try
//        LItem.AddPair('nome', Query.DataSet.FieldByName('nome').AsString);
//        LItem.AddPair('valor',
//            TJSONNumber.Create(Query.DataSet.FieldByName('valor').AsFloat));
//        LItem.AddPair('lucro',
//            TJSONNumber.Create(Query.DataSet.FieldByName('lucro').AsFloat));
//        aJson.Add(LItem);
//        LItem := nil;
//      finally
//        LItem.Free;
//      end;
//      Query.Dataset.Next;
//    end;
//
//    LResponseJSON.AddPair('data', aJson);
//    aJson := nil;
//    Res.Send<TJSONObject>(LResponseJSON);
//    LResponseJSON := nil;
//  finally
//    aJson.Free;
//    LResponseJSON.Free;
//  end;
//end;

class procedure TDashboardController.OsMargemLucro(Req: THorseRequest;
  Res: THorseResponse);
var
  aJson: TJSONArray;
  LResponseJSON, LItem: TJSONObject;
  Query: iQuery;
  StartDateParam, EndDateParam: string;
  ParamName, ParamValue, QueryParams: string;
begin
  LResponseJSON := nil;
  aJson := nil;
  StartDateParam := '';
  EndDateParam := '';
  try
    LResponseJSON := TJSONObject.Create;
    aJson := TJSONArray.Create;
    Query := TDatabase.Query;

    // Monta filtros dinamicos
    for QueryParams in Req.Query.Dictionary.Keys do
    begin
      ParamName := QueryParams.ToUpper;
      ParamValue := Req.Query.Items[QueryParams].Replace('''', '');

      // Ignora parâmetros de controle
      if (ParamName = 'LIMIT') or (ParamName = 'PAGE') then
        Continue;

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

    end;

    if not StartDateParam.IsEmpty and not EndDateParam.IsEmpty then
    begin
      Query.Add(
        'SELECT CAST(O.ORD_DATA AS DATE) AS data, SUM(COALESCE(O.ORD_VALOR, 0)) as valor,'
        + ' SUM(COALESCE(P.LUCRO_PRODUTOS, 0) + COALESCE(S.LUCRO_SERVICOS, 0)) as margem_lucro'
        + ' FROM ORDENS O'
        + ' LEFT JOIN (SELECT ORE_ORD, SUM(COALESCE(ORE_LUCRO, 0)) AS LUCRO_PRODUTOS FROM ORD_EST GROUP BY ORE_ORD) P ON P.ORE_ORD = O.ORD_CODIGO'
        + ' LEFT JOIN (SELECT OS_ORD, SUM(COALESCE(OS_VALOR, 0) - COALESCE(OS_VALORR, 0)) AS LUCRO_SERVICOS FROM ORD_SER GROUP BY OS_ORD) S ON S.OS_ORD = O.ORD_CODIGO'
        + ' WHERE O.ORD_DATAC = ''01/01/1900'' AND COALESCE(O.ORD_DEVOLUCAO_P, '''') <> ''S'''
        + ' AND O.ORD_DATA BETWEEN :DATE1 and :DATE2'
        + ' GROUP BY 1'
        + ' ORDER BY 1');
      Query.AddParam('DATE1', StartDateParam);
      Query.AddParam('DATE2', EndDateParam);
    end
    else
      Query.Add(
        'SELECT CAST(O.ORD_DATA AS DATE) AS data, SUM(COALESCE(O.ORD_VALOR, 0)) as valor,'
        + ' SUM(COALESCE(P.LUCRO_PRODUTOS, 0) + COALESCE(S.LUCRO_SERVICOS, 0)) as margem_lucro'
        + ' FROM ORDENS O'
        + ' LEFT JOIN (SELECT ORE_ORD, SUM(COALESCE(ORE_LUCRO, 0)) AS LUCRO_PRODUTOS FROM ORD_EST GROUP BY ORE_ORD) P ON P.ORE_ORD = O.ORD_CODIGO'
        + ' LEFT JOIN (SELECT OS_ORD, SUM(COALESCE(OS_VALOR, 0) - COALESCE(OS_VALORR, 0)) AS LUCRO_SERVICOS FROM ORD_SER GROUP BY OS_ORD) S ON S.OS_ORD = O.ORD_CODIGO'
        + ' WHERE O.ORD_DATAC = ''01/01/1900'' AND COALESCE(O.ORD_DEVOLUCAO_P, '''') <> ''S'''
        + ' GROUP BY 1'
        + ' ORDER BY 1');

    Query.Open();

    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      LItem := TJSONObject.Create;
      try
        if not Query.Dataset.FieldByName('data').IsNull then
          LItem.AddPair('data', FormatDateTime('yyyy-mm-dd',
            Query.Dataset.FieldByName('data').AsDateTime))
        else
          LItem.AddPair('data', '');

        LItem.AddPair('valor',
          TJSONNumber.Create(Query.Dataset.FieldByName('valor').AsFloat));
        LItem.AddPair('margem_lucro',
          TJSONNumber.Create(Query.Dataset.FieldByName('margem_lucro').AsFloat));
        aJson.Add(LItem);
        LItem := nil;
      finally
        LItem.Free;
      end;
      Query.Dataset.Next;
    end;

    LResponseJSON.AddPair('data', aJson);
    aJson := nil;
    Res.Send<TJSONObject>(LResponseJSON);
    LResponseJSON := nil;
  finally
    aJson.Free;
    LResponseJSON.Free;
  end;
end;

class procedure TDashboardController.Router;
begin
  THorse
  .Group
    .Prefix('/v1')
    .Route('/dashboard/clientes-cidade')
    .Get(ClientesCidade)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/despesas-tipo-pagamento')
    .Get(DespesasPorTipoPagamento)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/movimentacoes')
    .Get(Movimentacoes)
  .&End
//  .Group
//    .Prefix('/v1')
//    .Route('/dashboard/recebimentos-status')
//    .Get(RecebimentosStatus)
//  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/vendas-diarias')
    .Get(VendasDiarias)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/vendas-diarias/hora')
    .Get(VendasDiariasHora)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/os-diarias')
    .Get(OsDiarias)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/vendas-margem-lucro')
    .Get(VendasPorMargemLucro)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/os-margem-lucro')
    .Get(OsMargemLucro)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/vendas-lucro-grupo')
    .Get(LucroVendasPorGrupo)
  .&End
//  .Group
//    .Prefix('/v1')
//    .Route('/dashboard/os-lucro-servico')
//    .Get(OsLucroServico)
//  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-vendas')
    .Get(TiposPagamentosVendas)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-compras')
    .Get(TiposPagamentosCompras)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-recebimentos')
    .Get(TiposPagamentosRecebimentos)
  .&End
  .Group
    .Prefix('/v1')
    .Route('/dashboard/tipos-pagamentos-pagamentos')
    .Get(TiposPagamentosPagamentos)
  .&End;
end;

initialization

  Swagger
    .BasePath('v1')
      .Path('dashboard/clientes-cidade')
        .Tag('Dashboard')
          .Get('Clientes por Cidade', 'Retorna a quantidade de clientes agrupados por Cidade')
          .AddResponse(200,'Operação bem Sucedida')
          .Schema(TDashboardClientesCidade).IsArray(True)
        .&End.
          AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/despesas-tipo-pagamento')
        .Tag('Dashboard')
          .Get('Despesas por Tipo Pagamento', 'Retorna as despesas agrupadas por tipo de pagamento')
          .AddResponse(200,'Operação bem Sucedida')
//          .Schema(TDashboardClientesCidade).IsArray(True)
        .&End.
          AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/vendas-lucro-grupo')
        .Tag('Dashboard')
          .Get('Lucros por Grupo de Venda', 'Retorna o lucro agrupadas por grupo de vendas')
          .AddResponse(200,'Operação bem Sucedida')
//          .Schema(TDashboardClientesCidade).IsArray(True)
        .&End.
          AddResponse(500)
        .&End
      .&End
    .&End
//      .Path('dashboard/os-lucro-servico')
//        .Tag('Dashboard')
//          .Get('OS Lucro por Serviço', 'Retorna o lucro de OS por serviço')
//          .AddResponse(200,'Operação bem Sucedida')
////          .Schema(TDashboardClientesCidade).IsArray(True)
//        .&End.
//          AddResponse(500)
//        .&End
//      .&End
//    .&End
      .Path('dashboard/movimentacoes')
        .Tag('Dashboard')
          .Get('Movimentações', 'Retorna o sumário de crédito e débito agrupado por data')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardMovimentacoes).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/recebimentos-status')
        .Tag('Dashboard')
          .Get('Recebimentos por Data', 'Retorna o sumário de valores recebidos agrupado por data')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardRecebimentosStatus).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/vendas-diarias')
        .Tag('Dashboard')
          .Get('Vendas Diárias', 'Retorna o sumário de vendas por data agrupados')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardVendasData).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/vendas-diarias/hora')
        .Tag('Dashboard')
          .Get('Vendas Diárias por Hora', 'Retorna o sumário de vendas por hora')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardVendasDiariasHora).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/os-diarias')
        .Tag('Dashboard')
          .Get('OS Diárias', 'Retorna o sumário de OS por data agrupados')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardVendasData).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/vendas-margem-lucro')
        .Tag('Dashboard')
          .Get('Vendas Diárias por Margem de Lucro', 'Retorna o sumário de vendas e margem de lucro por data agrupados')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardVendasData).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/os-margem-lucro')
        .Tag('Dashboard')
          .Get('OS por Margem de Lucro', 'Retorna o sumário de faturamento e margem de lucro de OS por data agrupados')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardVendasData).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/tipos-pagamentos-vendas')
        .Tag('Dashboard')
          .Get('Tipos de Pagamento das Vendas', 'Retorna o sumário de vendas por tipo de pagamento')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardTiposPagamentos).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/tipos-pagamentos-compras')
        .Tag('Dashboard')
          .Get('Tipos de Pagamento das Compras', 'Retorna o sumário de compras por tipo de pagamento')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardTiposPagamentos).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/tipos-pagamentos-recebimentos')
        .Tag('Dashboard')
          .Get('Tipos de Pagamento dos Recebimentos', 'Retorna o sumário de recebimentos por tipo de pagamento')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardTiposPagamentos).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End
      .Path('dashboard/tipos-pagamentos-pagamentos')
        .Tag('Dashboard')
          .Get('Tipos de Pagamento dos Pagamentos', 'Retorna o sumário de pagamentos por tipo de pagamento')
          .AddResponse(200, 'Operação bem Sucedida')
          .Schema(TDashboardTiposPagamentos).IsArray(True)
        .&End
          .AddResponse(500)
        .&End
      .&End
    .&End;

end.
