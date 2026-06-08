unit QRUnit;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, FileUtil, ExtCtrls,
  ubarcodes, Process;

type

  { TQRForm }

  TQRForm = class(TForm)
    BarcodeQR1: TBarcodeQR;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  QRForm: TQRForm;

implementation

uses Unit1;

  {$R *.lfm}

  { TQRForm }

procedure TQRForm.FormShow(Sender: TObject);
var
  S: string;
begin
  //Квадрат
  QRForm.Width := QRForm.Height;

  //В центр
  QRForm.Left := MainForm.Left + MainForm.Width div 2 - QRForm.Width div 2;
  QRForm.Top := MainForm.Top + MainForm.Height div 2 - QRForm.Height div 2;

  // RunCommand('bash', ['-c', 'ssurl --encode ~/.config/ss-cloak-client/config.json'], S);

  RunCommand('ssurl', ['--encode', GetUserDir + '.config/ss-cloak-client/config.json'],
    s, [powaitonexit]);

  BarcodeQR1.Text := Trim(S);

 { Image1.Picture := nil;

  //Получаем текст URL
  GetQR.Parameters.Clear;
  GetQR.Parameters.Add('-c');
  GetQR.Parameters.Add(
    'qrencode "$(ssurl --encode ~/.config/ss-cloak-client/config.json)" -o ~/.config/ss-cloak-client/qr.xpm --margin=4 --type=XPM');

  //Получаем картинку
  GetQR.Execute;

  //Выводим картинку
  if FileExists(GetUserDir + '.config/ss-cloak-client/qr.xpm') then
    Image1.Picture.LoadFromFile(GetUserDir + '.config/ss-cloak-client/qr.xpm');}

end;

procedure TQRForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
 // DeleteFile(GetUserDir + '.config/ss-cloak-client/qr.xpm');
end;

end.
