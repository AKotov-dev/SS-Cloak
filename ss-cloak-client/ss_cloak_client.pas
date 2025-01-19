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
  portscan_trd { you can add units after this };

  {$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title:=
    'SS-Cloak-Client v0.1 (sslocal v1.22.0, ck-client v2.19.0)';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
