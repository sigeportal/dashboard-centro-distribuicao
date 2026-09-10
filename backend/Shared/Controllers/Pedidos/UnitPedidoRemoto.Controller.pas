unit UnitPedidoRemoto.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json;

type
  TPedidoRemotoController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TPedidosController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitPedidoRemoto.Model,
  UnitTabela.Helpers;

class procedure TPedidoRemotoController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Pedidos: TPedidoRemoto;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Pedidos := TPedidoRemoto.Create(TDatabase.Connection);
    Pedidos.BuscaDadosTabela(id);
    Pedidos.DataCancelamento := Date;
    Pedidos.SalvaNoBanco();
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Pedidos.DisposeOf;
  end;
end;

class procedure TPedidoRemotoController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var 
	Pedidos: TPedidoRemoto;
  aJson: TJSONArray;
  Query: iQuery;
  Estado: string;
begin	
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
  	if Req.Query.ContainsKey('estado') then
    	Estado := Req.Query.Items['estado'];    
    Pedidos := TPedidoRemoto.Create(TDatabase.Connection);
    try
      Pedidos.BuscaDadosTabela(GeraCodigo('PEDIDOS_REMOTO', 'PED_CODIGO')-1);
    except
      Pedidos.BuscaDadosTabela(1);
    end;
    if not Estado.IsEmpty then    
    begin
      Query.Add('SELECT PED_CODIGO FROM PEDIDOS_REMOTO WHERE PED_DATAC IS NULL AND PED_ESTADO = :ESTADO ORDER BY PED_CODIGO');
      Query.AddParam('ESTADO', Estado);
      Query.Open();
    end else
    	Query.Open('SELECT PED_CODIGO FROM PEDIDOS_REMOTO WHERE PED_DATAC IS NULL AND ((PED_ESTADO IS NULL) or (PED_ESTADO <> ''FINALIZADO''))  ORDER BY PED_CODIGO');
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Pedidos.BuscaDadosTabela(Query.Dataset.FieldByName('PED_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(Pedidos.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
    Pedidos.DisposeOf;
  end;
end;

class procedure TPedidoRemotoController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Pedidos: TPedidoRemoto;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    Pedidos := TPedidoRemoto.Create(TDatabase.Connection);
    Pedidos.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Pedidos.ToJson) as TJSONObject);
  finally
    Pedidos.DisposeOf;
  end;
end;

class procedure TPedidoRemotoController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Pedidos: TPedidoRemoto;
begin
  try
    Pedidos := TPedidoRemoto.Create(TDatabase.Connection).fromJson<TPedidoRemoto>(Req.Body);
    Pedidos.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Pedidos.ToJson) as TJSONObject);
  finally
    Pedidos.DisposeOf;
  end;
end;

class procedure TPedidoRemotoController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Pedidos: TPedidoRemoto;
begin
  try
    Pedidos := TPedidoRemoto.Create(TDatabase.Connection).fromJson<TPedidoRemoto>(Req.Body);
    Pedidos.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Pedidos.ToJson) as TJSONObject);
  finally
    Pedidos.DisposeOf;
  end;
end;

class procedure TPedidoRemotoController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/pedidos')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Prefix('/v1')
        .Route('/pedidos/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
end;

end.
