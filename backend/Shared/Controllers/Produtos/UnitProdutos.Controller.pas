unit UnitProdutos.Controller;

interface

uses
	Horse,
	Horse.Commons,
	Classes,
	SysUtils,
	System.IOUtils,
	System.Json, FireDAC.Comp.Client;

type
	TProdutosController = class
		class procedure Router;
		class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure UploadImage(Req: THorseRequest; Res: THorseResponse);
		class procedure DeleteImage(Req: THorseRequest; Res: THorseResponse);
		class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
	end;

implementation

{ TProdutosController }

uses
	UnitConnection.Model.Interfaces,
	UnitDatabase,
	UnitFunctions,
	UnitProdutos.Model,
	UnitTabela.Helpers;

class procedure TProdutosController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Produtos: TProdutos;
	id      : Integer;
begin
	try
		id       := Req.Params.Items['id'].ToInteger();
		Produtos := TProdutos.Create(TDatabase.Connection);
		Produtos.Apagar(id);
		Res.Send('').Status(THTTPStatus.NoContent);
	finally
		Produtos.DisposeOf;
	end;
end;

class procedure TProdutosController.DeleteImage(Req: THorseRequest; Res: THorseResponse);
var
	id               : string;
	CaminhoPasta     : string;
	NomeArquivo      : string;
	CaracterSeparador: Char;
begin
	id                := Req.Params.Items['id'];
	CaracterSeparador := TPath.DirectorySeparatorChar;
	CaminhoPasta      := TPath.Combine(GetCurrentDir, GetCurrentDir + CaracterSeparador + 'imagens' + CaracterSeparador + 'produtos' + CaracterSeparador);
	NomeArquivo       := ChangeFileExt(CaminhoPasta + id, '.png');
	if FileExists(NomeArquivo) then
		DeleteFile(NomeArquivo);
	Res.Send<TJSONObject>(TJSONObject.Create.AddPair('msg', 'arquivo deletado com sucesso'))
end;

class procedure TProdutosController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Produtos: TProdutos;
  aJson: TJSONArray;
  LResponseObj, LMetaObj: TJSONObject;
  QueryCount, QueryData: iQuery;
  LSearch, LStockStatus, LCodigo, LNome, LCodbarra, LCadastrar, LWhereClause: string;
  LPage, LLimit, LOffset, LTotalRecords, LTotalPages, I: Integer;
  LWhereList: TStringList;
  LIsPaginated: Boolean;
begin
  aJson := TJSONArray.Create;
  QueryCount := TDatabase.Query;
  QueryData := TDatabase.Query;
  Produtos := TProdutos.Create(TDatabase.Connection);
  LWhereList := TStringList.Create;
  try
    LIsPaginated := Req.Query.ContainsKey('page') or Req.Query.ContainsKey('limit') or Req.Query.ContainsKey('search') or Req.Query.ContainsKey('stockStatus');
    LPage := StrToIntDef(Req.Query.Items['page'], 1);
    if LPage < 1 then LPage := 1;

    LLimit := StrToIntDef(Req.Query.Items['limit'], 10);
    if Req.Query.ContainsKey('total') then
      LLimit := StrToIntDef(Req.Query.Items['total'], LLimit);

    if LLimit < 1 then LLimit := 10;
    if LLimit > 500 then LLimit := 500;

    LOffset := (LPage - 1) * LLimit;

    if Req.Query.ContainsKey('search') then
    begin
      LSearch := Trim(Req.Query.Items['search'].Replace('''', ''));
      if not LSearch.IsEmpty then
      begin
        LWhereList.Add(Format('(LOWER(PRO_NOME) LIKE %s OR LOWER(PRO_FABRICANTE) LIKE %s OR PRO_CODBARRA LIKE %s OR CAST(PRO_CODIGO AS VARCHAR(20)) LIKE %s)',
          [QuotedStr('%' + LowerCase(LSearch) + '%'),
           QuotedStr('%' + LowerCase(LSearch) + '%'),
           QuotedStr('%' + LSearch + '%'),
           QuotedStr('%' + LSearch + '%')]));
      end;
    end;

    if Req.Query.ContainsKey('codigo') then
    begin
      LCodigo := Trim(Req.Query.Items['codigo'].Replace('''', ''));
      if not LCodigo.IsEmpty then
        LWhereList.Add(Format('CAST(PRO_CODIGO AS VARCHAR(20)) LIKE %s', [QuotedStr('%' + LCodigo + '%')]));
    end;

    if Req.Query.ContainsKey('nome') then
    begin
      LNome := Trim(Req.Query.Items['nome'].Replace('''', ''));
      if not LNome.IsEmpty then
        LWhereList.Add(Format('LOWER(PRO_NOME) LIKE %s', [QuotedStr('%' + LowerCase(LNome) + '%')]));
    end;

    if Req.Query.ContainsKey('codbarra') then
    begin
      LCodbarra := Trim(Req.Query.Items['codbarra'].Replace('''', ''));
      if not LCodbarra.IsEmpty then
        LWhereList.Add(Format('PRO_CODBARRA LIKE %s', [QuotedStr('%' + LCodbarra + '%')]));
    end;

    if Req.Query.ContainsKey('cadastrar') then
    begin
      LCadastrar := Req.Query.Items['cadastrar'];
      if LCadastrar.Contains('S') then
        LWhereList.Add('PRO_CADASTRAR = ''S''');
    end;

    if Req.Query.ContainsKey('stockStatus') then
    begin
      LStockStatus := LowerCase(Trim(Req.Query.Items['stockStatus']));
      if LStockStatus = 'sem_estoque' then
        LWhereList.Add('(PRO_QUANTIDADE <= 0 OR PRO_QUANTIDADE IS NULL)')
      else if LStockStatus = 'acabando' then
        LWhereList.Add('(PRO_QUANTIDADE > 0 AND PRO_QUANTIDADE <= 5)');
    end;

    LWhereClause := '';
    if LWhereList.Count > 0 then
    begin
      LWhereClause := ' WHERE ' + LWhereList[0];
      for I := 1 to LWhereList.Count - 1 do
        LWhereClause := LWhereClause + ' AND ' + LWhereList[I];
    end;

    QueryCount.Clear;
    QueryCount.Add('SELECT COUNT(*) AS TOTAL FROM PRODUTOS' + LWhereClause);
    QueryCount.Open;
    LTotalRecords := QueryCount.Dataset.FieldByName('TOTAL').AsInteger;

    if LLimit > 0 then
      LTotalPages := (LTotalRecords + LLimit - 1) div LLimit
    else
      LTotalPages := 1;

    QueryData.Clear;
    QueryData.Add(Format('SELECT FIRST %d SKIP %d PRO_CODIGO FROM PRODUTOS %s ORDER BY PRO_CODIGO', [LLimit, LOffset, LWhereClause]));
    QueryData.Open;
    QueryData.Dataset.First;

    while not QueryData.Dataset.Eof do
    begin
      Produtos.BuscaDadosTabela(QueryData.Dataset.FieldByName('PRO_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(Produtos.ToJson) as TJSONObject);
      QueryData.Dataset.Next;
    end;

    if LIsPaginated then
    begin
      LResponseObj := TJSONObject.Create;
      LMetaObj := TJSONObject.Create;

      LMetaObj.AddPair('page', TJSONNumber.Create(LPage));
      LMetaObj.AddPair('limit', TJSONNumber.Create(LLimit));
      LMetaObj.AddPair('total', TJSONNumber.Create(LTotalRecords));
      LMetaObj.AddPair('pages', TJSONNumber.Create(LTotalPages));

      LResponseObj.AddPair('data', aJson);
      LResponseObj.AddPair('meta', LMetaObj);

      Res.Send<TJSONObject>(LResponseObj);
    end
    else
    begin
      Res.Send<TJSONArray>(aJson);
    end;
  finally
    LWhereList.Free;
    Produtos.DisposeOf;
  end;
end;

class procedure TProdutosController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Produtos: TProdutos;
	aJson   : TJSONArray;
	id      : Integer;
begin
	aJson := TJSONArray.Create;
	id    := Req.Params.Items['id'].ToInteger();
	try
		Produtos := TProdutos.Create(TDatabase.Connection);
		Produtos.BuscaDadosTabela(id);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Produtos.ToJson) as TJSONObject);
	finally
		Produtos.DisposeOf;
	end;
end;

class procedure TProdutosController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Produtos: TProdutos;
	LBodyObj: TJSONObject;
	LQueryEmp, LQueryEE, LQueryInsert: iQuery;
	LEmpId, LNewEEId: Integer;
	LQtdEE: Double;
begin
	try
		LBodyObj := Req.Body<TJSONObject>;
		Produtos := TProdutos.Create(TDatabase.Connection).fromJson<TProdutos>(Req.Body);
		if Produtos.Codigo = 0 then
			Produtos.Codigo := Produtos.GeraCodigo('PRO_CODIGO');
		if Assigned(LBodyObj) then
		begin
			if LBodyObj.GetValue('pro_valor_dinheiro') <> nil then
				Produtos.ValorDinheiro := LBodyObj.GetValue<Double>('pro_valor_dinheiro')
			else if LBodyObj.GetValue('valor_dinheiro') <> nil then
				Produtos.ValorDinheiro := LBodyObj.GetValue<Double>('valor_dinheiro')
			else if LBodyObj.GetValue('valordinheiro') <> nil then
				Produtos.ValorDinheiro := LBodyObj.GetValue<Double>('valordinheiro');

			if LBodyObj.GetValue('pro_valorv_prazo') <> nil then
				Produtos.ValorPrazo := LBodyObj.GetValue<Double>('pro_valorv_prazo')
			else if LBodyObj.GetValue('valor_prazo') <> nil then
				Produtos.ValorPrazo := LBodyObj.GetValue<Double>('valor_prazo')
			else if LBodyObj.GetValue('valorprazo') <> nil then
				Produtos.ValorPrazo := LBodyObj.GetValue<Double>('valorprazo');

			if LBodyObj.GetValue('pro_for') <> nil then
				Produtos.ForCodigo := LBodyObj.GetValue<Integer>('pro_for')
			else if LBodyObj.GetValue('forCodigo') <> nil then
				Produtos.ForCodigo := LBodyObj.GetValue<Integer>('forCodigo')
			else if LBodyObj.GetValue('fornecedorId') <> nil then
				Produtos.ForCodigo := LBodyObj.GetValue<Integer>('fornecedorId');

			if LBodyObj.GetValue('pro_gru') <> nil then
				Produtos.Gru := LBodyObj.GetValue<Integer>('pro_gru')
			else if LBodyObj.GetValue('gru') <> nil then
				Produtos.Gru := LBodyObj.GetValue<Integer>('gru')
			else if LBodyObj.GetValue('subgrupoId') <> nil then
				Produtos.Gru := LBodyObj.GetValue<Integer>('subgrupoId');
		end;
		Produtos.Cadastrar := 'S';
		Produtos.SalvaNoBanco(0);

		// Cria o vinculo ESTOQUE_EMPRESA para cada empresa cadastrada (zerado para filiais, mantendo padronizacao)
		try
			LQueryEmp := TDatabase.Query;
			LQueryEmp.Open('SELECT EMP_CODIGO FROM EMPRESA');
			LQueryEmp.Dataset.First;
			while not LQueryEmp.Dataset.Eof do
			begin
				LEmpId := LQueryEmp.Dataset.FieldByName('EMP_CODIGO').AsInteger;
				LQueryEE := TDatabase.Query;
				LQueryEE.Open(Format('SELECT EE_ID FROM ESTOQUE_EMPRESA WHERE EE_EMPRESA_ID = %d AND EE_PRO_CODIGO = %d', [LEmpId, Produtos.Codigo]));
				if LQueryEE.Dataset.IsEmpty then
				begin
					LNewEEId := GeraCodigo('ESTOQUE_EMPRESA', 'EE_ID');
					LQueryInsert := TDatabase.Query;
					LQueryInsert.Clear;
					if LEmpId = 1 then
						LQtdEE := Produtos.Quantidade
					else
						LQtdEE := 0;

					LQueryInsert.Add(Format(
						'INSERT INTO ESTOQUE_EMPRESA (EE_ID, EE_EMPRESA_ID, EE_PRO_CODIGO, EE_QUANTIDADE, EE_DATA_ATUALIZACAO) ' +
						'VALUES (%d, %d, %d, %s, CURRENT_TIMESTAMP)',
						[LNewEEId, LEmpId, Produtos.Codigo, FloatToStr(LQtdEE).Replace(',', '.')]
					));
					LQueryInsert.ExecSQL;
				end;
				LQueryEmp.Dataset.Next;
			end;
		except
			on E: Exception do
				Writeln('-> Erro ao criar vinculo ESTOQUE_EMPRESA: ' + E.Message);
		end;

		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Produtos.ToJson) as TJSONObject).Status(THTTPStatus.Created);
	finally
		Produtos.DisposeOf;
	end;
end;

class procedure TProdutosController.PostEmLote(Req: THorseRequest; Res: THorseResponse);
var
	Itens     : TProdutos;
	aJson     : TJSONArray;
	oJsonValue: TJSONValue;
	oJson     : TJSONObject;
	LQuery    : iQuery;
	FDQuery   : TFDQuery;
	i         : Integer;
begin
	oJson   := Req.Body<TJSONObject>;
	aJson   := oJson.GetValue<TJSONArray>('itens');
	LQuery  := TDatabase.Query;
	FDQuery := TFDQuery(LQuery.Query);
	FDQuery.Close;
	FDQuery.SQL.Clear;
	FDQuery.SQL.Add('UPDATE OR INSERT INTO PRODUTOS (PRO_CODIGO, PRO_FOR, PRO_FABRICANTE, PRO_QUANTIDADEM, PRO_QUANTIDADE,');
	FDQuery.SQL.Add('PRO_VALORV, PRO_VALORCM, PRO_VALORC, PRO_VALORL, PRO_VALORF, PRO_QUANTIDADEF, PRO_LOCAL,');
	FDQuery.SQL.Add('PRO_EMBALAGEM, PRO_DATAUC, PRO_GRU, PRO_DESCRICAO, PRO_DATAUA, PRO_ABC, PRO_CODBARRA,');
	FDQuery.SQL.Add('PRO_VALORS, PRO_TIPO, PRO_TOTALIZADOR, PRO_NOME, PRO_ESTADO, PRO_GTIN, PRO_IAT,');
	FDQuery.SQL.Add('PRO_IPPT, PRO_ALIQICMS_OPINT, PRO_PERC_RED_OPINT, PRO_UM, PRO_GENERO, PRO_NCM, PRO_CFOP,');
	FDQuery.SQL.Add('PRO_EXCECAO_NCM, PRO_TIPO_ITEM, PRO_ABC_ANALITICO, PRO_CEST,');
	FDQuery.SQL.Add('PRO_SIT_TRIB, PRO_CST, PRO_TT, PRO_MAR, PRO_COD_AGRUP,');
	FDQuery.SQL.Add('PRO_VALORP, PRO_URL_IMAGEM, PRO_CADASTRAR)');
	FDQuery.SQL.Add('VALUES (:PRO_CODIGO, :PRO_FOR, :PRO_FABRICANTE, :PRO_QUANTIDADEM, :PRO_QUANTIDADE, :PRO_VALORV, :PRO_VALORCM,');
	FDQuery.SQL.Add(':PRO_VALORC, :PRO_VALORL, :PRO_VALORF, :PRO_QUANTIDADEF, :PRO_LOCAL, :PRO_EMBALAGEM, :PRO_DATAUC, :PRO_GRU,');
	FDQuery.SQL.Add(':PRO_DESCRICAO, :PRO_DATAUA, :PRO_ABC, :PRO_CODBARRA, :PRO_VALORS, :PRO_TIPO, :PRO_TOTALIZADOR, :PRO_NOME,');
	FDQuery.SQL.Add(':PRO_ESTADO, :PRO_GTIN, :PRO_IAT, :PRO_IPPT, :PRO_ALIQICMS_OPINT, :PRO_PERC_RED_OPINT, :PRO_UM, :PRO_GENERO,');
	FDQuery.SQL.Add(':PRO_NCM, :PRO_CFOP, :PRO_EXCECAO_NCM, :PRO_TIPO_ITEM, :PRO_ABC_ANALITICO, :PRO_CEST,');
	FDQuery.SQL.Add(':PRO_SIT_TRIB, :PRO_CST, :PRO_TT, :PRO_MAR, :PRO_COD_AGRUP, :PRO_VALORP,');
	FDQuery.SQL.Add(':PRO_URL_IMAGEM, :PRO_CADASTRAR)');
	FDQuery.SQL.Add('MATCHING (PRO_CODIGO)');
	// preparando para usar inseres via ArrayDML
	FDQuery.Params.ArraySize := aJson.Count;
	for i                    := 0 to Pred(aJson.Count) do
	begin
		oJsonValue := aJson.Items[i];
		Itens      := TProdutos.Create(TDatabase.Connection).fromJson<TProdutos>(oJsonValue.ToJson);
		try
			FDQuery.ParamByName('PRO_CODIGO').AsIntegers[i]              := Itens.Codigo;
			FDQuery.ParamByName('PRO_FOR').AsIntegers[i]                 := Itens.ForCodigo;
			FDQuery.ParamByName('PRO_FABRICANTE').AsStrings[i]           := Itens.Fabricante;
			FDQuery.ParamByName('PRO_QUANTIDADEM').AsFloats[i]           := Itens.Quantidadem;
			FDQuery.ParamByName('PRO_QUANTIDADE').AsFloats[i]            := Itens.Quantidade;
			FDQuery.ParamByName('PRO_VALORV').AsCurrencys[i]             := Itens.Valorv;
			FDQuery.ParamByName('PRO_VALORCM').AsCurrencys[i]            := Itens.Valorcm;
			FDQuery.ParamByName('PRO_VALORC').AsCurrencys[i]             := Itens.Valorc;
			FDQuery.ParamByName('PRO_VALORL').AsCurrencys[i]             := Itens.Valorl;
			FDQuery.ParamByName('PRO_VALORF').AsCurrencys[i]             := Itens.Valorf;
			FDQuery.ParamByName('PRO_QUANTIDADEF').AsFloats[i]           := Itens.Quantidadef;
			FDQuery.ParamByName('PRO_LOCAL').AsStrings[i]                := Itens.Local;
			FDQuery.ParamByName('PRO_EMBALAGEM').AsStrings[i]            := Itens.Embalagem;
			FDQuery.ParamByName('PRO_DATAUC').AsDateTimes[i]             := Itens.Datauc;
			FDQuery.ParamByName('PRO_GRU').AsIntegers[i]                 := Itens.Gru;
			FDQuery.ParamByName('PRO_DESCRICAO').AsStrings[i]            := Itens.Descricao.Substring(0, 30);
			FDQuery.ParamByName('PRO_DATAUA').AsDateTimes[i]             := Itens.Dataua;
			FDQuery.ParamByName('PRO_ABC').AsStrings[i]                  := Itens.Abc;
			FDQuery.ParamByName('PRO_CODBARRA').AsStrings[i]             := Itens.Codbarra;
			FDQuery.ParamByName('PRO_VALORS').AsCurrencys[i]             := Itens.Valors;
			FDQuery.ParamByName('PRO_TIPO').AsIntegers[i]                := Itens.Tipo;
			FDQuery.ParamByName('PRO_TOTALIZADOR').AsIntegers[i]         := Itens.CodTotalizador;
			FDQuery.ParamByName('PRO_NOME').AsStrings[i]                 := Itens.Nome;
			FDQuery.ParamByName('PRO_ESTADO').AsStrings[i]               := Itens.Estado;
			FDQuery.ParamByName('PRO_GTIN').AsStrings[i]                 := Itens.Gtin;
			FDQuery.ParamByName('PRO_IAT').AsStrings[i]                  := Itens.Iat;
			FDQuery.ParamByName('PRO_IPPT').AsStrings[i]                 := Itens.Ippt;
			FDQuery.ParamByName('PRO_ALIQICMS_OPINT').AsFloats[i]        := Itens.Aliqicms_opint;
			FDQuery.ParamByName('PRO_PERC_RED_OPINT').AsFloats[i]        := Itens.Perc_red_opint;
			FDQuery.ParamByName('PRO_UM').AsIntegers[i]                  := Itens.Um;
			FDQuery.ParamByName('PRO_GENERO').AsIntegers[i]              := Itens.Genero;
			FDQuery.ParamByName('PRO_NCM').AsStrings[i]                  := Itens.Ncm;
			FDQuery.ParamByName('PRO_CFOP').AsStrings[i]                 := Itens.Cfop;
			FDQuery.ParamByName('PRO_EXCECAO_NCM').AsIntegers[i]         := Itens.Excecao_ncm;
			FDQuery.ParamByName('PRO_TIPO_ITEM').AsStrings[i]            := Itens.Tipo_item;
			FDQuery.ParamByName('PRO_ABC_ANALITICO').AsStrings[i]        := Itens.Abc_analitico;
			FDQuery.ParamByName('PRO_CEST').AsStrings[i]                 := Itens.Cest;
			FDQuery.ParamByName('PRO_SIT_TRIB').AsStrings[i]             := Itens.Sit_trib;
			FDQuery.ParamByName('PRO_CST').AsStrings[i]                  := Itens.Cst;
			FDQuery.ParamByName('PRO_TT').AsIntegers[i]                  := Itens.Tt;
			FDQuery.ParamByName('PRO_MAR').AsIntegers[i]                 := Itens.Mar;
			FDQuery.ParamByName('PRO_COD_AGRUP').AsStrings[i]            := Itens.Cod_agrup;
			FDQuery.ParamByName('PRO_VALORP').AsCurrencys[i]             := Itens.Valorp;
			FDQuery.ParamByName('PRO_URL_IMAGEM').AsStrings[i]           := Itens.URL_Imagem;
			FDQuery.ParamByName('PRO_CADASTRAR').AsStrings[i]            := 'S';
		finally
			Itens.DisposeOf;
		end;
	end;
	// Executa as inseres em lote
	FDQuery.Execute(aJson.Count, 0);
	Res.Send<TJSONObject>(oJson);
end;

class procedure TProdutosController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Produtos: TProdutos;
	LBodyObj: TJSONObject;
begin
	try
		LBodyObj := Req.Body<TJSONObject>;
		Produtos := TProdutos.Create(TDatabase.Connection).fromJson<TProdutos>(Req.Body);
		if Assigned(LBodyObj) then
		begin
			if LBodyObj.GetValue('pro_valor_dinheiro') <> nil then
				Produtos.ValorDinheiro := LBodyObj.GetValue<Double>('pro_valor_dinheiro')
			else if LBodyObj.GetValue('valor_dinheiro') <> nil then
				Produtos.ValorDinheiro := LBodyObj.GetValue<Double>('valor_dinheiro')
			else if LBodyObj.GetValue('valordinheiro') <> nil then
				Produtos.ValorDinheiro := LBodyObj.GetValue<Double>('valordinheiro');

			if LBodyObj.GetValue('pro_valorv_prazo') <> nil then
				Produtos.ValorPrazo := LBodyObj.GetValue<Double>('pro_valorv_prazo')
			else if LBodyObj.GetValue('valor_prazo') <> nil then
				Produtos.ValorPrazo := LBodyObj.GetValue<Double>('valor_prazo')
			else if LBodyObj.GetValue('valorprazo') <> nil then
				Produtos.ValorPrazo := LBodyObj.GetValue<Double>('valorprazo');

			if LBodyObj.GetValue('pro_for') <> nil then
				Produtos.ForCodigo := LBodyObj.GetValue<Integer>('pro_for')
			else if LBodyObj.GetValue('forCodigo') <> nil then
				Produtos.ForCodigo := LBodyObj.GetValue<Integer>('forCodigo')
			else if LBodyObj.GetValue('fornecedorId') <> nil then
				Produtos.ForCodigo := LBodyObj.GetValue<Integer>('fornecedorId');

			if LBodyObj.GetValue('pro_gru') <> nil then
				Produtos.Gru := LBodyObj.GetValue<Integer>('pro_gru')
			else if LBodyObj.GetValue('gru') <> nil then
				Produtos.Gru := LBodyObj.GetValue<Integer>('gru')
			else if LBodyObj.GetValue('subgrupoId') <> nil then
				Produtos.Gru := LBodyObj.GetValue<Integer>('subgrupoId');
		end;
		Produtos.Cadastrar := 'S';
		Produtos.SalvaNoBanco(1);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Produtos.ToJson) as TJSONObject);
	finally
		Produtos.DisposeOf;
	end;
end;

class procedure TProdutosController.Router;
begin
	THorse.Group.Prefix('/v1')
  	.Route('/produtos')
      .Get(Get)
      .Post(Post)
      .Put(Put)
	  .&End;
	THorse.Group.Prefix('/v1')
  	.Route('/produtos/:id')
      .Get(GetForID)
      .Delete(Delete)
	  .&End;
  THorse.Group.Prefix('/v1')
  	.Route('/produtos/emLote')
    	.Post(PostEmLote)
	  .&End;
	THorse.Group.Prefix('/v1')
  	.Route('produtos/foto/:id')
    	.Post(UploadImage)
    	.Delete(DeleteImage)
	  .&End;
end;

class procedure TProdutosController.UploadImage(Req: THorseRequest; Res: THorseResponse);
var
	id               : string;
	Arquivo          : TMemoryStream;
	CaminhoPasta     : string;
	NomeArquivo      : string;
	Produto          : TProdutos;
	CaracterSeparador: Char;
begin
	Arquivo           := Req.Body<TMemoryStream>;
	id                := Req.Params.Items['id'];
	CaracterSeparador := TPath.DirectorySeparatorChar;
	CaminhoPasta      := TPath.Combine(GetCurrentDir, GetCurrentDir + CaracterSeparador + 'imagens' + CaracterSeparador + 'produtos' + CaracterSeparador);
	if not DirectoryExists(CaminhoPasta) then
		ForceDirectories(CaminhoPasta);
	NomeArquivo := ChangeFileExt(CaminhoPasta + id, '.png');
	if Assigned(Arquivo) then
	begin
		Arquivo.SaveToFile(NomeArquivo);
		Produto := TProdutos.Create(TDatabase.Connection);
		try
			Produto.BuscaDadosTabela(id.ToInteger());
			Produto.URL_Imagem := ExtractFileName(NomeArquivo);
			Produto.SalvaNoBanco(1);
			Res.Send<TJSONObject>(TJSONObject.Create.AddPair('foto', Produto.URL_Imagem)).Status(THTTPStatus.Created);
		finally
			Produto.DisposeOf;
		end;
	end
	else
	begin
		Res.Send<TJSONObject>(TJSONObject.Create.AddPair('msg', 'N�o foi poss�vel criar a imagem!')).Status(THTTPStatus.BadRequest);
	end;
end;

end.
