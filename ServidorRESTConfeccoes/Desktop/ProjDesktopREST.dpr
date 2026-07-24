program ProjDesktopREST;

uses
  Forms,
  UnitPrincipal in 'UnitPrincipal.pas' {FrmPrincipal},
  MidasLib,
  Vcl.Themes,
  Vcl.Styles,
  UnitFrmEsmaecido in '..\..\..\FormsComuns\Herança\UnitFrmEsmaecido.pas' {FrmEsmaecido},
  UnitFormBase in '..\..\..\FormsComuns\Herança\UnitFormBase.pas' {FrmBase},
  UnitDMPrincipal in 'UnitDMPrincipal.pas' {DMPrincipal: TDataModule},
  UnitPesquisa in 'UnitPesquisa.pas' {FrmPesquisa},
  UnitSobre in 'UnitSobre.pas' {FrmSobre},
  UnitLogin in 'UnitLogin.pas' {FrmLogin},
  UnitObserver.Model.Interfaces in '..\..\..\FormsComuns\Classes\Observer\UnitObserver.Model.Interfaces.pas',
  Cripto in '..\..\..\FormsComuns\Cripto.pas',
  MD5 in '..\..\..\FormsComuns\MD5.pas',
  UnitCapturaExcecao in '..\..\..\FormsComuns\UnitCapturaExcecao.pas',
  UnitPermissoesSenhas in 'UnitPermissoesSenhas.pas' {FrmPermissoesSenhas},
  UnitSplash in '..\..\..\FormsComuns\UnitSplash.pas' {FrmSplash},
  UnitCommand.Interfaces in '..\..\..\FormsComuns\Classes\Command\UnitCommand.Interfaces.pas',
  UnitCadEmpresa in 'Modulos\Empresa\Views\UnitCadEmpresa.pas' {FrmCadEmpresa},
  UnitMsgUsuario in '..\..\..\FormsComuns\UnitMsgUsuario.pas' {FrmMsgUsuario},
  UnitArquivosIni.Model in '..\..\..\FormsComuns\Classes\ArquivosIni\Model\UnitArquivosIni.Model.pas',
  UnitGrid in 'UnitGrid.pas' {FrmGrid},
  UnitComponentes.Model.Interfaces in '..\..\..\FormsComuns\Fabrica Componentes\UnitComponentes.Model.Interfaces.pas',
  UnitDataSet.Model in '..\..\..\FormsComuns\Fabrica Componentes\UnitDataSet.Model.pas',
  UnitDBGrid.Model in '..\..\..\FormsComuns\Fabrica Componentes\UnitDBGrid.Model.pas',
  UnitFactoryComponentes.Model in '..\..\..\FormsComuns\Fabrica Componentes\UnitFactoryComponentes.Model.pas',
  UnitMenuItem.Model in '..\..\..\FormsComuns\Fabrica Componentes\UnitMenuItem.Model.pas',
  UnitPageControl.Model in '..\..\..\FormsComuns\Fabrica Componentes\UnitPageControl.Model.pas',
  UnitStoreProc.Model in '..\..\..\FormsComuns\Fabrica Componentes\UnitStoreProc.Model.pas',
  UnitTabSheet.Model in '..\..\..\FormsComuns\Fabrica Componentes\UnitTabSheet.Model.pas',
  UnitRelGeral in 'UnitRelGeral.pas' {FrmRelGeral},
  UnitFortesReportPadrao in '..\..\..\FormsComuns\Herança\UnitFortesReportPadrao.pas' {FrmFortesReportPadrao},
  UnitPermissoes.Model in '..\..\..\FormsComuns\Classes\Permissoes\Model\UnitPermissoes.Model.pas',
  UnitUsuarios.Model in '..\..\..\FormsComuns\Classes\Usuarios\Model\UnitUsuarios.Model.pas',
  UnitConfigIniciaisServidor in '..\..\..\FormsComuns\UnitConfigIniciaisServidor.pas' {FrmConfigIniciaisServidor},
  UnitFormCadastroRTTI in '..\..\..\FormsComuns\Herança\UnitFormCadastroRTTI.pas' {FrmCadastroRTTI},
  UnitCadProduto in 'Modulos\Produtos\View\UnitCadProduto.pas' {FrmCadProdutos},
  Bitmap.HelperClass in '..\..\..\FormsComuns\Classes\BitmapHelper\Bitmap.HelperClass.pas',
  UnitAmpliaFoto in '..\..\..\FormsComuns\AmpliaFoto\UnitAmpliaFoto.pas' {FrmAmpliaFoto},
  UnitCadGrupoSubGrupo in '..\..\..\FormsComuns\Cadastros Comuns\Grupo_SubGrupo_Produto\Rest\UnitCadGrupoSubGrupo.pas' {FrmCadGrupoSubGrupo},
  UnitCadFornecedores in '..\..\..\FormsComuns\Cadastros Comuns\Fornecedores\Rest\UnitCadFornecedores.pas' {FrmCadFornecedores},
  UnitFrameRelogioPortal in '..\..\..\FormsComuns\RelógioPortal\UnitFrameRelogioPortal.pas' {FrameRelogioPortal: TFrame},
  UnitEstado.Model in '..\..\..\FormsComuns\Classes\Estado\UnitEstado.Model.pas',
  UnitCidade.Model in '..\..\..\FormsComuns\Classes\Cidade\UnitCidade.Model.pas',
  UnitGridProduto in 'UnitGridProduto.pas' {FrmGridProduto},
  UnitFuncoesUtils in 'UnitFuncoesUtils.pas',
  UnitPortalStoreFirebase.Model in '..\..\..\FormsComuns\Classes\PortalStoreFirebase\Model\UnitPortalStoreFirebase.Model.pas',
  UnitNavegadorWeb in '..\..\..\FormsComuns\Classes\NavegadorWeb\View\UnitNavegadorWeb.pas' {FrmNavegadorWeb},
  UnitCorrigirJSNoWebBrowser.Model in '..\..\..\FormsComuns\Classes\NavegadorWeb\Model\UnitCorrigirJSNoWebBrowser.Model.pas',
  UnitFuncionarios.Model in '..\Shared\Models\Funcionarios\UnitFuncionarios.Model.pas',
  UnitProdutos.Model in '..\Shared\Models\Produtos\UnitProdutos.Model.pas',
  UnitSubGrupos.Model in '..\Shared\Models\SubGrupos\UnitSubGrupos.Model.pas',
  UnitTotalizadores.Model in '..\Shared\Models\Totalizadores\UnitTotalizadores.Model.pas',
  UnitUnidadeMedida.Model in '..\Shared\Models\UnidadeMedida\UnitUnidadeMedida.Model.pas',
  UnitGrupos.Model in '..\Shared\Models\Grupos\UnitGrupos.Model.pas',
  UnitFornecedores.Model in '..\Shared\Models\Fornecedores\UnitFornecedores.Model.pas',
  UnitUploadCloudStorage.Model in '..\Shared\Models\Produtos\UnitUploadCloudStorage.Model.pas',
  UnitCadFuncionario in 'Modulos\Funcionarios\Views\UnitCadFuncionario.pas' {FrmCadFuncionario},
  UnitEmpresa.Model in '..\Shared\Models\Empresa\UnitEmpresa.Model.pas',
  UnitPedidos.View in 'Modulos\Pedidos\Views\UnitPedidos.View.pas' {FrmPedidos},
  UnitPedEstRemoto.Model in '..\Shared\Models\PedEst\UnitPedEstRemoto.Model.pas',
  UnitPedidoRemoto.Model in '..\Shared\Models\Pedidos\UnitPedidoRemoto.Model.pas',
  UnitBuscaPedidoRemoto in 'Modulos\Pedidos\Views\UnitBuscaPedidoRemoto.pas' {FrmBuscaPedidoRemoto},
  UnitCodBarra in 'Modulos\Etiquetas\View\UnitCodBarra.pas' {FrmCodBarra},
  UnitEtiquetaEAN13_MaxPrint in 'Modulos\Etiquetas\Models\UnitEtiquetaEAN13_MaxPrint.pas' {FrmEtiquetaEAN13_MaxPrint},
  UnitEtiquetaEAN13_Pimaco in 'Modulos\Etiquetas\Models\UnitEtiquetaEAN13_Pimaco.pas' {FrmEtiquetaEAN13_Pimaco},
  UnitEtiquetaL21_A15 in 'Modulos\Etiquetas\Models\UnitEtiquetaL21_A15.pas' {FrmEtiquetaL21_A15},
  UnitEtiquetaL34_A21 in 'Modulos\Etiquetas\Models\UnitEtiquetaL34_A21.pas' {FrmEtiquetaL34_A21},
  UnitEtiquetaL45_A12 in 'Modulos\Etiquetas\Models\UnitEtiquetaL45_A12.pas' {FrmEtiquetaL45_A12},
  UnitEtiquetaL65_A25 in 'Modulos\Etiquetas\Models\UnitEtiquetaL65_A25.pas' {FrmEtiquetaL65_A25},
  UnitGrades.Model in '..\Shared\Models\Grades\UnitGrades.Model.pas',
  UnitGridGrade in 'Modulos\Grades\Views\UnitGridGrade.pas' {FrmGridGrade},
  UnitCadGrades in 'Modulos\Grades\Views\UnitCadGrades.pas' {FrmCadGrades},
  UnitTamanho.Model in '..\Shared\Models\Tamanhos\UnitTamanho.Model.pas',
  UnitPortalQueryREST.Component in '..\..\..\Packages\PortalQueryREST\src\UnitPortalQueryREST.Component.pas',
  UnitEtiquetasRibbon.Interfaces in 'Modulos\EtiquetasRibbon\UnitEtiquetasRibbon.Interfaces.pas',
  UnitEtiquetasRibbon in 'Modulos\EtiquetasRibbon\Views\UnitEtiquetasRibbon.pas' {FrmEtiquetasRibbon},
  UnitEtiquetaZebra3Colunas.Model in 'Modulos\EtiquetasRibbon\Models\UnitEtiquetaZebra3Colunas.Model.pas',
  UnitEscolhaImpressora in 'Modulos\EscolhaImpressora\Views\UnitEscolhaImpressora.pas' {FrmEscolhaImpressora};

{$R *.RES}

var
	i      : shortint;
	maximo : shortint = 0;
	divisor: shortint = 5;

begin
	// ReportMemoryLeaksOnShutdown := True;
	Application.Initialize;
	with TFrmSplash.Create(nil) do
		try
			Gauge1.MaxValue := 50;
			Show;
			Update;
			for i := 1 to (maximo + (100 div divisor)) do
			begin
				Gauge1.Progress := i;
				maximo          := i;
				delay(0.1);
			end;
			Application.Title := 'SIGE - Desktop';
			Application.CreateForm(TDMPrincipal, DMPrincipal);
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  for i := maximo to (maximo + (50 div divisor)) do
			begin
				Gauge1.Progress := i;
				maximo          := i;
				delay(0.05);
			end;
			for i := maximo to (maximo + (50 div divisor)) do
			begin
				Gauge1.Progress := i;
				maximo          := i;
				delay(0.05);
			end;
			for i := maximo to (maximo + (50 div divisor)) do
			begin
				Gauge1.Progress := i;
				maximo          := i;
				delay(0.05);
			end;
			Application.CreateForm(TFrmPesquisa, FrmPesquisa);
			for i := maximo to (maximo + (100 div divisor)) do
			begin
				Gauge1.Progress := i;
				maximo          := i;
				delay(0.05);
			end;
		finally
			Free;
		end;
	Application.Run;

end.
