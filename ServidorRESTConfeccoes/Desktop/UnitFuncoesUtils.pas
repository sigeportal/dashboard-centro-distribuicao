unit UnitFuncoesUtils;

interface

uses
  System.Classes,
  UnitClientREST.Model.Interfaces,
  System.Threading,
  System.SysUtils,
  Winapi.Windows,
  Winapi.TlHelp32,
  Vcl.Forms,
  Vcl.DBGrids,
  Vcl.Graphics,
  Vcl.Grids,
  System.Rtti,
  System.IniFiles,
  System.Generics.Collections,
  UnitMsgUsuario,
  Vcl.Controls,
  Vcl.Dialogs,
  System.Generics.Defaults,
  Vcl.DBCtrls,
  Vcl.StdCtrls,
	JvValidateEdit, 
	System.Win.Registry;

type
  TCampoValidacao = record
    Campo: string;
    Component: TComponent;
  end;

  Validador = class(TCustomAttribute)
  private
    FNomeCampo: string;
  published
    constructor Create(NomeCampo: string); overload;
    property NomeCampo: string read FNomeCampo write FNomeCampo;
  end;

type
  TFormHelper = class helper for TForm
  public
    // array de grids
    /// <summary>
    /// <para>Foi criado um ClassHelper para adicionar ao TForm a funcionalidade</para>
    /// <para>de guardar em arquivo .ini a largura, altura, estado e posicoes das colunas do dbGrid</para>
    /// </summary>
    procedure GravaEstadoForm(ArrayGrids: Array of TDBGrid; Recurso: string = '');
    // array de grids
    /// <summary>
    /// <para>Foi criado um ClassHelper para adicionar ao TForm a funcionalidade</para>
    /// <para>de guardar em arquivo .ini a largura, altura, estado e posicoes das colunas do dbGrid</para>    ///
    /// </summary>
    procedure InicializaEstadoForm(ArrayGrids: Array of TDBGrid; Recurso: string = '');
    // Validação usando RTTI
    /// <summary>
    /// <para>Criado para varrer, através da RTTI, os componentes para validação </para>
    /// </summary>
    function ValidarCampos: Boolean;
  end;

function BuscaCidades(UF: string): TStringList;
function BuscaEstados: TStringList;
function GeraCodigo(Tabela, Campo: string): Integer;
function TestaServidor(BaseURL: string): TClientResult;
function StrToEnumerado(out ok: Boolean; const s: string; const AString: array of string; const AEnumerados: array of variant): variant;
function EnumeradoToStr(const t: variant; const AString: array of string; const AEnumerados: array of variant): variant;
function CriaArquivoIniLocalData: string;
function ConverteData(Value: string): string;
function KillTask(ExeFileName: string): integer;
function EnDecryptString(StrValue: String; Chave: Word): String;
procedure GridPadrao(RecNo: longint; Grid: TDBGrid; Rect: TRect; Column: TColumn; State: TGridDrawState; Zebrar: Boolean = True);
procedure MensagemUsuario(Mensagem: string; TempoSegundos: integer; BotaoOK, Esperar: Boolean);
procedure AbreModulo(Permissao: string; ClasseForm: TFormClass; var NomeForm; Modal: Boolean = false);
procedure AbreForm(FClass: TFormClass; var Instancia; Modal: Boolean = false);
procedure DestroiForms();
procedure CamposObrigatorios(ListS: TStrings);overload;
function CamposObrigatorios(ListaCamposValidacao: TList<TCampoValidacao>): Boolean; overload;
function RetiraMascara(Texto: string): string;
procedure ConectaServidor;
function Centralizar(Texto: String; Espaco: integer): String;
function RetZero(ZEROS: string; QUANT: integer): String;
function GeraCodigoBarras(CodProduto: integer): string;
function GeraDVEAN(Cadeia: string): string;
function AllTrim(Texto: string): string;
function QuebrarEmVariasLinhas(Linha: string; TamanhoLinha: integer): TList<string>;

var
  UltimaMsg: TTime;
  
const
	Cores: Array [0 .. 9] of TColor = ($00F0A660, $009260F0, $00EF6D62, $00F0E158, $00A8A8A8, $0057B5F0, $0054F083, $0063F0E3, $004483F0, $00AD637C);

implementation

uses
  System.JSON,
  UnitClientREST.Model,
  UnitConfiguracaoServidor.Singleton,
  UnitCidade.Model, UnitDMPrincipal,
  UnitTabela.Helper.Json, System.DateUtils, UnitPrincipal, UnitLogin,
  UnitConfigIniciaisServidor;

function BuscaCidades(UF: string): TStringList;
var
  aJson: TJSONArray;
  Response: TClientResult;
  jsonCidade: TJSONValue;
  Cidade: TCidade;
begin
  Result := TStringList.Create;
  Result.Clear;
  aJson := TJSONArray.Create;
  try
    MensagemUsuario('Aguarde, buscando cidades...', 1, False, False);
    Response := TClientREST.New(TConfiguracaoServidor.BaseURL+'/cidade?UF='+UF).Get();
    if Response.StatusCode = 200 then
    begin
      aJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONArray;
      for jsonCidade in aJson do
      begin
         Cidade := TCidade.Create();
         Result.AddObject(jsonCidade.GetValue<string>('nome'), Cidade.fromJson<TCidade>(jsonCidade.ToJSON));
      end;
    end;
  finally
    aJson.DisposeOf;
  end;
end;

function BuscaEstados: TStringList;
var
  Response: TClientResult;
  aJson: TJSONArray;
  jsonUF: TJSONValue;
begin
  Result := TStringList.Create;
  aJson := TJSONArray.Create;
  try
    MensagemUsuario('Aguarde, buscando estados...', 1, False, False);
    Response := TClientREST.New(TConfiguracaoServidor.BaseURL+'/estado').Get();
    if Response.StatusCode = 200 then
    begin
      aJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONArray;
      for jsonUF in aJson do
      begin
         Result.Add(jsonUF.GetValue<string>('sigla'));
      end;
    end;
  finally
    aJson.DisposeOf;
  end;
end;

function GeraCodigo(Tabela, Campo: string): Integer;
var
  Response: TClientResult;
  oJson: TJSONObject;
  ResponseJson: TJSONObject;
begin
  Result := 0;
  oJson := TJSONObject.Create;
  try
    oJson.AddPair('tabela', Tabela);
    oJson.AddPair('campo', Campo);
    Response := TClientREST.New(TConfiguracaoServidor.BaseURL+'/gera_codigo')
                            .AddBody(oJson)
                            .Post();
    if Response.StatusCode = 200 then
    begin
      ResponseJson := TJSONObject.ParseJSONValue(Response.Content) as TJSONObject;
      Result :=  ResponseJson.GetValue<integer>('codigo');
    end else
      raise Exception.Create('Erro ao gerar código!'+sLineBreak+Response.Error);
  finally
    oJson.DisposeOf;
  end;
end;

function TestaServidor(BaseURL: string): TClientResult;
var
  Response: TClientResult;
begin
  try
    Response := TClientREST.New(BaseURL+'/usuarios').Get();
    Result := Response;
  except
    on E: Exception do
    begin
      raise Exception.Create('Houve erro ao conectar!'#13 + E.Message);
    end;
  end;
end;

function StrToEnumerado(out ok: Boolean; const s: string; const AString: array of string; const AEnumerados: array of variant): variant;
var
  i: integer;
begin
  Result := -1;
  for i  := Low(AString) to High(AString) do
    if AnsiSameText(s, AString[i]) then
      Result := AEnumerados[i];
  ok         := Result <> -1;
  if not ok then
    Result := AEnumerados[0];
end;

function EnumeradoToStr(const t: variant; const AString: array of string; const AEnumerados: array of variant): variant;
var
  i: integer;
begin
  Result := '';
  for i  := Low(AEnumerados) to High(AEnumerados) do
    if t = AEnumerados[i] then
      Result := AString[i];
end;

function CriaArquivoIniLocalData: string;
var
  CaminhoIni: string;
begin
  CaminhoIni := GetEnvironmentVariable('LOCALAPPDATA') + '\PORTAL\' + ExtractFileName(ParamStr(0));
  if not DirectoryExists(ExtractFileDir(CaminhoIni)) then
    ForceDirectories(ExtractFileDir(CaminhoIni));
  Result := CaminhoIni;
end;

function KillTask(ExeFileName: string): integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result                 := 0;
  FSnapshotHandle        := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := sizeof(FProcessEntry32);
  ContinueLoop           := Process32First(FSnapshotHandle, FProcessEntry32);
  while integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) = UpperCase(ExeFileName)))
    then
      Result     := integer(TerminateProcess(OpenProcess(PROCESS_TERMINATE, BOOL(0), FProcessEntry32.th32ProcessID), 0));
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

function EnDecryptString(StrValue: String; Chave: Word): String;
var
  i: integer;
  OutValue: String;
begin
  OutValue   := '';
  for i      := 1 to Length(StrValue) do
    OutValue := OutValue + AnsiChar(Not(Ord(StrValue[i]) - Chave));
  Result     := OutValue;
end;

procedure GridPadrao(RecNo: longint; Grid: TDBGrid; Rect: TRect; Column: TColumn; State: TGridDrawState; Zebrar: Boolean = True);
const
  CorCelula: TColor = $00F1F2F3;
  CorCelulaSel: TColor = clGray;
  CorFonte: TColor = $004D4B4A;
  CorFonteSel: TColor = $0067F3DE;
begin
  if (gdSelected in State) then
  begin
    with Grid do
    begin
      with Canvas do
      begin
        Brush.Color := CorCelulaSel; // Cor da celula
        Font.Color  := CorFonteSel; // cor fonte
        FillRect(Rect); // Pinta a ceula
      end; // with Canvas
      DefaultDrawDataCell(Rect, Column.Field, State)
    end;
  end
  else
  begin
    if not(Odd(RecNo)) and Zebrar then // Se nao for par                                             // With Grid
    begin
      with Grid do
      begin
        with Canvas do
        begin
          Brush.Color := $00CECECE; // Cor da celula
          // Font.Color  := clBlack;                  // cor fonte
          FillRect(Rect); // Pinta a ceula
        end; // with Canvas
        DefaultDrawDataCell(Rect, Column.Field, State)
      end;
    end;
  end;
end;

{ TFormHelper }

procedure TFormHelper.GravaEstadoForm(ArrayGrids: Array of TDBGrid; Recurso: string = '');
var
  Config: TIniFile;
  i, j: integer;
  Grid: TDBGrid;
  ListaGrids: TList<TDBGrid>;
  CaminhoIni: string;
begin
  ListaGrids := TList<TDBGrid>.Create;
  try
    CaminhoIni := CriaArquivoIniLocalData;
    // adiciona os arrays
    ListaGrids.AddRange(ArrayGrids);
    if Recurso.IsEmpty then
      Config := TIniFile.Create(ChangeFileExt(CaminhoIni, '.ini'))
    else Config := TIniFile.Create(ChangeFileExt(CaminhoIni, '_'+Recurso+'.ini'));
    Config.WriteInteger(Self.Name, 'Altura', Self.Height);
    Config.WriteInteger(Self.Name, 'Largura', Self.Width);
    Config.WriteBool(Self.Name, 'Maximizada', Self.WindowState = wsMaximized);
    Config.WriteInteger(Self.Name, 'Topo', Self.Top);
    Config.WriteInteger(Self.Name, 'Esquerda', Self.Left);
    if ListaGrids <> nil then
    begin
      for i := 0 to Pred(ListaGrids.Count) do
      begin
        Grid := ListaGrids[i];
        if Assigned(Grid) then
        begin
          for j := 0 to Grid.Columns.Count - 1 do
          begin
            Config.WriteInteger(Self.Name + '.' + Grid.Name + '.Coluna' + IntToStr(j), 'Largura', Grid.Columns[j].Width);
            Config.WriteString(Self.Name + '.' + Grid.Name + '.Coluna' + IntToStr(j), 'Campo', Grid.Columns[j].FieldName);
          end;
        end;
      end;
    end;
  finally
    Config.Free;
    FreeAndNil(ListaGrids);
  end;
end;

procedure TFormHelper.InicializaEstadoForm(ArrayGrids: Array of TDBGrid; Recurso: string = '');
var
  Config: TIniFile;
  Altura, Largura: integer;
  Maximizado: Boolean;
  Topo: integer;
  Esquerda: integer;
  i, j: integer;
  LargCampo: integer;
  Grid: TDBGrid;
  ListaGrids: TList<TDBGrid>;
  Titulos: TDictionary<string, string>;
  TitulosAux: TStringList;
  Titulo: string;
  Campo: string;
  Indice: integer;
  CaminhoIni: string;
begin
  ListaGrids := TList<TDBGrid>.Create;
  try
    CaminhoIni := CriaArquivoIniLocalData;
    // adiciona os arrays
    ListaGrids.AddRange(ArrayGrids);
    if Recurso.IsEmpty then
      Config     := TIniFile.Create(ChangeFileExt(CaminhoIni, '.ini'))
    else Config     := TIniFile.Create(ChangeFileExt(CaminhoIni, '_'+Recurso+'.ini'));
    Altura     := Config.ReadInteger(Self.Name, 'Altura', Self.Height);
    Largura    := Config.ReadInteger(Self.Name, 'Largura', Self.Width);
    Maximizado := Config.ReadBool(Self.Name, 'Maximizada', false);
    Topo       := Config.ReadInteger(Self.Name, 'Topo', Self.Top);
    Esquerda   := Config.ReadInteger(Self.Name, 'Esquerda', Self.Left);
    Titulos    := TDictionary<string, string>.Create();
    TitulosAux := TStringList.Create;
    if ListaGrids <> nil then
    begin
      for i := 0 to Pred(ListaGrids.Count) do
      begin
        Grid  := ListaGrids[i];
        for j := 0 to Grid.Columns.Count - 1 do
        begin
          Titulos.Add(Grid.Columns[j].FieldName, Grid.Columns[j].Title.Caption);
          TitulosAux.Add(Grid.Columns[j].FieldName);
        end;
        Indice := 0;
        for j  := 0 to Grid.Columns.Count - 1 do
        begin
          if Config.ValueExists(Self.Name + '.' + Grid.Name + '.Coluna' + IntToStr(j), 'Largura') then
          begin
            LargCampo             := Config.ReadInteger(Self.Name + '.' + Grid.Name + '.Coluna' + IntToStr(j), 'Largura', Grid.Columns[j].Width);
            Grid.Columns[j].Width := LargCampo;
          end;
          if Config.ValueExists(Self.Name + '.' + Grid.Name + '.Coluna' + IntToStr(j), 'Campo') then
          begin
            Campo := Config.ReadString(Self.Name + '.' + Grid.Name + '.Coluna' + IntToStr(j), 'Campo', '');
            if Titulos.TryGetValue(Campo, Titulo) then
            begin
              // Aqui deve ser mesmo o "j" e não o "indice"
              Grid.Columns[j].FieldName     := Campo;
              Grid.Columns[j].Title.Caption := Titulo;
              Titulos.Remove(Campo);
              TitulosAux.Delete(TitulosAux.IndexOf(Campo));
              Inc(Indice, 1);
            end;
          end;
        end;
        if Titulos.Count > 0 then
        begin
          for j := Indice to Grid.Columns.Count - 1 do
          begin
            if Titulos.TryGetValue(TitulosAux.Strings[0], Titulo) then
            begin
              Grid.Columns[j].FieldName     := TitulosAux.Strings[0];
              Grid.Columns[j].Title.Caption := Titulo;
              Titulos.Remove(TitulosAux.Strings[0]);
              TitulosAux.Delete(0);
            end;
          end;
        end;
      end;
    end;
    if Altura > 0 then
    begin
      Self.Left   := Esquerda;
      Self.Top    := Topo;
      Self.Height := Altura;
      Self.Width  := Largura;
      if Maximizado then
        Self.WindowState := wsMaximized;
    end;
  finally
    Config.Free;
    Titulos.Free;
    TitulosAux.Free;
    FreeAndNil(ListaGrids);
  end;
end;

function TFormHelper.ValidarCampos: Boolean;
var
  Contexto: TRttiContext;
  FormTipo: TRttiType;
  Propriedade: TRttiProperty;
  Atributo: TCustomAttribute;
  Valor: variant;
  Preenchido: Boolean;
  CampoValidacao: TCampoValidacao;
  ListaCamposValidacao: TList<TCampoValidacao>;
  Field: TRttiField;
  Component: TComponent;
begin
  Result               := True; // a principio todos sao validos
  ListaCamposValidacao := TList<TCampoValidacao>.Create;
  try
    // Cria o contexto do RTTI
    Contexto := TRttiContext.Create;
    // Obtém as informações de RTTI da classe TBoleto
    FormTipo := Contexto.GetType(Self.ClassInfo);
    // Executa um loop nas propriedades do objeto
    for Field in FormTipo.GetFields do
    begin
      // Executa um loop nos atributos da propriedade
      for Atributo in Field.GetAttributes do
      begin
        if Atributo is Validador then
        begin
          // obtém o componente
          Component := Self.FindComponent(Field.Name);
          // cria um lista com os componentes a serem validados
          CampoValidacao.Campo     := Validador(Atributo).NomeCampo;
          CampoValidacao.Component := Component;
          ListaCamposValidacao.Add(CampoValidacao);
        end;
      end;
    end;
    // aciona procedure de validacao
    if ListaCamposValidacao.Count > 0 then
      Result := CamposObrigatorios(ListaCamposValidacao);
  finally
    ListaCamposValidacao.DisposeOf;
  end;
end;

procedure MensagemUsuario(Mensagem: string; TempoSegundos: integer; BotaoOK, Esperar: Boolean);
begin
  if (SecondsBetween(Time, UltimaMsg) > 4) or (Esperar) then
  begin
    if FrmMsgUsuario <> nil then
    begin
      FrmMsgUsuario.Free;
      FrmMsgUsuario := nil;
    end;
  end;
  SetForegroundWindow(Application.Handle);
  if TempoSegundos > 1000 then
    TempoSegundos := Round(TempoSegundos / 1000);
  if FrmMsgUsuario = nil then
    Application.CreateForm(TFrmMsgUsuario, FrmMsgUsuario);
  FrmMsgUsuario.Label1.Caption  := Mensagem;
  FrmMsgUsuario.Timer1.Interval := TempoSegundos * 1000; // Transforma Segundos em Milissegundos
  FrmMsgUsuario.Button1.Visible := BotaoOK;
  UltimaMsg                     := Time;
  if Esperar then
  begin
    FrmMsgUsuario.BringToFront;
    FrmMsgUsuario.ShowModal;
  end
  else
  begin
    FrmMsgUsuario.Show;
    FrmMsgUsuario.FormShow(FrmPrincipal);
  end;
end;

procedure AbreModulo(Permissao: string; ClasseForm: TFormClass; var NomeForm; Modal: Boolean = false);
begin
  if not Assigned(DMPrincipal.UsuarioLogado) then
  begin
    if FrmLogin = nil then
      FrmLogin         := TFrmLogin.Create(nil);
    FrmLogin.Permissao := Permissao;
    if (FrmLogin.ShowModal = mrOK) then
      AbreForm(ClasseForm, NomeForm, Modal);
  end else
    AbreForm(ClasseForm, NomeForm, Modal);
end;

procedure AbreForm(FClass: TFormClass; var Instancia; Modal: Boolean = false);
begin
  try
    if Assigned(TForm(Instancia)) then
    begin
      FrmPrincipal.HabilitaMenu(false);
      if Modal then
        TForm(Instancia).ShowModal
      else
      begin
        TForm(Instancia).Show;
        TForm(Instancia).SetFocus;
        TForm(Instancia).WindowState := wsNormal;
        TForm(Instancia).BringToFront;
      end;
    end
    else
    begin
      FrmPrincipal.HabilitaMenu(false);
      // FrmPrincipal.DesabilitaCadastro;
      Application.CreateForm(FClass, Instancia);
      if Modal then
        TForm(Instancia).ShowModal
      else
        TForm(Instancia).Show;
    end;
  except
    on E: Exception do
    begin
      Application.MessageBox(PWideChar('Não foi possível abrir o Módulo!'#13#13 + E.Message), 'Erro', MB_OK);
      FrmPrincipal.HabilitaMenu(True);
    end;
  end;
end;

procedure DestroiForms();
var
  FormAtivo: TForm;
begin
  FormAtivo := nil;
  try
    // Enquanto houver form criado
    while Screen.FormCount > 0 do
    begin
      with Screen.Forms[Screen.FormCount - 1] do
      begin
        // Atribuo o form a variavel
        FormAtivo := Screen.Forms[Screen.FormCount - 1];
        // Libero o Form
        if Assigned(FormAtivo) then
          FormAtivo.DisposeOf;
      end;
    end;
  except
  end;
end;

procedure CamposObrigatorios(ListS: TStrings);
var
  X: integer;
  Campos: string;
begin
  Campos := '';
  for X  := 1 to ListS.Count do
  begin
    if (X = ListS.Count) then
    begin
      Campos := Campos + ListS[X - 1];
    end
    else
    begin
      if (X = ListS.Count - 1) then
        Campos := Campos + ListS[X - 1] + ' e ' + #13
      else
        Campos := Campos + ListS[X - 1] + ', ' + #13;
    end;
  end;
  if ListS.Count > 1 then
    ShowMessage('Os Campos:' + #13 + Campos + #13 + 'são obrigatórios.')
  else
    ShowMessage('O Campo ' + Campos + ' é obrigatório.');
  Application.BringToFront;
end;

function CamposObrigatorios(ListaCamposValidacao: TList<TCampoValidacao>): Boolean;
var
  Campos: TCampoValidacao;
  ListaCampos: TStringList;
begin
  Result      := True;
  ListaCampos := TStringList.Create;
  // ordena os componentes pelo tabOrder
  ListaCamposValidacao.Sort(TComparer<TCampoValidacao>.Construct(
    function(const Left, Right: TCampoValidacao): integer
    begin
      if Left.Component is TDBEdit then
        Result := TDBEdit(Left.Component).TabOrder - TDBEdit(Right.Component).TabOrder;
      if Left.Component is TEdit then
        Result := TEdit(Left.Component).TabOrder - TEdit(Right.Component).TabOrder;
      if Left.Component is TDBComboBox then
        Result := TDBComboBox(Left.Component).TabOrder - TDBComboBox(Right.Component).TabOrder;
      if Left.Component is TDBLookupComboBox then
        Result := TDBLookupComboBox(Left.Component).TabOrder - TDBLookupComboBox(Right.Component).TabOrder;
      if Left.Component is TComboBox then
        Result := TComboBox(Left.Component).TabOrder - TComboBox(Right.Component).TabOrder;
      if Left.Component is TJvValidateEdit then
        Result := TJvValidateEdit(Left.Component).TabOrder - TJvValidateEdit(Right.Component).TabOrder;
    end));
  try
    for Campos in ListaCamposValidacao do
    begin
      if Campos.Component is TDBEdit then
      begin
        if RetiraMascara(TDBEdit(Campos.Component).Text) = EmptyStr then
        begin
          ListaCampos.Add(Campos.Campo);
          TDBEdit(Campos.Component).SetFocus;
          break;
        end;
      end;
      if Campos.Component is TEdit then
      begin
        if RetiraMascara(TEdit(Campos.Component).Text) = EmptyStr then
        begin
          ListaCampos.Add(Campos.Campo);
          TEdit(Campos.Component).SetFocus;
          break;
        end;
      end;
      if Campos.Component is TDBComboBox then
      begin
        if TDBComboBox(Campos.Component).Text = EmptyStr then
        begin
          ListaCampos.Add(Campos.Campo);
          TDBComboBox(Campos.Component).SetFocus;
          break;
        end;
      end;
      if Campos.Component is TDBLookupComboBox then
      begin
        if TDBLookupComboBox(Campos.Component).Text = EmptyStr then
        begin
          ListaCampos.Add(Campos.Campo);
          TDBLookupComboBox(Campos.Component).SetFocus;
          break;
        end;
      end;
      if Campos.Component is TComboBox then
      begin
        if TDBComboBox(Campos.Component).Text = EmptyStr then
        begin
          ListaCampos.Add(Campos.Campo);
          TComboBox(Campos.Component).SetFocus;
          break;
        end;
      end;
      if Campos.Component is TJvValidateEdit then
      begin
        if TJvValidateEdit(Campos.Component).Text = EmptyStr then
        begin
          ListaCampos.Add(Campos.Campo);
          TJvValidateEdit(Campos.Component).SetFocus;
          break;
        end;
      end;
    end;
    if ListaCampos.Count > 0 then
      CamposObrigatorios(ListaCampos);
    Result := ListaCampos.Count = 0;
  finally
    ListaCampos.DisposeOf;
  end;
  Application.BringToFront;
end;

function RetiraMascara(Texto: string): string;
var
  i: smallint;
const
  Permitidos: string = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
begin
  Result := '';
  for i  := 1 to Length(Texto) do
  begin
    if Pos(Texto[i], Permitidos) > 0 then
      Result := Result + Texto[i];
  end;
end;

{ Validador }

constructor Validador.Create(NomeCampo: string);
begin
  FNomeCampo := NomeCampo;
end;

function ConverteData(Value: string): string;
var
  Data: TArray<string>;
begin
  Data := Value.Split(['-']);
  Result := Format('%s/%s/%s', [Data[2], Data[1], Data[0]]);
end;

procedure ConectaServidor;
var
  reg: Tregistry;
  CaminhoBDRetaguarda: string;
  VoltarAoInicio: Boolean;
  Resposta: TClientResult;
Label Inicio;
begin
  reg         := Tregistry.Create;
  reg.RootKey := HKEY_LOCAL_MACHINE;
  reg.OpenKey('SOFTWARE\PORTAL.COM\' + ExtractFileName(Application.ExeName), True);
Inicio:
  VoltarAoInicio      := False;
  TConfiguracaoServidor.BaseURL := reg.ReadString('baseURL');
  CaminhoBDRetaguarda := reg.ReadString('CaminhoBDRetaguarda');
  try
    FrmPrincipal.PDV := reg.ReadInteger('PDV');
  except
    FrmPrincipal.PDV := 1;
  end;
  if TConfiguracaoServidor.BaseURL.IsEmpty then
  begin
    ShowMessage('Você deverá configurar Base URL do Servidor na próxima tela!');
    if FrmConfigIniciaisServidor = nil then
      FrmConfigIniciaisServidor := TFrmConfigIniciaisServidor.Create(nil);
    FrmConfigIniciaisServidor.ShowModal;
    TConfiguracaoServidor.BaseURL     := reg.ReadString('CaminhoBD');
  end;
  if TConfiguracaoServidor.BaseURL.IsEmpty then
  begin
    ShowMessage('Você não configurou Base URL do Servidor.'#13'Não será possível acessar o Servidor.');
  end
  else
  begin
    try
      Resposta := TestaServidor(TConfiguracaoServidor.BaseURL);
      if Resposta.StatusCode <> 200 then
      begin
        ShowMessage('Houve erro ao conectar com o Servidor!'#13 + Resposta.Error);
        if FrmConfigIniciaisServidor = nil then
          FrmConfigIniciaisServidor := TFrmConfigIniciaisServidor.Create(nil);
        FrmConfigIniciaisServidor.ShowModal;
        VoltarAoInicio := True;
      end;
    except
      on E: Exception do
      begin
        ShowMessage('Houve erro ao conectar com o Servidor!'#13 + E.Message);
        if Application.MessageBox('Deseja configurar o caminho do Servidor?', 'Configuração', MB_YESNO + MB_ICONQUESTION) = MrYes then
        begin
          if FrmConfigIniciaisServidor = nil then
            FrmConfigIniciaisServidor := TFrmConfigIniciaisServidor.Create(nil);
          FrmConfigIniciaisServidor.ShowModal;
          VoltarAoInicio := True;
        end
        else
        begin
          KillTask(ExtractFileName(Application.ExeName));
        end;
      end;
    end;
    if VoltarAoInicio then
      goto Inicio;
  end;
  reg.Free;
end;

function Centralizar(Texto: String; Espaco: integer): String;
var
  AjusteE, AjusteD: string;
  Esquerdo, Direito: integer;
begin
  if Length(Texto) >= Espaco then
    Result := Copy(Texto, 1, Espaco)
  else
  begin
    Esquerdo := Round((Espaco - Length(Texto)) / 2);
    AjusteE  := Format('%' + IntToStr(Esquerdo) + 's', ['']);
    Direito  := Espaco - Length(Texto) - Esquerdo;
    AjusteD  := Format('%' + IntToStr(Direito) + 's', ['']);
    Result   := AjusteE + Texto + AjusteD;
  end;
end;

function RetZero(ZEROS: string; QUANT: integer): String;
var
  i, Tamanho: integer;
  aux: string;
begin
  aux     := ZEROS;
  Tamanho := Length(ZEROS);
  ZEROS   := '';
  for i   := 1 to QUANT - Tamanho do
    ZEROS := ZEROS + '0';
  aux     := ZEROS + aux;
  RetZero := aux;
end;

function GeraDVEAN(Cadeia: string): string;
var
  DVCalculado, i, Indice: byte;
  num: array of byte;
  soma: Cardinal;
begin
  // Retira possiveis espa�os em branco
  Cadeia := AllTrim(Cadeia);
  SetLength(num, Length(Cadeia));
  for i    := 0 to Length(Cadeia) - 1 do
    num[i] := StrToInt(Cadeia[i + 1]);

  Indice := 3;
  soma   := 0;

  for i := High(num) downto Low(num) do
  begin
    soma   := soma + num[i] * Indice;
    Indice := Abs(4 - Indice);
  end;
  // Calcula o DV da Cadeia
  DVCalculado := (((soma div 10) + 1) * 10) - soma;
  if DVCalculado > 9 then
    DVCalculado := 0;
  Result        := IntToStr(DVCalculado);
end;

function AllTrim(Texto: string): string;
// Retorna uma string retirando todos os espacos em branco
begin
  Result := Texto;
  while Pos(' ', Result) > 0 do
    Result := StringReplace(Result, ' ', '', [rfReplaceAll]);
end;

function GeraCodigoBarras(CodProduto: integer): string;
var
	Aux: string;
begin
	Aux  := '78960000' + RetZero(CodProduto.ToString, 6); // no lugar do 1 colocar campo cod_produto
	Result := '789600' + RetZero(CodProduto.ToString, 6) + GeraDVEAN(Aux);	
end;

function QuebrarEmVariasLinhas(Linha: string; TamanhoLinha: integer): TList<string>;
var
	ContaNumCaracteres: integer;
	LinhaAdicionar: string;
begin
	Result             := TList<String>.Create;
	ContaNumCaracteres := 0;
	while (ContaNumCaracteres < Linha.Length) do
	begin
		LinhaAdicionar := Linha.Substring(ContaNumCaracteres, TamanhoLinha).TrimRight;
		Result.Add(LinhaAdicionar);
		ContaNumCaracteres := ContaNumCaracteres + TamanhoLinha;
	end;
end;

end.

