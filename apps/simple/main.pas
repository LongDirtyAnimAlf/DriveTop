unit main;

{$mode objfpc}{$H+}

{$i customdefines.inc}

interface

// TODO
// S-0-0144, Signal status word
// Together with
// S-0-0026, Configuration list signal status word and
// S-0-0328, Config. list for signal status word, bit number
// for realtime data collection !!!
// Same for S-0-0145

uses
  {$ifdef MSWindows}
  Windows,
  {$endif}
  Classes, SysUtils, FileUtil, SynEdit, Forms, Controls, syncobjs,
  Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls, Menus, ValEdit,
  common, drive,
  commworker,
  {$ifdef MSWindows}
  LMessages,
  {$endif}
  dsLeds, Grids, Types;

{$WARN 5023 off}
{$WARN 5024 off}

type
  TCONNECTION                       = (conNone,conASCIIDDRS232,conASCIIDDRS485);

  { TMainForm }
  TMainForm = class(TForm)
    btnAbsoluteAxis: TButton;
    btnAxisHome: TButton;
    btnClearErrors: TButton;
    btnConnectDriveRS232: TButton;
    btnConnectDriveRS485: TButton;
    btnMove: TButton;
    btnPhase2: TButton;
    btnPhase3: TButton;
    btnPhase4: TButton;
    btnReps: TButton;
    btnResetAxis: TButton;
    btnStop: TButton;
    cmboSerialPorts: TComboBox;
    editDist: TEdit;
    editFeed: TEdit;
    editReps: TEdit;
    editStatus: TEdit;
    grpAxisCommands: TGroupBox;
    grpDriveDashBoard: TGroupBox;
    grpSettings: TGroupBox;
    labelDist: TLabel;
    labelFeed: TLabel;
    Memo1: TMemo;
    PanelControl: TPanel;
    panelDriveDiags: TPanel;
    panelDrivePhase: TPanel;
    panelDriveStatus: TPanel;
    PanelEnable: TPanel;
    PanelHalt: TPanel;
    panelInPosition: TPanel;
    panelInReference: TPanel;
    PanelPhase2: TPanel;
    PanelPhase3: TPanel;
    PanelPhase4: TPanel;
    PanelPower: TPanel;
    panelStandstill: TPanel;
    panelTargetPosition: TPanel;
    procedure btnAxisHomeClick({%H-}Sender: TObject);
    procedure btnAxisCommandClick(Sender: TObject);
    procedure btnConnectSerialClick(Sender: TObject);
    procedure btnExecuteRepsClick(Sender: TObject);
    procedure btnResetAxisClick({%H-}Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnMoveClick({%H-}Sender: TObject);
    procedure btnAbsoluteAxisClick({%H-}Sender: TObject);
    procedure editDistKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormDestroy({%H-}Sender: TObject);
  private
    { private declarations }
    FActiveSerialConnection     : TCONNECTION;
    FActiveDriveNumber          : word;
    FDataFormatSettings         : TFormatSettings;

    CommWorker                  : TWorkManager;

    procedure SetActiveDriveNumber(value:word);

    procedure SetActiveConnection(value : TCONNECTION);

    procedure InitMain({%H-}Data: PtrInt);
    procedure SetInfoPanel(aPanel:TPanel;Status:boolean);
    function  CommandExecuteAndWait(const aCD: TPARAMETERDATA):boolean;

    function  ProcessDirectDriveCommand(const Command:RawByteString; var Value:RawByteString):boolean;
    function  CheckComms:boolean;
    property  ActiveSerialConnection : TCONNECTION read FActiveSerialConnection write SetActiveConnection;
    property  ActiveDriveNumber : word read FActiveDriveNumber write SetActiveDriveNumber;

    function  GetPrio(const {%H-}CD:TPARAMETERDATA):boolean;
    function  GetBlocking(const {%H-}CD:TPARAMETERDATA):boolean;

    procedure ProcessDR14(const CD: TPARAMETERDATA);
    procedure ProcessDR134(const CD: TPARAMETERDATA);
    procedure ProcessDR135(const CD: TPARAMETERDATA);
    procedure ProcessDR182(const CD: TPARAMETERDATA);
    procedure SetStatus(const LocalCD:TPARAMETERDATA);

    procedure OnWorkComplete(Sender: TObject);
  public
    { public declarations }
    function  ProcessParameter(const CD:TPARAMETERDATA;out response:RawByteString; prio:boolean=false; blocking:boolean=false; verbose:boolean=false):boolean;
    procedure MoveDistance(Sender: TObject; Axis: word; Distance:integer);
  end;

var
  MainForm            : TMainForm;

implementation

{$R *.lfm}

uses
  StrUtils, IniFiles,
  InterfaceBase,
  sis,
  Tools;

{$ifdef MsWindows}
procedure ProcessControlMessages(Ctrl: TWinControl);
var
  Msg: Windows.TMsg;
begin
  Msg := Default(Windows.TMsg);
  while Windows.PeekMessage(Msg, 0, 0, 0, PM_REMOVE) do
  begin
    if Msg.message = WM_QUIT then
    begin
      Windows.PostQuitMessage(Msg.wParam);
      break;
    end
    else
    if (Msg.hwnd = Ctrl.Handle) or IsChild(Ctrl.Handle, Msg.hwnd) then
    begin
      //Windows.TranslateMessage(@Msg);
      //Windows.DispatchMessageW(@Msg);
      Windows.TranslateMessage(Msg);
      Windows.DispatchMessage(Msg);
    end
    else
    begin
      // Put message back if not for this control
      Windows.PostMessage(Msg.hwnd, Msg.message, Msg.wParam, Msg.lParam);
      break; // prevent starving other messages
    end;
  end;
end;
{$else}
procedure ProcessControlMessages(Ctrl: TWinControl);
begin
  //Application.ProcessMessages;
end;
{$endif MsWindows}

function ChangeBrightness(lIn: tColor; factor:double): TColor;
var
  lR,lG,lB: byte;
begin
  lR := Red(lIn);
  lG := Green(lIn);
  lB := Blue(lIn);
  result := RGBToColor(Round(lR*factor),Round(lG*factor),Round(lB*factor));
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  i        : integer;
  s        : string;
  Ini      : TIniFile;
  PDI      : PDRIVE;
begin
  //Application.OnIdle  := @ApplicationIdle;

  {$ifndef MSWindows}
  btnConnectDDE.Enabled:=False;
  editDLLFileName.Enabled:=False;
  {$endif}

  {$IF DEFINED(FPC_FULLVERSION) AND (FPC_FULLVERSION > 30000)}
  s:=GetLCLWidgetTypeName;
  {$ELSE}
  s:=sUN;
  {$ENDIF}
  Caption := 'DriveTop Simple'+ ' for ' + GetTargetCPUOS+ '-'+  s;

  for i:=1 to MAXDRIVES do
  begin
    PDI:=GetPDriveInfo(i);
    PDI^:=Default(TDRIVE);
    PDI^.DRIVEADDRESS:=i; // Set drive address to drive number ... not necessary correct however.
  end;

  FActiveDriveNumber:=1;

  CommWorker := TWorkManager.Create;
  CommWorker.WorkComplete:=@OnWorkComplete;

  ActiveSerialConnection:=conNone;

  {$IFDEF DELPHI}
    GetLocaleFormatSettings(GetThreadLocale(),FFileFormatSettings);
    GetLocaleFormatSettings(getsystemdefaultlcid,FFileFormatSettings);
  {$ENDIF}
  {$IFDEF FPC}
    FDataFormatSettings := DefaultFormatSettings;
  {$ENDIF}
  FDataFormatSettings.DecimalSeparator:=Char('.');
  FDataFormatSettings.ThousandSeparator:=Char(',');
  FDataFormatSettings.ListSeparator:=Char(';');

  ActiveSerialConnection:=conNone;

  Memo1.Append(DateTimeToStr(NowUTC)+' : '+'System started.');

  // Reset GUI elements
  //TabControl1Change(nil);

  Ini := TIniFile.Create( ChangeFileExt( Application.ExeName, '.ini' ) );
  try
    Self.Top          := ini.ReadInteger(Self.Name,'Top',Self.Top);
    Self.Left         := ini.ReadInteger(Self.Name,'Left',Self.Left);
    Self.Width        := ini.ReadInteger(Self.Name,'Width',Self.Width);
    Self.Height       := ini.ReadInteger(Self.Name,'Height',Self.Height);

    i                             := StrToIntDef(editDist.Text,0);
    i                             := ini.ReadInteger('Move','Distance',i);
    editDist.Text                 := InttoStr(i);

    i                             := StrToIntDef(editFeed.Text,0);
    i                             := ini.ReadInteger('Move','Speed',i);
    editFeed.Text                 := InttoStr(i);

    i                             := StrToIntDef(editReps.Text,0);
    i                             := ini.ReadInteger('Move','Repetitions',i);
    editReps.Text                 := InttoStr(i);

  finally
    Ini.Free;
  end;

  // Get comport list after form has been created
  Application.QueueAsyncCall(@InitMain,0);
end;

function TMainForm.CommandExecuteAndWait(const aCD: TPARAMETERDATA):boolean;
var
  c,s      : RawByteString;
  i        : word;
  SCS      : SERCOSCOMMAND_STATUS;
  success  : boolean;
  CD       : TPARAMETERDATA;
begin
  result:=false;

  CD:=aCD;
  CD.CSUBCLASS:=mscParameterData;

  // Execute command
  SCS.Raw:=0;
  SCS.Data.CommandSetInDrive:=1;
  SCS.Data.ExecutionOfCommandInDriveEnabled:=1;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,2,True);
  success:=ProcessParameter(CD,s,false,true);

  // Sleep at least 64 ms
  Sleep(200);

  i:=0;
  while true do
  begin
    Inc(i);
    CD:=aCD;
    CD.DATA:='';
    s:='';
    // Direct Drive checks the status of a command in a very special way
    // write ID,1,w,0
    // read normal result
    c:=Format('%s,%d,w,0',[GetIDN(CD),1]);
    //c:=GetDirectDriveCommand(CD);
    success:=ProcessDirectDriveCommand(c,s);
    CD.DATA:=s;
    NewProcessNormalResponse(@CD);

    sleep(150);

    if (NOT success) then break;
    if (Length(CD.ERROR)>0) then break;
    //success:=(s<>sERR);
    //if (NOT success) then break;
    SCS.Raw:=HexStringToDecimal(CD.DATA);
    //Detect command error.
    success:=((SCS.Data.CommandSetInDrive=1) AND (SCS.Data.ExecutionOfCommandInDriveEnabled=1) AND (SCS.Data.ExecutionOfCommandIsNotPossible=0));
    if (NOT success) then break;
    if (SCS.Data.CommandNotYetExecuted=0) then break; // Command ready !

    if (i>20) then
    begin
      break; // we are stuck ... :-( ... breakout
    end;
  end;

  // Clear command
  CD:=aCD;
  CD.CSUBCLASS:=mscParameterData;
  SCS.Raw:=0;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,2,True);
  success:=ProcessParameter(CD,s,false,true);
  //success:=(s<>sERR);

  result:=success;
end;

procedure TMainForm.btnResetAxisClick(Sender: TObject);
var
  s               : RawByteString;
  driveaddress    : byte;
  CD              : TPARAMETERDATA;
  SC0403          : TDRIVEPARAMETER_0403;
  success         : boolean;
begin
  (*
  Hardware reset

  The subsequent function is enabled by pressing the S1 key with the
  address set to 00. The function enable signal is present for 20 seconds.
  This is indicated by “Ad” on the display. After selecting the function
  number and confirming it with the S1 key, the display disappears if the
  function was completed.

  Address 90 ASCII protocol 9600 Baud NO parity
  Address 91 SIS protocol 9600 Baud EVEN Parity
  Address 92 RS on drive 9600 Baud No Parity
  Address 93 SIS protocol 9600 Baud No Parity
  Address 94 SIS protocol 9600 Baud EVEN
  Address 95 SIS protocol 9600 Baud No Parity
  Address 97 Load parameter with default values Programs, Variables, Marker Flags are cleared SIS Protocol 9600 Baud NO Parity (BTV04)
  Address 98 Load parameter with default values (Basic parameter load) ASCII protocol 9600 Baud NO Parity (MotionManager)
  Address 99 Load parameter with default values (Basic parameter load) SIS protocol 9600 Baud NO Parity y (BTV04)

  Press S1
  All parameters might be lost (97,98,99)
  So, make a backup first !!!!!
  *)

  success:=false;

  if CheckComms then exit;

  CD:=Default(TPARAMETERDATA);
  driveaddress := GetDriveAddress(ActiveDriveNumber);

  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=driveaddress;

  // Preset value for encoder 1
  CD.NUMID:=52;
  CD.DATA:='0';
  success:=ProcessParameter(CD,s);

  // Preset value for encoder 2
  CD.NUMID:=54;
  CD.DATA:='0';
  success:=ProcessParameter(CD,s);

  // Offset value for encoder 1
  CD.NUMID:=150;
  CD.DATA:='0';
  success:=ProcessParameter(CD,s);

  // Offset value for encoder 2
  CD.NUMID:=151;
  CD.DATA:='0';
  success:=ProcessParameter(CD,s);

  // Execute command "set absolute measuring"
  // C300 Command Set absolute measuring

  CD:=COMMAND2CD(DRIVE_COMMAND_ABSOLUTE,driveaddress);
  success:=CommandExecuteAndWait(CD);

  // Check success of P-0-0012, C300 Command
  CD:=COMMAND2CD(DRIVE_POSITIONFEEDBACKSTATUS,driveaddress);
  CD.DATA:='';
  success:=ProcessParameter(CD,s,false,true);
  SC0403.Raw:=BinaryStringToDecimal(s);
  if (SC0403.Data.InReference=1) then
  begin
    // Success !!!
    Memo1.Lines.Append('P-0-0012, C300 Command success !');
  end;
end;


procedure TMainForm.btnConnectSerialClick(Sender: TObject);
var
  Success      : boolean;
  OldDN        : word;
begin
  if commworker.Connected then
  begin
    Success:=true;
  end
  else
  begin
    Success:=false;
    ActiveSerialConnection:=conNone;
    if (Sender=btnConnectDriveRS232) then ActiveSerialConnection:=conASCIIDDRS232;
    if (Sender=btnConnectDriveRS485) then ActiveSerialConnection:=conASCIIDDRS485;

    if (cmboSerialPorts.ItemIndex<>-1) then
    begin
      commworker.Connect(cmboSerialPorts.Text);
      if (commworker.Connected) then
      begin
        Success:=True;
        Memo1.Lines.Append('RS232/RS485 device connected and active: '+cmboSerialPorts.Text);
      end
      else
      begin
        commworker.Comms.CloseSocket;
      end;
    end;
  end;

  if (NOT Success) then ActiveSerialConnection:=conNone;

  if Success then
  begin
    cmboSerialPorts.Enabled:=(NOT Success);
    btnConnectDriveRS232.Enabled:=(NOT Success);
    btnConnectDriveRS485.Enabled:=(NOT Success);

    // Force the activedrive change magic
    // Bit tricky ... ;-)
    // But when connecting, we directly need drive data !!
    OldDN:=ActiveDriveNumber;
    ActiveDriveNumber:=0;
    ActiveDriveNumber:=OldDN;
  end;
end;

procedure TMainForm.btnExecuteRepsClick(Sender: TObject);
var
  i,Reps,Distance      : integer;
  driveaddress         : byte;
  CD                   : TPARAMETERDATA;
  success              : boolean;
  s                    : RawByteString;
  DW                   : DATAWORD;
  StandStill           : boolean;
begin
  driveaddress:=GetDriveAddress(ActiveDriveNumber);
  Reps:=StrToIntDef(editReps.Text,0);
  Distance:=StrToIntDef(editDist.Text,0);
  if (Reps>0) then
  begin
    for i:=1 to Reps do
    begin
      editReps.Text:=InttoStr(Reps-i);
      editReps.Repaint;
      ProcessControlMessages(editReps);
      MoveDistance(Sender,driveaddress,Distance);
      repeat
        sleep(100);
        // Force a data reception of message 'nactual < nx'
        CD:=COMMAND2CD(DRIVE_332,driveaddress);
        ProcessParameter(CD,s,false,true);
        DW.Raw:=BinaryStringToDecimal(s);
        StandStill:=(DW.Bits[0]=1);
        SetInfoPanel(panelStandstill,StandStill);
        panelStandstill.Repaint;
        ProcessControlMessages(panelStandstill);
      until StandStill;
      MoveDistance(Sender,driveaddress,-1*Distance);
      repeat
        sleep(100);
        // Force a data reception of message 'nactual < nx'
        CD:=COMMAND2CD(DRIVE_332,driveaddress);
        ProcessParameter(CD,s,false,true);
        DW.Raw:=BinaryStringToDecimal(s);
        StandStill:=(DW.Bits[0]=1);
        SetInfoPanel(panelStandstill,StandStill);
        panelStandstill.Repaint;
        ProcessControlMessages(panelStandstill);
      until StandStill;
    end;
    editReps.Text:=InttoStr(Reps);
  end;
end;

procedure TMainForm.SetInfoPanel(aPanel:TPanel;Status:boolean);
const
  GreenColor : array[boolean] of TColor = ($004000,$00FF00);
  RedColor : array[boolean] of TColor = ($000040,$2020FF);
  BlueColor : array[boolean] of TColor = ($400000,$FF2020);
  FontColor : array[boolean] of TColor = ($A0A0A0,$FFFFFF);
begin
  if ((aPanel=PanelPhase2) OR (aPanel=PanelPhase3) OR (aPanel=PanelPhase4))  then
  begin
    aPanel.Color:=BlueColor[Status]
  end
  else
  if aPanel=PanelHalt then
    aPanel.Color:=RedColor[Status]
  else
    aPanel.Color:=GreenColor[Status];
  aPanel.Font.Color:=FontColor[Status];
end;

procedure TMainForm.btnAxisCommandClick(Sender: TObject);
var
  m             : string;
  driveaddress  : byte;
  CD            : TPARAMETERDATA;
  success       : boolean;
begin
  if CheckComms then exit;

  CD:=Default(TPARAMETERDATA);
  driveaddress:=GetDriveAddress(ActiveDriveNumber);

  if (Sender=btnPhase2) then
  begin
    // C400 Communication phase 2 transition
    CD:=COMMAND2CD(DRIVE_COMMAND_PHASE2,driveaddress);
    m:='Axis back in Phase 2';
  end;

  if (Sender=btnPhase3) then
  begin
    // C100 Communication phase 3 transition check
    CD:=COMMAND2CD(DRIVE_COMMAND_PHASE3,driveaddress);
    m:='Axis from Phase 2 to Phase 3';
  end;

  if (Sender=btnPhase4) then
  begin
    // C200 Communication phase 4 transition check
    CD:=COMMAND2CD(DRIVE_COMMAND_PHASE4,driveaddress);
    m:='Axis from Phase 3 to Phase 4'
  end;

  if (Sender=btnClearErrors) then
  begin
    // C500 Reset class 1 diagnostics
    CD:=COMMAND2CD(DRIVE_COMMAND_CLEARERRORS,driveaddress);
    m:='Cleared all drive errors';
  end;

  success:=CommandExecuteAndWait(CD);
  if success then
  begin
    Memo1.Lines.Append(m);
  end;
end;

procedure TMainForm.btnAxisHomeClick(Sender: TObject);
var
  s       : RawByteString;
  CD      : TPARAMETERDATA;
  SC0403  : TDRIVEPARAMETER_0403;
  SC0147  : TDRIVEPARAMETER_0147;
  success : boolean;
begin
  success:=false;

  if CheckComms then exit;

  CD:=Default(TPARAMETERDATA);
  CD.SETID:=GetDriveAddress(ActiveDriveNumber);
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;

  // Set absolute distance 1
  CD.NUMID:=177;
  CD.DATA:=InttoStr(0);
  success:=ProcessParameter(CD,s);

  // Set acceleration
  CD.NUMID:=260;
  CD.DATA:=InttoStr(200);
  success:=ProcessParameter(CD,s);

  // Set Homing Parameter
  CD.NUMID:=147;
  SC0147.Raw:=0;
  SC0147.Data.HomeSwitchEvaluation:=1; // do NOT evaluate HomeSwitch
  SC0147.Data.ReferenceMarkEvaluation:=1; // do NOT evaluate ReferenceMark
  CD.DATA:=DecimalToBinaryString(SC0147.Raw,True);
  success:=ProcessParameter(CD,s);

  // Execute command Drive-Controlled Homing Procedure
  // C600 Drive-controlled homing procedure command
  CD.NUMID:=148;
  success:=CommandExecuteAndWait(CD);

  // Check success of P-0-0148, C600 Command
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.NUMID:=403;
  CD.DATA:='';
  success:=ProcessParameter(CD,s);
  //success:=(s<>sERR);
  SC0403.Raw:=StringToIntSafe(s);
  if (SC0403.Data.InReference=1) then
  begin
    // Success !!!
    Memo1.Lines.Append('P-0-0148, C600 Command success !');
  end;

end;

procedure TMainForm.btnStopClick(Sender: TObject);
begin
  commworker.DisConnect;
  ActiveSerialConnection:=conNone;
  cmboSerialPorts.Enabled:=true;
  btnConnectDriveRS232.Enabled:=true;
  btnConnectDriveRS485.Enabled:=true;
end;

procedure TMainForm.MoveDistance(Sender: TObject; Axis: word; Distance:integer);
var
  s                    : RawByteString;
  CD                   : TPARAMETERDATA;
  SC346                : TDRIVEPARAMETER_0346;
  success              : boolean;
begin
  if CheckComms then exit;

  CD:=Default(TPARAMETERDATA);

  CD.SETID:=axis;
  CD.STEPID:=0;

  // Set feedrate
  CD:=COMMAND2CD(DRIVE_FEED,axis);
  CD.DATA:=editFeed.Text; // 100% = no changes
  success:=ProcessParameter(CD,s,false,true);

  // Set relative travel distance
  CD:=COMMAND2CD(DRIVE_DISTANCE,axis); // only with omRDIE1
  CD.DATA:=InttoStr(Distance);
  success:=ProcessParameter(CD,s,false,true);

  // Get strobe flag to toggle
  CD:=COMMAND2CD(DRIVE_SETUPRELATIVECOMMAND,axis);
  CD.DATA:='';
  // Get current register value
  success:=ProcessParameter(CD,s,false,true);
  SC346.Raw:=BinaryStringToDecimal(s);
  // Engage drive by toggling strobe bit
  SC346.Data.AcceptPositionToggle:=1-SC346.Data.AcceptPositionToggle; // toggle strobe bit
  SC346.Data.PositionType:=1;
  SC346.Data.Reference:=1;
  SC346.Data.TargetOverride:=1;
  CD.DATA:=DecimalToBinaryString(SC346.Raw,True);
  success:=ProcessParameter(CD,s,false,true);
end;

procedure TMainForm.btnAbsoluteAxisClick(Sender: TObject);
var
  s                    : RawByteString;
  CD                   : TPARAMETERDATA;
  success              : boolean;
  SC0403               : TDRIVEPARAMETER_0403;
  driveaddress         : byte;
begin
  CD:=Default(TPARAMETERDATA);
  driveaddress:=GetDriveAddress(ActiveDriveNumber);

  // Execute command "set absolute measuring"
  // C300 Command Set absolute measuring

  CD:=COMMAND2CD(DRIVE_COMMAND_ABSOLUTE,driveaddress);
  success:=CommandExecuteAndWait(CD);

  // Check success of P-0-0012, C300 Command

  CD:=COMMAND2CD(DRIVE_POSITIONFEEDBACKSTATUS,driveaddress);
  CD.DATA:='';
  success:=ProcessParameter(CD,s,false,true);
  SC0403.Raw:=BinaryStringToDecimal(s);
  if (SC0403.Data.InReference=1) then
  begin
    // Success !!!
    Memo1.Lines.Append('P-0-0012, C300 Command success !');
  end;

  // We might read position and store this into target
  CD:=COMMAND2CD(DRIVE_POSITIONCOMMAND,driveaddress);
  CD.DATA:='';
  success:=ProcessParameter(CD,s,false,true);
  CD:=COMMAND2CD(DRIVE_TARGET,driveaddress);
  CD.DATA:=s;
  success:=ProcessParameter(CD,s,false,true);


  CD:=COMMAND2CD(DRIVE_DISTANCE,driveaddress);
  CD.DATA:='0';
  success:=ProcessParameter(CD,s,false,true);

  (*
  // Switch to parameter mode
  CD.CCLASSCHAR:=VMCOMMANDCLASS[ccRegister];
  CD.CSUBCLASSCHAR:=VMREGISTERSUBCLASS[rscDecimalState];
  CD.DATA:='';
  CD.NUMID:=1;
  success:=ProcessParameter(CD,s);
  if success then
  begin
    SystemControl.Raw:=StringToIntSafe(s);
    SystemControl.Data.ParameterMode:=1;
    CD.DATA:=InttoStr(SystemControl.Raw);
    success:=ProcessParameter(CD,s);
  end;

  CD:=Default(TPARAMETERDATA);
  CD.CCLASS:=ccAxis;
  CD.CSUBCLASS:=mscParameterData;

  raise EArgumentException.Create ('Bad code !!!');
  //for axis:=1 to 2 do
  for axis:=ActiveDriveNumber to ActiveDriveNumber do
  begin
    CD.SETID:=axis;

    CD.NUMID:=7;
    //CD.DATA:='0'; // 0 = init with task
    CD.DATA:='1'; // 1 = init without task
    //CD.DATA:='2'; // 2 = no init
    success:=ProcessParameter(CD,s);

    CD.NUMID:=26;
    CD.DATA:='80000';
    success:=ProcessParameter(CD,s);

    CD.NUMID:=23;
    CD.DATA:='100';
    success:=ProcessParameter(CD,s);
  end;

  // Switch back to run mode
  if (SystemControl.Data.ParameterMode=1) then
  begin
    SystemControl.Data.ParameterMode:=0;
    CD:=Default(TPARAMETERDATA);
    CD.CCLASSCHAR:=VMCOMMANDCLASS[ccRegister];
    CD.CSUBCLASSCHAR:=VMREGISTERSUBCLASS[rscDecimalState];
    CD.NUMID:=1;
    CD.DATA:=InttoStr(SystemControl.Raw);
    success:=ProcessParameter(CD,s);
  end;
  *)
end;

procedure TMainForm.btnMoveClick(Sender: TObject);
var
  Distance             : integer;
  driveaddress         : byte;
  CD                   : TPARAMETERDATA;
  s                    : RawByteString;
begin
  driveaddress:=GetDriveAddress(ActiveDriveNumber);

  Distance:=StrToIntDef(editDist.Text,0);
  if (Distance<>0) then
  begin
    MoveDistance(Sender,driveaddress,Distance);
    // Force a data reception of message 'nactual < nx'
    CD:=COMMAND2CD(DRIVE_332,driveaddress);
    ProcessParameter(CD,s,true,false);
  end;
end;

function TMainForm.CheckComms:boolean;
begin
  result:=(NOT commworker.Connected);
end;

function TMainForm.ProcessDirectDriveCommand(const Command:RawByteString; var Value:RawByteString):boolean;
var
  c        : RawByteString;
  ro       : boolean;
begin
  c:=Command;
  ro:=(Length(Value)=0);
  if (NOT ro) then c:=c+Value;
  result:=commworker.ProcessASCIIRaw(c);
  if result then Value:=c;
end;

procedure TMainForm.editDistKeyPress(Sender: TObject; var Key: char);
begin
  //if not (Key in [#8, '0'..'9', DecimalSeparator]) then begin
  if (not CharInSet(Key,[#8, '0'..'9', '-', FormatSettings.DecimalSeparator])) then begin
    //ShowMessage('Invalid key: ' + Key);
    Key := #0;
  end
  else if (Key = FormatSettings.DecimalSeparator) and
          (Pos(Key, (Sender as TEdit).Text) > 0) then begin
    //ShowMessage('Invalid Key: twice ' + Key);
    Key := #0;
  end
  else if (Key = '-') and
          ((Sender as TEdit).SelStart <> 0) then begin
    ShowMessage('Only allowed at beginning of number: ' + Key);
    Key := #0;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  IniFile               : TIniFile;
  i                     : integer;
begin
  CommWorker.DisConnect;
  CommWorker.Free;

  IniFile := TIniFile.Create( ChangeFileExt( Application.ExeName, '.ini' ) );
  try
    IniFile.WriteInteger(Self.Name,'Top',Self.Top);
    IniFile.WriteInteger(Self.Name,'Left',Self.Left);
    IniFile.WriteInteger(Self.Name,'Width',Self.Width);
    IniFile.WriteInteger(Self.Name,'Height',Self.Height);

    i := StringToIntSafe(editDist.Text);
    IniFile.WriteInteger('Move','Distance',i);
    i := StringToIntSafe(editFeed.Text);
    IniFile.WriteInteger('Move','Speed',i);
    i := StringToIntSafe(editReps.Text);
    IniFile.WriteInteger('Move','Repetitions',i);
  finally
    IniFile.Free;
  end;
end;

procedure TMainForm.InitMain(Data: PtrInt);
{$ifdef UNIX}
var
  com:string;
  i:integer;
{$endif UNIX}
begin
  EnumerateCOMPorts(cmboSerialPorts.Items);
  if (cmboSerialPorts.Items.Count>0) then cmboSerialPorts.ItemIndex:=0;
  {$ifdef UNIX}
  // Make life easy on RPi: pick first available USB serial port.
  // Not necessary correct, but ok for testing.
  i:=0;
  for com in cmboSerialPorts.Items do
  begin
    if (Pos('ttyUSB',com)>0) then
    begin
      cmboSerialPorts.ItemIndex:=i;
      break;
    end;
    Inc(i);
  end;
  {$endif UNIX}
end;

function TMainForm.ProcessParameter(const CD:TPARAMETERDATA;out response:RawByteString; prio:boolean=false; blocking:boolean=false; verbose:boolean=false):boolean;
var
  s                      : RawByteString;
  ro                     : boolean;
  LocalCD                : TPARAMETERDATA;
  StoreCD                : TPARAMETERDATA;
  wp,wb                  : boolean;
begin
  result:=false;

  ro:=(Length(CD.DATA)=0);

  s:=sERR;
  LocalCD:=CD;
  LocalCD.CSUBCLASS:=mscName;
  if LocalCD.CCLASS in [ccDrive,ccDriveSpecific] then
  begin
    StoreCD:=LoadDriveRegisterData(LocalCD);
    s:=StoreCD.DATA;
  end;

  if (NOT ro) then
    Memo1.Lines.Append('Write command: '+s+'. Value: '+CD.DATA)
  else
    Memo1.Lines.Append('Read command: '+s+'.');

  if (ActiveSerialConnection=TCONNECTION.conNone) then exit;

  wp:=false;
  wb:=false;
  if (NOT wb) then
  begin
    wp:=prio;
    wb:=blocking;
    if (NOT wb) then wb:=GetBlocking(CD);
    if wb then
      wp:=false
    else
      if (NOT wp) then wp:=GetPrio(CD);
  end;

  LocalCD:=CD;

  CommWorker.AddWork(LocalCD,false,wp,wb);

  response:=LocalCD.DATA;
end;

procedure TMainForm.ProcessDR14(const CD: TPARAMETERDATA);
var
  DP14    : TDRIVEPARAMETER_0014;
  PDI     : PDRIVE;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=GetDriveAddress(ActiveDriveNumber)) then
  begin
    DP14.Raw:=BinaryStringToDecimal(CD.DATA);
    //SetInfoPanel(PanelPhase1,(DP14.Data.CommPhase=1));
    SetInfoPanel(PanelPhase2,(DP14.Data.CommPhase=2));
    SetInfoPanel(PanelPhase3,(DP14.Data.CommPhase=3));
    SetInfoPanel(PanelPhase4,(DP14.Data.CommPhase=4));

    btnPhase2.Enabled:=(DP14.Data.CommPhase<>2);
    btnPhase3.Enabled:=(DP14.Data.CommPhase<>3);
    btnPhase4.Enabled:=(DP14.Data.CommPhase<>4);

    PDI:=GetPDriveInfo(ActiveDriveNumber);
    if (PDI^.DRIVEPHASE<>DP14.Data.CommPhase) then
    begin
      PDI^.DRIVEPHASE:=DP14.Data.CommPhase;
    end;
  end;
end;

procedure TMainForm.ProcessDR134(const CD: TPARAMETERDATA);
var
  SC134      : TDRIVEPARAMETER_0134;
  HaltState  : boolean;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=GetDriveAddress(ActiveDriveNumber)) then
  begin
    HaltState:=false;
    SC134.Raw:=BinaryStringToDecimal(CD.DATA);
    if ((SC134.Data.DriveEnable=1) AND (SC134.Data.DriveOn=1)) then
      HaltState:=(SC134.Data.DriveHalt=0);
    SetInfoPanel(PanelHalt,HaltState);
  end;
end;

procedure TMainForm.ProcessDR135(const CD: TPARAMETERDATA);
var
  SC135      : TDRIVEPARAMETER_0135;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=GetDriveAddress(ActiveDriveNumber)) then
  begin
    SC135.Raw:=BinaryStringToDecimal(CD.DATA);
    SetInfoPanel(PanelControl,(SC135.Data.DriveReady>0));
    SetInfoPanel(PanelPower,(SC135.Data.DriveReady>1));
    SetInfoPanel(PanelEnable,(SC135.Data.DriveReady>2));
  end;
end;

procedure TMainForm.ProcessDR182(const CD: TPARAMETERDATA);
var
  DR182          : TDRIVEPARAMETER_0182;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  exit;
  if (CD.SETID=GetDriveAddress(ActiveDriveNumber)) then
  begin
    DR182.Raw:=BinaryStringToDecimal(CD.DATA);
    SetInfoPanel(panelInPosition,(DR182.Data.EndPosition=1));
    //SetInfoPanel(panelStandstill,(DR182.Data.Velocity=1));
    SetInfoPanel(panelTargetPosition,(DR182.Data.InTargetPosition=1));
  end;
end;

function TMainForm.GetPrio(const CD:TPARAMETERDATA):boolean;
begin
  result:=false;
end;

function TMainForm.GetBlocking(const CD:TPARAMETERDATA):boolean;
begin
  result:=false;
end;

procedure TMainForm.SetActiveConnection(value : TCONNECTION);
begin
  if (value<>FActiveSerialConnection) then
  begin
    FActiveSerialConnection:=value;
  end;
end;

procedure TMainForm.OnWorkComplete(Sender: TObject);
var
  WorkData: PPARAMETERDATA;
  Thread: TWorkerThread;
begin
  Thread := Sender as TWorkerThread;
  WorkData := Thread.CurrentWorkData;
  if Assigned(WorkData) then
  begin
    try
      try
        Memo1.Lines.Append(WorkData^.DATA);
      except
        // Swallow exceptions !!
        // We always need to free the workdata
      end;
    finally
      Dispose(WorkData);
    end;
  end;
end;

procedure TMainForm.SetActiveDriveNumber(value:word);
var
  Success      : boolean;
  c,s          : RawByteString;
  CD           : TPARAMETERDATA;
  SC0393       : TDRIVEPARAMETER_0393;
begin
  if (value<>FActiveDriveNumber) then
  begin
    FActiveDriveNumber:=value;

    if (FActiveDriveNumber>0) then
    begin
      if CheckComms then exit;

      // Select drive to activate serial port for that drive
      // BCD = Bus Change Drive
      c:=Format('BCD:%.2d',[GetPDriveInfo(ActiveDriveNumber)^.DRIVEADDRESS]);
      s:='';
      Success:=ProcessDirectDriveCommand(c,s);
      Memo1.Lines.Append('Select drive ASCII response: '+s);
      c:=Format('E%.2d',[GetPDriveInfo(ActiveDriveNumber)^.DRIVEADDRESS]);
      if s=c then Memo1.Lines.Append('Selected drive connected !');

      CD:=Default(TPARAMETERDATA);
      CD.CSUBCLASS:=mscParameterData;
      CD.CCLASS:=ccDrive;
      CD.SETID:=GetDriveAddress(ActiveDriveNumber);

      // Perform some default actions on the active drive

      (*
      Parameter S-0-0393, Command value mode, TargetPosAfter = 0
      After activation, the drive positions to the value in the parameter S-0-
      0258 Target position. So, after an interruption of the operation mode (e.g.
      on error), the drive can go to the same target position as it should have
      done before the error. That means, the remaining path is performed.

      Parameter S-0-0393, Command value mode, TargetPosAfter = 1
      After acivating the operation mode, the drive refers the distance to move
      always to the actual position. To do this, the parameter S-0-0258, Target
      position is set to the actual position. That means, after an accidental
      interruption, the drive stays at the actual position at first.
      In the operation mode Relative drive internal interpolation, the distance to
      move refers to the actual position after toggling the parameter S-0-0346

      // We need TargetPosAfter = 1
      *)

      // Command value mode
      CD:=COMMAND2CD(DRIVE_COMMANDMODE,GetDriveAddress(ActiveDriveNumber));
      CD.DATA:='';
      s:='';
      success:=ProcessParameter(CD,s,false,true);
      SC0393.Raw:=BinaryStringToDecimal(s);
      if (SC0393.Data.TargetPosAfter=0) then
      begin
        SC0393.Data.TargetPosAfter:=1;
        CD.DATA:=DecimalToBinaryString(SC0393.Raw,True);
        success:=ProcessParameter(CD,s,false,true);
      end;

      // Deactivate resident memory mode to preserve EEPROM
      // Might be decided by global switch
      CD.NUMID:=269;
      CD.DATA:='1';
      s:='';
      success:=ProcessParameter(CD,s,false,true);

      CD:=COMMAND2CD(DRIVE_INTERFACE,GetDriveAddress(ActiveDriveNumber));
      CD.DATA:='';
      s:='';
      success:=ProcessParameter(CD,s,false,true);
      ProcessDR14(CD);


      //with DRIVE_CONTROLWORD do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))         then ProcessDR134(LocalCD);
      //with DRIVE_STATUSWORD do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))          then ProcessDR135(LocalCD);
      //with DRIVE_MANUDIAGS_CLASS3 do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))   then ProcessDR182(LocalCD);
      //ProcessDR134(CD);
      //ProcessDR135(CD);
      //ProcessDR182(CD);
    end;
  end;
end;

procedure TMainForm.SetStatus(const LocalCD:TPARAMETERDATA);
begin
  editStatus.Text:=GetIDN(LocalCD)+'. Drive '+InttoStr(LocalCD.SETID)+' '+LowerCase(VMCOMMANDPARAMETERSUBCLASSLONG[LocalCD.CSUBCLASS])+' update: '+LocalCD.DATA;
  editStatus.Repaint;
  ProcessControlMessages(editStatus);
end;

end.

