unit UnitPrincipal;

interface

uses
  Winapi.Windows, 
  Winapi.Messages, 
  System.SysUtils, 
  System.Classes, 
  Vcl.Graphics, 
  Vcl.Controls, 
  Vcl.SvcMgr, 
  Vcl.Dialogs;

type
  TServicoEventos = class(TService)
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  ServicoEventos: TServicoEventos;

implementation

{$R *.dfm}

uses
	Horse,
  Horse.CORS,
  Horse.Jhonson,
  Horse.HandleException,
  UnitEmpresa.Controller, 
  UnitLogin.Controller, UnitProdutos.Controller, UnitGrupos.Controller,
  UnitGrupoSubgrupo.Controller, UnitSubGrupos.Controller,
  UnitFornecedores.Controller, UnitEstado.Controller, UnitCidade.Controller,
  UnitTotalizadores.Controller, UnitUnidadeMedida.Controller,
  UnitFuncoesComuns.Controller, UnitFuncionarios.Controller,
  UnitDataset.Controller, UnitTransferencias.Controller, UnitSync.Controller;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  ServicoEventos.Controller(CtrlCode);
end;

function TServicoEventos.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TServicoEventos.ServiceCreate(Sender: TObject);
begin
	//Middleware
	THorse.Use(CORS)
        .Use(Jhonson)
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
	TTransferenciasController.Router;
	TSyncController.Router;
end;

procedure TServicoEventos.ServiceStart(Sender: TService; var Started: Boolean);
begin
	THorse.Listen(9000);
  Started := True;	
end;

procedure TServicoEventos.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
	Stopped := True;
	THorse.StopListen;
end;

end.
