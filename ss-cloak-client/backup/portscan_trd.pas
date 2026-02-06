unit portscan_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, Graphics;

type
  PortScan = class(TThread)
  private
    FPortValue: string;
    ResultStr: TStringList;

    procedure ReadPort;
    procedure ShowStatus;

  protected
    procedure Execute; override;
  end;

implementation

uses Unit1;

//Опрос порта SOCKS5
procedure PortScan.Execute;
var
  ScanProcess: TProcess;
begin
  FreeOnTerminate := True;

  ResultStr := TStringList.Create;
  ScanProcess := TProcess.Create(nil);

  try
    ScanProcess.Executable := '/bin/bash';
    ScanProcess.Parameters.Add('-c');
    ScanProcess.Options := [poUsePipes, poWaitOnExit];

    while not Terminated do
    begin
      // читаем порт из UI безопасно
      Synchronize(@ReadPort);

      ResultStr.Clear;
      ScanProcess.Parameters.Clear;
      ScanProcess.Parameters.Add('-c');

      ScanProcess.Parameters.Add(
        'ss -ltn | grep -q "127\.0\.0\.1:' + FPortValue + ' " && echo yes');

      ScanProcess.Execute;

      ResultStr.LoadFromStream(ScanProcess.Output);

      if not Terminated then
        Synchronize(@ShowStatus);

      Sleep(800);
    end;

  finally
    ScanProcess.Free;
    ResultStr.Free;
  end;
end;

//Безопасное чтение порта
procedure PortScan.ReadPort;
begin
  FPortValue := MainForm.LocalPortEdit.Text;
end;

//Индикация
procedure PortScan.ShowStatus;
begin
  with MainForm do
  begin
    if ResultStr.Count > 0 then
    begin
      Shape1.Brush.Color := clLime;
      LocalPortEdit.Enabled := False;
    end
    else
    begin
      Shape1.Brush.Color := clYellow;
      LocalPortEdit.Enabled := True;
    end;

    Shape1.Invalidate; //лучше чем Repaint
  end;
end;

end.
