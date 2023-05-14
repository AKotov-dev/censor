program censor;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX}
  cthreads,
           {$ENDIF}
  Interfaces,
  Forms,
  Unit1, start_trd,
  SysUtils,
  Dialogs,
  Classes { you can add units after this };

{$R *.res}

begin
  if GetEnvironmentVariable('USER') <> 'root' then
  begin
    MessageDlg(SRootRequires, mtWarning, [mbOK], 0);
    Halt;
  end;

  RequireDerivedFormResource := True;
  Application.Title:='Сensor v0.7';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
