; =====================================================================
; Script Inno Setup - API Dashboard Sincronizador (Instalador & Update)
; =====================================================================

#define MyAppName "API Dashboard Sincronizador"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Portal ORM / CD"
#define MyAppExeName "api_dashboard.exe"
#define MyAppURL "https://github.com/sigeportal/dashboard-centro-distribuicao"

[Setup]
AppId={{D374A92B-6C3E-4B7B-A14C-15228DFA812A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\APIDashboard
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=dist
OutputBaseFilename=APIDashboard_Setup_v1.0.0
SetupIconFile=api_dashboard_Icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "autostart"; Description: "Iniciar automaticamente com o Windows (shell:startup)"; Flags: checkedonce
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; Flags: unchecked

[Files]
Source: "api_dashboard.exe"; DestDir: "{app}"; Flags: ignoreversion promptifolder
Source: "sinc_config.ini"; DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "update_schema.sql"; DestDir: "{app}"; Flags: ignoreversion
Source: "COMO_RODAR.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Configuração de Sincronia (sinc_config.ini)"; Filename: "{app}\sinc_config.ini"
Name: "{group}\Desinstalar {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{autostartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: autostart

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "taskkill.exe"; Parameters: "/f /im {#MyAppExeName}"; Flags: runhidden

[Code]
var
  CaminhoBDPage: TInputFileWizardPage;

// Fechar instancia ativa antes de atualizar/instalar
procedure StopRunningProcess;
var
  ResultCode: Integer;
begin
  Exec('taskkill.exe', '/f /im api_dashboard.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure InitializeWizard;
begin
  // Pagina para selecionar o arquivo do Banco de Dados Firebird (CAMINHO_BD)
  CaminhoBDPage := CreateInputFilePage(
    wpSelectDir,
    'Configuração do Banco de Dados Firebird',
    'Selecione o arquivo do banco de dados (PRINCIPAL.FDB)',
    'A API Local precisa do caminho completo do banco Firebird para sincronizar os dados.'
  );
  CaminhoBDPage.Add(
    'Caminho do Banco de Dados (.FDB):',
    'Arquivos Firebird (*.fdb)|*.fdb|Todos os arquivos (*.*)|*.*',
    '.fdb'
  );
  
  // Buscar caminho existente ou valor padrao
  CaminhoBDPage.Values[0] := GetEnv('CAMINHO_BD');
  if CaminhoBDPage.Values[0] = '' then
    CaminhoBDPage.Values[0] := 'C:\Estagio\API-Local\Dados\PRINCIPAL.FDB';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  CaminhoBD: string;
begin
  if CurStep = ssInstall then
  begin
    StopRunningProcess;
  end;

  if CurStep = ssPostInstall then
  begin
    CaminhoBD := CaminhoBDPage.Values[0];
    if CaminhoBD <> '' then
    begin
      // Definir Variavel de Ambiente de Sistema CAMINHO_BD no Registro do Windows
      RegWriteStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'CAMINHO_BD', CaminhoBD);
      // Notificar o sistema Windows sobre a alteracao das variaveis de ambiente
      SendNotifyMessage(HWND_BROADCAST, 26, 0, StrToInt(Format('%d', [PtrInt(PChar('Environment'))])));
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    StopRunningProcess;
  end;
end;
