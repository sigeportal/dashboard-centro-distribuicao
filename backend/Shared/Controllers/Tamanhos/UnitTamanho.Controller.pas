unit UnitTamanho.Controller;

interface
uses
  Horse,
  Horse.Commons,
  Classes,
  SysUtils,
  System.Json;

type
  TTamanhoController = class
    class procedure Router;
    class procedure Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure PostEmLote(Req: THorseRequest; Res: THorseResponse);
    class procedure Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    class procedure Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TTamanhoController }

uses
  UnitConnection.Model.Interfaces,
  UnitDatabase,
  UnitFunctions,
  UnitTamanho.Model,
  UnitTabela.Helpers, FireDAC.Comp.Client;

class procedure TTamanhoController.Delete(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Tamanho: TTamanho;
  id: Integer;
begin
  try
    id := Req.Params.Items['id'].ToInteger();
    Tamanho := TTamanho.Create(TDatabase.Connection);
    Tamanho.Apagar(id);
    Res.Send('').Status(THTTPStatus.NoContent);
  finally
    Tamanho.DisposeOf;
  end;
end;

class procedure TTamanhoController.Get(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Tamanho: TTamanho;
    aJson: TJSONArray;
    Query: iQuery;
begin
  aJson := TJSONArray.Create;
  Query := TDatabase.Query;
  try
    Tamanho := TTamanho.Create(TDatabase.Connection);
    try
      Tamanho.BuscaDadosTabela(GeraCodigo('TAMANHOS', 'TAM_CODIGO')-1);
    except
      Tamanho.BuscaDadosTabela(1);
    end;
    Query.Open('SELECT TAM_CODIGO FROM TAMANHOS ORDER BY TAM_CODIGO');
    Query.Dataset.First;
    while not Query.Dataset.Eof do
    begin
      Tamanho.BuscaDadosTabela(Query.Dataset.FieldByName('TAM_CODIGO').AsInteger);
      aJson.Add(TJSONObject.ParseJSONValue(Tamanho.ToJson) as TJSONObject);
      Query.Dataset.Next;
    end;
    Res.Send<TJSONArray>(aJson);
  finally
    Tamanho.DisposeOf;
  end;
end;

class procedure TTamanhoController.GetForID(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Tamanho: TTamanho;
    aJson: TJSONArray;
    id: Integer;
begin
  aJson := TJSONArray.Create;
  id := Req.Params.Items['id'].ToInteger();
  try
    Tamanho := TTamanho.Create(TDatabase.Connection);
    Tamanho.BuscaDadosTabela(id);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Tamanho.ToJson) as TJSONObject);
  finally
    Tamanho.DisposeOf;
  end;
end;

class procedure TTamanhoController.Post(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Tamanho: TTamanho;
begin
  try
    Tamanho := TTamanho.Create(TDatabase.Connection).fromJson<TTamanho>(Req.Body);
    if Tamanho.Codigo <= 0 then
      Tamanho.Codigo := GeraCodigo('TAMANHOS', 'TAM_CODIGO');
    Tamanho.Cadastrar := 'S';
    Tamanho.SalvaNoBanco(0);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Tamanho.ToJson) as TJSONObject).Status(THTTPStatus.Created);
  finally
    Tamanho.DisposeOf;
  end;
end;

class procedure TTamanhoController.PostEmLote(Req: THorseRequest; Res: THorseResponse);
var
	Itens     : TTamanho;
	aJson     : TJSONArray;
	oJsonValue: TJSONValue;
	oJson     : TJSONObject;
	LQuery    : iQuery;
	FDQuery   : TFDQuery;
	i         : Integer;
  Tamanho: TTamanho;
begin
	Tamanho := TTamanho.Create(TDatabase.Connection);
  try
    Tamanho.BuscaDadosTabela(GeraCodigo('TAMANHOS', 'TAM_CODIGO')-1);
  except
    Tamanho.BuscaDadosTabela(1);
  end;    
	oJson   := Req.Body<TJSONObject>;
	aJson   := oJson.GetValue<TJSONArray>('itens');
	LQuery  := TDatabase.Query;
	FDQuery := TFDQuery(LQuery.Query);
	FDQuery.Close;
	FDQuery.SQL.Add('UPDATE OR INSERT INTO TAMANHOS (TAM_CODIGO, TAM_PRO, TAM_TAMANHO, TAM_SIGLA, TAM_VALOR)');
  FDQuery.SQL.Add('VALUES (:TAM_CODIGO, :TAM_PRO, :TAM_TAMANHO, :TAM_SIGLA, :TAM_VALOR)');
  FDQuery.SQL.Add('MATCHING (TAM_CODIGO)');  
	// preparando para usar inser��es via ArrayDML
	FDQuery.Params.ArraySize := aJson.Count;
	for i                    := 0 to Pred(aJson.Count) do
	begin
		oJsonValue := aJson.Items[i];
		Itens      := TTamanho.Create(TDatabase.Connection).fromJson<TTamanho>(oJsonValue.ToJson);
		try
			FDQuery.ParamByName('TAM_CODIGO').AsIntegers[i] := Itens.Codigo;
			FDQuery.ParamByName('TAM_PRO').AsIntegers[i]    := Itens.Pro;
			FDQuery.ParamByName('TAM_TAMANHO').AsStrings[i]	:= Itens.Tamanho;
			FDQuery.ParamByName('TAM_SIGLA').AsStrings[i]   := Itens.Sigla;
			FDQuery.ParamByName('TAM_VALOR').AsCurrencys[i] := Itens.Valor;
		finally
			Itens.DisposeOf;
		end;
	end;
	// Executa as inser��es em lote
	FDQuery.Execute(aJson.Count, 0);
	Res.Send<TJSONObject>(oJson);
end;

class procedure TTamanhoController.Put(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var Tamanho: TTamanho;
begin
  try
    Tamanho := TTamanho.Create(TDatabase.Connection).fromJson<TTamanho>(Req.Body);
    Tamanho.SalvaNoBanco(1);
    Res.Send<TJSONObject>(TJSONObject.ParseJSONValue(Tamanho.ToJson) as TJSONObject);
  finally
    Tamanho.DisposeOf;
  end;
end;

class procedure TTamanhoController.Router;
begin
  THorse.Group
        .Prefix('/v1')
        .Route('/tamanhos')
          .Get(Get)
          .Post(Post)
          .Put(Put)
        .&End
        .Prefix('/v1')
        .Route('/tamanhos/:id')
          .Get(GetForID)
          .Delete(Delete)
        .&End
        .Prefix('/v1')
        .Route('/tamanhos/emLote')
          .Post(PostEmLote)
        .&End
end;

end.
