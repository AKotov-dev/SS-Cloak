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
    SWPBox: TCheckBox;
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
    procedure SWPBoxChange(Sender: TObject);
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
    procedure CreateSWProxy;
    procedure CreateGostHTTP;

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

//Create ~/config/ss-cloak-client/swproxy.sh
procedure TMainForm.CreateSWProxy;
var
  S: ansistring;
  A: TStringList;
begin
  try
    A := TStringList.Create;
    A.Add('#!/bin/bash');
    A.Add('');
    A.Add('if [[ "$1" == "set" ]]; then');
    A.Add('  echo "set proxy..."');
    A.Add('');
    A.Add('  # GNOME / GTK-based');
    A.Add('  if [[ "$XDG_CURRENT_DESKTOP" =~ GNOME|Budgie|Cinnamon|MATE|XFCE|LXDE ]]; then');
    A.Add('    gsettings set org.gnome.system.proxy mode manual');
    A.Add('    gsettings set org.gnome.system.proxy.http  host "127.0.0.1"');
    A.Add('    gsettings set org.gnome.system.proxy.http  port 8889');
    A.Add('    gsettings set org.gnome.system.proxy.https host "127.0.0.1"');
    A.Add('    gsettings set org.gnome.system.proxy.https port 8889');
    A.Add('    gsettings set org.gnome.system.proxy.ftp   host "127.0.0.1"');
    A.Add('    gsettings set org.gnome.system.proxy.ftp   port 8889');
    A.Add('    gsettings set org.gnome.system.proxy.socks host "127.0.0.1"');
    A.Add('    gsettings set org.gnome.system.proxy.socks port ' + LocalPortEdit.Text);
    A.Add('    gsettings set org.gnome.system.proxy ignore-hosts "[' +
      '''' + 'localhost' + '''' + ', ' + '''' + '127.0.0.1' + '''' +
      ', ' + '''' + '::1' + '''' + ']"');
    A.Add('  fi');
    A.Add('');
    A.Add('  # KDE Plasma');
    A.Add('  if [[ "$XDG_CURRENT_DESKTOP" == KDE ]]; then');
    A.Add('    if command -v kwriteconfig5 >/dev/null; then');
    A.Add('      v=5');
    A.Add('    elif command -v kwriteconfig6 >/dev/null; then');
    A.Add('      v=6');
    A.Add('    else');
    A.Add('      echo "No kwriteconfig found"');
    A.Add('      exit 1');
    A.Add('  fi');
    A.Add('');
    A.Add('    kwriteconfig$v --file kioslaverc --group "Proxy Settings" --key ProxyType 1');
    A.Add('    kwriteconfig$v --file kioslaverc --group "Proxy Settings" --key httpProxy  "http://127.0.0.1:8889"');
    A.Add('    kwriteconfig$v --file kioslaverc --group "Proxy Settings" --key httpsProxy "http://127.0.0.1:8889"');
    A.Add('    kwriteconfig$v --file kioslaverc --group "Proxy Settings" --key ftpProxy   "http://127.0.0.1:8889"');
    A.Add('    kwriteconfig$v --file kioslaverc --group "Proxy Settings" --key socksProxy "socks5h://127.0.0.1:' + LocalPortEdit.Text + '"');
    A.Add('    kwriteconfig$v --file kioslaverc --group "Proxy Settings" --key NoProxy    "['
      + '''' + 'localhost' + '''' + ', ' + '''' + '127.0.0.1' + '''' +
      ', ' + '''' + '::1' + '''' + ']"');
    A.Add('  fi');
    A.Add('else');
    A.Add('  echo "unset proxy..."');
    A.Add('');
    A.Add('  # GNOME / GTK-based');
    A.Add('  if [[ "$XDG_CURRENT_DESKTOP" =~ GNOME|Budgie|Cinnamon|MATE|XFCE|LXDE ]]; then');
    A.Add('    gsettings set org.gnome.system.proxy mode none');
    A.Add('  fi');
    A.Add('');
    A.Add('  # KDE Plasma');
    A.Add('  if [[ "$XDG_CURRENT_DESKTOP" == KDE ]]; then');
    A.Add('    if command -v kwriteconfig5 >/dev/null; then');
    A.Add('      v=5');
    A.Add('    elif command -v kwriteconfig6 >/dev/null; then');
    A.Add('      v=6');
    A.Add('    else');
    A.Add('      echo "No kwriteconfig found"');
    A.Add('      exit 1');
    A.Add('    fi');
    A.Add('');
    A.Add('    kwriteconfig$v --file kioslaverc --group "Proxy Settings" --key ProxyType 0');
    A.Add('  fi');
    A.Add('fi');
    A.Add('');

    A.SaveToFile(GetUserDir + '.config/ss-cloak-client/swproxy.sh');
    RunCommand('/bin/bash', ['-c', 'chmod +x ~/.config/ss-cloak-client/swproxy.sh'], S);
  finally
    A.Free;
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

    //Запрещаем утечку DNS
    //    S.Add('127.0.0.1');
    //    S.Add('localhost');
    //    S.Add('::1');

    S.Add(Trim(BypassBox.Text));

    S.SaveToFile(GetUserDir + '.config/ss-cloak-client/bypass.acl');

  finally
    S.Free;
  end;
end;

//Создаём файл ~/.config/ss-cloak-client/gost.conf (HTTP:8889)
procedure TMainForm.CreateGostHTTP;
var
  S: TStringList;
begin
  try
    S := TStringList.Create;

    S.Add('{');
    S.Add('      "Debug": false,');
    S.Add('      "Retries": 0,');
    S.Add('      "ServeNodes": [');
    S.Add('        "http://127.0.0.1:8889"');
    S.Add('      ],');
    S.Add('      "ChainNodes": [');
    S.Add('        "socks5://127.0.0.1:' + LocalPortEdit.Text + '"');
    S.Add('      ]');
    S.Add('}');

    S.SaveToFile(GetUserDir + '.config/ss-cloak-client/gost.conf');

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
  //От частого нажатия
  //Application.ProcessMessages;

  //Если прокси включен и менялся порт
  if SWPBox.Checked then
  begin
    //Делаем скрипт звпуска ~/.config/xraygui/swproxy.sh
    CreateSWProxy;
    //Запуск System-Wide Proxy если он уже работает
    RunCommand('/bin/bash', ['-c', '~/.config/ss-cloak-client/swproxy.sh set'], S);
  end;

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

  //Пересоздаём ~/.config/ss-cloak-client/bypass.acl
  CreateBypass;

  //Пересоздаём ~/.config/ss-cloak-client/gost.conf
  CreateGostHTTP;

  //Быстрая очистка вывода перед стартом
  LogMemo.Clear;

  //Перезапускаем сервисы SS:XXXX и HTTP:8889
  StartProcess('systemctl --user restart ss-cloak-client.service gost.service');
end;

//Стоп
procedure TMainForm.StopBtnClick(Sender: TObject);
var
  S: string;
begin
  //Application.ProcessMessages;

  StartProcess('systemctl --user stop ss-cloak-client.service gost.service');

  //Сброс System-Wide Proxy если он включен
  if FileExists(GetUserDir + '.config/ss-cloak-client/swproxy.sh') then
    RunCommand('/bin/bash', ['-c', '~/.config/ss-cloak-client/swproxy.sh reset'], S);
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
  begin
    //Иначе блокируем запуск и ждём создания конфигурации клиента
    StartBtn.Enabled := False;
    AutoStartBox.Checked := False;
    SWPBox.Checked := False;
    AutoStartBox.Enabled := False;
    SWPBox.Enabled := False;
  end;

  // bypass.acl
  config := GetUserDir + '.config/ss-cloak-client/bypass.acl';
  if FileExists(config) then
  begin
    if RunCommand('grep', ['^\.', config], S) then
      BypassBox.Text := Trim(S);
  end;

  //SWP ?
  if FileExists(GetUserDir + '.config/ss-cloak-client/swproxy.sh') then
    SWPBox.Checked := True
  else
    SWPBox.Checked := False;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  IniPropStorage1.Save;
end;

//Автостарт (ss-cloak-client/gost)
procedure TMainForm.AutoStartBoxChange(Sender: TObject);
var
  S: ansistring;
begin
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;

  if not AutoStartBox.Checked then
  begin
    SWPBox.Checked := False;
    RunCommand('/bin/bash', ['-c',
      'systemctl --user disable ss-cloak-client.service gost.service'], S);
  end
  else
    RunCommand('/bin/bash', ['-c',
      'systemctl --user enable ss-cloak-client.service gost.service'], S);
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

//SWP (включение/отключение системного прокси)
procedure TMainForm.SWPBoxChange(Sender: TObject);
var
  S: ansistring;
begin
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;

  if (not SWPBox.Checked) and FileExists(GetUserDir +
    '.config/ss-cloak-client/swproxy.sh') then
  begin
    RunCommand('/bin/bash', ['-c', '~/.config/ss-cloak-client/swproxy.sh unset'], S);
    DeleteFile(GetUserDir + '.config/ss-cloak-client/swproxy.sh');
  end
  else
  begin
    //Автозапуск самого прокси, поскольку при перезагрузке прокси будет недоступен
    AutoStartBox.Checked := True;
    //Делаем скрипт звпуска ~/.config/xraygui/swproxy.sh
    CreateSWProxy;
    //Запуск System-Wide Proxy если он уже работает
    if Shape1.Brush.Color <> clYellow then
      RunCommand('/bin/bash', ['-c', '~/.config/ss-cloak-client/swproxy.sh set'], S);
  end;
  Screen.Cursor := crDefault;
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

//Save Settings + конфигуратор конфигов
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

    //Присвоение переменных
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
    S.Add('    \"mode\": \"tcp_and_udp\",');
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
    S.Add('    \"mode\": \"tcp_and_udp\",');
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

    //Если конфиг клиента успешно создан - разрешить старт и переключатели Autostart/SWP
    if FileExists(GetUserDir + '.config/ss-cloak-client/config.json') then
    begin
      StartBtn.Enabled := True;
      AutoStartBox.Enabled := True;
      SWPBox.Enabled := True;
    end;
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
