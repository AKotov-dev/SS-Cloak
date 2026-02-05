unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, StrUtils,
  Buttons, IniPropStorage, FileUtil, ExtCtrls, Process, DefaultTranslator;

type

  { TMainForm }

  TMainForm = class(TForm)
    CamouflageEdit: TComboBox;
    BypassBox: TComboBox;
    Image1: TImage;
    Label7: TLabel;
    Label8: TLabel;
    StatusLabel: TLabel;
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
    procedure CreateSWProxy;
    procedure CreateGostHTTP;

  private
    LastStart, LastStop: QWord; //Debounce

  public

  end;

var
  MainForm: TMainForm;

resourcestring
  SGenerateConf =
    'Based on the entered data, a configuration link will be created for the Client (overwrite) and Server (downloadable archive for your VPS). Continue?';

  SSecStatusOn = 'Enabled';
  SSecStatusOff = 'Disabled';

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

//Старт
procedure TMainForm.StartBtnClick(Sender: TObject);
var
  JSONFile, Cmd, S: string;
begin
  //От частого нажатия
  Application.ProcessMessages;

  //Проверяем, прошло ли более 1000 мс с последнего нажатия (Debounce)
  if GetTickCount64 - LastStart < 2000 then Exit;

  //Останавливаем ssclient и gost
  StartProcess('systemctl --user stop ss-cloak-client.service gost.service');

  //Быстрая очистка вывода перед стартом
  LogMemo.Clear;

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
    //acl_home_user_path (для переноса на другие компы)
    Cmd := Format('sed -i ''s/"acl": *"[^"]*"/"acl": "%s"/'' "%s"',
      [GetUserDir + '.config/ss-cloak-client/bypass.acl', JSONFile]);
    RunCommand('bash', ['-c', Cmd], S);

    //камуфляж
    Cmd := Format('sed -i ''s/ServerName=[^;]*/ServerName=%s/'' "%s"',
      [CamouflageEdit.Text, JSONFile]);
    RunCommand('bash', ['-c', Cmd], S);
  end
  else
    Exit;

  //Делаем скрипт звпуска ~/.config/xraygui/swproxy.sh
  CreateSWProxy;
  //Запуск System-Wide Proxy если он уже работает
  RunCommand('/bin/bash', ['-c', '~/.config/ss-cloak-client/swproxy.sh set'], S);

  //Пересоздаём ~/.config/ss-cloak-client/bypass.acl
  CreateBypass;

  //Пересоздаём ~/.config/ss-cloak-client/gost.conf
  CreateGostHTTP;

  //Запускаем сервисы SS:XXXX и HTTP:8889
  StartProcess('systemctl --user start ss-cloak-client.service gost.service');

  //Активация System-Wide Proxy
  RunCommand('/bin/bash', ['-c', '~/.config/ss-cloak-client/swproxy.sh set'], S);

  //Включение Автозагрузки
  RunCommand('/bin/bash', ['-c',
    'systemctl --user enable ss-cloak-client.service gost.service'], S);

  LastStart := GetTickCount64;
end;

//Стоп
procedure TMainForm.StopBtnClick(Sender: TObject);
var
  S: string;
begin
  Application.ProcessMessages;

  // Проверяем, прошло ли более 1000 мс с последнего нажатия (Debounce)
  if GetTickCount64 - LastStop < 1000 then Exit;

  StartProcess('systemctl --user stop ss-cloak-client.service gost.service');

  //Сброс System-Wide Proxy
  RunCommand('/bin/bash', ['-c', '~/.config/ss-cloak-client/swproxy.sh reset'], S);

  //Отключение из автозагрузки
  RunCommand('/bin/bash', ['-c',
    'systemctl --user disable ss-cloak-client.service gost.service'], S);

  LastStop := GetTickCount64;
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

  //Конфигурация формы
  IniPropStorage1.IniFileName :=
    GetUserDir + '.config/ss-cloak-client/ss-cloak-client.conf';
  IniPropStorage1.Active := True;

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

  QRBtn.Width := QRBtn.Height;

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
    S.Add('    \"timeout\": 150,');
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
    S.Add('    \"timeout\": 300,');
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

    //Если конфиг клиента успешно создан - разрешить старт и переключатель Autostart
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
