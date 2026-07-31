program api_centro_distribuicao;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Horse,
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
  UnitConstants in '..\Shared\Utils\UnitConstants.pas',
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
  UnitHisPro.Controller in '..\Shared\Controllers\HistoricoEstoque\UnitHisPro.Controller.pas';

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
          .Use(HandleException);
    //controllers
    TLoginController.Router;
    TProdutosController.Router;
    TGruposController.Router;
    TSubGruposController.Router;
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
    
    //inicializa classes
    TInicializarClasses.Iniciar;  
    //start
    THorse.Listen(ObterPorta,
    procedure
    begin
      Writeln('Servidor rodando na porta '+THorse.Port.ToString);
      Writeln('BD: '+TConstants.BancoDados);
    end);
  finally
		LLogFileConfig.Free;
	end;
end.
