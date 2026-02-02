program ss_cloak_client;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}{$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  start_trd,
  portscan_trd, unit2 { you can add units after this };

  {$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:='SS-Cloak-Client v0.4 (ck-client v2.12.0)';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TQRForm, QRForm);
  Application.Run;
end.
