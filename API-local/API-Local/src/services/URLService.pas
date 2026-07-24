unit URLService;

interface

uses
  UnitEmpresa.Model,
  UnitConstants,
  UnitDatabase,
  HashService,
  System.JSON,
  System.SysUtils,
  System.Classes,
  System.Net.HttpClient,
  System.Net.URLClient,
  System.Net.HttpClientComponent,
  System.DateUtils;

type
  TURLService = class
  public
    class function GetURL(ACount: Integer): string;
    class function SendURL(): Boolean;
    class procedure PrintEmpresaClaim;
    class procedure TrySendURL();     // Valida retorno da SendURL para debug
  end;

implementation

uses
  UnitFunctions;

{ TURLService }

class function TURLService.GetURL(ACount: Integer): string;
var
  Client: TNetHTTPClient;
  Response: IHTTPResponse;
  LJSON: TJSONObject;
  LTunnels: TJSONArray;
  LTunnel: TJSONObject;
  LAux: string;

  const TIMEOUT_MS = 5000;
begin
  Result := '';

  // Buscou 5 vezes e falhou nas 5
  if ACount = 0 then
    Exit('ERRO_NGROK_OFFLINE');

  Client := TNetHTTPClient.Create(nil);
  try
    // Configuracao do timeout
    Client.ConnectionTimeout := TIMEOUT_MS;
    Client.ResponseTimeout   := TIMEOUT_MS;

    try
      Response := Client.Get('http://127.0.0.1:4040/api/tunnels');

      LJSON := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
      try
        // pega o array "tunnels"
        LTunnels := LJSON.GetValue<TJSONArray>('tunnels');

        if (LTunnels <> nil) and (LTunnels.Count > 0) then
        begin
          // pega o primeiro item do array
          LTunnel := LTunnels.Items[0] as TJSONObject;

          // pega o campo dentro do objeto
          LAux := LTunnel.GetValue<string>('public_url');

          // Se LAux for vazio, espera 1 segundo e tenta novamente
          if LAux.Trim.IsEmpty then
          begin
            Sleep(1000);
            Result := GetURL(ACount - 1);
            Exit;
          end;

          // Retorna URL valida
          Result := LAux;
        end
        else
        begin
          // Nao encontrou tunnels ainda
          Sleep(1000);
          Result := GetURL(ACount - 1);
        end;

      finally
        LJSON.Free;
      end;

    except
      // Ngrok ainda nao respondeu
      Sleep(1000);
      Result := GetURL(ACount - 1);
    end;

  finally
    Client.Free;
  end;
end;

class function TURLService.SendURL: Boolean;
var
  LURL, LTimestamp, LSignature, LDataToSign, LCNPJNormalizado, LNome, LClaim: string;
  LJSON: TJSONObject;
  LClient: TNetHTTPClient;
  LBody: TStringStream;
  LResponse: IHTTPResponse;
  LEmpresa: TEmpresa;
  LAPICentralURL: string;
  const TIMEOUT_MS = 5000;  // Define tempo maximo para tentativa de conexao e resposta
begin
  Result := False;

  // Obtem a URL publica do ngrok
  LURL := GetURL(5);  // Tenta buscar a URL do ngrok 5 vezes
  if LURL.IsEmpty or (LURL = 'ERRO_NGROK_OFFLINE') then
    Exit;

  // Depois de recebida a URL do ngrok, adicionar o base path v1
  LURL := LURL + '/v1';

  // No cenario real, buscar dentro do BD Local o CNPJ desta empresa
  // Simulando a busca do CNPJ da empresa configurada localmente
  LEmpresa := TEmpresa.Create(TDataBase.Connection);
  try
    LEmpresa.BuscaPorCampo('EMP_CODIGO', 1);
    LCNPJNormalizado := NormalizaCNPJ(LEmpresa.CNPJ);
    LNome := LEmpresa.Fantasia;
    LClaim := GeraClaimEmpresa(LCNPJNormalizado);

    // Formato ISO8601 para sincronia com a Central
    LTimestamp := DateToISO8601(Now);

    // Gera HMAC-SHA256(CNPJ normalizado + URL + Timestamp, CNPJ normalizado)
    LDataToSign := LCNPJNormalizado + LURL + LTimestamp;
    LSignature := THashService.CalcHMAC(LDataToSign, LCNPJNormalizado);

    LAPICentralURL := TConstants.URL_AUTENTICACAO + '/v1/update-url';

    LClient := TNetHTTPClient.Create(nil);
    try
      LClient.ContentType := 'application/json';

      // Configuracao do timeout
      LClient.ConnectionTimeout := TIMEOUT_MS;
      LClient.ResponseTimeout   := TIMEOUT_MS;

      try
//        Writeln(LURL);

        // 1a Tentativa: Atualiza a URL se a empresa ja estiver cadastrada
        LJSON := TJSONObject.Create;
        try
          LJSON.AddPair('cnpj', LCNPJNormalizado);
          LJSON.AddPair('url', LURL);
          LJSON.AddPair('timestamp', LTimestamp);
          LJSON.AddPair('assinatura', LSignature);
//
//          Writeln('Requisicao enviada na 1a tentativa:' + LJSON.ToString);

          LBody := TStringStream.Create(LJSON.ToString, TEncoding.UTF8);
          try
            LResponse := LClient.Post(LAPICentralURL, LBody);
          finally
            LBody.Free;
          end;
        finally
          LJSON.Free;
        end;

        if LResponse.StatusCode = 200 then
        begin
          Result := True;
          Exit;
        end;

        // 2a Tentativa: Se retornar 404 (nao cadastrada), tenta autocadastro
        if LResponse.StatusCode = 404 then
        begin
          Writeln('* Empresa nao cadastrada na Central. Tentando autocadastro...');

          LDataToSign := LCNPJNormalizado + LNome + LURL + LClaim + LTimestamp;
          LSignature := THashService.CalcHMAC(LDataToSign, LCNPJNormalizado);
          LAPICentralURL := TConstants.URL_AUTENTICACAO + '/v1/companies/self-register';

          LJSON := TJSONObject.Create;
          try
            LJSON.AddPair('cnpj', LCNPJNormalizado);
            LJSON.AddPair('nome', LNome);
            LJSON.AddPair('url', LURL);
            LJSON.AddPair('claim', LClaim);
            LJSON.AddPair('timestamp', LTimestamp);
            LJSON.AddPair('assinatura', LSignature);
//
//            Writeln('Requisicao enviada na 2a tentativa:' + LJSON.ToString);

            LBody := TStringStream.Create(LJSON.ToString, TEncoding.UTF8);
            try
              LResponse := LClient.Post(LAPICentralURL, LBody);
            finally
              LBody.Free;
            end;
          finally
            LJSON.Free;
          end;

          Result := (LResponse.StatusCode = 201);
        end;

      except
        on E: Exception do
        begin
          // Se estourar o timeout ou houver erro de rede, encerra o programa imediatamente
          Writeln('Encerrando o programa. Conexao com a API de Autenticacao nao estabelecida');
          Halt(1);
        end;
      end;
    finally
      LClient.Free;
    end;
  finally
    LEmpresa.Free;
  end;
end;

class procedure TURLService.PrintEmpresaClaim;
var
  LEmpresa: TEmpresa;
  LClaim: string;
begin
  LEmpresa := TEmpresa.Create(TDataBase.Connection);
  try
    LEmpresa.BuscaPorCampo('EMP_CODIGO', 1);
    LClaim := GeraClaimEmpresa(LEmpresa.CNPJ);

    Writeln('==================================');
    Writeln('Claim da empresa: ' + LClaim);
    Writeln('Use este claim no Dashboard para vincular a empresa.');
    Writeln('==================================');
    Writeln('');
  finally
    LEmpresa.Free;
  end;
end;

class procedure TURLService.TrySendURL;
var
  LReturn: Boolean;
begin
  PrintEmpresaClaim;

  LReturn := SendURL;

  if LReturn then
  begin
    Writeln('* Requisicao de Atualizacao/Autocadastro Bem-Sucedida!');
    Writeln('');
  end
  else
  begin
    Writeln('* Erro na requisicao de Atualizacao/Autocadastro!');
    Writeln('');
  end;
end;

end.
