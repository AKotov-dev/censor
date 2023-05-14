unit start_trd;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils, ComCtrls, Forms;

type
  StartScript = class(TThread)
  private

    { Private declarations }
  protected
  var
    Result: TStringList;

    procedure Execute; override;

    procedure StartProgress;
    procedure StopProgress;

  end;

implementation

uses Unit1;

{ TRD }

procedure StartScript.Execute;
var
  ExProcess: TProcess;
begin
  try //Вывод лога и прогресса
    Synchronize(@StartProgress);

    FreeOnTerminate := True; //Уничтожить по завершении
    Result := TStringList.Create;

    ExProcess := TProcess.Create(nil);

    ExProcess.Executable := 'bash';
    ExProcess.Options := [poWaitOnExit];
    ExProcess.Parameters.Add('-c');

    ExProcess.Parameters.Add(
      'chmod +x /usr/local/bin/censor.sh; /usr/local/bin/censor.sh');

    ExProcess.Execute;

  finally
    Synchronize(@StopProgress);
    Result.Free;
    ExProcess.Free;
    Terminate;
  end;
end;

{ БЛОК ОТОБРАЖЕНИЯ ЛОГА }

//Старт
procedure StartScript.StartProgress;
begin
  with MainForm do
  begin
    ProgressBar1.Style := pbstMarquee;
    ProgressBar1.Refresh;
    ApplyBtn.Enabled := False;
  end;
end;

//Стоп
procedure StartScript.StopProgress;
begin
  with MainForm do
  begin
    ProgressBar1.Style := pbstNormal;
    ProgressBar1.Refresh;
    ApplyBtn.Enabled := True;
  end;
end;

end.
