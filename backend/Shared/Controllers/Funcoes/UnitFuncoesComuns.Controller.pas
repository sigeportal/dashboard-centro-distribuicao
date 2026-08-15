unit UnitFuncoesComuns.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json;

type
  TFuncoesComunsController = class
    class procedure Router;
		class procedure PostGeraCodigo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
		class procedure PostIncrementaGenerator(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TFuncoesComunsController }

uses
  UnitTabela.Helpers,
	UnitFunctions;

class procedure TFuncoesComunsController.PostGeraCodigo(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	oJson: TJSONObject;
	Tabela: string;
	Campo: string;
	JsonBody: TJSONObject;
begin
	oJson := TJSONObject.Create;
	try
		JsonBody := Req.Body<TJSONObject>;
		Tabela := JsonBody.GetValue<string>('tabela');
		Campo := JsonBody.GetValue<string>('campo');
		oJson.AddPair('codigo', TJSONNumber.Create(GeraCodigo(Tabela, Campo)));
		Res.Send<TJSONObject>(oJson);
	finally
	end;
end;

class procedure TFuncoesComunsController.PostIncrementaGenerator(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
	oJson: TJSONObject;
	Generator: string;
	JsonBody: TJSONObject;
begin
	oJson := TJSONObject.Create;
	try
		JsonBody := Req.Body<TJSONObject>;
		Generator := JsonBody.GetValue<string>('generator');
		oJson.AddPair('codigo', TJSONNumber.Create(IncrementaGenerator(Generator)));
		Res.Send<TJSONObject>(oJson);
	finally
	end;
end;

class procedure TFuncoesComunsController.Router;
begin
	THorse.Group
				.Prefix('/v1')
				.Route('/gera_codigo')
					.Post(PostGeraCodigo)
				.&End
				.Prefix('/v1')
				.Route('/incrementa_generator')
					.Post(PostIncrementaGenerator)
				.&End;
end;

end.
