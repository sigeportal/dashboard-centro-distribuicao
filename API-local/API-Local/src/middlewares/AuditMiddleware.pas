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
    Next; // Executa o próximo middleware/rota primeiro
  finally
    try
      // Verifica existência do diretório
      LogDir := TPath.Combine(ExtractFilePath(ParamStr(0)), 'logs');
      if not TDirectory.Exists(LogDir) then
        TDirectory.CreateDirectory(LogDir); // Se não existir, cria-o

      LogFile := TPath.Combine(LogDir, 'audit-' + FormatDateTime('yyyy-mm-dd', Now) + '.log');

      // Acessando propriedades via RawWebRequest
      ClientIP := Req.RawWebRequest.RemoteAddr;

      // Monta linha de log: [DATA HORA] IP - METODO PATH - STATUS
      LogLine := Format('[%s] %s - %s %s - %d', [
       FormatDateTime('yyyy-mm-dd hh:nn:ss', Now),
       ClientIP,
       Req.RawWebRequest.Method,
       Req.RawWebRequest.PathInfo,
       Res.Status
      ]);

//      Writeln(LogLine); // Escrita do log no terminal

      // Escrita do log no arquivo
      TFile.AppendAllText(LogFile, LogLine + sLineBreak);
    except
      on E: Exception do
//        System.Writeln('Erro ao gravar log: ' + E.Message);
    end;
  end;
end;

end.
