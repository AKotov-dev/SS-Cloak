unit portscan_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Controls, SysUtils, Process, Graphics;

type
  PortScan = class(TThread)
  private
    FPortValue: string;
    ResultStr: TStringList;

    { Private declarations }

  protected

    procedure Execute; override;
    procedure ShowStatus;
    procedure ReadPortValue;

  end;

implementation

uses unit1;

  { TRD }

procedure PortScan.Execute;
var
  ScanProcess: TProcess;
begin
  FreeOnTerminate := True; //Уничтожать по завершении

  while not Terminated do
  try
    ResultStr := TStringList.Create;

    ScanProcess := TProcess.Create(nil);

    //Безопасно читаем порт
    if not Terminated then
      Synchronize(@ReadPortValue);

    ScanProcess.Executable := '/bin/bash';
    ScanProcess.Parameters.Add('-c');
    ScanProcess.Options := [poUsePipes, poWaitOnExit]; // poStderrToOutPut,

    //Проверка локального порта клиента
    ScanProcess.Parameters.Add('ss -ltn | grep -q "127.0.0.1:' +
      FPortValue + '" && echo yes');

    ScanProcess.Execute;

    ResultStr.LoadFromStream(ScanProcess.Output);

    if not Terminated then
      Synchronize(@ShowStatus);

    Sleep(800);
  finally
    ResultStr.Free;
    ScanProcess.Free;
  end;
end;

//Чтение порта с формы
procedure PortScan.ReadPortValue;
begin
  FPortValue := MainForm.LocalPortEdit.Text;
end;

//Отображение статуса
procedure PortScan.ShowStatus;
begin
  with MainForm do
  begin
    if ResultStr.Count <> 0 then
    begin
      Shape1.Brush.Color := clLime;
      LocalPortEdit.Enabled := False;
    end
    else
    begin
      Shape1.Brush.Color := clYellow;
      LocalPortEdit.Enabled := True;
    end;

    Shape1.Repaint;
  end;
end;

end.
