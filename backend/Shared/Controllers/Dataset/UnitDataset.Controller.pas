unit UnitDataset.Controller;

interface
uses
	System.SysUtils,
  System.Json,
	Horse,
  Dataset.Serialize,
  UnitConnection.Model.Interfaces;

type
	TDatasetController = class
  	class procedure Router;
    class procedure Post(Req: THorseRequest; Res: THorseResponse);
  end;

implementation

{ TControllerDataset }

uses UnitDatabase;

class procedure TDatasetController.Post(Req: THorseRequest;
  Res: THorseResponse);
var
  JsonSQL: TJSONObject;
  SQL: string;
  Query: iQuery;
begin
	JsonSQL := Req.Body<TJSONObject>;
  SQL := JsonSQL.GetValue<string>('sql');
  Query := TDatabase.Query;
  Query.Add(SQL);
  if not SQL.ToUpper.contains('SELECT') then
  begin
	  Query.ExecSQL;
    Res.Send('{"msg": "ok"}');
  end else
  begin  	
  	Query.Open();
    if Query.DataSet.FieldCount > 1 then
    	Res.Send<TJSONArray>(Query.DataSet.ToJSONArray())
    else
    	Res.Send<TJSONObject>(Query.DataSet.ToJSONObject())    
  end;
end;

class procedure TDatasetController.Router;
begin
 	THorse.Group
  	.Prefix('v1')
    	.Route('dataset')
      	.Post(Post)
      .&End;
end;

end.
