unit UnitGrades.Controller;

interface

uses
	Horse,
	Horse.Commons,
	Classes,
	SysUtils,
	System.Json;

	type
	TGradesController = class
		class procedure Router;
		class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure GetGradeProduto(Req: THorseRequest; Res: THorseResponse);
		class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
		class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure AtualizaEstoqueProduto(const ACodProduto: Integer); static;
	end;

implementation

{ TGradesController }

uses
	UnitConnection.Model.Interfaces,
	UnitDatabase,
	UnitFunctions,
	UnitGrades.Model,
	UnitTabela.Helpers, FireDAC.Comp.Client;

class procedure TGradesController.AtualizaEstoqueProduto(const ACodProduto: Integer);
var
	LQuery: iQuery;
begin
	if ACodProduto <= 0 then Exit;
	try
		LQuery := TDatabase.Query;
		// 1. Atualiza a quantidade consolidada no cadastro mestre PRODUTOS
		LQuery.Clear;
		LQuery.Add(Format(
			'UPDATE PRODUTOS SET PRO_QUANTIDADE = ' +
			'  COALESCE((SELECT SUM(GRA_QUANTIDADE) FROM GRADES WHERE GRA_PRO = %d), 0) ' +
			'WHERE PRO_CODIGO = %d',
			[ACodProduto, ACodProduto]
		));
		LQuery.ExecSQL;

		// 2. Atualiza a quantidade do CD DOURADINA (Empresa 1) na tabela ESTOQUE_EMPRESA
		LQuery.Clear;
		LQuery.Add(Format(
			'UPDATE ESTOQUE_EMPRESA SET EE_QUANTIDADE = ' +
			'  COALESCE((SELECT SUM(GRA_QUANTIDADE) FROM GRADES WHERE GRA_PRO = %d), 0), ' +
			'  EE_DATA_ATUALIZACAO = CURRENT_TIMESTAMP ' +
			'WHERE EE_EMPRESA_ID = 1 AND EE_PRO_CODIGO = %d',
			[ACodProduto, ACodProduto]
		));
		LQuery.ExecSQL;

		if TFDQuery(LQuery.Query).RowsAffected = 0 then
		begin
			LQuery.Clear;
			LQuery.Add(Format(
				'INSERT INTO ESTOQUE_EMPRESA (EE_ID, EE_EMPRESA_ID, EE_PRO_CODIGO, EE_QUANTIDADE, EE_DATA_ATUALIZACAO) ' +
				'VALUES (%d, 1, %d, COALESCE((SELECT SUM(GRA_QUANTIDADE) FROM GRADES WHERE GRA_PRO = %d), 0), CURRENT_TIMESTAMP)',
				[UnitFunctions.GeraCodigo('ESTOQUE_EMPRESA', 'EE_ID'), ACodProduto, ACodProduto]
			));
			LQuery.ExecSQL;
		end;
	except
		on E: Exception do
			Writeln('-> Erro ao atualizar PRO_QUANTIDADE pelas GRADES: ' + E.Message);
	end;
end;

class procedure TGradesController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Grades: TGrades;
	id, LCodPro: Integer;
	LQuery: iQuery;
begin
	try
		id      := Req.Params.Items['id'].ToInteger();
		LCodPro := 0;
		LQuery  := TDatabase.Query;
		try
			LQuery.Open('SELECT GRA_PRO FROM GRADES WHERE GRA_CODIGO = ' + id.ToString);
			if not LQuery.Dataset.Eof then
				LCodPro := LQuery.Dataset.FieldByName('GRA_PRO').AsInteger;
		except
		end;

		Grades := TGrades.Create(TDatabase.Connection);
		Grades.Apagar(id);

		if LCodPro > 0 then
			AtualizaEstoqueProduto(LCodPro);

		Res.Send('').Status(THTTPStatus.NoContent);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	aJson: TJSONArray;
	Query: iQuery;
	LObj, LTamObj: TJSONObject;
	LSQL, LWhere: string;
	LCodPro: Integer;
	LSomenteComEstoque: Boolean;
begin
	aJson := TJSONArray.Create;
	Query := TDatabase.Query;
	try
		LCodPro := 0;
		if Req.Query.ContainsKey('produto_id') then
			LCodPro := StrToIntDef(Req.Query.Items['produto_id'], 0)
		else if Req.Query.ContainsKey('pro') then
			LCodPro := StrToIntDef(Req.Query.Items['pro'], 0)
		else if Req.Query.ContainsKey('gra_pro') then
			LCodPro := StrToIntDef(Req.Query.Items['gra_pro'], 0)
		else if Req.Query.ContainsKey('pro_codigo') then
			LCodPro := StrToIntDef(Req.Query.Items['pro_codigo'], 0)
		else if Req.Query.ContainsKey('codigo') then
			LCodPro := StrToIntDef(Req.Query.Items['codigo'], 0);

		LSomenteComEstoque := False;
		if Req.Query.ContainsKey('somente_com_estoque') and (UpperCase(Req.Query.Items['somente_com_estoque']) = 'S') then
			LSomenteComEstoque := True
		else if Req.Query.ContainsKey('com_estoque') and (LowerCase(Req.Query.Items['com_estoque']) = 'true') then
			LSomenteComEstoque := True;

		LSQL := 
			'SELECT G.GRA_CODIGO, G.GRA_PRO, G.GRA_VALOR, G.GRA_VALOR_DINHEIRO, G.GRA_VALOR_PRAZO, ' +
			'G.GRA_TAM, G.GRA_QUANTIDADE, G.GRA_CODBARRA, G.GRA_COR, ' +
			'T.TAM_TAMANHO, T.TAM_SIGLA ' +
			'FROM GRADES G ' +
			'LEFT JOIN TAMANHOS T ON T.TAM_CODIGO = G.GRA_TAM ';

		LWhere := '';
		if LCodPro > 0 then
			LWhere := 'WHERE G.GRA_PRO = ' + IntToStr(LCodPro);

		if LSomenteComEstoque then
		begin
			if LWhere = '' then
				LWhere := 'WHERE COALESCE(G.GRA_QUANTIDADE, 0) > 0'
			else
				LWhere := LWhere + ' AND COALESCE(G.GRA_QUANTIDADE, 0) > 0';
		end;

		LSQL := LSQL + LWhere + ' ORDER BY G.GRA_CODIGO';
		Query.Open(LSQL);
		Query.Dataset.First;
		while not Query.Dataset.Eof do
		begin
			LObj := TJSONObject.Create;
			LObj.AddPair('codigo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_CODIGO').AsInteger));
			LObj.AddPair('gra_codigo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_CODIGO').AsInteger));
			LObj.AddPair('pro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_PRO').AsInteger));
			LObj.AddPair('gra_pro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_PRO').AsInteger));
			LObj.AddPair('tam', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_TAM').AsInteger));
			LObj.AddPair('gra_tam', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_TAM').AsInteger));
			
			if not Query.Dataset.FieldByName('TAM_SIGLA').IsNull and (Query.Dataset.FieldByName('TAM_SIGLA').AsString <> '') then
			begin
				LObj.AddPair('tam_nome', Query.Dataset.FieldByName('TAM_SIGLA').AsString);
				LObj.AddPair('sigla', Query.Dataset.FieldByName('TAM_SIGLA').AsString);
				LObj.AddPair('tamanho_str', Query.Dataset.FieldByName('TAM_SIGLA').AsString);
			end
			else if not Query.Dataset.FieldByName('TAM_TAMANHO').IsNull and (Query.Dataset.FieldByName('TAM_TAMANHO').AsString <> '') then
			begin
				LObj.AddPair('tam_nome', Query.Dataset.FieldByName('TAM_TAMANHO').AsString);
				LObj.AddPair('sigla', Query.Dataset.FieldByName('TAM_TAMANHO').AsString);
				LObj.AddPair('tamanho_str', Query.Dataset.FieldByName('TAM_TAMANHO').AsString);
			end
			else
			begin
				LObj.AddPair('tam_nome', 'Tam #' + Query.Dataset.FieldByName('GRA_TAM').AsString);
				LObj.AddPair('sigla', 'Tam #' + Query.Dataset.FieldByName('GRA_TAM').AsString);
				LObj.AddPair('tamanho_str', 'Tam #' + Query.Dataset.FieldByName('GRA_TAM').AsString);
			end;

			LTamObj := TJSONObject.Create;
			LTamObj.AddPair('codigo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_TAM').AsInteger));
			LTamObj.AddPair('tamanho', Query.Dataset.FieldByName('TAM_TAMANHO').AsString);
			LTamObj.AddPair('sigla', Query.Dataset.FieldByName('TAM_SIGLA').AsString);
			LObj.AddPair('tamanho', LTamObj);

			LObj.AddPair('valor', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR').AsFloat));
			LObj.AddPair('gra_valor', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR').AsFloat));
			LObj.AddPair('valor_dinheiro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_DINHEIRO').AsFloat));
			LObj.AddPair('valorDinheiro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_DINHEIRO').AsFloat));
			LObj.AddPair('gra_valor_dinheiro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_DINHEIRO').AsFloat));
			LObj.AddPair('valor_prazo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_PRAZO').AsFloat));
			LObj.AddPair('valorPrazo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_PRAZO').AsFloat));
			LObj.AddPair('gra_valor_prazo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_PRAZO').AsFloat));

			LObj.AddPair('quantidade', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_QUANTIDADE').AsFloat));
			LObj.AddPair('gra_quantidade', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_QUANTIDADE').AsFloat));
			LObj.AddPair('codbarra', Query.Dataset.FieldByName('GRA_CODBARRA').AsString);
			LObj.AddPair('gra_codbarra', Query.Dataset.FieldByName('GRA_CODBARRA').AsString);
			LObj.AddPair('cor', Query.Dataset.FieldByName('GRA_COR').AsString);
			LObj.AddPair('gra_cor', Query.Dataset.FieldByName('GRA_COR').AsString);

			aJson.Add(LObj);
			Query.Dataset.Next;
		end;
		Res.Send<TJSONArray>(aJson);
	finally
		//
	end;
end;

class procedure TGradesController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Grades: TGrades;
	id    : Integer;
begin
	id := Req.Params.Items['id'].ToInteger();
	try
		Grades := TGrades.Create(TDatabase.Connection);
		Grades.BuscaDadosTabela(id);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Grades.ToJson) as TJSONObject);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.GetGradeProduto(Req: THorseRequest; Res: THorseResponse);
var
	aJson     : TJSONArray;
	Query     : iQuery;
	CodProduto: Integer;
	LObj, LTamObj: TJSONObject;
begin
	aJson := TJSONArray.Create;
	if not Req.Params.ContainsKey('id') then
		raise Exception.Create('Campo id é obrigatório');
	CodProduto := Req.Params.Items['id'].ToInteger();
	Query      := TDatabase.Query;
	try
		Query.Open(
			'SELECT G.GRA_CODIGO, G.GRA_PRO, G.GRA_VALOR, G.GRA_VALOR_DINHEIRO, G.GRA_VALOR_PRAZO, ' +
			'G.GRA_TAM, G.GRA_QUANTIDADE, G.GRA_CODBARRA, G.GRA_COR, ' +
			'T.TAM_TAMANHO, T.TAM_SIGLA ' +
			'FROM GRADES G ' +
			'LEFT JOIN TAMANHOS T ON T.TAM_CODIGO = G.GRA_TAM ' +
			'WHERE G.GRA_PRO = ' + CodProduto.ToString + ' ORDER BY G.GRA_CODIGO'
		);
		Query.Dataset.First;
		while not Query.Dataset.Eof do
		begin
			LObj := TJSONObject.Create;
			LObj.AddPair('codigo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_CODIGO').AsInteger));
			LObj.AddPair('gra_codigo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_CODIGO').AsInteger));
			LObj.AddPair('pro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_PRO').AsInteger));
			LObj.AddPair('gra_pro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_PRO').AsInteger));
			LObj.AddPair('tam', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_TAM').AsInteger));
			LObj.AddPair('gra_tam', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_TAM').AsInteger));
			
			if not Query.Dataset.FieldByName('TAM_SIGLA').IsNull and (Query.Dataset.FieldByName('TAM_SIGLA').AsString <> '') then
				LObj.AddPair('tam_nome', Query.Dataset.FieldByName('TAM_SIGLA').AsString)
			else if not Query.Dataset.FieldByName('TAM_TAMANHO').IsNull then
				LObj.AddPair('tam_nome', Query.Dataset.FieldByName('TAM_TAMANHO').AsString)
			else
				LObj.AddPair('tam_nome', 'Tam #' + Query.Dataset.FieldByName('GRA_TAM').AsString);

			LTamObj := TJSONObject.Create;
			LTamObj.AddPair('codigo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_TAM').AsInteger));
			LTamObj.AddPair('tamanho', Query.Dataset.FieldByName('TAM_TAMANHO').AsString);
			LTamObj.AddPair('sigla', Query.Dataset.FieldByName('TAM_SIGLA').AsString);
			LObj.AddPair('tamanho', LTamObj);

			LObj.AddPair('valor', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR').AsFloat));
			LObj.AddPair('gra_valor', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR').AsFloat));
			LObj.AddPair('valor_dinheiro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_DINHEIRO').AsFloat));
			LObj.AddPair('valorDinheiro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_DINHEIRO').AsFloat));
			LObj.AddPair('gra_valor_dinheiro', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_DINHEIRO').AsFloat));
			LObj.AddPair('valor_prazo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_PRAZO').AsFloat));
			LObj.AddPair('valorPrazo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_PRAZO').AsFloat));
			LObj.AddPair('gra_valor_prazo', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_VALOR_PRAZO').AsFloat));

			LObj.AddPair('quantidade', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_QUANTIDADE').AsFloat));
			LObj.AddPair('gra_quantidade', TJSONNumber.Create(Query.Dataset.FieldByName('GRA_QUANTIDADE').AsFloat));
			LObj.AddPair('codbarra', Query.Dataset.FieldByName('GRA_CODBARRA').AsString);
			LObj.AddPair('gra_codbarra', Query.Dataset.FieldByName('GRA_CODBARRA').AsString);
			LObj.AddPair('cor', Query.Dataset.FieldByName('GRA_COR').AsString);
			LObj.AddPair('gra_cor', Query.Dataset.FieldByName('GRA_COR').AsString);

			aJson.Add(LObj);
			Query.Dataset.Next;
		end;
		Res.Send<TJSONArray>(aJson);
	finally
		//
	end;
end;

class procedure TGradesController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Grades: TGrades;
	LBodyObj: TJSONObject;
begin
	try
		LBodyObj := Req.Body<TJSONObject>;
		Grades := TGrades.Create(TDatabase.Connection).fromJson<TGrades>(Req.Body);
		if Assigned(LBodyObj) then
		begin
			if (Grades.Codigo = 0) and (LBodyObj.GetValue('gra_codigo') <> nil) then
				Grades.Codigo := LBodyObj.GetValue<Integer>('gra_codigo');

			if (Grades.Pro = 0) then
			begin
				if LBodyObj.GetValue('gra_pro') <> nil then
					Grades.Pro := LBodyObj.GetValue<Integer>('gra_pro')
				else if LBodyObj.GetValue('pro') <> nil then
					Grades.Pro := LBodyObj.GetValue<Integer>('pro')
				else if LBodyObj.GetValue('produto') <> nil then
					Grades.Pro := LBodyObj.GetValue<Integer>('produto');
			end;

			if (Grades.Tam = 0) then
			begin
				if LBodyObj.GetValue('gra_tam') <> nil then
					Grades.Tam := LBodyObj.GetValue<Integer>('gra_tam')
				else if LBodyObj.GetValue('tam') <> nil then
					Grades.Tam := LBodyObj.GetValue<Integer>('tam')
				else if LBodyObj.GetValue('tamanho') <> nil then
				begin
					if LBodyObj.GetValue('tamanho') is TJSONNumber then
						Grades.Tam := LBodyObj.GetValue<Integer>('tamanho')
					else if (LBodyObj.GetValue('tamanho') is TJSONObject) and (TJSONObject(LBodyObj.GetValue('tamanho')).GetValue('codigo') <> nil) then
						Grades.Tam := TJSONObject(LBodyObj.GetValue('tamanho')).GetValue<Integer>('codigo');
				end;
			end;

			if (Grades.Valor = 0) then
			begin
				if LBodyObj.GetValue('gra_valor') <> nil then
					Grades.Valor := LBodyObj.GetValue<Double>('gra_valor')
				else if LBodyObj.GetValue('valor') <> nil then
					Grades.Valor := LBodyObj.GetValue<Double>('valor');
			end;

			if LBodyObj.GetValue('valor_dinheiro') <> nil then
				Grades.ValorDinheiro := LBodyObj.GetValue<Double>('valor_dinheiro')
			else if LBodyObj.GetValue('valordinheiro') <> nil then
				Grades.ValorDinheiro := LBodyObj.GetValue<Double>('valordinheiro')
			else if LBodyObj.GetValue('gra_valor_dinheiro') <> nil then
				Grades.ValorDinheiro := LBodyObj.GetValue<Double>('gra_valor_dinheiro')
			else if Grades.ValorDinheiro = 0 then
				Grades.ValorDinheiro := Grades.Valor;

			if LBodyObj.GetValue('valor_prazo') <> nil then
				Grades.ValorPrazo := LBodyObj.GetValue<Double>('valor_prazo')
			else if LBodyObj.GetValue('valorprazo') <> nil then
				Grades.ValorPrazo := LBodyObj.GetValue<Double>('valorprazo')
			else if LBodyObj.GetValue('gra_valor_prazo') <> nil then
				Grades.ValorPrazo := LBodyObj.GetValue<Double>('gra_valor_prazo')
			else if Grades.ValorPrazo = 0 then
				Grades.ValorPrazo := Grades.Valor;

			if Grades.Codbarra = '' then
			begin
				if LBodyObj.GetValue('gra_codbarra') <> nil then
					Grades.Codbarra := LBodyObj.GetValue<string>('gra_codbarra')
				else if LBodyObj.GetValue('codbarra') <> nil then
					Grades.Codbarra := LBodyObj.GetValue<string>('codbarra');
			end;

			if Grades.Cor = '' then
			begin
				if LBodyObj.GetValue('gra_cor') <> nil then
					Grades.Cor := LBodyObj.GetValue<string>('gra_cor')
				else if LBodyObj.GetValue('cor') <> nil then
					Grades.Cor := LBodyObj.GetValue<string>('cor');
			end;

			if Grades.Quantidade = 0 then
			begin
				if LBodyObj.GetValue('gra_quantidade') <> nil then
					Grades.Quantidade := LBodyObj.GetValue<Double>('gra_quantidade')
				else if LBodyObj.GetValue('quantidade') <> nil then
					Grades.Quantidade := LBodyObj.GetValue<Double>('quantidade');
			end;
		end;

		if Grades.Codigo = 0 then
			Grades.Codigo := GeraCodigo('GRADES', 'GRA_CODIGO');
		Grades.Cadastrar := 'S';
		Grades.SalvaNoBanco(0);
		AtualizaEstoqueProduto(Grades.Pro);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Grades.ToJson) as TJSONObject).Status(THTTPStatus.Created);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.PostEmLote(Req: THorseRequest; Res: THorseResponse);
var
	aJson     : TJSONArray;
	oJsonValue: TJSONValue;
	oJson     : TJSONObject;
	LQuery    : iQuery;
	FDQuery   : TFDQuery;
	i         : Integer;
	LItemObj  : TJSONObject;
	LCod, LBaseCod, LPro, LTam, LUltimoPro: Integer;
	LVlr, LQty: Double;
	LVlrDin, LVlrPrz: Double;
	LBar, LCor: string;
begin
	oJson := Req.Body<TJSONObject>;
	if not Assigned(oJson) or not oJson.TryGetValue<TJSONArray>('itens', aJson) or (aJson.Count = 0) then
	begin
		Res.Send<TJSONObject>(TJSONObject.Create.AddPair('msg', 'Nenhum item informado.')).Status(THTTPStatus.BadRequest);
		Exit;
	end;

	LQuery  := TDatabase.Query;
	FDQuery := TFDQuery(LQuery.Query);
	FDQuery.Close;
	FDQuery.SQL.Clear;
	FDQuery.SQL.Add('UPDATE OR INSERT INTO GRADES (GRA_CODIGO, GRA_PRO, GRA_VALOR, GRA_VALOR_DINHEIRO, GRA_VALOR_PRAZO, GRA_TAM, GRA_QUANTIDADE, GRA_CODBARRA, GRA_COR, GRA_CADASTRAR)');
	FDQuery.SQL.Add('VALUES (:GRA_CODIGO, :GRA_PRO, :GRA_VALOR, :GRA_VALOR_DINHEIRO, :GRA_VALOR_PRAZO, :GRA_TAM, :GRA_QUANTIDADE, :GRA_CODBARRA, :GRA_COR, ''S'')');
	FDQuery.SQL.Add('MATCHING (GRA_CODIGO)');
	FDQuery.Params.ArraySize := aJson.Count;
	LBaseCod := UnitFunctions.GeraCodigo('GRADES', 'GRA_CODIGO');
	LUltimoPro := 0;

	for i := 0 to Pred(aJson.Count) do
	begin
		oJsonValue := aJson.Items[i];
		LCod := 0;
		LPro := 0;
		LTam := 0;
		LVlr := 0.0;
		LVlrDin := 0.0;
		LVlrPrz := 0.0;
		LQty := 0.0;
		LBar := '';
		LCor := 'UNICA';

		if oJsonValue is TJSONObject then
		begin
			LItemObj := TJSONObject(oJsonValue);

			if LItemObj.GetValue('codigo') <> nil then
				LCod := LItemObj.GetValue<Integer>('codigo')
			else if LItemObj.GetValue('gra_codigo') <> nil then
				LCod := LItemObj.GetValue<Integer>('gra_codigo');

			if LItemObj.GetValue('pro') <> nil then
				LPro := LItemObj.GetValue<Integer>('pro')
			else if LItemObj.GetValue('gra_pro') <> nil then
				LPro := LItemObj.GetValue<Integer>('gra_pro')
			else if LItemObj.GetValue('produto') <> nil then
				LPro := LItemObj.GetValue<Integer>('produto');

			if LItemObj.GetValue('tam') <> nil then
				LTam := LItemObj.GetValue<Integer>('tam')
			else if LItemObj.GetValue('gra_tam') <> nil then
				LTam := LItemObj.GetValue<Integer>('gra_tam')
			else if LItemObj.GetValue('tamanho') <> nil then
			begin
				if LItemObj.GetValue('tamanho') is TJSONNumber then
					LTam := LItemObj.GetValue<Integer>('tamanho')
				else if (LItemObj.GetValue('tamanho') is TJSONObject) and (TJSONObject(LItemObj.GetValue('tamanho')).GetValue('codigo') <> nil) then
					LTam := TJSONObject(LItemObj.GetValue('tamanho')).GetValue<Integer>('codigo');
			end;

			if LItemObj.GetValue('valor') <> nil then
				LVlr := LItemObj.GetValue<Double>('valor')
			else if LItemObj.GetValue('gra_valor') <> nil then
				LVlr := LItemObj.GetValue<Double>('gra_valor');

			if LItemObj.GetValue('valor_dinheiro') <> nil then
				LVlrDin := LItemObj.GetValue<Double>('valor_dinheiro')
			else if LItemObj.GetValue('valordinheiro') <> nil then
				LVlrDin := LItemObj.GetValue<Double>('valordinheiro')
			else if LItemObj.GetValue('gra_valor_dinheiro') <> nil then
				LVlrDin := LItemObj.GetValue<Double>('gra_valor_dinheiro')
			else
				LVlrDin := LVlr;

			if LItemObj.GetValue('valor_prazo') <> nil then
				LVlrPrz := LItemObj.GetValue<Double>('valor_prazo')
			else if LItemObj.GetValue('valorprazo') <> nil then
				LVlrPrz := LItemObj.GetValue<Double>('valorprazo')
			else if LItemObj.GetValue('gra_valor_prazo') <> nil then
				LVlrPrz := LItemObj.GetValue<Double>('gra_valor_prazo')
			else
				LVlrPrz := LVlr;

			if LItemObj.GetValue('quantidade') <> nil then
				LQty := LItemObj.GetValue<Double>('quantidade')
			else if LItemObj.GetValue('gra_quantidade') <> nil then
				LQty := LItemObj.GetValue<Double>('gra_quantidade');

			if LItemObj.GetValue('codbarra') <> nil then
				LBar := LItemObj.GetValue<string>('codbarra')
			else if LItemObj.GetValue('gra_codbarra') <> nil then
				LBar := LItemObj.GetValue<string>('gra_codbarra');

			if LItemObj.GetValue('cor') <> nil then
				LCor := LItemObj.GetValue<string>('cor')
			else if LItemObj.GetValue('gra_cor') <> nil then
				LCor := LItemObj.GetValue<string>('gra_cor');
			if LPro > 0 then
				LUltimoPro := LPro;
		end;

		if LCod <= 0 then
		begin
			LCod := LBaseCod;
			Inc(LBaseCod);
		end;

		FDQuery.ParamByName('GRA_CODIGO').AsIntegers[i]         := LCod;
		FDQuery.ParamByName('GRA_PRO').AsIntegers[i]            := LPro;
		FDQuery.ParamByName('GRA_VALOR').AsCurrencys[i]         := LVlr;
		FDQuery.ParamByName('GRA_VALOR_DINHEIRO').AsCurrencys[i]:= LVlrDin;
		FDQuery.ParamByName('GRA_VALOR_PRAZO').AsCurrencys[i]   := LVlrPrz;
		FDQuery.ParamByName('GRA_TAM').AsIntegers[i]            := LTam;
		FDQuery.ParamByName('GRA_QUANTIDADE').AsFloats[i]       := LQty;
		FDQuery.ParamByName('GRA_CODBARRA').AsStrings[i]        := LBar;
		FDQuery.ParamByName('GRA_COR').AsStrings[i]             := LCor;
	end;

	FDQuery.Execute(aJson.Count, 0);
	if LUltimoPro > 0 then
		AtualizaEstoqueProduto(LUltimoPro);
	Res.Send<TJSONObject>(oJson);
end;

class procedure TGradesController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	Grades: TGrades;
	LBodyObj: TJSONObject;
begin
	try
		LBodyObj := Req.Body<TJSONObject>;
		Grades := TGrades.Create(TDatabase.Connection).fromJson<TGrades>(Req.Body);
		if Assigned(LBodyObj) then
		begin
			if (Grades.Codigo = 0) and (LBodyObj.GetValue('gra_codigo') <> nil) then
				Grades.Codigo := LBodyObj.GetValue<Integer>('gra_codigo');

			if (Grades.Pro = 0) then
			begin
				if LBodyObj.GetValue('gra_pro') <> nil then
					Grades.Pro := LBodyObj.GetValue<Integer>('gra_pro')
				else if LBodyObj.GetValue('pro') <> nil then
					Grades.Pro := LBodyObj.GetValue<Integer>('pro')
				else if LBodyObj.GetValue('produto') <> nil then
					Grades.Pro := LBodyObj.GetValue<Integer>('produto');
			end;

			if (Grades.Tam = 0) then
			begin
				if LBodyObj.GetValue('gra_tam') <> nil then
					Grades.Tam := LBodyObj.GetValue<Integer>('gra_tam')
				else if LBodyObj.GetValue('tam') <> nil then
					Grades.Tam := LBodyObj.GetValue<Integer>('tam')
				else if LBodyObj.GetValue('tamanho') <> nil then
				begin
					if LBodyObj.GetValue('tamanho') is TJSONNumber then
						Grades.Tam := LBodyObj.GetValue<Integer>('tamanho')
					else if (LBodyObj.GetValue('tamanho') is TJSONObject) and (TJSONObject(LBodyObj.GetValue('tamanho')).GetValue('codigo') <> nil) then
						Grades.Tam := TJSONObject(LBodyObj.GetValue('tamanho')).GetValue<Integer>('codigo');
				end;
			end;

			if (Grades.Valor = 0) then
			begin
				if LBodyObj.GetValue('gra_valor') <> nil then
					Grades.Valor := LBodyObj.GetValue<Double>('gra_valor')
				else if LBodyObj.GetValue('valor') <> nil then
					Grades.Valor := LBodyObj.GetValue<Double>('valor');
			end;

			if LBodyObj.GetValue('valor_dinheiro') <> nil then
				Grades.ValorDinheiro := LBodyObj.GetValue<Double>('valor_dinheiro')
			else if LBodyObj.GetValue('valordinheiro') <> nil then
				Grades.ValorDinheiro := LBodyObj.GetValue<Double>('valordinheiro')
			else if LBodyObj.GetValue('gra_valor_dinheiro') <> nil then
				Grades.ValorDinheiro := LBodyObj.GetValue<Double>('gra_valor_dinheiro')
			else if Grades.ValorDinheiro = 0 then
				Grades.ValorDinheiro := Grades.Valor;

			if LBodyObj.GetValue('valor_prazo') <> nil then
				Grades.ValorPrazo := LBodyObj.GetValue<Double>('valor_prazo')
			else if LBodyObj.GetValue('valorprazo') <> nil then
				Grades.ValorPrazo := LBodyObj.GetValue<Double>('valorprazo')
			else if LBodyObj.GetValue('gra_valor_prazo') <> nil then
				Grades.ValorPrazo := LBodyObj.GetValue<Double>('gra_valor_prazo')
			else if Grades.ValorPrazo = 0 then
				Grades.ValorPrazo := Grades.Valor;

			if Grades.Codbarra = '' then
			begin
				if LBodyObj.GetValue('gra_codbarra') <> nil then
					Grades.Codbarra := LBodyObj.GetValue<string>('gra_codbarra')
				else if LBodyObj.GetValue('codbarra') <> nil then
					Grades.Codbarra := LBodyObj.GetValue<string>('codbarra');
			end;

			if Grades.Cor = '' then
			begin
				if LBodyObj.GetValue('gra_cor') <> nil then
					Grades.Cor := LBodyObj.GetValue<string>('gra_cor')
				else if LBodyObj.GetValue('cor') <> nil then
					Grades.Cor := LBodyObj.GetValue<string>('cor');
			end;

			if Grades.Quantidade = 0 then
			begin
				if LBodyObj.GetValue('gra_quantidade') <> nil then
					Grades.Quantidade := LBodyObj.GetValue<Double>('gra_quantidade')
				else if LBodyObj.GetValue('quantidade') <> nil then
					Grades.Quantidade := LBodyObj.GetValue<Double>('quantidade');
			end;
		end;

		Grades.Cadastrar := 'S';
		Grades.SalvaNoBanco(1);
		AtualizaEstoqueProduto(Grades.Pro);
		Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Grades.ToJson) as TJSONObject);
	finally
		Grades.DisposeOf;
	end;
end;

class procedure TGradesController.Router;
begin
	THorse.Group.Prefix('/v1')
		.Route('/grades')
			.Get(Get)
			.Post(Post)
			.Put(Put)
		.&End;

	THorse.Group.Prefix('/v1')
		.Route('/grades/:id')
			.Get(GetForID)
			.Delete(Delete)
		.&End;

	THorse.Group.Prefix('/v1')
		.Route('/grades/produto/:id')
			.Get(GetGradeProduto)
		.&End;

	THorse.Group.Prefix('/v1')
		.Route('/grades/emLote')
			.Post(PostEmLote)
		.&End;

	THorse.Group.Prefix('/v1')
		.Route('/grades/lote')
			.Post(PostEmLote)
		.&End;
end;

end.
