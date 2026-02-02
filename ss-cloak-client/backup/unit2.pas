unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, FileUtil, ExtCtrls,
  AsyncProcess;

type

  { TQRForm }

  TQRForm = class(TForm)
    GetQR: TAsyncProcess;
    Image1: TImage;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  QRForm: TQRForm;

implementation

{$R *.lfm}

{ TQRForm }

procedure TQRForm.FormShow(Sender: TObject);
begin
  Image1.Picture := nil;

  //Получаем текст URL
  GetQR.Parameters.Clear;
  GetQR.Parameters.Add('-c');
  GetQR.Parameters.Add(
    'qrencode "$(ssurl --encode <(jq ' + '''' + 'del(.acl)' + '''' +
    ' ~/.config/ss-cloak-client/config.json)" -o ~/.config/ss-cloak-client/qr.xpm --margin=4 --type=XPM');

  //Получаем картинку
  GetQR.Execute;

  //Выводим картинку
  if FileExists(GetUserDir + '.config/ss-cloak-client/qr.xpm') then
    Image1.Picture.LoadFromFile(GetUserDir + '.config/ss-cloak-client/qr.xpm');
end;

procedure TQRForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  DeleteFile(GetUserDir + '.config/ss-cloak-client/qr.xpm');
end;

end.
