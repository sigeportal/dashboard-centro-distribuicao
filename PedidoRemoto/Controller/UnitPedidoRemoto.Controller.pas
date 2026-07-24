unit UnitPedidoRemoto.Controller;

interface

uses
	UnitTabela.Helpers,
	UnitFuncoes,
	UnitProduto.Model,
	System.JSON,
	System.Generics.Collections,
  IBX.IBQuery, 
  System.Classes;

type
	TPedidoRemotoController = class
	private
		class procedure SincronizaFornecedores;
		class procedure SincronizaProdutos;
		class procedure SincronizaGrupos;
		class procedure SincronizaSubGrupos;
		class procedure SincronizaTotalizadores;
		class procedure SincronizaTamanhos;
		class procedure SincronizaGrades;
		class procedure MarcarSincronizados(Lista: TList<string>);
	public
		class function CadastrarProduto(CodPro: Integer): TProduto;
		class procedure ConectaServidor;
		class procedure SincronizarEmLote;
		class var JaSincronizouUmaVez: Boolean;
	end;

implementation

uses
	UnitTotalizadores.Model,
	UnitClientREST.Model.Interfaces,
	UnitDMPrincipal,
	UnitClientREST.Model,
	UnitConfiguracaoServidor.Singleton,
	System.SysUtils,
	UnitSubGrupos.Model,
	UnitFornecedores.Model,
	UnitProdutoRemoto.Model,
	UnitGrade.Model, 
  UnitTamanho.Model, 
  UnitGrupo1.Model, UnitPrincipal;

{ TPedidoRemotoController }

class procedure TPedidoRemotoController.ConectaServidor;
begin
	TThread.Synchronize(TThread.CurrentThread, 
  procedure 
  begin
  	UnitFuncoes.ConectaServidor;
  end);
end;

class procedure TPedidoRemotoController.MarcarSincronizados(Lista: TList<string>);
var
	Query: TIBQuery;
begin
	// marca como ja sincronizado
	Query             := TIBQuery.Create(nil);
	Query.Database    := DMPrincipal.IBDBPrincipal;
	Query.Transaction := DMPrincipal.IBTransPrincipal;
	try
		try
			Query.Close;
			Query.SQL.Clear;
			Query.SQL.Add(Format('UPDATE PRODUTOS SET PRO_SINCRONIZAR = ''N'' WHERE PRO_CODIGO IN (%s)', [''.Join(',', Lista.ToArray)]));
			Query.ExecSQL;
			Query.Transaction.CommitRetaining;
		except
			on E: Exception do
				raise Exception.Create('Erro ao atualizar estado de produtos sincronizados!' + sLineBreak + E.Message);
		end;
	finally
		Query.DisposeOf;
	end;
end;

class procedure TPedidoRemotoController.SincronizarEmLote;
begin
	TThread.CreateAnonymousThread(
  procedure
  begin
  	try
      try
        ConectaServidor;
        SincronizaFornecedores;
        SincronizaGrupos;
        SincronizaSubGrupos;
        SincronizaTotalizadores;
        SincronizaTamanhos;
        SincronizaGrades;
        SincronizaProdutos;
      except
          //on E: Exception do
            // Se falhar (sem internet), não avisa o operador. 
            // Deixa como "Pendente" para o próximo ciclo tentar enviar.
            //raise Exception.Create(E.Message);
      end;
    finally
    	FrmPrincipal.TimerSincronizacao.Enabled := False;
    end;
  end).Start;
end;

class procedure TPedidoRemotoController.SincronizaTamanhos;
var
	aJson   : TJSONArray;
	Tamanho : TTamanho;
	oJson   : TJSONObject;
	i       : Integer;
	Response: TClientResult;
  Query: TIBQuery;
begin
	TThread.Synchronize(TThread.CurrentThread, 
  procedure 
  begin
  	MensagemUsuario('Aguarde, sincronizando Tamanhos...', 1, False, False);
  end);
	aJson := TJSONArray.Create;
  Query := TIBQuery.Create(nil);
  Query.Database    := DMPrincipal.IBDBPrincipal;
  Query.Transaction := DMPrincipal.IBTransPrincipal;
  try
	  Query.Close;
    Query.SQL.Clear;
		Query.SQL.Add('SELECT TAM_CODIGO FROM TAMANHOS');
		Query.Open;
		Query.First;
		while not Query.Eof do
		begin
			Tamanho := TTamanho.Create(DMPrincipal.IBDBPrincipal);
			try
				Tamanho.BuscaDadosTabela(Query.FieldByName('TAM_CODIGO').AsInteger);
				// add no arrayJson
				oJson := Tamanho.Clone.ToJsonObject;
				aJson.AddElement(oJson);
			finally
				Tamanho.Free;
			end;
			Query.Next;
		end;
    Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/tamanhos/emLote').AddHeader('Content-Type', 'application/json').AddBody(TJSONObject.Create.AddPair('itens', aJson)).Post;
    if Response.StatusCode <> 200 then
      raise Exception.Create(Response.Content);
		TThread.Synchronize(TThread.CurrentThread, 
    procedure 
    begin
    	MensagemUsuario('Tamanhos sincronizados com sucesso!', 1, False, False);
    end);
		JaSincronizouUmaVez := True;
	finally
		aJson.DisposeOf;
	  Query.DisposeOf;
  end;
end;

class procedure TPedidoRemotoController.SincronizaTotalizadores;
var
	aJson        : TJSONArray;
	Totalizadores: TTotalizadores;
	oJson        : TJSONObject;
	i            : Integer;
	Response     : TClientResult;
  Query: TIBQuery;
begin
	TThread.Synchronize(TThread.CurrentThread, 
  procedure 
  begin
  	MensagemUsuario('Aguarde, sincronizando Totalizadores...', 1, False, False);
  end);
	aJson := TJSONArray.Create;
  Query := TIBQuery.Create(nil);
  Query.Database    := DMPrincipal.IBDBPrincipal;
  Query.Transaction := DMPrincipal.IBTransPrincipal;
	try
		Query.Close;
		Query.SQL.Clear;
		Query.SQL.Add('SELECT TOT_CODIGO FROM TOTALIZADORES');
		Query.Open;
		Query.First;
		while not Query.Eof do
		begin
			Totalizadores := TTotalizadores.Create(DMPrincipal.IBDBPrincipal);
			try
				Totalizadores.BuscaDadosTabela(Query.FieldByName('TOT_CODIGO').AsInteger);
				// add no arrayJson
				oJson := Totalizadores.Clone.ToJsonObject;
				aJson.AddElement(oJson);
			finally
				Totalizadores.Free;
			end;
			Query.Next;
		end;
    Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/totalizadores/emLote').AddHeader('Content-Type', 'application/json').AddBody(TJSONObject.Create.AddPair('itens', aJson)).Post;
    if Response.StatusCode <> 200 then
      raise Exception.Create(Response.Content);
		TThread.Synchronize(TThread.CurrentThread, 
    procedure 
    begin
	    MensagemUsuario('Totalizadores sincronizados com sucesso!', 1, False, False);
    end);
		JaSincronizouUmaVez := True;
	finally
		aJson.DisposeOf;
    Query.DisposeOf;
	end;
end;

class procedure TPedidoRemotoController.SincronizaSubGrupos;
var
	aJson   : TJSONArray;
	SubGrupo: TSubGrupos;
	oJson   : TJSONObject;
	i       : Integer;
	Response: TClientResult;
  Query: TIBQuery;
begin
	TThread.Synchronize(TThread.CurrentThread, 
  procedure 
  begin
  	MensagemUsuario('Aguarde, sincronizando SubGrupos...', 1, False, False);
  end);
	aJson := TJSONArray.Create;
	Query := TIBQuery.Create(nil);
  Query.Database    := DMPrincipal.IBDBPrincipal;
  Query.Transaction := DMPrincipal.IBTransPrincipal;
	try
		Query.Close;
		Query.SQL.Clear;
		Query.SQL.Add('SELECT GRU_CODIGO FROM GRUPOS');
		Query.Open;
		Query.First;
		while not Query.Eof do
		begin
			SubGrupo := TSubGrupos.Create(DMPrincipal.IBDBPrincipal);
			try
				SubGrupo.BuscaDadosTabela(Query.FieldByName('GRU_CODIGO').AsInteger);
				// add no arrayJson
				oJson := SubGrupo.Clone.ToJsonObject;
				aJson.AddElement(oJson);
			finally
				SubGrupo.Free;
			end;
			Query.Next;
		end;
    Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/subgrupos/emLote').AddHeader('Content-Type', 'application/json').AddBody(TJSONObject.Create.AddPair('itens', aJson)).Post;
    if Response.StatusCode <> 200 then
      raise Exception.Create(Response.Content);
		TThread.Synchronize(TThread.CurrentThread, 
    procedure 
		begin
  		MensagemUsuario('SubGrupos sincronizados com sucesso!', 1, False, False);
    end);
		JaSincronizouUmaVez := True;
	finally
		aJson.DisposeOf;
    Query.DisposeOf;
	end;
end;

class procedure TPedidoRemotoController.SincronizaFornecedores;
var
	aJson     : TJSONArray;
	Fornecedor: TFornecedores;
	oJson     : TJSONObject;
	i         : Integer;
	Response  : TClientResult;
  Query: TIBQuery;
begin
  TThread.Synchronize(TThread.CurrentThread, 
  procedure 
  begin
  	MensagemUsuario('Aguarde, sincronizando fornecedores...', 1, False, False);	
  end);
	aJson := TJSONArray.Create;
	Query := TIBQuery.Create(nil);
  Query.Database    := DMPrincipal.IBDBPrincipal;
  Query.Transaction := DMPrincipal.IBTransPrincipal;
	try
		Query.Close;
		Query.SQL.Clear;
		Query.SQL.Add('SELECT FOR_CODIGO FROM FORNECEDORES');
		Query.Open;
		Query.First;
		while not Query.Eof do
		begin
			Fornecedor := TFornecedores.Create(DMPrincipal.IBDBPrincipal);
			try
				Fornecedor.BuscaDadosTabela(Query.FieldByName('FOR_CODIGO').AsInteger);
				// add no arrayJson
				oJson := Fornecedor.Clone.ToJsonObject;
				aJson.AddElement(oJson);
			finally
				Fornecedor.Free;
			end;
			Query.Next;
		end;
    Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/fornecedores/emLote').AddHeader('Content-Type', 'application/json').AddBody(TJSONObject.Create.AddPair('itens', aJson)).Post;
    if Response.StatusCode <> 200 then
      raise Exception.Create(Response.Content);
		TThread.Synchronize(TThread.CurrentThread, 
    procedure 
    begin
    	MensagemUsuario('Fornecedores sincronizados com sucesso!', 1, False, False);
    end);
		JaSincronizouUmaVez := True;
	finally
		aJson.DisposeOf;
    Query.DisposeOf;
	end;
end;

class procedure TPedidoRemotoController.SincronizaGrades;
var
	aJson   : TJSONArray;
	Grades  : TGrades;
	oJson   : TJSONObject;
	i       : Integer;
	Response: TClientResult;
  Query: TIBQuery;
begin
	TThread.Synchronize(TThread.CurrentThread, 
  procedure 
  begin
  	MensagemUsuario('Aguarde, sincronizando Grades...', 1, False, False);
  end);
	aJson := TJSONArray.Create;
	Query := TIBQuery.Create(nil);
  Query.Database    := DMPrincipal.IBDBPrincipal;
  Query.Transaction := DMPrincipal.IBTransPrincipal;
	try
		Query.Close;
		Query.SQL.Clear;
		Query.SQL.Add('SELECT GRA_CODIGO FROM GRADES');
		Query.Open;
		if not Query.IsEmpty then
		begin
			Query.First;
			while not Query.Eof do
			begin
				Grades := TGrades.Create(DMPrincipal.IBDBPrincipal);
				try
					Grades.BuscaDadosTabela(Query.FieldByName('GRA_CODIGO').AsInteger);
					// add no arrayJson
					oJson := Grades.Clone.ToJsonObject;
					aJson.AddElement(oJson);
				finally
					Grades.Free;
				end;
				Query.Next;
			end;
      Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/grades/emLote').AddHeader('Content-Type', 'application/json').AddBody(TJSONObject.Create.AddPair('itens', aJson)).Post;
      if Response.StatusCode <> 200 then
        raise Exception.Create(Response.Content);
			TThread.Synchronize(TThread.CurrentThread, 
      procedure 
      begin
      	MensagemUsuario('Grades sincronizados com sucesso!', 1, False, False);
      end);
			JaSincronizouUmaVez := True;
		end;
	finally
		aJson.DisposeOf;
    Query.DisposeOf;
	end;
end;

class procedure TPedidoRemotoController.SincronizaGrupos;
var
	aJson   : TJSONArray;
	Grupo   : TGrupo1;
	oJson   : TJSONObject;
	i       : Integer;
	Response: TClientResult;
  Query: TIBQuery;
begin
	TThread.Synchronize(TThread.CurrentThread, 
  procedure 
  begin
  	MensagemUsuario('Aguarde, sincronizando Grupos...', 1, False, False);
  end);
	aJson := TJSONArray.Create;
	Query := TIBQuery.Create(nil);
  Query.Database    := DMPrincipal.IBDBPrincipal;
  Query.Transaction := DMPrincipal.IBTransPrincipal;
	try
		Query.Close;
		Query.SQL.Clear;
		Query.SQL.Add('SELECT G1_CODIGO FROM GRUPO_1');
		Query.Open;
		Query.First;
		while not Query.Eof do
		begin
			Grupo := TGrupo1.Create(DMPrincipal.IBDBPrincipal);
			try
				Grupo.BuscaDadosTabela(Query.FieldByName('G1_CODIGO').AsInteger);
				// add no arrayJson
				oJson := Grupo.Clone.ToJsonObject;
				aJson.AddElement(oJson);
			finally
				Grupo.Free;
			end;
			Query.Next;
		end;
    Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/grupos/emLote').AddHeader('Content-Type', 'application/json').AddBody(TJSONObject.Create.AddPair('itens', aJson)).Post;
    if Response.StatusCode <> 200 then
      raise Exception.Create(Response.Content);
		TThread.Synchronize(TThread.CurrentThread, 
    procedure 
    begin
    	MensagemUsuario('Grupos sincronizados com sucesso!', 1, False, False);
    end);
		JaSincronizouUmaVez := True;
	finally
		aJson.DisposeOf;
    Query.DisposeOf;
	end;
end;

class procedure TPedidoRemotoController.SincronizaProdutos;
var
	aJson           : TJSONArray;
	Produto         : TProduto;
	ProdutoRemoto   : TProdutoRemoto;
	oJson           : TJSONObject;
	i               : Integer;
	Response        : TClientResult;
	auxArrayJson    : TJSONArray;
	QtdTotal        : Integer;
	j               : Integer;
	Restante        : Integer;
	QtdRestante     : Integer;
	ListaCodProdutos: TList<string>;
  Query: TIBQuery;
const
	QtdLote = 50;
begin
	TThread.Synchronize(TThread.CurrentThread, 
  procedure 
  begin
  	MensagemUsuario('Aguarde, sincronizando produtos REMOTO->LOCAL...', 1, False, False);
  end);
	Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/produtos?cadastrar=S').Get();
	if Response.StatusCode = 200 then
	begin
		aJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONArray;
		for i := 0 to Pred(aJson.Count) do
		begin
			ProdutoRemoto := TProdutoRemoto.Create.fromJson<TProdutoRemoto>(aJson.Items[i].ToJSON);
			if ProdutoRemoto.Cadastrar.Contains('S') then
			begin
				CadastrarProduto(ProdutoRemoto.Codigo);
			end;
		end;
	end;
	TThread.Synchronize(TThread.CurrentThread, 
  procedure 
  begin
  	MensagemUsuario('Aguarde, sincronizando produtos LOCAL->REMOTO...', 1, False, False);
  end);
	ListaCodProdutos := TList<string>.Create;
	aJson            := TJSONArray.Create;
	Query := TIBQuery.Create(nil);
  Query.Database    := DMPrincipal.IBDBPrincipal;
  Query.Transaction := DMPrincipal.IBTransPrincipal;
	try
		Query.Close;
		Query.SQL.Clear;
		Query.SQL.Add('SELECT PRO_CODIGO FROM PRODUTOS WHERE PRO_SINCRONIZAR = ''S''');
		Query.Open;
		Query.First;
		while not Query.Eof do
		begin
			Produto := TProduto.Create(DMPrincipal.IBDBPrincipal);
			try
				Produto.BuscaDadosTabela(Query.FieldByName('PRO_CODIGO').AsInteger);
				ProdutoRemoto := TProdutoRemoto.Create;
				try
					ProdutoRemoto.Codigo         := Produto.Codigo;
					ProdutoRemoto.Nome           := Produto.Nome;
					ProdutoRemoto.ForCodigo      := Produto.CodFor;
					ProdutoRemoto.Fabricante     := Produto.Fabricante;
					ProdutoRemoto.Quantidadem    := Produto.Quantidadem;
					ProdutoRemoto.Quantidade     := Produto.Quantidade;
					ProdutoRemoto.Valorv         := Produto.Valorv;
					ProdutoRemoto.Valorcm        := Produto.Valorcm;
					ProdutoRemoto.Valorc         := Produto.Valorc;
					ProdutoRemoto.Valorl         := Produto.Valorl;
					ProdutoRemoto.Valorf         := Produto.Valorf;
					ProdutoRemoto.Quantidadef    := Produto.Quantidadef;
					ProdutoRemoto.Local          := Produto.Local;
					ProdutoRemoto.Embalagem      := Produto.Embalagem;
					ProdutoRemoto.Datauc         := Produto.Datauc;
					ProdutoRemoto.Gru            := Produto.Gru;
					ProdutoRemoto.Descricao      := Produto.Descricao;
					ProdutoRemoto.Dataua         := Produto.Dataua;
					ProdutoRemoto.Abc            := Produto.Abc;
					ProdutoRemoto.Codbarra       := Produto.Codbarra;
					ProdutoRemoto.Valors         := Produto.Valors;
					ProdutoRemoto.Tipo           := 0;
					ProdutoRemoto.CodTotalizador := Produto.CodTotalizador;
					ProdutoRemoto.Nome           := Produto.Nome.Substring(0, 50);
					ProdutoRemoto.Estado         := Produto.Estado;
					ProdutoRemoto.Valorp         := Produto.Valorp;
					ProdutoRemoto.Cadastrar      := 'N';
					// add no arrayJson
					oJson := ProdutoRemoto.ToJsonObject;
					aJson.AddElement(oJson);
				finally
					ProdutoRemoto.DisposeOf;
				end;
			finally
				Produto.Free;
			end;
			Query.Next;
		end;
    QtdTotal     := aJson.Count;
    QtdRestante  := aJson.Count;
    auxArrayJson := TJSONArray.Create;
    for i        := 0 to Pred(aJson.Count) do
    begin
      // adiciono na lista produtos sincronizados
      ListaCodProdutos.Add(aJson.Items[i].GetValue<string>('codigo'));
      auxArrayJson.AddElement(aJson.Items[i]);
      if (auxArrayJson.Count = QtdLote) or (QtdTotal < QtdLote) then
      begin
        if (QtdTotal < QtdLote) then
        begin
          Restante := i + 1;
          for j    := 0 to Pred(QtdTotal) do
          begin
            auxArrayJson.AddElement(aJson.Items[Restante]);
            Inc(Restante);
          end;
        end;
        Response := TClientREST.New(TConfiguracaoServidor.BaseURL + '/produtos/emLote').AddHeader('Content-Type', 'application/json').AddBody(TJSONObject.Create.AddPair('itens', auxArrayJson)).Post;
        if Response.StatusCode <> 200 then
          raise Exception.Create(Response.Content);
        // marca os ja sincronizados
        MarcarSincronizados(ListaCodProdutos);
        ListaCodProdutos.Clear; // lista para pegar novos produtos
        if (QtdTotal < QtdLote) then
          Break;
        auxArrayJson := TJSONArray.Create;
        QtdRestante  := QtdRestante - QtdLote;
        TThread.Synchronize(TThread.CurrentThread, 
        procedure 
        begin
        	MensagemUsuario(Format('Enviando produtos, %d de %d ...', [QtdRestante, QtdTotal]), 1, False, False);
      	end);
      end;
    end;
		// atualizo o estado dos produtos sincronizados
		TThread.Synchronize(TThread.CurrentThread, 
    procedure 
    begin
	    MensagemUsuario('Produtos sincronizados com sucesso!', 1, False, False);
    end);
	finally
		aJson.DisposeOf;
		ListaCodProdutos.DisposeOf;
    Query.DisposeOf;
	end;
end;

class function TPedidoRemotoController.CadastrarProduto(CodPro: Integer): TProduto;
var
	ProdutoRemoto : TProdutoRemoto;
	ProdutoLocal  : TProduto;
	SubGrupo      : TSubGrupos;
	SubGrupoRemoto: TSubGrupos;
begin
	try
		ProdutoRemoto := TProdutoRemoto.Create.Get<TProdutoRemoto>(CodPro);
		if ProdutoRemoto.Cadastrar.Contains('S') then
		begin
			TThread.Synchronize(TThread.CurrentThread, 
      procedure 
      begin
      	MensagemUsuario(Format('Cadastrando produto %s', [ProdutoRemoto.Nome]), 1, False, False);
      end);
			// grupo
			SubGrupo := TSubGrupos.Create(DMPrincipal.IBDBPrincipal);
			try
				SubGrupo.BuscaDadosTabela(ProdutoRemoto.Gru);
				if SubGrupo.Codigo = 0 then
				begin
					// obtem os dados dos subgrupo remotamente
					SubGrupoRemoto := TSubGrupos.Create.Get<TSubGrupos>(ProdutoRemoto.Gru);
					try
						// gera um novo
						SubGrupo.Codigo := DMPrincipal.GeraCodigo('GRUPOS', 'GRU_CODIGO');
						SubGrupo.Nome   := SubGrupoRemoto.Nome;
						SubGrupo.G1     := SubGrupoRemoto.G1;
						SubGrupo.SalvaNoBanco();
					finally
						SubGrupoRemoto.DisposeOf;
					end;
				end;
				// cria produto local
				ProdutoLocal                := TProduto.Create(DMPrincipal.IBDBPrincipal);
				ProdutoLocal.Codigo         := ProdutoRemoto.Codigo; // DMPrincipal.GeraCodigo('PRODUTOS', 'PRO_CODIGO');
				ProdutoLocal.CodFor         := ProdutoRemoto.ForCodigo;
				ProdutoLocal.Fabricante     := ProdutoRemoto.Fabricante;
				ProdutoLocal.Quantidadem    := Trunc(ProdutoRemoto.Quantidadem);
				ProdutoLocal.Quantidade     := ProdutoRemoto.Quantidade;
				ProdutoLocal.Valorv         := ProdutoRemoto.Valorv;
				ProdutoLocal.Valorcm        := ProdutoRemoto.Valorcm;
				ProdutoLocal.Valorc         := ProdutoRemoto.Valorc;
				ProdutoLocal.Valorl         := ProdutoRemoto.Valorl;
				ProdutoLocal.Valorf         := ProdutoRemoto.Valorf;
				ProdutoLocal.Quantidadef    := ProdutoRemoto.Quantidadef;
				ProdutoLocal.Local          := ProdutoRemoto.Local;
				ProdutoLocal.Embalagem      := ProdutoRemoto.Embalagem;
				ProdutoLocal.Datauc         := ProdutoRemoto.Datauc;
				ProdutoLocal.Gru            := SubGrupo.Codigo;
				ProdutoLocal.Descricao      := ProdutoRemoto.Descricao;
				ProdutoLocal.Dataua         := ProdutoRemoto.Dataua;
				ProdutoLocal.Abc            := ProdutoRemoto.Abc;
				ProdutoLocal.Codbarra       := ProdutoRemoto.Codbarra;
				ProdutoLocal.Valors         := ProdutoRemoto.Valors;
				ProdutoLocal.Tipo_item      := ProdutoRemoto.Tipo_item;
				ProdutoLocal.CodTotalizador := ProdutoRemoto.CodTotalizador;
				ProdutoLocal.Nome           := ProdutoRemoto.Nome.Substring(0, 50);
				ProdutoLocal.Estado         := ProdutoRemoto.Estado;
				ProdutoLocal.Valorp         := ProdutoRemoto.Valorp;
				ProdutoLocal.SalvaNoBanco();
				///
				// atualiza para já cadastrado
				ProdutoRemoto.Cadastrar := 'N';
				ProdutoRemoto.Post;
				// retorna o produto cadastrado
				Result := ProdutoLocal;
			finally
				ProdutoLocal.DisposeOf;
				SubGrupo.DisposeOf;
			end;
		end
		else
		begin
			Result := TProduto.Create(DMPrincipal.IBDBPrincipal);
			Result.BuscaDadosTabela(DMPrincipal.GeraCodigo('PRODUTOS', 'PRO_CODIGO') - 1);
		end;
	finally
		ProdutoRemoto.DisposeOf;
	end;
end;

end.
