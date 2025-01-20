unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Buttons, IniPropStorage, FileUtil, ExtCtrls, Process, IniFiles, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    AutoStartBox: TCheckBox;
    ClearBox: TCheckBox;
    MethodComboBox: TComboBox;
    DNSComboBox: TComboBox;
    Label5: TLabel;
    Label6: TLabel;
    GenProcess: TProcess;
    SaveDialog1: TSaveDialog;
    QRBtn: TSpeedButton;
    ServerEdit: TEdit;
    ServerPortEdit: TEdit;
    CamouflageEdit: TEdit;
    LocalPortEdit: TEdit;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    LogMemo: TMemo;
    Shape1: TShape;
    SaveBtn: TSpeedButton;
    ServerConfigs: TSpeedButton;
    StartBtn: TSpeedButton;
    StaticText1: TStaticText;
    StopBtn: TSpeedButton;
    procedure AutoStartBoxChange(Sender: TObject);
    procedure ClearBoxChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure QRBtnClick(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure ServerConfigsClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
    procedure StartProcess(command: string);
  private

  public

  end;

var
  MainForm: TMainForm;

resourcestring
  SGenerateConf = 'Client and Server configurations will be recreated! Continue?';

implementation

uses unit2, start_trd, portscan_trd;

  {$R *.lfm}

  { TMainForm }


//Общая процедура запуска команд (асинхронная)
procedure TMainForm.StartProcess(command: string);
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := '/bin/bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);
    //  ExProcess.Options := ExProcess.Options + [poWaitOnExit];
    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Проверка чекбокса ClearBox (очистка кеш/cookies)
function CheckClear: boolean;
begin
  if FileExists(GetUserDir + '.config/ss-cloak-client/clear') then
    Result := True
  else
    Result := False;
end;

//Проверка чекбокса AutoStart
function CheckAutoStart: boolean;
var
  S: ansistring;
begin
  RunCommand('/bin/bash', ['-c',
    '[[ -n $(systemctl --user is-enabled ss-cloak-client | grep "enabled") ]] && echo "yes"'],
    S);

  if Trim(S) = 'yes' then
    Result := True
  else
    Result := False;
end;

//Start
procedure TMainForm.StartBtnClick(Sender: TObject);
begin
  //Быстрая очистка вывода перед стартом
  LogMemo.Clear;
  //Запускаем сервис
  StartProcess('systemctl --user restart ss-cloak-client.service');
end;

//Стоп
procedure TMainForm.StopBtnClick(Sender: TObject);
begin
  StartProcess('systemctl --user stop ss-cloak-client.service');
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  INI: TIniFile;
begin
  try
    MainForm.Caption := Application.Title;

    //Создаём каталоги настроек
    if not DirectoryExists(GetUserDir + '.config') then MkDir(GetUserDir + '.config');
    if not DirectoryExists(GetUserDir + '.config/ss-cloak-client') then
      MkDir(GetUserDir + '.config/ss-cloak-client');

    //Для настроек по нажатию Start (server, server_port, password и local_port)
    INI := TINIFile.Create(GetUserDir +
      '.config/ss-cloak-client/ss-cloak-client.ini');

    //Для сохранения настроек формы и др.
    IniPropStorage1.IniFileName := INI.FileName;

    //Начитываем настройки из ss-cloak-client.ini или дефолтные
    if FileExists(GetUserDir + '.config/ss-cloak-client/ss-cloak-client.ini') then
    begin
      ServerEdit.Text := INI.ReadString('settings', 'server', '192.168.0.77');
      ServerPortEdit.Text := INI.ReadString('settings', 'server_port', '443');
      CamouflageEdit.Text := INI.ReadString('settings', 'camouflage',
        'www.bing.com');
      LocalPortEdit.Text := INI.ReadString('settings', 'local_port', '1080');
      DNSComboBox.Text := INI.ReadString('settings', 'dns', '1.1.1.1');
      MethodComboBox.Text := INI.ReadString('settings', 'method', 'aes-128-gcm');
    end;
  finally
    INI.Free;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  IniPropStorage1.Save;
end;

//Автостарт
procedure TMainForm.AutoStartBoxChange(Sender: TObject);
var
  S: ansistring;
begin
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;

  if not AutoStartBox.Checked then
    RunCommand('/bin/bash', ['-c',
      'systemctl --user disable ss-cloak-client.service'], S)
  else
    RunCommand('/bin/bash', ['-c',
      'systemctl --user enable ss-cloak-client.service'], S);
  Screen.Cursor := crDefault;
end;

//Файл-флаг автоочистки кеша и кукисов
procedure TMainForm.ClearBoxChange(Sender: TObject);
var
  S: ansistring;
begin
  if not ClearBox.Checked then
    RunCommand('/bin/bash', ['-c', 'rm -f ~/.config/ss-cloak-client/clear'], S)
  else
    RunCommand('/bin/bash', ['-c', 'touch ~/.config/ss-cloak-client/clear'], S);
end;

//MainForm, запуск потоков
procedure TMainForm.FormShow(Sender: TObject);
var
  FShowLogTRD, FPortScanThread: TThread;
begin
  IniPropStorage1.Restore;

  ClearBox.Checked := CheckClear;
  AutoStartBox.Checked := CheckAutoStart;

  //Запуск потока проверки состояния локального порта
  FPortScanThread := PortScan.Create(False);
  FPortScanThread.Priority := tpNormal;

  //Запуск поток непрерывного чтения лога
  FShowLogTRD := ShowLogTRD.Create(False);
  FShowLogTRD.Priority := tpNormal;
end;

procedure TMainForm.QRBtnClick(Sender: TObject);
begin
  if FileExists(GetUserDir + '.config/ss-cloak-client/config.json') then QRForm.Show;
end;

//Save Settings
procedure TMainForm.SaveBtnClick(Sender: TObject);
var
  INI: TIniFile;
  S: TStringList;
begin
  if MessageDlg(SGenerateConf, mtWarning, [mbYes, mbCancel], 0) <> mrYes then  Exit;

  try
    //Stop Client
    StopBtn.Click;

    //Запоминаем настройки INI
    INI := TINIFile.Create(GetUserDir +
      '.config/ss-cloak-client/ss-cloak-client.ini');
    INI.WriteString('settings', 'server', ServerEdit.Text);
    INI.WriteString('settings', 'server_port', ServerPortEdit.Text);
    INI.WriteString('settings', 'camouflage', CamouflageEdit.Text);
    INI.WriteString('settings', 'local_port', LocalPortEdit.Text);
    INI.WriteString('settings', 'dns', DNSComboBox.Text);
    INI.WriteString('settings', 'method', MethodComboBox.Text);

    //Create ~/.config/ss-cloak-client/config-gen.sh
    S := TStringList.Create;

    S.Add('#!/bin/bash');
    S.Add('');
    S.Add('#settings');
    S.Add('server_port="' + ServerPortEdit.Text + '"');
    S.Add('server_ip="' + ServerEdit.Text + '"');
    S.Add('nameserver="' + DNSComboBox.Text + '"');
    S.Add('redirect_url="' + CamouflageEdit.Text + '"');
    S.Add('browser="chrome"');
    S.Add('#local_client_port');
    S.Add('local_client_port="' + LocalPortEdit.Text + '"');
    S.Add('#BypassUID, PublicKey, PrivateKey, EncryptMethod (aes-128-gcm, aes-256-gcm)');
    S.Add('encrypt_method="' + MethodComboBox.Text + '"');
    S.Add('ck_uid="$(ck-server -u)"');
    S.Add('keys="$(ck-server -k)"');
    S.Add('public_key="$(echo $keys | cut -f1 -d",")"');
    S.Add('private_key="$(echo $keys | cut -f2 -d",")"');
    S.Add('password="$(ssservice genkey --encrypt-method $encrypt_method)"');
    S.Add('');

    S.Add('#---CLIENT---');
    S.Add('echo "\');
    S.Add('{');
    S.Add('    \"server\": \"$server_ip\",');
    S.Add('    \"server_port\": $server_port,');
    S.Add('    \"local_address\": \"127.0.0.1\",');
    S.Add('    \"local_port\": $local_client_port,');
    S.Add('    \"method\": \"$encrypt_method\",');
    S.Add('    \"password\": \"$password\",');
    S.Add('    \"timeout\": 60,');
    S.Add('    \"nameserver\": \"$nameserver\",');
    S.Add('    \"plugin\": \"ck-client\",');
    S.Add('    \"plugin_opts\": \"Transport=direct;ProxyMethod=shadowsocks;EncryptionMethod=$encrypt_method;UID=$ck_uid;PublicKey=$public_key;ServerName=$redirect_url;BrowserSig=$browser;NumConn=4;StreamTimeout=300\"');
    S.Add('}');
    S.Add('">~/.config/ss-cloak-client/config.json');
    S.Add('');

    S.Add('#---SERVER---');
    S.Add('mkdir -p ~/.config/ss-cloak-client/etc/ss-cloak-server');
    S.Add('echo "\');
    S.Add('{');
    S.Add('    \"server\": \"127.0.0.1\",');
    S.Add('    \"server_port\": 50346,');
    S.Add('    \"password\": \"$password\",');
    S.Add('    \"timeout\": 60,');
    S.Add('    \"method\": \"$encrypt_method\",');
    S.Add('    \"dns\": \"$nameserver\",');
    S.Add('    \"plugin\": \"ck-server\",');
    S.Add('    \"plugin_opts\": \"/etc/ss-cloak-server/ckserver.json\"');
    S.Add('}">~/.config/ss-cloak-client/etc/ss-cloak-server/config.json');
    S.Add('');

    S.Add('echo "\');
    S.Add('{');
    S.Add('  \"ProxyBook\": {');
    S.Add('    \"shadowsocks\": [\"tcp\",\"127.0.0.1:50346\"]');
    S.Add('  },');
    S.Add('  \"BypassUID\": [');
    S.Add('    \"$ck_uid\"');
    S.Add('  ],');
    S.Add('  \"BindAddr\": [\":$server_port\"],');
    S.Add('  \"RedirAddr\": \"$redirect_url\",');
    S.Add('  \"PrivateKey\": \"$private_key\",');
    S.Add('  \"StreamTimeout\": 300');
    S.Add('}">~/.config/ss-cloak-client/etc/ss-cloak-server/ckserver.json');
    S.Add('');

    S.Add('cd ~/.config/ss-cloak-client');
    S.Add('tar czf server-conf.tar.gz ./etc');

    S.SaveToFile(GetUserDir + '.config/ss-cloak-client/config-gen.sh');

    //Generate client/server configs
    GenProcess.Execute;

    //Upload Server Configs archive
    ServerConfigs.Click;
  finally
    S.Free;
    INI.Free;
  end;
end;

//Save Server Configs
procedure TMainForm.ServerConfigsClick(Sender: TObject);
begin
  if not FileExists(GetUserDir + '.config/ss-cloak-client/server-conf.tar.gz') then Exit;

  if (SaveDialog1.Execute) then
    CopyFile(GetUserDir + '.config/ss-cloak-client/server-conf.tar.gz',
      SaveDialog1.FileName, [cffOverwriteFile]);
end;

end.
