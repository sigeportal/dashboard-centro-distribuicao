program AUTH;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Horse,
  Horse.CORS,
  Horse.Jhonson,
  Horse.GBSwagger,
  System.SysUtils,
  TokenService in 'src\services\TokenService.pas',
  AuthService in 'src\services\AuthService.pas',
  HashService in 'src\services\HashService.pas',
  AuthMiddleware in 'src\middlewares\AuthMiddleware.pas',
  AuditMiddleware in 'src\middlewares\AuditMiddleware.pas',
  AuthController in 'src\controllers\AuthController.pas',
  ClienteController in 'src\controllers\ClienteController.pas',
  UnitConstants in 'src\utils\UnitConstants.pas',
  UnitFunctions in 'src\utils\UnitFunctions.pas',
  CompanyController in 'src\controllers\CompanyController.pas',
  CompanyService in 'src\services\CompanyService.pas',
  ClienteService in 'src\services\ClienteService.pas',
  UnitCliente.Model in 'src\models\Cliente\UnitCliente.Model.pas',
  UnitClienteEmpresa.Model in 'src\models\ClienteEmpresa\UnitClienteEmpresa.Model.pas',
  UnitEmpresa.Model in 'src\models\Empresa\UnitEmpresa.Model.pas',
  SyncController in 'src\controllers\SyncController.pas',
  UnitClientesSinc.Model in 'src\models\Clientes\UnitClientesSinc.Model.pas',
  UnitProdutosSinc.Model in 'src\models\Produtos\UnitProdutosSinc.Model.pas',
  UnitVendasSinc.Model in 'src\models\Vendas\UnitVendasSinc.Model.pas',
  UnitMovimentacoesSinc.Model in 'src\models\Movimentacoes\UnitMovimentacoesSinc.Model.pas',
  UnitRecebimentosSinc.Model in 'src\models\Recebimentos\UnitRecebimentosSinc.Model.pas',
  UnitOrdensSinc.Model in 'src\models\Ordens\UnitOrdensSinc.Model.pas',
  UnitGrupo1Sinc.Model in 'src\models\Produtos\UnitGrupo1Sinc.Model.pas',
  UnitGruposSinc.Model in 'src\models\Produtos\UnitGruposSinc.Model.pas',
  UnitTamanhosSinc.Model in 'src\models\Produtos\UnitTamanhosSinc.Model.pas',
  UnitGradesSinc.Model in 'src\models\Produtos\UnitGradesSinc.Model.pas',
  UnitTransferencia.Model in 'src\models\Transferencias\UnitTransferencia.Model.pas',
  UnitTransferenciaItem.Model in 'src\models\Transferencias\UnitTransferenciaItem.Model.pas';

begin
//  // Validação de Segredos (Gerenciamento de Ambiente)
//  if GetEnvironmentVariable('SECRET_KEY').Trim.IsEmpty then
//  begin
//    Writeln('---------------------------------------------------------');
//    Writeln('ERRO FATAL: Variavel de ambiente SECRET_KEY nao definida.');
//    Writeln('A aplicacao nao pode iniciar sem uma chave mestre segura.');
//    Writeln('---------------------------------------------------------');
//    // Em produção, você pode querer logar isso em um serviço externo antes de parar.
//    {$IFDEF DEBUG}
//    Readln;
//    {$ENDIF}
//    Halt(1);
//  end;

  THorse
    .Use(AuditLog)
    .Use(CORS)
    .Use(HorseSwagger)
    .Use(Jhonson);

  TTokenService.Init;

  Writeln('Usando o BD: ' + TConstants.BancoDados);

  AuthController.Router;
  ClienteController.Router;
  CompanyController.Router;
  SyncController.Router;

  Swagger
    .Info
      .Title('Horse Sample')
      .Description('API Horse')
      .Contact
        .Name('Contact Name')
        .Email('contact@email.com.br')
        .URL('http://www.mypage.com.br')
      .&End
    .&End;

  THorse.Listen(ObterPorta,
    procedure
    begin
      Writeln('API Central rodando na porta: ' + THorse.Port.ToString);
      Readln;
    end);
end.
