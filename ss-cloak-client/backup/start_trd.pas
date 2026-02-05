unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils;

type
  ShowLogTRD = class(TThread)
  protected
    Result: TStringList;

    procedure Execute; override;
    procedure ShowLog;
    procedure StartTrd;
  end;

implementation

uses Unit1;

procedure ShowLogTRD.Execute;
var
  ExProcess: TProcess;
  Buffer: array[0..255] of Byte;
  ReadCnt: LongInt;
  S, Line: string;
  P: SizeInt;
begin
  FreeOnTerminate := True;

  Result := TStringList.Create;
  ExProcess := TProcess.Create(nil);

  try
    Synchronize(@StartTRD);

    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(
      '[[ -f ~/.config/ss-cloak-client/ss-cloak-client.log ]] || touch ' +
      '~/.config/ss-cloak-client/ss-cloak-client.log && ' +
      'tail -n 100 -f ~/.config/ss-cloak-client/ss-cloak-client.log'
    );

    ExProcess.Options := [poUsePipes, poStderrToOutPut];
    ExProcess.Execute;

    S := '';

    while not Terminated and ExProcess.Running do
    begin
      if ExProcess.Output.NumBytesAvailable > 0 then
      begin
        ReadCnt := ExProcess.Output.Read(Buffer, SizeOf(Buffer));
        if ReadCnt > 0 then
        begin
          SetString(Line, PChar(@Buffer[0]), ReadCnt);
          S := S + Line;

          while True do
          begin
            P := Pos(#10, S);
            if P = 0 then Break;

            Result.Add(Trim(Copy(S, 1, P - 1)));
            Delete(S, 1, P);
          end;

          Synchronize(@ShowLog);
        end;
      end
      else
        Sleep(10);
    end;

  finally
    ExProcess.Free;
    Result.Free;
  end;
end;

{ UI }

procedure ShowLogTRD.StartTRD;
begin
  MainForm.LogMemo.SelStart := Length(MainForm.LogMemo.Text);
  MainForm.LogMemo.SelLength := 0;
end;

procedure ShowLogTRD.ShowLog;
var
  i: Integer;
begin
  for i := 0 to Result.Count - 1 do
    MainForm.LogMemo.Lines.Add(Result[i]);

  Result.Clear;

  // ограничиваем размер лога
  while MainForm.LogMemo.Lines.Count > 500 do
    MainForm.LogMemo.Lines.Delete(0);

  MainForm.LogMemo.SelStart := Length(MainForm.LogMemo.Text);
  MainForm.LogMemo.SelLength := 0;
end;

end.

