program censor;

{$mode objfpc}{$H+}

uses
 {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads,   {$ENDIF}   {$ENDIF}
  Interfaces,
  Forms,
  Unit1,
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
  Application.Title:='Сensor v0.3';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
