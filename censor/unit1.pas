unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Buttons, Menus, XMLPropStorage,
  ComCtrls, Process, EditBtn, DefaultTranslator, LCLTranslator, LCLType;

type

  { TMainForm }

  TMainForm = class(TForm)
    DictionaryCheck: TCheckBox;
    ImageList1: TImageList;
    EditItem: TMenuItem;
    ProgressBar1: TProgressBar;
    Separator2: TMenuItem;
    SortItem: TMenuItem;
    Separator1: TMenuItem;
    LoadBtn: TSpeedButton;
    SaveBtn: TSpeedButton;
    SortBtn: TSpeedButton;
    SelectAll: TSpeedButton;
    AddBtn: TSpeedButton;
    DeleteBtn: TSpeedButton;
    EditBtn: TSpeedButton;
    ApplyBtn: TBitBtn;
    GroupBox3: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    OnlyWebCheck: TCheckBox;
    OpenDialog1: TOpenDialog;
    ResetBtn: TBitBtn;
    SaveDialog1: TSaveDialog;
    StartTime: TTimeEdit;
    StaticText1: TStaticText;
    StopTime: TTimeEdit;
    TuesdayCheck: TCheckBox;
    WednesdayCheck: TCheckBox;
    ThursdayCheck: TCheckBox;
    FridayCheck: TCheckBox;
    SaturdayCheck: TCheckBox;
    SundayCheck: TCheckBox;
    MondayCheck: TCheckBox;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    ListBox1: TListBox;
    AddItem: TMenuItem;
    RemoveItem: TMenuItem;
    LoadFromFileItem: TMenuItem;
    SaveToFileItem: TMenuItem;
    N2: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    PopupMenu1: TPopupMenu;
    Splitter1: TSplitter;
    MainFormStorage: TXMLPropStorage;
    procedure AddItemClick(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure ListBox1DrawItem(Control: TWinControl; Index: integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure EditItemClick(Sender: TObject);
    procedure SelectAllClick(Sender: TObject);
    procedure SortItemClick(Sender: TObject);
    procedure ApplyBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LoadFromFileItemClick(Sender: TObject);
    procedure MondayCheckChange(Sender: TObject);
    procedure RemoveItemClick(Sender: TObject);
    procedure ResetBtnClick(Sender: TObject);
    procedure SaveToFileItemClick(Sender: TObject);
    procedure DaysCheck;
    procedure StartProcess(command, opt: string);
    procedure CreateServices;
    procedure CreateCrontab;
    procedure ResetCheck;

  private

  public

  end;

//Ресурсы перевода
resourcestring
  SDeleteConfiguration = 'Remove selected from list?';
  SAppendRecord = 'Append a website';
  SRootRequires = 'Requires a root environment!';
  STimeWrong = 'Wrong time range!';
  SEditRecord = 'Editing an entry:';
  SRecordExists = 'The record already exists!';
  SEdit = 'Edit';

var
  MainForm: TMainForm;

implementation

uses start_trd;

{$R *.lfm}

{ TMainForm }


//Общая процедура запуска команд
procedure TMainForm.StartProcess(command, opt: string);
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add(command);

    if opt = 'wait' then
      ExProcess.Options := [poWaitOnExit];

    ExProcess.Execute;
  finally
    ExProcess.Free;
  end;
end;

//Состояние кнопки Reset
procedure TMainForm.ResetCheck;
begin
  //Проверка созданных файлов
  if FileExists('/etc/systemd/system/censor.service') or
    FileExists('/var/spool/cron/root') or
    FileExists('/var/spool/cron/crontabs/root') then
    ResetBtn.Enabled := True
  else
    ResetBtn.Enabled := False;
end;

//Cоздаём сервис /etc/systemd/system/censor.service
procedure TMainForm.CreateServices;
var
  S: TStringList;
begin
  try
    S := TStringList.Create;

    //Если нет, создаём и активируем сервис /etc/systemd/system/censor.service
    //Перекрыть возможные правила от shorewall shorewall6 ufw firewalld
    if not FileExists('/etc/systemd/system/censor.service') then
    begin
      S.Add('[Unit]');
      S.Add('Description=Censor Unit');
      S.Add('After=network-online.target shorewall.service shorewall6.service ufw.service firewalld.service');
      S.Add('Wants=network-online.target');
      S.Add('');
      S.Add('[Service]');
      S.Add('Type=oneshot');
      S.Add('ExecStart=/usr/local/bin/censor.sh');
      S.Add('');
      S.Add('[Install]');
      S.Add('WantedBy=multi-user.target');
      S.SaveToFile('/etc/systemd/system/censor.service');

      StartProcess('systemctl enable censor.service', 'nowait');
    end;

    //Проверка состояния кнопки Reset
    ResetCheck;
  finally
    S.Free;
  end;
end;

//Создаём план Crontab и активируем
procedure TMainForm.CreateCrontab;
var
  Days: string;
  S: TStringList;
begin
  try
    //Строка дней блокировки
    if MondayCheck.Checked then
      Days := Days + '1,';
    if TuesdayCheck.Checked then
      Days := Days + '2,';
    if WednesdayCheck.Checked then
      Days := Days + '3,';
    if ThursdayCheck.Checked then
      Days := Days + '4,';
    if FridayCheck.Checked then
      Days := Days + '5,';
    if SaturdayCheck.Checked then
      Days := Days + '6,';
    if SundayCheck.Checked then
      Days := Days + '7,';

    //Убираем последнюю запятую
    Days := Copy(Days, 1, Length(Days) - 1);

    //Пишем /var/spool/cron/root
    S := TStringList.Create;
    S.Add('SHELL=/bin/bash');
    S.Add('PATH=/sbin:/bin:/usr/sbin:/usr/bin');
    S.Add('MAILTO=root');
    S.Add('HOME=/');
    S.Add('');
    S.Add('# Censor plan-' + DateToStr(Now));
    S.Add(Copy(StartTime.Text, 4, 2) + ' ' + Copy(StartTime.Text, 1, 2) +
      ' * ' + Days + ' * /usr/local/bin/censor.sh');
    S.Add(Copy(StopTime.Text, 4, 2) + ' ' + Copy(StopTime.Text, 1, 2) +
      ' * ' + Days + ' * /usr/local/bin/censor.sh');
    //Пустая строка в конце обязательна! Иначе Cron не понимает...
    S.Add('');

    //RedHat или Debian...
    if DirectoryExists('/var/spool/cron/crontabs') then
    begin
      S.SaveToFile('/var/spool/cron/crontabs/root');
      StartProcess('chmod 600 /var/spool/cron/crontabs/root', 'wait');
    end
    else
    begin
      S.SaveToFile('/var/spool/cron/root');
      StartProcess('chmod 600 /var/spool/cron/root', 'wait');
    end;

  finally
    S.Free;
  end;

  //Проверяем автозапуск crond (Mageia) или cron (Ubuntu) и перезапускаем с новым расписанием
  StartProcess('(systemctl enable crond.service && systemctl restart crond.service) || '
    + '(systemctl enable cron.service && systemctl restart cron.service)', 'nowait');
end;

//Состояние панели управления
procedure TMainForm.DaysCheck;
begin
  if (MondayCheck.Checked or TuesDayCheck.Checked or WednesDayCheck.Checked or
    ThursDayCheck.Checked or FridayCheck.Checked or SaturDayCheck.Checked or
    SunDayCheck.Checked) and (ListBox1.Count <> 0) then
    GroupBox3.Enabled := True
  else
    GroupBox3.Enabled := False;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  //Рабочая директория в профиле
  if not DirectoryExists('/root/.censor') then
    MkDir('/root/.censor');

  MainFormStorage.FileName := '/root/.censor/settings.ini';

  if FileExists('/root/.censor/blacklist') then
    ListBox1.Items.LoadFromFile('/root/.censor/blacklist');

  //Состояние кнопки Reset
  ResetCheck;
end;

//Загрузка черного списка
procedure TMainForm.LoadFromFileItemClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    ListBox1.Items.LoadFromFile(OpenDialog1.FileName);
    ListBox1.Items.SaveToFile('/root/.censor/blacklist');
    if ListBox1.Count <> 0 then ListBox1.ItemIndex := 0;

    //Состояние панели управления
    DaysCheck;
  end;
end;

procedure TMainForm.MondayCheckChange(Sender: TObject);
begin
  //Состояние панели управления
  DaysCheck;
end;

//Удаление записей
procedure TMainForm.RemoveItemClick(Sender: TObject);
var
  i: integer;
begin
  if ListBox1.SelCount <> 0 then
    if MessageDlg(SDeleteConfiguration, mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      //Удаление записей
      for i := -1 + ListBox1.Items.Count downto 0 do
        if ListBox1.Selected[i] then
          ListBox1.Items.Delete(i);

      //Курсор в начало
      if ListBox1.Count <> 0 then ListBox1.ItemIndex := 0;

      ListBox1.Items.SaveToFile('/root/.censor/blacklist');

      //Состояние панели управления
      DaysCheck;
    end;
end;

//Сброс
procedure TMainForm.ResetBtnClick(Sender: TObject);
begin
  //Прорисовываем Disable
  ResetBtn.Enabled := False;
  ApplyBtn.Enabled := False;
  Application.ProcessMessages;

  //Удаляем настройки планировщика (RedHat или Debian)
  if DirectoryExists('/var/spool/cron/crontabs') then
    DeleteFile('/var/spool/cron/crontabs/root')
  else
    DeleteFile('/var/spool/cron/root');

  //Убиваем зависший (?) host (цикл ipset в скрипте)
  StartProcess(
    'killall censor.sh; [[ $(systemctl list-units | grep "crond.service") ]] && ' +
    'systemctl restart crond.service || systemctl restart cron.service', 'nowait');

  //Удаляем сервис автозапуска, ipset_rules и скрипт правил iptables
  StartProcess('systemctl disable censor.service; ' +
    'rm -f /etc/systemd/system/censor.service /usr/local/bin/censor.sh /root/.censor/ipset_rules; '
    + 'systemctl daemon-reload', 'wait');

  //Возвращаем iptables/ip6tables в Default, удаляем blacklist(6)
  StartProcess(
    'iptables -F; iptables -X; iptables -t nat -F; iptables -t nat -X; ' +
    'iptables -t mangle -F; iptables -t mangle -X; ipset -X blacklist; ' +
    'ip6tables -F; ip6tables -X; ip6tables -t nat -F; ip6tables -t nat -X; ' +
    'ip6tables -t mangle -F; ip6tables -t mangle -X; ipset -X blacklist6; ' +
    'iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT; ' +
    'ip6tables -P INPUT ACCEPT; ip6tables -P OUTPUT ACCEPT; ip6tables -P FORWARD ACCEPT',
    'nowait');

  //Проверка состояния кнопки Reset
  ResetCheck;
  ApplyBtn.Enabled := True;
end;

//Сохранить список
procedure TMainForm.SaveToFileItemClick(Sender: TObject);
begin
  if ListBox1.Count <> 0 then
    if SaveDialog1.Execute then
      ListBox1.Items.SaveToFile(SaveDialog1.FileName);
end;

//Добавление в список
procedure TMainForm.AddItemClick(Sender: TObject);
var
  Value: string;
begin
  Value := '';
  repeat
    if not InputQuery(SAppendRecord, '', Value) then
      Exit;
  until Trim(Value) <> '';

  //Очистка от https:// и http://
  Value := StringReplace(Value, '/', '', [rfReplaceAll, rfIgnoreCase]);
  Value := StringReplace(Value, 'http:', '', [rfReplaceAll, rfIgnoreCase]);
  Value := StringReplace(Value, 'https:', '', [rfReplaceAll, rfIgnoreCase]);

  //Если существует - показать в списке, если нет - добавить
  if ListBox1.Items.IndexOf(Value) <> -1 then
  begin
    ListBox1.ItemIndex := ListBox1.Items.IndexOf(Value);
    Exit;
  end
  else
  begin
    ListBox1.Items.Append(Trim(Value));
    ListBox1.ItemIndex := ListBox1.Count - 1;
  end;

  ListBox1.Items.SaveToFile('/root/.censor/blacklist');

  //Состояние панели управления
  DaysCheck;
end;

//Опрос кнопок
procedure TMainForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  case Key of
    VK_F4: EditBtn.Click;
    VK_F8: DeleteBtn.Click;
    VK_INSERT: AddBtn.Click;
  end;

  //Отлуп после закрытия InputQery (окно модальное)
  Key := $0;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  //Для KDE
  MainFormStorage.Restore;

  MainForm.Caption := Application.Title;

  if ListBox1.Count > 0 then
    ListBox1.ItemIndex := 0;

  StartTime.Button.Width := StartTime.Button.Height;
  StopTime.Button.Width := StopTime.Button.Height;
end;

//Иконки списка
procedure TMainForm.ListBox1DrawItem(Control: TWinControl; Index: integer;
  ARect: TRect; State: TOwnerDrawState);
var
  BitMap: TBitMap;
begin
  try
    BitMap := TBitMap.Create;
    with ListBox1 do
    begin
      Canvas.FillRect(aRect);

      //Название (текст по центру-вертикали)
      Canvas.TextOut(aRect.Left + 30, aRect.Top + ItemHeight div 2 -
        Canvas.TextHeight('A') div 2 + 1, Items[Index]);

      //Иконка
      ImageList1.GetBitMap(0, BitMap);

      Canvas.Draw(aRect.Left + 2, aRect.Top + (ItemHeight - 24) div 2 + 2, BitMap);
    end;
  finally
    BitMap.Free;
  end;
end;

//Редактирование записи
procedure TMainForm.EditItemClick(Sender: TObject);
var
  S: string;
begin
  if ListBox1.SelCount <> 0 then
  begin
    S := ListBox1.Items.Strings[ListBox1.ItemIndex];
    if not InputQuery(SEdit, SEditRecord, S) or (Trim(S) = '') then
      Exit
    else
    //Если существует - предупредить
    if ListBox1.Items.IndexOf(S) <> -1 then
    begin
      MessageDlg(SRecordExists, mtWarning, [mbOK], 0);
      Exit;
    end
    else
    begin
      ListBox1.Items.Strings[ListBox1.ItemIndex] := S;
      ListBox1.Items.SaveToFile('/root/.censor/blacklist');
    end;
  end;
end;

//Выбрать все в списке
procedure TMainForm.SelectAllClick(Sender: TObject);
begin
  ListBox1.SelectAll;
end;

//Сортировка списка
procedure TMainForm.SortItemClick(Sender: TObject);
begin
  if ListBox1.Count <> 0 then
  begin
    ListBox1.Sorted := True;
    ListBox1.Items.SaveToFile('/root/.censor/blacklist');
    ListBox1.Items.LoadFromFile('/root/.censor/blacklist');
    ListBox1.Sorted := False;
    ListBox1.ItemIndex := 0;
  end;
end;

procedure TMainForm.ApplyBtnClick(Sender: TObject);
var
  i: integer;
  Days: string;
  S: TStringList;
  FStartScript: TThread;
begin
  //Проверяем наличие рабочей папки /usr/local/bin
  if not DirectoryExists('/usr/local/bin') then
    StartProcess('mkdir -p /usr/local/bin', 'wait');

  //Перечитываем время (валидность, если ввод был ручным)
  StartTime.Refresh;
  StopTime.Refresh;

  //Проверяем время Начала < Окончания блокировки
  if StartTime.Time >= StopTime.Time then
  begin
    MessageDlg(STimeWrong, mtWarning, [mbOK], 0);
    Exit;
  end;

  //Сохраняем настройки
  MainFormStorage.Save;

  try
    Days := '';
    S := TStringList.Create;

    S.Add('#!/bin/bash');
    S.Add('');

    S.Add('# Параметры -----//-----');
    S.Add('hstart="' + StartTime.Text + '"' +
      ' # Начало блокировки (час)');
    S.Add('hend="' + StopTime.Text + '"' +
      ' # Окончание блокировки (час)');
    S.Add('');

    S.Add('# Загрузка нужных модулей ядра');
    S.Add('modprobe ip_set; modprobe xt_string');
    S.Add('');

    S.Add('# Текущий день недели находится в списке блокировки?');
    if MondayCheck.Checked then
      Days := Days + ' 1';
    if TuesdayCheck.Checked then
      Days := Days + ' 2';
    if WednesdayCheck.Checked then
      Days := Days + ' 3';
    if ThursdayCheck.Checked then
      Days := Days + ' 4';
    if FridayCheck.Checked then
      Days := Days + ' 5';
    if SaturdayCheck.Checked then
      Days := Days + ' 6';
    if SundayCheck.Checked then
      Days := Days + ' 7';

    S.Add('block_day="no"; for i in' + Days +
      '; do [[ "$i" = "$(date +%u)" ]] && block_day="yes"; done');
    S.Add('');

    S.Add('# Очистка iptables/ip6tables');
    S.Add('iptables -F; iptables -X');
    S.Add('ip6tables -F; ip6tables -X');
    S.Add('iptables -t nat -F; iptables -t nat -X');
    S.Add('ip6tables -t nat -F; ip6tables -t nat -X');
    S.Add('iptables -t mangle -F; iptables -t mangle -X');
    S.Add('ip6tables -t mangle -F; ip6tables -t mangle -X');
    S.Add('');

    S.Add('# Разрешаем всё (iptables/ip6tables)');
    S.Add('iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT');
    S.Add('ip6tables -P INPUT ACCEPT; ip6tables -P OUTPUT ACCEPT; ip6tables -P FORWARD ACCEPT');
    S.Add('');

    { S.Add('# Разрешаем lo и уже установленные соединения (iptables/ip6tables)');
    S.Add('iptables -A OUTPUT -o lo -j ACCEPT');
    S.Add('ip6tables -A OUTPUT -o lo -j ACCEPT');
    S.Add('iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT');
    S.Add('ip6tables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT');
    S.Add('');

    S.Add('# Разрешаем пинг (iptables/ip6tables)');
    S.Add('iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT');
    S.Add('ip6tables -A OUTPUT -p icmpv6 --icmpv6-type echo-reply -j ACCEPT');
    S.Add('iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT');
    S.Add('ip6tables -A OUTPUT -p icmpv6 --icmpv6-type echo-request -j ACCEPT');
    S.Add('');

    S.Add('# Разрешаем DNS (iptables/ip6tables)');
    S.Add('iptables -A OUTPUT -p udp --dport domain -j ACCEPT');
    S.Add('ip6tables -A OUTPUT -p udp --dport domain -j ACCEPT');
    S.Add(''); }

    S.Add('# С XX:XX часов утра до NN:NN часов вечера пускать с ограничениями');
    S.Add('if [[ "$(date +%T)" > "$hstart" && "$(date +%T)" < "$hend" && "$block_day" = "yes" ]]; then');
    S.Add('');

    //Только Web-серфинг (блокировка VPN, Torrent, Jabber etc...)
    if OnlyWebCheck.Checked then
    begin
      S.Add('# Только Web-серфинг (блокировка VPN, Torrent Skype и т.д., http/https/dns разрешен)');
      S.Add('iptables -A OUTPUT -p tcp -m multiport ! --dports http,https -j REJECT');
      S.Add('ip6tables -A OUTPUT -p tcp -m multiport ! --dports http,https -j REJECT');
      S.Add('# Оставляем чистый DNS (udp)');
      S.Add('iptables -A OUTPUT -p udp ! --sport dns --dport 1024:65535 -j REJECT');
      S.Add('ip6tables -A OUTPUT -p udp ! --sport dns --dport 1024:65535 -j REJECT');
      S.Add('');
    end;

    //Формируем списки IPv4/IPv6 blacklist и blacklist6
    S.Add('# Блокировка IPSET по множеству IP-адресов (iptables/ip6tables)');
    S.Add('if [ ! -f /root/.censor/ipset_rules ]; then');
    S.Add('ipset -X blacklist; ipset -N blacklist iphash family inet; ipset -F blacklist');
    S.Add('ipset -X blacklist6; ipset -N blacklist6 iphash family inet6; ipset -F blacklist6');

    S.Add('for site in $(cat /root/.censor/blacklist); do');
    S.Add('data=$(host $site)');
    S.Add('   for ip in $(echo "$data" | grep "has address" | cut -d " " -f4); do');
    S.Add('     ipset -A blacklist $ip; done');
    S.Add('   for ip in $(echo "$data" | grep "has IPv6 address" | cut -d " " -f5); do');
    S.Add('     ipset -A blacklist6 $ip; done');
    S.Add('done;');
    S.Add('ipset save > /root/.censor/ipset_rules');
    S.Add('   else');
    S.Add('ipset load < /root/.censor/ipset_rules');
    S.Add('fi');
    S.Add('');

    S.Add('iptables -A OUTPUT -m set --match-set blacklist dst -j REJECT');
    S.Add('ip6tables -A OUTPUT -m set --match-set blacklist6 dst -j REJECT');
    S.Add('');

    S.Add('# Визуальный контроль черных списков (iptables/ip6tables)');
    S.Add('ipset -L blacklist');
    S.Add('ipset -L blacklist6');
    S.Add('');

    if DictionaryCheck.Checked then
    begin
      S.Add('# Блокировка STRING - словарная фильтрация (iptables/ip6tables)');
      for i := 0 to ListBox1.Count - 1 do
      begin
        S.Add('iptables -A OUTPUT -m string --string "' +
          ListBox1.Items[i] + '" --algo bm -j REJECT');
        S.Add('ip6tables -A OUTPUT -m string --string "' +
          ListBox1.Items[i] + '" --algo bm -j REJECT');
      end;
    end;
    S.Add('fi;');
    S.Add('');

    S.Add('exit 0');

    //Удаляем файл таблиц ipset для обновления
    DeleteFile('/root/.censor/ipset_rules');

    //Сохраняем файл censor.sh
    S.SaveToFile('/usr/local/bin/censor.sh');

  finally;
    S.Free;
  end;

  //Запускаем скрипт блокировки
  FStartScript := StartScript.Create(False);
  FStartScript.Priority := tpNormal;

  //Создаём новый план CRON
  CreateCrontab;
  //Создан ли сервис автозапуска? (возможно был Reset, пересоздать)
  CreateServices;

  //Это отправляем в поток...
  //Делаем исполняемым и запускаем /usr/local/bin/censor.sh
  // StartProcess('chmod +x /usr/local/bin/censor.sh; /usr/local/bin/censor.sh');
end;

end.
