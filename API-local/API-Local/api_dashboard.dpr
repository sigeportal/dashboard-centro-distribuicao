program api_dashboard;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Horse,
  Horse.Jhonson,
  Horse.CORS,
  Horse.GBSwagger,
  Horse.JWT,
  Horse.Logger,
  Horse.Logger.Provider.Console,
  Horse.Logger.Provider.LogFile,
  JOSE.Core.JWT,
  JOSE.Core.Builder,
  UnitMovimentacoes.Model in 'modulos\Movimentacoes\UnitMovimentacoes.Model.pas',
  UnitMovimentacoes.Controller in 'modulos\Movimentacoes\UnitMovimentacoes.Controller.pas',
  UnitClientes.Model in 'modulos\Clientes\UnitClientes.Model.pas',
  UnitClientes.Controller in 'modulos\Clientes\UnitClientes.Controller.pas',
  UnitProdutos.Model in 'modulos\Produtos\UnitProdutos.Model.pas',
  UnitProdutos.Controller in 'modulos\Produtos\UnitProdutos.Controller.pas',
  UnitRecebimentos.Model in 'modulos\Recebimentos\UnitRecebimentos.Model.pas',
  UnitRecebimentos.Controller in 'modulos\Recebimentos\UnitRecebimentos.Controller.pas',
  UnitDashboard.Controller in 'modulos\Dashboard\UnitDashboard.Controller.pas',
  URLService in 'src\services\URLService.pas',
  AuthMiddleware in 'src\middlewares\AuthMiddleware.pas',
  HashService in 'src\services\HashService.pas',
  UnitConstants in 'src\utils\UnitConstants.pas',
  UnitFunctions in 'src\utils\UnitFunctions.pas',
  UnitDatabase in 'src\utils\Database\UnitDatabase.pas',
  UnitEmpresa.Model in 'src\models\UnitEmpresa.Model.pas',
  UnitProcessRunner in 'src\utils\UnitProcessRunner.pas',
  UnitVendas.Model in 'modulos\Vendas\UnitVendas.Model.pas',
  UnitVendas.Controller in 'modulos\Vendas\UnitVendas.Controller.pas',
  UnitVenEst.Model in 'modulos\VenEst\UnitVenEst.Model.pas',
  UnitFuncionarios.Model in 'modulos\Funcionarios\UnitFuncionarios.Model.pas',
  UnitOrdens.Model in 'modulos\Ordens\UnitOrdens.Model.pas',
  UnitOrdEst.Model in 'modulos\OrdEst\UnitOrdEst.Model.pas',
  UnitOrdens.Controller in 'modulos\Ordens\UnitOrdens.Controller.pas',
  UnitGrades.Model in 'src\models\UnitGrades.Model.pas',
  UnitTamanho.Model in 'src\models\UnitTamanho.Model.pas',
  SyncService in 'src\services\SyncService.pas',
  UnitCddTransferencia.Model in 'src\models\UnitCddTransferencia.Model.pas';

//function GetConsoleWindow: HWND; stdcall; external kernel32;
//
//var
//  ConsoleWindow: HWND;
begin
  THorse
    .Use(THorseLoggerManager.HorseCallback)
    .Use(CORS)
    .Use(Jhonson)
    .Use(HorseSwagger); // Access http://localhost:9000/swagger/doc/html

  // Logs para requisicoes
//  THorseLoggerManager.RegisterProvider(THorseLoggerProviderConsole.New());
  THorseLoggerManager.RegisterProvider(THorseLoggerProviderLogFile.New());

  // Iniciar ngrok
  //TProcessRunner.StartNgrok('ngrok http ' + ObterPorta.ToString);
    
  // Ocultar janela do console
//  ConsoleWindow := GetConsoleWindow;
//  if ConsoleWindow <> 0 then
//    ShowWindow(ConsoleWindow, SW_HIDE);

  TAuthMiddleware.RegisterAuthMiddleware;

  TURLService.TrySendURL;  // Validar retorno da requisicao de atualizacao/autocadastro

  TSyncService.Start; // Inicializar a sincronizacao automatica a cada 10 min

  TMovimentacoesController.Router;
  TClientesController.Router;
  TProdutosController.Router;
  TRecebimentosController.Router;
  TDashboardController.Router;
  TVendasController.Router;
  TOrdensController.Router;

  Swagger
    .Info
      .Title('API-Local (Integration Gateway)')
      .Description('API Local para Sincronizacao Dinamica e Integracao do Dashboard')
      .Contact
        .Name('Contact Name')
        .Email('contact@email.com.br')
        .URL('http://www.mypage.com.br')
      .&End
    .&End;

  THorse.Listen(ObterPorta,
    procedure
    begin
      Writeln('==================================');
      Writeln('API Local rodando na porta: ' + THorse.Port.ToString);
      Writeln('BD: ' + TConstants.BancoDados);
      Writeln('URL CD: ' + TConstants.URL_CD);
      Writeln('==================================');
      Readln;
      THorse.StopListen;
    end);
end.
