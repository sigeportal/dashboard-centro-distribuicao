program ServidorConsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Horse,
  Horse.GBSwagger,
  Horse.CORS,
  Horse.Jhonson,
  Horse.HandleException,
  Horse.Logger,
  Horse.Logger.Provider.Console,
  System.SysUtils,
  UnitCidade.Controller in '..\Shared\Controllers\Cidade\UnitCidade.Controller.pas',
  UnitDataset.Controller in '..\Shared\Controllers\Dataset\UnitDataset.Controller.pas',
  UnitEmpresa.Controller in '..\Shared\Controllers\Empresa\UnitEmpresa.Controller.pas',
  UnitEstado.Controller in '..\Shared\Controllers\Estado\UnitEstado.Controller.pas',
  UnitFornecedores.Controller in '..\Shared\Controllers\Fornecedores\UnitFornecedores.Controller.pas',
  UnitFuncionarios.Controller in '..\Shared\Controllers\Funcionarios\UnitFuncionarios.Controller.pas',
  UnitFuncoesComuns.Controller in '..\Shared\Controllers\Funcoes\UnitFuncoesComuns.Controller.pas',
  UnitGrupos.Controller in '..\Shared\Controllers\Grupos\UnitGrupos.Controller.pas',
  UnitGrupoSubgrupo.Controller in '..\Shared\Controllers\GrupoSubgrupo\UnitGrupoSubgrupo.Controller.pas',
  UnitProdutos.Controller in '..\Shared\Controllers\Produtos\UnitProdutos.Controller.pas',
  UnitSubGrupos.Controller in '..\Shared\Controllers\SubGrupos\UnitSubGrupos.Controller.pas',
  UnitTotalizadores.Controller in '..\Shared\Controllers\Totalizadores\UnitTotalizadores.Controller.pas',
  UnitUnidadeMedida.Controller in '..\Shared\Controllers\UnidadeMedida\UnitUnidadeMedida.Controller.pas',
  UnitEmpresa.Model in '..\Shared\Models\Empresa\UnitEmpresa.Model.pas',
  UnitFornecedores.Model in '..\Shared\Models\Fornecedores\UnitFornecedores.Model.pas',
  UnitGrupos.Model in '..\Shared\Models\Grupos\UnitGrupos.Model.pas',
  UnitProdutos.Model in '..\Shared\Models\Produtos\UnitProdutos.Model.pas',
  UnitSubGrupos.Model in '..\Shared\Models\SubGrupos\UnitSubGrupos.Model.pas',
  UnitTotalizadores.Model in '..\Shared\Models\Totalizadores\UnitTotalizadores.Model.pas',
  UnitUnidadeMedida.Model in '..\Shared\Models\UnidadeMedida\UnitUnidadeMedida.Model.pas',
  UnitUsuarios.Model in '..\Shared\Models\Usuarios\UnitUsuarios.Model.pas',
  UnitCidade.Model in '..\..\..\FormsComuns\Classes\Cidade\UnitCidade.Model.pas',
  UnitEstado.Model in '..\..\..\FormsComuns\Classes\Estado\UnitEstado.Model.pas',
  UnitDatabase in '..\Shared\Database\UnitDatabase.pas',
  UnitLogin.Controller in '..\Shared\Controllers\Login\UnitLogin.Controller.pas',
  UnitFuncionarios.Model in '..\Shared\Models\Funcionarios\UnitFuncionarios.Model.pas',
  UnitPedidoRemoto.Controller in '..\Shared\Controllers\Pedidos\UnitPedidoRemoto.Controller.pas',
  UnitPedidoRemoto.Model in '..\Shared\Models\Pedidos\UnitPedidoRemoto.Model.pas',
  UnitPedEstRemoto.Model in '..\Shared\Models\PedEst\UnitPedEstRemoto.Model.pas',
  UnitPedEstRemoto.Controller in '..\Shared\Controllers\PedEst\UnitPedEstRemoto.Controller.pas',
  UnitGrades.Model in '..\Shared\Models\Grades\UnitGrades.Model.pas',
  UnitGrades.Controller in '..\Shared\Controllers\Grades\UnitGrades.Controller.pas',
  UnitTamanho.Model in '..\Shared\Models\Tamanhos\UnitTamanho.Model.pas',
  UnitTamanho.Controller in '..\Shared\Controllers\Tamanhos\UnitTamanho.Controller.pas',
  UnitTransferencia.Model in '..\Shared\Models\Transferencias\UnitTransferencia.Model.pas',
  UnitTransferenciaItem.Model in '..\Shared\Models\Transferencias\UnitTransferenciaItem.Model.pas',
  UnitTransferencias.Controller in '..\Shared\Controllers\Transferencias\UnitTransferencias.Controller.pas',
  UnitSync.Controller in '..\Shared\Controllers\Sync\UnitSync.Controller.pas',
  UnitFunctions in '..\..\..\FormsComuns\Classes\ServidoresUtils\Utils\UnitFunctions.pas',
  UnitInicializaClasses in '..\Shared\Utils\UnitInicializaClasses.pas',
  UnitLancamentoCentroCusto.Controller in '..\..\..\FormsComuns\Classes\LancamentoCentroCustos\UnitLancamentoCentroCusto.Controller.pas',
  UnitLancamentoCentroCusto.Model in '..\..\..\FormsComuns\Classes\LancamentoCentroCustos\UnitLancamentoCentroCusto.Model.pas',
  UnitDashboardSync.Model in '..\Shared\Models\DashboardSync\UnitDashboardSync.Model.pas',
  UnitEstoqueEmpresa.Model in '..\Shared\Models\Estoque\UnitEstoqueEmpresa.Model.pas',
  UnitCompras.Model in '..\Shared\Models\Compras\UnitCompras.Model.pas',
  UnitCompras.Controller in '..\Shared\Controllers\Compras\UnitCompras.Controller.pas',
  UnitHisPro.Model in '..\Shared\Models\HistoricoEstoque\UnitHisPro.Model.pas',
  UnitHisPro.Controller in '..\Shared\Controllers\HistoricoEstoque\UnitHisPro.Controller.pas',
  UnitNfeCentral.Model in '..\Shared\Models\Nfe\UnitNfeCentral.Model.pas',
  UnitNfe.Controller in '..\Shared\Controllers\Nfe\UnitNfe.Controller.pas',
  UnitClientes.Model in '..\Shared\Models\Clientes\UnitClientes.Model.pas',
  UnitClientes.Controller in '..\Shared\Controllers\Clientes\UnitClientes.Controller.pas',
  UnitPedidosCompra.Model in '..\Shared\Models\PedidosCompra\UnitPedidosCompra.Model.pas',
  UnitPedidosCompra.Controller in '..\Shared\Controllers\PedidosCompra\UnitPedidosCompra.Controller.pas',
  UnitFaturamento2.Controller in '..\..\..\FormsComuns\Classes\Faturamento2\UnitFaturamento2.Controller.pas',
  UnitPagamentos.Controller in '..\..\..\FormsComuns\Classes\Pagamentos\UnitPagamentos.Controller.pas',
  UnitPagPgm.Model in '..\..\..\FormsComuns\Classes\PagPgm\UnitPagPgm.Model.pas',
  UnitPagPgm.Controller in '..\..\..\FormsComuns\Classes\PagPgm\UnitPagPgm.Controller.pas',
  UnitMovimentacoes.Model in '..\..\..\FormsComuns\Classes\Movimentacoes\UnitMovimentacoes.Model.pas',
  UnitMovimentacoes.Controller in '..\..\..\FormsComuns\Classes\Movimentacoes\UnitMovimentacoes.Controller.pas',
  ConciliacaoFiscal.Controller in '..\Shared\Controllers\ConciliacaoFiscal.Controller.pas',
  UnitFaturamento2.Model in '..\..\..\FormsComuns\Classes\Faturamento2\UnitFaturamento2.Model.pas',
  UnitPagamentos.Model in '..\..\..\FormsComuns\Classes\Pagamentos\UnitPagamentos.Model.pas',
  UnitModelos.Model in '..\Shared\Models\Modelos\UnitModelos.Model.pas',
  UnitModelos.Controller in '..\Shared\Controllers\Modelos\UnitModelos.Controller.pas',
  UnitComEst.Model in '..\Shared\Models\Compras\UnitComEst.Model.pas',
  UnitConstants in '..\..\..\FormsComuns\Classes\ServidoresUtils\Utils\UnitConstants.pas';

var
	LLogFileConfig: THorseLoggerConsoleConfig;
begin
	// ReportMemoryLeaksOnShutdown := True;
	LLogFileConfig := THorseLoggerConsoleConfig.New.SetLogFormat('${request_clientip} [${time}] ${response_status}');
	try
		THorseLoggerManager.RegisterProvider(THorseLoggerProviderConsole.New());
	
    //Middleware
    THorse.Use(CORS)
          .Use(Jhonson)
          .Use(THorseLoggerManager.HorseCallback)		
          .Use(HandleException)
          .Use(HorseSwagger); // Access http://localhost:9000/swagger/doc/html
    //controllers
    TLoginController.Router;
    TClientesController.Router;
    TProdutosController.Router;
    TGruposController.Router;
    TSubGruposController.Router;
    TModelosController.Router;
    TFornecedoresController.Router;
    TEmpresaController.Router;
    TEstadoController.Router;
    TCidadeController.Router;
    TTotalizadoresController.Router;
    TUnidadeMedidaController.Router;
    TFuncoesComunsController.Router;
    TFuncionariosController.Router;
    TGrupoSubGrupoController.Router;
    TDatasetController.Router;
    TPedidoRemotoController.Router;
    TPedEstRemotoController.Router;
    TGradesController.Router;
    TTamanhoController.Router;
    TLancamentoCentroCustoController.Router;
    TTransferenciasController.Router;
    TComprasController.Router;
    TSyncController.Router;
    THisProController.Router;
    TNfeController.Router;
    TPedidosCompraController.Router;
    TFaturamento2Controller.Router;
    TPagamentosController.Router;
    TPagPgmController.Router;
    TMovimentacoesController.Router;

    Swagger
    .Info
      .Title('API PDV PORTAL')
      .Description('API para o sistema PDV PORTAL')
      .Contact
        .Name('Portal.com')
        .Email('sigeportal@gmail.com')
        .URL('http://www.portalsoft.net.br')
      .&End
    .&End;
    
    //inicializa classes
    TInicializarClasses.Iniciar;  
    //start
    THorse.Listen(ObterPorta,
    procedure
    begin
      Writeln('Servidor rodando na porta '+THorse.Port.ToString);
      Writeln('Documentacao: http://localhost:'+THorse.Port.ToString+'/swagger/doc/html');
      Writeln('BD: '+TConstants.BancoDados);
      Writeln('BD Fiscal: '+TConstants.BancoDadosFiscal);
    end);
  finally
		LLogFileConfig.Free;
	end;
end.
