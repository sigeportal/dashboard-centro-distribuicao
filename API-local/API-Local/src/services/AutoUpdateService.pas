unit AutoUpdateService;

interface

uses
  SysUtils,
  Classes,
  IniFiles,
  JSON,
  Windows,
  ShellAPI,
  IdFTP,
  IdFTPCommon,
  System.Net.HttpClient;

type
  TAutoUpdate = class
  private
    class function ConfigPath: string; static;
    class function AppDirectory: string; static;
    class function CompareVersions(const VersaoLocal, VersaoServidor: string): Integer; static;
    class function DownloadRemoteFile(const Host, Usuario, Senha: string; Porta: Integer;
      const RemotePathOrUrl, CaminhoLocal: string): Boolean; static;
    class function CreateUpdaterScript(const NewExePath, OldVersion, NewVersion: string): string; static;
    class function StartUpdater(const ScriptPath: string): Boolean; static;
    class function EscapePowerShellValue(const Value: string): string; static;
  public
    class function CheckUpdate: Integer;
    class function ObterVersionJson(const Host, Usuario, Senha, RemotePathOrUrl: string;
      Porta: Integer = 21): string;
    class function VerificaVersionJson(const VersaoLocal, VersaoServidor: string): Boolean;
  end;

implementation

{ TAutoUpdate }

class function TAutoUpdate.AppDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

class function TAutoUpdate.ConfigPath: string;
begin
  if FileExists(AppDirectory + 'sinc_config.ini') then
    Result := AppDirectory + 'sinc_config.ini'
  else
    Result := AppDirectory + 'config.ini';
end;

class function TAutoUpdate.CheckUpdate: Integer;
var
  LIni: TIniFile;
  LFtpHost, LFtpUser, LFtpPass, LManifestPath: string;
  LLocalVersion, LServerVersion, LDownloadUrl: string;
  LFtpPort: Integer;
  LAutoUpdate: Boolean;
  LVersionJson: string;
  LJsonValue, LVersionValue, LDownloadValue: TJSONValue;
  LJson: TJSONObject;
  LUpdateDir, LNewExePath, LScriptPath: string;
begin
  Result := 0; // 0 = sem atualizacao, 1 = atualizacao iniciada, negativos = erro

  if not FileExists(ConfigPath) then
  begin
    Writeln('AutoUpdate: Arquivo de configuracao nao encontrado em ' + ConfigPath);
    Exit(-1);
  end;

  LIni := TIniFile.Create(ConfigPath);
  try
    LAutoUpdate := LIni.ReadBool('Update', 'AutoUpdate', True);
    if not LAutoUpdate then
    begin
      Writeln('AutoUpdate: Atualizacao automatica desativada no config.');
      Exit(0);
    end;

    LLocalVersion := Trim(LIni.ReadString('App', 'Version', '1.0.0'));
    LFtpHost := Trim(LIni.ReadString('Update', 'FtpHost', ''));
    LFtpPort := LIni.ReadInteger('Update', 'FtpPort', 21);
    LFtpUser := LIni.ReadString('Update', 'FtpUser', '');
    LFtpPass := LIni.ReadString('Update', 'FtpPass', '');
    LManifestPath := Trim(LIni.ReadString('Update', 'RemoteFilePath', ''));
  finally
    LIni.Free;
  end;

  if LManifestPath.IsEmpty and LFtpHost.IsEmpty then
  begin
    Writeln('AutoUpdate: Configuracao de update (RemoteFilePath/FtpHost) nao definida.');
    Exit(-2);
  end;

  LVersionJson := ObterVersionJson(LFtpHost, LFtpUser, LFtpPass, LManifestPath, LFtpPort);
  if LVersionJson.IsEmpty then
    Exit(-3);

  LJsonValue := TJSONObject.ParseJSONValue(LVersionJson);
  try
    if not (LJsonValue is TJSONObject) then
    begin
      Writeln('AutoUpdate: version.json invalido.');
      Exit(-4);
    end;

    LJson := TJSONObject(LJsonValue);
    LVersionValue := LJson.GetValue('version');
    LDownloadValue := LJson.GetValue('downloadUrl');

    if (LVersionValue = nil) or (LDownloadValue = nil) then
    begin
      Writeln('AutoUpdate: version.json sem os campos version ou downloadUrl.');
      Exit(-5);
    end;

    LServerVersion := Trim(LVersionValue.Value);
    LDownloadUrl := Trim(LDownloadValue.Value);
  finally
    LJsonValue.Free;
  end;

  if not VerificaVersionJson(LLocalVersion, LServerVersion) then
  begin
    Writeln('AutoUpdate: API ja esta na versao mais recente (' + LLocalVersion + ').');
    Exit(0);
  end;

  Writeln('AutoUpdate: Nova versao encontrada! Local=' + LLocalVersion + ', Servidor=' + LServerVersion);

  LUpdateDir := AppDirectory + 'updates';
  ForceDirectories(LUpdateDir);
  LNewExePath := IncludeTrailingPathDelimiter(LUpdateDir) + ExtractFileName(ParamStr(0)) + '.new';

  if not DownloadRemoteFile(LFtpHost, LFtpUser, LFtpPass, LFtpPort, LDownloadUrl, LNewExePath) then
    Exit(-6);

  LScriptPath := CreateUpdaterScript(LNewExePath, LLocalVersion, LServerVersion);
  if LScriptPath.IsEmpty then
    Exit(-7);

  if not StartUpdater(LScriptPath) then
    Exit(-8);

  Writeln('AutoUpdate: Atualizador iniciado com sucesso. Encerrando API para aplicar a nova versao...');
  Result := 1;
end;

class function TAutoUpdate.CompareVersions(const VersaoLocal, VersaoServidor: string): Integer;
var
  LLocalParts, LServerParts: TStringList;
  I, LMaxCount, LLocalValue, LServerValue: Integer;

  procedure FillParts(const Version: string; Parts: TStringList);
  var
    LText: string;
  begin
    LText := StringReplace(Version, '.', sLineBreak, [rfReplaceAll]);
    Parts.Text := LText;
  end;

  function PartValue(Parts: TStringList; Index: Integer): Integer;
  begin
    Result := 0;
    if Index < Parts.Count then
      Result := StrToIntDef(Trim(Parts[Index]), 0);
  end;

begin
  Result := 0;
  LLocalParts := TStringList.Create;
  LServerParts := TStringList.Create;
  try
    FillParts(VersaoLocal, LLocalParts);
    FillParts(VersaoServidor, LServerParts);

    LMaxCount := LLocalParts.Count;
    if LServerParts.Count > LMaxCount then
      LMaxCount := LServerParts.Count;

    for I := 0 to LMaxCount - 1 do
    begin
      LLocalValue := PartValue(LLocalParts, I);
      LServerValue := PartValue(LServerParts, I);

      if LServerValue > LLocalValue then
        Exit(1);

      if LServerValue < LLocalValue then
        Exit(-1);
    end;
  finally
    LLocalParts.Free;
    LServerParts.Free;
  end;
end;

class function TAutoUpdate.CreateUpdaterScript(const NewExePath, OldVersion, NewVersion: string): string;
var
  LScript: TStringList;
  LScriptPath, LAppExePath, LBackupDir, LBackupExePath: string;
begin
  Result := '';
  LScriptPath := AppDirectory + 'apply_update.bat';
  LAppExePath := ParamStr(0);
  LBackupDir := AppDirectory + 'backup';
  ForceDirectories(LBackupDir);
  LBackupExePath := IncludeTrailingPathDelimiter(LBackupDir) +
    ChangeFileExt(ExtractFileName(LAppExePath), '_' + OldVersion + '.bak');

  LScript := TStringList.Create;
  try
    LScript.Add('@echo off');
    LScript.Add('setlocal');
    LScript.Add('set "APP_EXE=' + LAppExePath + '"');
    LScript.Add('set "NEW_EXE=' + NewExePath + '"');
    LScript.Add('set "BACKUP_EXE=' + LBackupExePath + '"');
    LScript.Add('set "CONFIG_INI=' + ConfigPath + '"');
    LScript.Add('set "NEW_VERSION=' + NewVersion + '"');
    LScript.Add('timeout /t 2 /nobreak > nul');
    LScript.Add(':wait_api');
    LScript.Add('tasklist /FI "IMAGENAME eq ' + ExtractFileName(LAppExePath) + '" | find /I "' + ExtractFileName(LAppExePath) + '" > nul');
    LScript.Add('if not errorlevel 1 (');
    LScript.Add('  timeout /t 1 /nobreak > nul');
    LScript.Add('  goto wait_api');
    LScript.Add(')');
    LScript.Add('if exist "%BACKUP_EXE%" del /F /Q "%BACKUP_EXE%"');
    LScript.Add('if exist "%APP_EXE%" move /Y "%APP_EXE%" "%BACKUP_EXE%"');
    LScript.Add('move /Y "%NEW_EXE%" "%APP_EXE%"');
    LScript.Add('if errorlevel 1 goto rollback');
    LScript.Add('powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=''' + EscapePowerShellValue(ConfigPath) + '''; $v=''' + EscapePowerShellValue(NewVersion) + '''; $c=Get-Content -Raw -LiteralPath $p; $c=$c -replace ''(?m)^Version=.*$'', (''Version='' + $v); Set-Content -LiteralPath $p -Value $c -Encoding Default"');
    LScript.Add('start "" "%APP_EXE%"');
    LScript.Add('del "%~f0"');
    LScript.Add('exit /b 0');
    LScript.Add(':rollback');
    LScript.Add('if exist "%BACKUP_EXE%" move /Y "%BACKUP_EXE%" "%APP_EXE%"');
    LScript.Add('exit /b 1');
    LScript.SaveToFile(LScriptPath, TEncoding.Default);
    Result := LScriptPath;
  except
    on E: Exception do
      Writeln('AutoUpdate: erro ao criar script de atualizacao: ' + E.Message);
  end;
  LScript.Free;
end;

class function TAutoUpdate.DownloadRemoteFile(const Host, Usuario, Senha: string;
  Porta: Integer; const RemotePathOrUrl, CaminhoLocal: string): Boolean;
var
  FTP: TIdFTP;
  HTTP: THTTPClient;
  FileStream: TFileStream;
begin
  Result := False;

  // Suporte HTTP / HTTPS
  if RemotePathOrUrl.ToLower.StartsWith('http://') or RemotePathOrUrl.ToLower.StartsWith('https://') then
  begin
    HTTP := THTTPClient.Create;
    FileStream := TFileStream.Create(CaminhoLocal, fmCreate);
    try
      try
        HTTP.Get(RemotePathOrUrl, FileStream);
        Result := FileExists(CaminhoLocal) and (FileStream.Size > 0);
      except
        on E: Exception do
          Writeln('AutoUpdate: Erro ao baixar via HTTP/HTTPS: ' + E.Message);
      end;
    finally
      FileStream.Free;
      HTTP.Free;
    end;
    Exit;
  end;

  // Suporte FTP
  FTP := TIdFTP.Create(nil);
  try
    try
      FTP.Host := Host;
      FTP.Username := Usuario;
      FTP.Password := Senha;
      FTP.Port := Porta;
      FTP.Passive := True;
      FTP.TransferType := ftBinary;

      FTP.Connect;
      try
        FTP.Get(RemotePathOrUrl, CaminhoLocal, True);
      finally
        FTP.Disconnect;
      end;

      Result := FileExists(CaminhoLocal);
    except
      on E: Exception do
        Writeln('AutoUpdate: Erro ao baixar via FTP: ' + E.Message);
    end;
  finally
    FTP.Free;
  end;
end;

class function TAutoUpdate.EscapePowerShellValue(const Value: string): string;
begin
  Result := StringReplace(Value, '''', '''''', [rfReplaceAll]);
end;

class function TAutoUpdate.ObterVersionJson(const Host, Usuario, Senha,
  RemotePathOrUrl: string; Porta: Integer): string;
var
  FTP: TIdFTP;
  HTTP: THTTPClient;
  StringStream: TStringStream;
  HTTPResp: IHTTPResponse;
begin
  Result := '';

  // Suporte HTTP / HTTPS
  if RemotePathOrUrl.ToLower.StartsWith('http://') or RemotePathOrUrl.ToLower.StartsWith('https://') then
  begin
    HTTP := THTTPClient.Create;
    try
      try
        HTTPResp := HTTP.Get(RemotePathOrUrl);
        if HTTPResp.StatusCode = 200 then
          Result := HTTPResp.ContentAsString(TEncoding.UTF8);
      except
        on E: Exception do
          Writeln('AutoUpdate: Erro ao ler version.json via HTTP/HTTPS: ' + E.Message);
      end;
    finally
      HTTP.Free;
    end;
    Exit;
  end;

  // Suporte FTP
  FTP := TIdFTP.Create(nil);
  StringStream := TStringStream.Create('', TEncoding.UTF8);
  try
    try
      FTP.Host := Host;
      FTP.Username := Usuario;
      FTP.Password := Senha;
      FTP.Port := Porta;
      FTP.Passive := True;

      FTP.Connect;
      try
        FTP.Get(RemotePathOrUrl, StringStream);
        StringStream.Position := 0;
        Result := StringStream.DataString;
      finally
        FTP.Disconnect;
      end;
    except
      on E: Exception do
        Writeln('AutoUpdate: Erro ao ler version.json via FTP: ' + E.Message);
    end;
  finally
    FTP.Free;
    StringStream.Free;
  end;
end;

class function TAutoUpdate.StartUpdater(const ScriptPath: string): Boolean;
begin
  Result := ShellExecute(0, 'open', PChar(ScriptPath), nil, PChar(AppDirectory), SW_HIDE) > 32;
  if not Result then
    Writeln('AutoUpdate: Nao foi possivel iniciar o script de atualizacao.');
end;

class function TAutoUpdate.VerificaVersionJson(const VersaoLocal, VersaoServidor: string): Boolean;
begin
  Result := CompareVersions(VersaoLocal, VersaoServidor) > 0;
end;

end.
