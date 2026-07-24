unit AuditMiddleware;

interface

uses
  Horse,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  Web.HTTPApp;

procedure AuditLog(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

procedure AuditLog(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LogDir, LogFile, LogLine: string;
  ClientIP: string;
begin
  try
    // Executa o próximo middleware/rota primeiro
    Next;
  finally
    try
//      LogDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'logs');
//      if not TDirectory.Exists(LogDir) then
//        TDirectory.CreateDirectory(LogDir);
//
//      LogFile := TPath.Combine(LogDir, 'audit-' + FormatDateTime('yyyy-mm-dd', Now) + '.log');

      // Acessando propriedades via RawWebRequest
      ClientIP := Req.RawWebRequest.RemoteAddr;

      // Monta a linha de log: [DATA HORA] IP - METODO PATH - STATUS
      LogLine := Format('[%s] %s - %s %s - %d', [
        FormatDateTime('yyyy-mm-dd hh:nn:ss', Now),
        ClientIP,
        Req.RawWebRequest.Method,
        Req.RawWebRequest.PathInfo,
        Res.Status
      ]);
      Writeln(LogFile);

      // Escrita no arquivo
//      TFile.AppendAllText(LogFile, LogLine + sLineBreak);
    except
      on E: Exception do
        System.Writeln('Erro ao gravar log: ' + E.Message);
    end;
  end;
end;

end.
