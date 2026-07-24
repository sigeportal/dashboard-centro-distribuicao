unit SyncController;

interface

uses
  Horse,
  System.JSON,
  System.SysUtils,
  System.DateUtils,
  UnitFunctions,
  UnitConstants,
  UnitDatabase,
  UnitEmpresa.Model,
  UnitClientesSinc.Model,
  UnitProdutosSinc.Model,
  UnitVendasSinc.Model,
  UnitMovimentacoesSinc.Model,
  UnitRecebimentosSinc.Model,
  UnitOrdensSinc.Model,
  UnitGrupo1Sinc.Model,
  UnitGruposSinc.Model,
  UnitTamanhosSinc.Model,
  UnitGradesSinc.Model,
  UnitTransferencia.Model,
  UnitTransferenciaItem.Model,
  TokenService,
  JOSE.Core.JWT,
  JOSE.Core.Builder;

procedure Router;

implementation

function ExtractBearerToken(const AAuthorization: string): string;
const
  BearerPrefix = 'Bearer ';
begin
  Result := AAuthorization.Trim;
  if Result.StartsWith(BearerPrefix, True) then
    Result := Result.Substring(Length(BearerPrefix));
end;

function GetAuthenticatedEmpresa(Req: THorseRequest; out AEmpresa: TEmpresa; out AError: string): Boolean;
var
  LAuthorization: string;
  LToken: string;
  LJWT: TJWT;
  LCNPJ: string;
begin
  Result := False;
  AEmpresa := nil;
  AError := '';

  if not Req.Headers.ContainsKey('Authorization') then
  begin
    AError := 'Cabecalho Authorization nao informado';
    Exit;
  end;

  LAuthorization := Req.Headers.Items['Authorization'];
  LToken := ExtractBearerToken(LAuthorization);

  if LToken.Trim.IsEmpty then
  begin
    AError := 'Token nao informado';
    Exit;
  end;

  try
    LJWT := TJOSE.Verify(TTokenService.Secret, LToken);
    try
      if not Assigned(LJWT) then
      begin
        AError := 'Token invalido';
        Exit;
      end;

      LCNPJ := ApenasNumeros(LJWT.Claims.Subject);
      if LCNPJ.IsEmpty then
      begin
        AError := 'CNPJ nao encontrado no token';
        Exit;
      end;

      AEmpresa := TEmpresa.Create(TDataBase.Connection);
      AEmpresa.BuscaPorCampo('EMP_CNPJ', LCNPJ);

      if AEmpresa.Id <= 0 then
      begin
        AEmpresa.Free;
        AEmpresa := nil;
        AError := 'Empresa nao cadastrada com o CNPJ do token';
        Exit;
      end;

      Result := True;
    finally
      LJWT.Free;
    end;
  except
    on E: Exception do
      AError := 'Erro na verificacao do token: ' + E.Message;
  end;
end;

procedure SyncClientes(Req: THorseRequest; Res: THorseResponse);
var
  LEmpresa: TEmpresa;
  LError, datau: string;
  LBody: TJSONArray;
  LItem: TJSONObject;
  LCliente: TClientesSinc;
  I: Integer;
  LCodigoLocal: Integer;
begin
  if not GetAuthenticatedEmpresa(Req, LEmpresa, LError) then
  begin
    Res.Status(401).Send(TJSONObject.Create.AddPair('error', LError));
    Exit;
  end;

  try
    LBody := Req.Body<TJSONArray>;
    if not Assigned(LBody) then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Array JSON esperado no corpo'));
      Exit;
    end;

    for I := 0 to LBody.Count - 1 do
    begin
      LItem := LBody.Items[I] as TJSONObject;
      LCodigoLocal := LItem.GetValue<Integer>('codigo', 0);
      if LCodigoLocal = 0 then
        Continue;

      LCliente := TClientesSinc.Create(TDataBase.Connection);
      try
        LCliente.BuscaPorCampos(
          ['CLI_EMP_ID', 'CLI_CODIGO'],
          [LEmpresa.Id.ToString, LCodigoLocal.ToString]
        );

        if LCliente.Codigo <= 0 then
        begin
          LCliente.EmpId := LEmpresa.Id;
          LCliente.Codigo := LCodigoLocal;
        end;

        LCliente.Nome := LItem.GetValue<string>('nome', '');
        LCliente.Celular := LItem.GetValue<string>('celular', '');
        LCliente.Email := LItem.GetValue<string>('email', '');
        LCliente.Cidade := LItem.GetValue<string>('cidade', '');
        LCliente.Uf := LItem.GetValue<string>('uf', '');
        LCliente.CnpjCpf := LItem.GetValue<string>('cnpj_cpf', '');
        LCliente.Situacao := LItem.GetValue<string>('situacao', '');
        LCliente.Limite := LItem.GetValue<Double>('limite', 0.0);
        LCliente.Bairro := LItem.GetValue<string>('bairro', '');
        LCliente.Cep := LItem.GetValue<string>('cep', '');
        
        if LItem.TryGetValue('datau', datau) then
          LCliente.Datau := ISO8601ToDate(LItem.GetValue<string>('datau'))
        else
          LCliente.Datau := Now;

        LCliente.SalvaNoBanco(1);
      finally
        LCliente.DisposeOf;
      end;
    end;

    Res.Status(200).Send(TJSONObject.Create.AddPair('status', 'Clientes sincronizados com sucesso'));
  finally
    LEmpresa.DisposeOf;
  end;
end;

procedure SyncProdutos(Req: THorseRequest; Res: THorseResponse);
var
  LEmpresa: TEmpresa;
  LError, dataua: string;
  LBody: TJSONArray;
  LItem: TJSONObject;
  LProduto: TProdutosSinc;
  I: Integer;
  LCodigoLocal: Integer;
begin
  if not GetAuthenticatedEmpresa(Req, LEmpresa, LError) then
  begin
    Res.Status(401).Send(TJSONObject.Create.AddPair('error', LError));
    Exit;
  end;

  try
    LBody := Req.Body<TJSONArray>;
    if not Assigned(LBody) then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Array JSON esperado no corpo'));
      Exit;
    end;

    for I := 0 to LBody.Count - 1 do
    begin
      LItem := LBody.Items[I] as TJSONObject;
      LCodigoLocal := LItem.GetValue<Integer>('codigo', 0);
      if LCodigoLocal = 0 then
        Continue;

      LProduto := TProdutosSinc.Create(TDataBase.Connection);
      try
        LProduto.BuscaPorCampos(
          ['PRO_EMP_ID', 'PRO_CODIGO'],
          [LEmpresa.Id.ToString, LCodigoLocal.ToString]
        );

        if LProduto.Codigo <= 0 then
        begin
          LProduto.EmpId := LEmpresa.Id;
          LProduto.Codigo := LCodigoLocal;
        end;

        LProduto.Nome := LItem.GetValue<string>('nome', '');
        LProduto.Descricao := LItem.GetValue<string>('descricao', '');
        LProduto.Fabricante := LItem.GetValue<string>('fabricante', '');
        LProduto.Codbarra := LItem.GetValue<string>('codbarra', '');
        LProduto.Quantidade := LItem.GetValue<Double>('quantidade', 0.0);
        LProduto.Valorv := LItem.GetValue<Double>('valorv', 0.0);
        LProduto.Valorc := LItem.GetValue<Double>('valorc', 0.0);
        LProduto.Gru := LItem.GetValue<Integer>('gru', 0);
        LProduto.Estado := LItem.GetValue<string>('estado', '');
        LProduto.Gtin := LItem.GetValue<string>('gtin', '');

        if LItem.TryGetValue('dataua', dataua) then
          LProduto.Dataua := ISO8601ToDate(LItem.GetValue<string>('dataua'))
        else
          LProduto.Dataua := Today;

        LProduto.SalvaNoBanco(1);
      finally
        LProduto.DisposeOf;
      end;
    end;

    Res.Status(200).Send(TJSONObject.Create.AddPair('status', 'Produtos sincronizados com sucesso'));
  finally
    LEmpresa.DisposeOf;
  end;
end;

procedure SyncVendas(Req: THorseRequest; Res: THorseResponse);
var
  LEmpresa: TEmpresa;
  LError: string;
  LBody: TJSONArray;
  LItem: TJSONObject;
  LVenda: TVendasSinc;
  I: Integer;
  LCodigoLocal: Integer;
  data: string;
  hora: string;
  datac: string;
begin
  if not GetAuthenticatedEmpresa(Req, LEmpresa, LError) then
  begin
    Res.Status(401).Send(TJSONObject.Create.AddPair('error', LError));
    Exit;
  end;

  try
    LBody := Req.Body<TJSONArray>;
    if not Assigned(LBody) then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Array JSON esperado no corpo'));
      Exit;
    end;

    for I := 0 to LBody.Count - 1 do
    begin
      LItem := LBody.Items[I] as TJSONObject;
      LCodigoLocal := LItem.GetValue<Integer>('codigo', 0);
      if LCodigoLocal = 0 then
        Continue;

      LVenda := TVendasSinc.Create(TDataBase.Connection);
      try
        LVenda.BuscaPorCampos(
          ['VEN_EMP_ID', 'VEN_CODIGO'],
          [LEmpresa.Id.ToString, LCodigoLocal.ToString]
        );

        if LVenda.Codigo <= 0 then
        begin
          LVenda.EmpId := LEmpresa.Id;
          LVenda.Codigo := LCodigoLocal;
        end;

        if LItem.TryGetValue('data', data) then
          LVenda.Data := ISO8601ToDate(LItem.GetValue<string>('data'))
        else
          LVenda.Data := Today;

        LVenda.Valor := LItem.GetValue<Double>('valor', 0.0);

        if LItem.TryGetValue('hora', hora) then
          LVenda.Hora := StrToTime(LItem.GetValue<string>('hora'))
        else
          LVenda.Hora := Time;

        LVenda.CodFun := LItem.GetValue<Integer>('codFun', 0);
        LVenda.CodCli := LItem.GetValue<Integer>('codCli', 0);
        LVenda.Vendedor := LItem.GetValue<Integer>('vendedor', 0);
        LVenda.Nf := LItem.GetValue<Integer>('nf', 0);

        if LItem.TryGetValue('datac', datac) then
          LVenda.Datac := ISO8601ToDate(LItem.GetValue<string>('datac'))
        else
          LVenda.Datac := Today;

        LVenda.SalvaNoBanco(1);
      finally
        LVenda.DisposeOf;
      end;
    end;

    Res.Status(200).Send(TJSONObject.Create.AddPair('status', 'Vendas sincronizadas com sucesso'));
  finally
    LEmpresa.DisposeOf;
  end;
end;

procedure SyncMovimentacoes(Req: THorseRequest; Res: THorseResponse);
var
  LEmpresa: TEmpresa;
  LError: string;
  LBody: TJSONArray;
  LItem: TJSONObject;
  LMov: TMovimentacoesSinc;
  I: Integer;
  LCodigoLocal: Integer;
  data: string;
  datahora: string;
begin
  if not GetAuthenticatedEmpresa(Req, LEmpresa, LError) then
  begin
    Res.Status(401).Send(TJSONObject.Create.AddPair('error', LError));
    Exit;
  end;

  try
    LBody := Req.Body<TJSONArray>;
    if not Assigned(LBody) then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Array JSON esperado no corpo'));
      Exit;
    end;

    for I := 0 to LBody.Count - 1 do
    begin
      LItem := LBody.Items[I] as TJSONObject;
      LCodigoLocal := LItem.GetValue<Integer>('codigo', 0);
      if LCodigoLocal = 0 then
        Continue;

      LMov := TMovimentacoesSinc.Create(TDataBase.Connection);
      try
        LMov.BuscaPorCampos(
          ['MOV_EMP_ID', 'MOV_CODIGO'],
          [LEmpresa.Id.ToString, LCodigoLocal.ToString]
        );

        if LMov.Codigo <= 0 then
        begin
          LMov.EmpId := LEmpresa.Id;
          LMov.Codigo := LCodigoLocal;
        end;

        LMov.Descricao := LItem.GetValue<string>('descricao', '');
        LMov.Nome := LItem.GetValue<string>('nome', '');

        if LItem.TryGetValue('data', data) then
          LMov.Data := ISO8601ToDate(LItem.GetValue<string>('data'))
        else
          LMov.Data := Today;

        LMov.Debito := LItem.GetValue<Double>('debito', 0.0);
        LMov.Credito := LItem.GetValue<Double>('credito', 0.0);
        LMov.Tipo := LItem.GetValue<Integer>('tipo', 0);

        if LItem.TryGetValue('datahora', datahora) then
          LMov.Datahora := ISO8601ToDate(LItem.GetValue<string>('datahora'))
        else
          LMov.Datahora := Now;

        LMov.SalvaNoBanco(1);
      finally
        LMov.DisposeOf;
      end;
    end;

    Res.Status(200).Send(TJSONObject.Create.AddPair('status', 'Movimentacoes sincronizadas com sucesso'));
  finally
    LEmpresa.DisposeOf;
  end;
end;

procedure SyncRecebimentos(Req: THorseRequest; Res: THorseResponse);
var
  LEmpresa: TEmpresa;
  LError: string;
  LBody: TJSONArray;
  LItem: TJSONObject;
  LRec: TRecebimentosSinc;
  I: Integer;
  LCodigoLocal: Integer;
  vencimento: string;
  datar: string;
begin
  if not GetAuthenticatedEmpresa(Req, LEmpresa, LError) then
  begin
    Res.Status(401).Send(TJSONObject.Create.AddPair('error', LError));
    Exit;
  end;

  try
    LBody := Req.Body<TJSONArray>;
    if not Assigned(LBody) then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Array JSON esperado no corpo'));
      Exit;
    end;

    for I := 0 to LBody.Count - 1 do
    begin
      LItem := LBody.Items[I] as TJSONObject;
      LCodigoLocal := LItem.GetValue<Integer>('codigo', 0);
      if LCodigoLocal = 0 then
        Continue;

      LRec := TRecebimentosSinc.Create(TDataBase.Connection);
      try
        LRec.BuscaPorCampos(
          ['REC_EMP_ID', 'REC_CODIGO'],
          [LEmpresa.Id.ToString, LCodigoLocal.ToString]
        );

        if LRec.Codigo <= 0 then
        begin
          LRec.EmpId := LEmpresa.Id;
          LRec.Codigo := LCodigoLocal;
        end;

        LRec.Valor := LItem.GetValue<Double>('valor', 0.0);
        LRec.Duplicata := LItem.GetValue<string>('duplicata', '');
        LRec.Obs := LItem.GetValue<string>('obs', '');

        if LItem.TryGetValue('vencimento', vencimento) then
          LRec.Vencimento := ISO8601ToDate(LItem.GetValue<string>('vencimento'))
        else
          LRec.Vencimento := Today;

        if LItem.TryGetValue('datar', datar) then
          LRec.Datar := ISO8601ToDate(LItem.GetValue<string>('datar'))
        else
          LRec.Datar := Today;

        LRec.Situacao := LItem.GetValue<Integer>('situacao', 0);

        LRec.SalvaNoBanco(1);
      finally
        LRec.DisposeOf;
      end;
    end;

    Res.Status(200).Send(TJSONObject.Create.AddPair('status', 'Recebimentos sincronizados com sucesso'));
  finally
    LEmpresa.DisposeOf;
  end;
end;

procedure SyncOrdens(Req: THorseRequest; Res: THorseResponse);
var
  LEmpresa: TEmpresa;
  LError: string;
  LBody: TJSONArray;
  LItem: TJSONObject;
  LOrdem: TOrdensSinc;
  I: Integer;
  LCodigoLocal: Integer;
  data: string;
  hora: string;
  datapronto: string;
  dataentrega: string;
begin
  if not GetAuthenticatedEmpresa(Req, LEmpresa, LError) then
  begin
    Res.Status(401).Send(TJSONObject.Create.AddPair('error', LError));
    Exit;
  end;

  try
    LBody := Req.Body<TJSONArray>;
    if not Assigned(LBody) then
    begin
      Res.Status(400).Send(TJSONObject.Create.AddPair('error', 'Array JSON esperado no corpo'));
      Exit;
    end;

    for I := 0 to LBody.Count - 1 do
    begin
      LItem := LBody.Items[I] as TJSONObject;
      LCodigoLocal := LItem.GetValue<Integer>('codigo', 0);
      if LCodigoLocal = 0 then
        Continue;

      LOrdem := TOrdensSinc.Create(TDataBase.Connection);
      try
        LOrdem.BuscaPorCampos(
          ['ORD_EMP_ID', 'ORD_CODIGO'],
          [LEmpresa.Id.ToString, LCodigoLocal.ToString]
        );

        if LOrdem.Codigo <= 0 then
        begin
          LOrdem.EmpId := LEmpresa.Id;
          LOrdem.Codigo := LCodigoLocal;
        end;

        if LItem.TryGetValue('data', data) then
          LOrdem.Data := ISO8601ToDate(LItem.GetValue<string>('data'))
        else
          LOrdem.Data := Today;

        LOrdem.Valor := LItem.GetValue<Double>('valor', 0.0);

        if LItem.TryGetValue('hora', hora) then
          LOrdem.Hora := StrToTime(LItem.GetValue<string>('hora'))
        else
          LOrdem.Hora := Time;

        LOrdem.CodFun := LItem.GetValue<Integer>('codFun', 0);
        LOrdem.CodCli := LItem.GetValue<Integer>('codCli', 0);
        LOrdem.Obs := LItem.GetValue<string>('obs', '');
        LOrdem.Estado := LItem.GetValue<string>('estado', '');

        if LItem.TryGetValue('datapronto', datapronto) then
          LOrdem.Datapronto := ISO8601ToDate(LItem.GetValue<string>('datapronto'))
        else
          LOrdem.Datapronto := Today;

        if LItem.TryGetValue('dataentrega', dataentrega) then
          LOrdem.Dataentrega := ISO8601ToDate(LItem.GetValue<string>('dataentrega'))
        else
          LOrdem.Dataentrega := Today;

        LOrdem.Veiculo := LItem.GetValue<string>('veiculo', '');
        LOrdem.Placa := LItem.GetValue<string>('placa', '');

        LOrdem.SalvaNoBanco(1);
      finally
        LOrdem.DisposeOf;
      end;
    end;

    Res.Status(200).Send(TJSONObject.Create.AddPair('status', 'Ordens sincronizadas com sucesso'));
  finally
    LEmpresa.DisposeOf;
  end;
end;

procedure Router;
begin
  THorse.Group
    .Prefix('/v1/sync')
    .Post('clientes', SyncClientes)
    .Post('produtos', SyncProdutos)
    .Post('vendas', SyncVendas)
    .Post('movimentacoes', SyncMovimentacoes)
    .Post('recebimentos', SyncRecebimentos)
    .Post('ordens', SyncOrdens);
end;

end.
