unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, StrUtils,
  Buttons, IniPropStorage, FileUtil, ExtCtrls, Process, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    AutoStartBox: TCheckBox;
    CamouflageEdit: TComboBox;
    BypassBox: TComboBox;
    CheckBox1: TCheckBox;
    Image1: TImage;
    Label7: TLabel;
    MethodComboBox: TComboBox;
    DNSComboBox: TComboBox;
    Label5: TLabel;
    Label6: TLabel;
    GenProcess: TProcess;
    SaveDialog1: TSaveDialog;
    QRBtn: TSpeedButton;
    SaveDialog2: TSaveDialog;
    ServerEdit: TEdit;
    ServerPortEdit: TEdit;
    LocalPortEdit: TEdit;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    LogMemo: TMemo;
    Shape1: TShape;
    CreateBtn: TSpeedButton;
    ServerConfigs: TSpeedButton;
    BackupBtn: TSpeedButton;
    StartBtn: TSpeedButton;
    StaticText1: TStaticText;
    StopBtn: TSpeedButton;
    procedure AutoStartBoxChange(Sender: TObject);
    procedure BackupBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure QRBtnClick(Sender: TObject);
    procedure CreateBtnClick(Sender: TObject);
    procedure ServerConfigsClick(Sender: TObject);
    procedure StartBtnClick(Sender: TObject);
    procedure StopBtnClick(Sender: TObject);
    procedure StartProcess(command: string);
    procedure CreateBypass;

  private

  public

  end;

var
  MainForm: TMainForm;

resourcestring
  SGenerateConf =
    'Based on the entered data, a configuration link will be created for the Client (overwrite) and Server (downloadable archive for your VPS). Continue?';

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

//Создаём файл ~/.config/ss-cloak-client/bypass.acl
procedure TMainForm.CreateBypass;
var
  S: TStringList;
begin
  try
    S := TStringList.Create;

    S.Add('[proxy_all]');
    S.Add('[bypass_list]');
    S.Add('127.0.0.1');
    S.Add('localhost');
    S.Add('::1');
    S.Add(Trim(BypassBox.Text));

    S.SaveToFile(GetUserDir + '.config/ss-cloak-client/bypass.acl');

  finally
    S.Free;
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
  RunCommand('bash', ['-c',
    '[[ -n $(systemctl --user is-enabled ss-cloak-client | grep "enabled") ]] && echo "yes"'],
    S);

  if Trim(S) = 'yes' then
    Result := True
  else
    Result := False;
end;

//Start
procedure TMainForm.StartBtnClick(Sender: TObject);
var
  JSONFile, Cmd, S: string;
begin
  //Редактируем клиентский конфиг (если что-то менялось)
  JSONFile := GetUserDir + '.config/ss-cloak-client/config.json';

  // Если файл существует - пишем новые настройки из полей
  if FileExists(JSONFile) then
  begin
    // меняем server
    Cmd := Format('sed -i ''s/"server": *"[^"]*"/"server": "%s"/'' "%s"',
      [ServerEdit.Text, JSONFile]);
    RunCommand('bash', ['-c', Cmd], S);
    //server_port
    Cmd := Format('sed -i ''s/"server_port": *[0-9]*/"server_port": %s/'' "%s"',
      [ServerPortEdit.Text, JSONFile]);
    RunCommand('bash', ['-c', Cmd], S);
    //local_port
    Cmd := Format('sed -i ''s/"local_port": *[0-9]*/"local_port": %s/'' "%s"',
      [LocalPortEdit.Text, JSONFile]);
    RunCommand('bash', ['-c', Cmd], S);
    //method
    Cmd := Format('sed -i ''s/"method": *"[^"]*"/"method": "%s"/'' "%s"',
      [MethodComboBox.Text, JSONFile]);
    RunCommand('bash', ['-c', Cmd], S);
    //nameserver
    Cmd := Format('sed -i ''s/"nameserver": *"[^"]*"/"nameserver": "%s"/'' "%s"',
      [DNSComboBox.Text, JSONFile]);
    RunCommand('bash', ['-c', Cmd], S);

    //камуфляж
    Cmd := Format('sed -i ''s/ServerName=[^;]*/ServerName=%s/'' "%s"',
      [CamouflageEdit.Text, JSONFile]);
    RunCommand('bash', ['-c', Cmd], S);
  end
  else
    Exit;

  //Создаём/обновляем ~/.config/ss-cloak-client/bypass.acl
  CreateBypass;

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
  S, config: string;
  bmp: TBitmap;
begin
  // Устраняем баг иконки приложения
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf32bit;
    bmp.Assign(Image1.Picture.Graphic);
    Application.Icon.Assign(bmp);
  finally
    bmp.Free;
  end;

  MainForm.Caption := Application.Title;

  //Создаём каталоги настроек
  if not DirectoryExists(GetUserDir + '.config') then MkDir(GetUserDir + '.config');
  if not DirectoryExists(GetUserDir + '.config/ss-cloak-client') then
    MkDir(GetUserDir + '.config/ss-cloak-client');

  // Если конфигурация клиента существует - читаем настройки в поля
  config := GetUserDir + '.config/ss-cloak-client/config.json';

  if FileExists(config) then
  begin
    // server
    if RunCommand('sed', ['-n',
      's/.*"server"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p', config], S) then
      ServerEdit.Text := Trim(S);

    // server_port
    if RunCommand('sed', ['-n',
      's/.*"server_port"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p', config], S) then
      ServerPortEdit.Text := Trim(S);

    // local_port
    if RunCommand('sed', ['-n',
      's/.*"local_port"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p', config], S) then
      LocalPortEdit.Text := Trim(S);

    // method
    if RunCommand('sed', ['-n',
      's/.*"method"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p', config], S) then
      MethodComboBox.Text := Trim(S);

    // nameserver
    if RunCommand('sed', ['-n',
      's/.*"nameserver"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p', config], S) then
      DNSComboBox.Text := Trim(S);

    // ServerName (plugin_opts)
    if RunCommand('sed', ['-n', 's/.*ServerName=\([^;]*\).*/\1/p', config], S) then
      CamouflageEdit.Text := Trim(S);
  end
  else
    //Иначе блокируем запуск и ждём создания конфигурации клиента
    StartBtn.Enabled := False;

  // bypass.acl
  config := GetUserDir + '.config/ss-cloak-client/bypass.acl';
  if FileExists(config) then
  begin
    if RunCommand('grep', ['^\.', config], S) then
      BypassBox.Text := Trim(S);
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

procedure TMainForm.BackupBtnClick(Sender: TObject);
begin
  if not FileExists(GetUserDir + '.config/ss-cloak-client/config.json') then Exit;

  if (SaveDialog2.Execute) then
  begin
    if not AnsiEndsText('.json', SaveDialog2.FileName) then
    begin
      if SameText(ExtractFileExt(SaveDialog2.FileName), '.json') then
        SaveDialog2.FileName := ChangeFileExt(SaveDialog2.FileName, '.json')
      else
        SaveDialog2.FileName := SaveDialog2.FileName + '.json';
    end;

    CopyFile(GetUserDir + '.config/ss-cloak-client/config.json',
      SaveDialog2.FileName, [cffOverwriteFile]);
  end;
end;

//MainForm, запуск потоков
procedure TMainForm.FormShow(Sender: TObject);
var
  FShowLogTRD, FPortScanThread: TThread;
begin
  IniPropStorage1.Restore;

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
procedure TMainForm.CreateBtnClick(Sender: TObject);
var
  S: TStringList;
begin
  if MessageDlg(SGenerateConf, mtWarning, [mbYes, mbCancel], 0) <> mrYes then  Exit;

  try
    //Stop Client
    StopBtn.Click;

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
    S.Add('    \"acl\": \"' + GetUserDir + '.config/ss-cloak-client/bypass.acl' + '\",');
    S.Add('    \"plugin\": \"ck-client\",');
    S.Add('    \"plugin_opts\": \"Transport=direct;ProxyMethod=shadowsocks;EncryptionMethod=$encrypt_method;UID=$ck_uid;PublicKey=$public_key;ServerName=$redirect_url;BrowserSig=$browser;NumConn=6;StreamTimeout=300\"');
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

    //Если конфиг клиента успешно создан - разрешить старт
    if FileExists(GetUserDir + '.config/ss-cloak-client/config.json') then
      StartBtn.Enabled := True;
  finally
    S.Free;
  end;
end;

//Save Server Configs
procedure TMainForm.ServerConfigsClick(Sender: TObject);
begin
  if not FileExists(GetUserDir + '.config/ss-cloak-client/server-conf.tar.gz') then Exit;

  if (SaveDialog1.Execute) then
  begin
    if not AnsiEndsText('.tar.gz', SaveDialog1.FileName) then
    begin
      if SameText(ExtractFileExt(SaveDialog1.FileName), '.gz') then
        SaveDialog1.FileName := ChangeFileExt(SaveDialog1.FileName, '.tar.gz')
      else
        SaveDialog1.FileName := SaveDialog1.FileName + '.tar.gz';
    end;

    CopyFile(GetUserDir + '.config/ss-cloak-client/server-conf.tar.gz',
      SaveDialog1.FileName, [cffOverwriteFile]);
  end;
end;

end.
