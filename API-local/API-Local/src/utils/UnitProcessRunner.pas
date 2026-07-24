unit UnitProcessRunner;

interface

uses
  System.SysUtils, Winapi.Windows, Winapi.TlHelp32;

type
  EProcessExecutionError = class(Exception);
  TProcessRunner = class
  private
    { Verifica se o ngrok está sendo executado }
    class function IsNgrokRunning(const AExeName: string): Boolean;
  public
    { Inicia o comando somente se o ngrok não estiver sendo executado }
    class procedure StartNgrok(const ACommand: string);
  end;

implementation

{ TProcessRunner }

class function TProcessRunner.IsNgrokRunning(const AExeName: string): Boolean;
var
  LSnapshot: THandle;
  LProcessEntry: TProcessEntry32;
begin
  Result := False;

  // Tira um "snapshot" de todos os processos do sistema
  LSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if LSnapshot <> INVALID_HANDLE_VALUE then
  try
    LProcessEntry.dwSize := SizeOf(TProcessEntry32);

    // Começa percorrer a lista de processos
    if Process32First(LSnapshot, LProcessEntry) then
    repeat
      // Compara o nome do executável
      if SameText(LProcessEntry.szExeFile, AExeName) then
      begin
        Writeln('ngrok já em execução!');
        Result := True;
        Break;
      end;
    until not Process32Next(LSnapshot, LProcessEntry);
  finally
    CloseHandle(LSnapshot);
  end;


end;

class procedure TProcessRunner.StartNgrok(const ACommand: string);
var
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
  LCommandLine: string;
begin
  // Verifica se o ngrok já está executando
  if IsNgrokRunning('ngrok.exe') then
    Exit;

  // Inicializa as estruturas
  FillChar(LStartupInfo, SizeOf(LStartupInfo), 0);
  LStartupInfo.cb := SizeOf(LStartupInfo);
  LStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  LStartupInfo.wShowWindow := SW_HIDE; // Oculta a janela do terminal

  // Prepara o comando
  LCommandLine := 'cmd.exe /c ' + ACommand;

  if not CreateProcess(
    nil,
    PChar(LCommandLine),
    nil,
    nil,
    False,
    CREATE_NEW_CONSOLE,
    nil,
    nil,
    LStartupInfo,
    LProcessInfo
  ) then
    raise EProcessExecutionError.CreateFmt('Falha ao iniciar ngrok. Erro %d', [GetLastError]);

  CloseHandle(LProcessInfo.hProcess);
  CloseHandle(LProcessInfo.hThread);
end;

end.
