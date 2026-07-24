program ServidorWinService;

uses
  Vcl.SvcMgr,
  UnitPrincipal in 'UnitPrincipal.pas' {ServicoEventos: TService},
  UnitDatabase in '..\Shared\Database\UnitDatabase.pas',
  UnitConstants in '..\Shared\Utils\UnitConstants.pas',
  UnitFunctions in '..\Shared\Utils\UnitFunctions.pas',
  UnitCidade.Controller in '..\Shared\Controllers\Cidade\UnitCidade.Controller.pas',
  UnitDataset.Controller in '..\Shared\Controllers\Dataset\UnitDataset.Controller.pas',
  UnitEstado.Controller in '..\Shared\Controllers\Estado\UnitEstado.Controller.pas',
  UnitFornecedores.Controller in '..\Shared\Controllers\Fornecedores\UnitFornecedores.Controller.pas',
  UnitFuncionarios.Controller in '..\Shared\Controllers\Funcionarios\UnitFuncionarios.Controller.pas',
  UnitFuncoesComuns.Controller in '..\Shared\Controllers\Funcoes\UnitFuncoesComuns.Controller.pas',
  UnitGrupos.Controller in '..\Shared\Controllers\Grupos\UnitGrupos.Controller.pas',
  UnitGrupoSubgrupo.Controller in '..\Shared\Controllers\GrupoSubgrupo\UnitGrupoSubgrupo.Controller.pas',
  UnitSubGrupos.Controller in '..\Shared\Controllers\SubGrupos\UnitSubGrupos.Controller.pas',
  UnitTotalizadores.Controller in '..\Shared\Controllers\Totalizadores\UnitTotalizadores.Controller.pas',
  UnitUnidadeMedida.Controller in '..\Shared\Controllers\UnidadeMedida\UnitUnidadeMedida.Controller.pas',
  UnitProdutos.Model in '..\Shared\Models\Produtos\UnitProdutos.Model.pas',
  UnitTotalizadores.Model in '..\Shared\Models\Totalizadores\UnitTotalizadores.Model.pas',
  UnitUnidadeMedida.Model in '..\Shared\Models\UnidadeMedida\UnitUnidadeMedida.Model.pas',
  UnitUsuarios.Model in '..\Shared\Models\Usuarios\UnitUsuarios.Model.pas',
  UnitCidade.Model in '..\..\FormsComuns\Classes\Cidade\UnitCidade.Model.pas',
  UnitEstado.Model in '..\..\FormsComuns\Classes\Estado\UnitEstado.Model.pas',
  UnitLogin.Controller in '..\Shared\Controllers\Login\UnitLogin.Controller.pas',
  UnitEmpresa.Controller in '..\Shared\Controllers\Empresa\UnitEmpresa.Controller.pas',
  UnitProdutos.Controller in '..\Shared\Controllers\Produtos\UnitProdutos.Controller.pas',
  UnitEmpresa.Model in '..\Shared\Models\Empresa\UnitEmpresa.Model.pas',
  UnitFornecedores.Model in '..\Shared\Models\Fornecedores\UnitFornecedores.Model.pas',
  UnitGrupos.Model in '..\Shared\Models\Grupos\UnitGrupos.Model.pas',
  UnitSubGrupos.Model in '..\Shared\Models\SubGrupos\UnitSubGrupos.Model.pas',
  UnitFuncionarios.Model in '..\Shared\Models\Funcionarios\UnitFuncionarios.Model.pas';

{$R *.RES}

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TServicoEventos, ServicoEventos);
  Application.Run;
end.
