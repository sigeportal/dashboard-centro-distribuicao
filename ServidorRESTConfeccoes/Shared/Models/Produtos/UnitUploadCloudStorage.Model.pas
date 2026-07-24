unit UnitUploadCloudStorage.Model;

interface
uses
	UnitPortalStoreFirebase.Model, 
  System.SysUtils;

type
	TUploadCloudStorage = class
	private
		FNomeArquivo: string;
    FDiretorio: string;
    FLogUpload: TProc<string>;
  published
		property NomeArquivo: string read FNomeArquivo write FNomeArquivo;
		property Diretorio: string read FDiretorio write FDiretorio;
    property LogUpload: TProc<string> read FLogUpload write FLogUpload;
		function Upload: string;
  end;

implementation

uses 
	System.Classes,
	System.StrUtils, 
  UnitFuncoesUtils;

{ TUploadCloudStorage }

function TUploadCloudStorage.Upload: string;
var
  PortalStoreFirebase: TPortalStoreFirebase;
begin
	PortalStoreFirebase := TPortalStoreFirebase.Create('AIzaSyAxfxVGU_SewFemGeL3NyugS6izVG2z3yE');
  try
  	PortalStoreFirebase.Log := FLogUpload;
    PortalStoreFirebase.StorageBucketName := 'joalheria-milauren.appspot.com';
  	PortalStoreFirebase.LogarComEmailESenha('portalsoft.com@gmail.com', 'portal3694');
    while not PortalStoreFirebase.Auth.Authenticated do
    	MensagemUsuario('Aguardando, login...', 1, False, True);    	
    Result := PortalStoreFirebase.UploadArquivo(NomeArquivo, Diretorio);
  finally
    PortalStoreFirebase.DisposeOf;
  end;
end;

end.

