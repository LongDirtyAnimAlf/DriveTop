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
  common, drive, visualmotion,
  CommBase,
  serialcomm,
  {$ifdef MSWindows}
  LMessages,
  ddecomm,
  {$endif}
  dsLeds, Grids, Types;

//{$WARN 5023 off}
//{$WARN 5024 off}

type
  TCONNECTION                       = (conNone,conASCIIDDRS232,conASCIIDDRS485,conSISDDRS232,conSISDDRS485,conCLCDDE,conCLCRS232,conCLCRS485);
  TAXISDIRECTION                    = (dirNone,dirLeft,dirRight,dirUp,dirDown);
  TAXIS                             = (axisNone,axisOne,axisTwo);
  TDATACOLLECTION                   = (dcNone,dcBasic,dcModes,dcIDN,dcIDNData,dcIDNAttribute);


  { TForm1 }
  TForm1 = class(TForm)
    btnConnectDriveRS232: TButton;
    btnConnectDriveSISRS486: TButton;
    btnConnectDriveSISRS232: TButton;
    btnConnectDriveRS485: TButton;
    btnMove: TButton;
    Button2: TButton;
    Button3: TButton;
    cmboSerialPorts: TComboBox;
    editFeed: TEdit;
    EditPos: TEdit;
    editStatus: TEdit;
    grpDriveDashBoard: TGroupBox;
    labelFeed: TLabel;
    MovementPanel1: TPanel;
    Panel1: TPanel;
    panelDriveFeedback: TPanel;
    panelDrivePosition: TPanel;
    panelDrivePhase: TPanel;
    panelDriveDiags: TPanel;
    panelDriveStatus: TPanel;
    PanelControl: TPanel;
    panelDriveDistance: TPanel;
    panelDriveTarget: TPanel;
    panelDriveVelocity: TPanel;
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
    StaticText1: TStaticText;
    TextPosition: TStaticText;
    TextTarget: TStaticText;
    TextDistance: TStaticText;
    TextFeedback: TStaticText;
    editDist: TEdit;
    editReps: TEdit;
    grpSettings: TGroupBox;
    labelDist: TLabel;
    labelReps: TLabel;
    Memo1: TMemo;
    PageControl2: TPageControl;
    selectDirection: TRadioGroup;
    OpenDialog1: TOpenDialog;
    shapeBase: TShape;
    shapeWork: TShape;
    shapeStar: TShape;
    shapeArrowUp: TShape;
    shapeArrowDown: TShape;
    shapeArrowRight: TShape;
    shapeArrowLeft: TShape;
    TabControl1: TTabControl;
    tabMove: TTabSheet;
    procedure btnConnectSerialClick(Sender: TObject);
    procedure btnSpeedLimitClick({%H-}Sender: TObject);
    procedure btnStartTaskAClick({%H-}Sender: TObject);
    procedure btnMoveClick({%H-}Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure cmboSerialPortsSelect(Sender: TObject);
    procedure editDistKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormDestroy({%H-}Sender: TObject);
    procedure panelDriveVelocityResize(Sender: TObject);
    procedure selectDirectionClick(Sender: TObject);
    procedure selectDirectionSelectionChanged(Sender: TObject);
    procedure ArrowMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ArrowMouseUp({%H-}Sender: TObject; {%H-}Button: TMouseButton; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
  private
    { private declarations }
    FActiveSerialConnection     : TCONNECTION;
    FActiveDriveNumber          : word;
    FDataFormatSettings         : TFormatSettings;

    PositionDisplay             : TdsSevenSegmentMultiDisplay;
    TargetDisplay               : TdsSevenSegmentMultiDisplay;
    DistanceDisplay             : TdsSevenSegmentMultiDisplay;
    FeedbackDisplay             : TdsSevenSegmentMultiDisplay;

    ActualVelocityDisplay       : TdsSevenSegmentMultiDisplay;
    SetVelocityDisplay          : TdsSevenSegmentMultiDisplay;

    MouseUpEvent                : TSimpleEvent;
    DCStatus                    : TDATACOLLECTION;
    ComDevice                   : ICommInterface;

    function  GetDirectDrive:boolean;
    function  GetSISDrive:boolean;
    function  GetVisualMotion:boolean;

    procedure SetActiveDriveNumber(value:word);

    procedure IDNCompare(Sender: TObject; Item1, Item2: TListItem; {%H-}Data: Integer; var Compare: Integer);
    procedure SetActiveConnection(value : TCONNECTION);

    procedure InitMain({%H-}Data: PtrInt);
    procedure SetInfoPanel(aPanel:TPanel;Status:boolean);
    function  CommandExecuteAndWait(const aCD: TPARAMETERDATA):boolean;
    {$ifdef MSWindows}
    procedure HandleInfo(var Msg: TLMessage); message WM_DDEINFO;
    function  ProcessDDECommand(const Command:RawByteString; var Value:RawByteString; const prio,blocking:boolean):boolean;
    {$endif}
    function  ProcessSerialCommand(const Command:RawByteString; var Value:RawByteString; const prio,blocking:boolean):boolean;
    function  ProcessDirectDriveCommand(const Command:RawByteString; var Value:RawByteString; const prio,blocking:boolean):boolean;
    procedure ArrowMouse(Sender: TObject; Button: TMouseButton; Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
    function  GetAxisActive:TAXIS;
    procedure ApplicationIdle({%H-}Sender: TObject; var Done: Boolean);
    function  CheckComms:boolean;
    function  CheckAxis(out axis:word):boolean;
    property  DataFormatSettings:TFormatSettings read FDataFormatSettings;
    property  AxisActive:TAXIS read GetAxisActive;
    property  DirectDrive : boolean read GetDirectDrive;
    property  VisualMotion : boolean read GetVisualMotion;
    property  SISDrive : boolean read GetSISDrive;
    property  ActiveSerialConnection : TCONNECTION read FActiveSerialConnection write SetActiveConnection;
    property  ActiveDriveNumber : word read FActiveDriveNumber write SetActiveDriveNumber;

    procedure OnRXUSBCData({%H-}Sender: TObject);
    {$ifdef MSWindows}
    procedure OnRXDDEData({%H-}Sender: TObject);
    {$endif}

    procedure ProcessCommResult(const CD:TPARAMETERDATA);

    function  GetPrio(const {%H-}CD:TPARAMETERDATA):boolean;
    function  GetBlocking(const {%H-}CD:TPARAMETERDATA):boolean;

    procedure GetDriveData;

    procedure ProcessDR11(const CD: TPARAMETERDATA);
    procedure ProcessDR12(const CD: TPARAMETERDATA);
    procedure ProcessDR13(const CD: TPARAMETERDATA);
    procedure ProcessDR14(const CD: TPARAMETERDATA);
    procedure ProcessDR134(const CD: TPARAMETERDATA);
    procedure ProcessDR135(const CD: TPARAMETERDATA);
    procedure ProcessDR182(const CD: TPARAMETERDATA);
    procedure ProcessRealtimeData(const CD: TPARAMETERDATA);
    procedure ProcessDiskDriveData(const Drive: word; StoreOnDisk:boolean);

    procedure OnCommData(const s:ansistring);
  public
    { public declarations }
    function  ProcessParameter(const CD:TPARAMETERDATA;out response:RawByteString; prio:boolean=false; blocking:boolean=false; verbose:boolean=false):boolean;
    function  JogAxis(aDir:TAXISDIRECTION;Engage:boolean):boolean;
  end;

var
  Form1            : TForm1;

implementation

{$R *.lfm}

uses
  StrUtils, IniFiles,
  InterfaceBase,
  sis,
  Tools;

function ChangeBrightness(lIn: tColor; factor:double): TColor;
var
  lR,lG,lB: byte;
begin
  lR := Red(lIn);
  lG := Green(lIn);
  lB := Blue(lIn);
  result := RGBToColor(Round(lR*factor),Round(lG*factor),Round(lB*factor));
end;

procedure TForm1.IDNCompare(Sender: TObject; Item1, Item2: TListItem; Data: Integer; var Compare: Integer);
var
  n1, n2: integer;
  IDN1: TIDN;
  IDN2: TIDN;
begin
  Compare:=0;
  IDN1 := Item1.Caption;
  IDN2 := Item2.Caption;
  if ( (Length(IDN1)>0) AND (Length(IDN2)>0)   ) then
  begin
    n1 := Ord(IDN1[1]);
    n2 := Ord(IDN2[1]);
    if n1 > n2 then
      Compare := -1
    else if n1 < n2 then
      Compare := 1
    else
    begin
      Compare := AnsiCompareText(IDN1, IDN2);
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i        : integer;
  s        : string;
  Ini      : TIniFile;
  DI       : TDRIVE;
  PDI      : PDRIVE;
  DD       : TRegisterRecord;
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
  Caption := 'DriveTop'+ ' for ' + GetTargetCPUOS+ '-'+  s;

  for i:=1 to MAXDRIVES do
  begin
    PDI:=GetPDriveInfo(i);
    PDI^:=Default(TDRIVE);
    PDI^.DRIVEADDRESS:=i; // Set drive address to drive number ... not necessary correct however.
  end;

  //FActiveDriveNumber:=0;
  FActiveDriveNumber:=(TabControl1.TabIndex+1);

  ComDevice:=nil;
  ActiveSerialConnection:=conNone;
  DCStatus:=TDATACOLLECTION.dcNone;

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

  PositionDisplay:=TdsSevenSegmentMultiDisplay.Create(panelDrivePosition);
  with PositionDisplay do
  begin
    Parent:=panelDrivePosition;
    OnColor:=clRed;
    OffColor:=ChangeBrightness(OnColor,0.1);
    DisplayCount:=7;
    BorderWidth:=4;
    //Anchors:=[akLeft,akRight];
    //AnchorSide[akLeft].Control:=nil;
    //AnchorSide[akTop].Control:=nil;
    Align:=alClient;
    Hint:='Drive position command value';
    ShowHint:=True;
  end;

  TargetDisplay:=TdsSevenSegmentMultiDisplay.Create(panelDriveTarget);
  with TargetDisplay do
  begin
    Parent:=panelDriveTarget;
    OnColor:=clRed;
    OffColor:=ChangeBrightness(OnColor,0.1);
    DisplayCount:=7;
    BorderWidth:=4;
    //Anchors:=[akLeft,akRight];
    //AnchorSide[akLeft].Control:=nil;
    //AnchorSide[akTop].Control:=nil;
    Align:=alClient;
    Hint:='Drive target';
    ShowHint:=True;
  end;

  DistanceDisplay:=TdsSevenSegmentMultiDisplay.Create(panelDriveDistance);
  with DistanceDisplay do
  begin
    Parent:=panelDriveDistance;
    OnColor:=clRed;
    OffColor:=ChangeBrightness(OnColor,0.1);
    DisplayCount:=7;
    BorderWidth:=4;
    //Anchors:=[akLeft,akRight];
    //AnchorSide[akLeft].Control:=nil;
    //AnchorSide[akTop].Control:=nil;
    Align:=alClient;
    Hint:='Drive distance';
    ShowHint:=True;
  end;

  FeedbackDisplay:=TdsSevenSegmentMultiDisplay.Create(panelDriveFeedback);
  with FeedbackDisplay do
  begin
    Parent:=panelDriveFeedback;
    OnColor:=clRed;
    OffColor:=ChangeBrightness(OnColor,0.1);
    DisplayCount:=7;
    BorderWidth:=4;
    //Anchors:=[akLeft,akRight];
    //AnchorSide[akLeft].Control:=nil;
    //AnchorSide[akTop].Control:=nil;
    Align:=alClient;
    Hint:='Drive extra';
    ShowHint:=True;
  end;


  ActualVelocityDisplay:=TdsSevenSegmentMultiDisplay.Create(panelDriveVelocity);
  with ActualVelocityDisplay do
  begin
    Parent:=panelDriveVelocity;
    OnColor:=clLime;
    OffColor:=ChangeBrightness(OnColor,0.1);
    DisplayCount:=5;
    BorderWidth:=4;
    //Anchors:=[akLeft,akRight];
    //AnchorSide[akLeft].Control:=nil;
    //AnchorSide[akTop].Control:=nil;
    //Align:=alNone;
    Hint:='Drive speed';
    ShowHint:=True;
  end;
  SetVelocityDisplay:=TdsSevenSegmentMultiDisplay.Create(panelDriveVelocity);
  with SetVelocityDisplay do
  begin
    Parent:=panelDriveVelocity;
    OnColor:=clLime;
    OffColor:=ChangeBrightness(OnColor,0.1);
    DisplayCount:=5;
    BorderWidth:=4;
    //Anchors:=[akLeft,akRight];
    //AnchorSide[akLeft].Control:=nil;
    //AnchorSide[akTop].Control:=nil;
    //Align:=alNone;
    Hint:='Drive force/torque';
    ShowHint:=True;
  end;

  ActiveSerialConnection:=conNone;
  ComDevice:=nil;

  MouseUpEvent:=TSimpleEvent.Create;

  Memo1.Append(DateTimeToStr(NowUTC)+' : '+'System started.');

  Ini := TIniFile.Create( ChangeFileExt( Application.ExeName, '.ini' ) );
  try
    Self.Top          := ini.ReadInteger(Self.Name,'Top',Self.Top);
    Self.Left         := ini.ReadInteger(Self.Name,'Left',Self.Left);
    Self.Width        := ini.ReadInteger(Self.Name,'Width',Self.Width);
    Self.Height       := ini.ReadInteger(Self.Name,'Height',Self.Height);

    selectDirection.ItemIndex     := ini.ReadInteger('Move','Direction',0);

    i                             := StrToIntDef(editDist.Text,0);
    i                             := ini.ReadInteger('Move','Distance',i);
    editDist.Text                 := InttoStr(i);

    i                             := StrToIntDef(editFeed.Text,0);
    i                             := ini.ReadInteger('Move','Feed',i);
    editFeed.Text                := InttoStr(i);

    i                             := StrToIntDef(editReps.Text,0);
    i                             := ini.ReadInteger('Move','Repetitions',i);
    editReps.Text                 := InttoStr(i);
  finally
    Ini.Free;
  end;

  // Get comport list after form has been created
  Application.QueueAsyncCall(@InitMain,0);
end;

function TForm1.CommandExecuteAndWait(const aCD: TPARAMETERDATA):boolean;
var
  c,s      : RawByteString;
  i        : word;
  SCS      : SERCOSCOMMAND_STATUS;
  success  : boolean;
  CD       : TPARAMETERDATA;
  CDStatus : TPARAMETERDATA;
begin
  result:=false;

  CD:=aCD;
  CD.CSUBCLASS:=mscParameterData;

  // Execute command
  SCS.Raw:=0;
  SCS.Data.CommandSetInDrive:=1;
  SCS.Data.ExecutionOfCommandInDriveEnabled:=1;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,2,DirectDrive);
  success:=ProcessParameter(CD,s,false,true);

  // Sleep at least 64 ms
  Sleep(100);

  i:=0;
  while true do
  begin
    Inc(i);
    CD:=aCD;
    CD.DATA:='';
    s:='';
    if DirectDrive then
    begin
      // Direct Drive checks the status of a command in a very special way
      // write ID,1,w,0
      // read normal result
      c:=Format('%s,%d,w,0',[GetIDN(CD),1]);
      //c:=GetDirectDriveCommand(CD);
      success:=ProcessDirectDriveCommand(c,s,false,true);
    end
    else
    begin
      success:=ProcessParameter(CD,s,false,true);
    end;
    CDStatus:=ProcessNormalResponse(CD,DirectDrive,s);

    sleep(150);

    if (NOT success) then break;
    if (Length(CDStatus.ERROR)>0) then break;
    //success:=(s<>sERR);
    //if (NOT success) then break;
    if DirectDrive then
      SCS.Raw:=HexStringToDecimal(CDStatus.DATA)
    else
      SCS.Raw:=BinaryStringToDecimal(CDStatus.DATA);
      //i:=StringToIntSafe(CDStatus.DATA);
    //Detect command error.
    success:=((SCS.Data.CommandSetInDrive=1) AND (SCS.Data.ExecutionOfCommandInDriveEnabled=1) AND (SCS.Data.ExecutionOfCommandIsNotPossible=0));
    if (NOT success) then break;
    if (SCS.Data.CommandNotYetExecuted=0) then break; // Command ready !

    if (i>20) then break; // we are stuck ... :-( ... breakout
  end;

  // Clear command
  CD:=aCD;
  CD.CSUBCLASS:=mscParameterData;
  SCS.Raw:=0;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,2,DirectDrive);
  success:=ProcessParameter(CD,s,false,true);
  //success:=(s<>sERR);

  result:=success;
end;

procedure TForm1.btnConnectSerialClick(Sender: TObject);
var
  Success      : boolean;
  OldDN        : word;
begin
  if Assigned(ComDevice) then
  begin
    Success:=true;
  end
  else
  begin
    Success:=false;
    ActiveSerialConnection:=conNone;
    if (Sender=btnConnectDriveSISRS232) then ActiveSerialConnection:=conSISDDRS232;
    if (Sender=btnConnectDriveSISRS486) then ActiveSerialConnection:=conSISDDRS485;
    if (Sender=btnConnectDriveRS232) then ActiveSerialConnection:=conASCIIDDRS232;
    if (Sender=btnConnectDriveRS485) then ActiveSerialConnection:=conASCIIDDRS485;

    if (cmboSerialPorts.ItemIndex<>-1) then
    begin
      ComDevice:=TLazSerial.Create(Self);
      ComDevice.Active:=False;
      with (ComDevice AS TLazSerial) do
      begin
        Device:=cmboSerialPorts.Text;
        BaudRate:=br__9600;
        FlowControl:=fcNone;
        Parity:=pNone;
        DataBits:=db8bits;
        StopBits:=sbOne;
      end;

      if SISDrive then
      begin
        ComDevice.OnRxData:=nil;
        ComDevice.Async:=false;
      end;

      if (VisualMotion OR DirectDrive) then
      begin
        ComDevice.OnRxData:=@OnRXUSBCData;
        ComDevice.Async:=true;
      end;

      ComDevice.Active:=True;

      if (ComDevice.Active=True) then
      begin
        Success:=True;
        if (ActiveSerialConnection in [conSISDDRS485,conASCIIDDRS485]) then (ComDevice AS TLazSerial).RTSToggle:=True;

        if VisualMotion then (ComDevice AS TLazSerial).Terminator:=CRLF;
        if SISDrive then (ComDevice AS TLazSerial).Terminator:='';
        if DirectDrive then (ComDevice AS TLazSerial).Terminator:=TERDT;

        Memo1.Lines.Append('RS232/RS485 device connected and active: '+cmboSerialPorts.Text);
      end
      else
      begin
        ComDevice:=nil;
      end;
    end;
  end;

  if (NOT Success) then ActiveSerialConnection:=conNone;

  if Success then
  begin
    cmboSerialPorts.Enabled:=(NOT Success);
    btnConnectDriveRS232.Enabled:=(NOT Success);
    btnConnectDriveRS485.Enabled:=(NOT Success);
    btnConnectDriveSISRS232.Enabled:=(NOT Success);
    btnConnectDriveSISRS486.Enabled:=(NOT Success);
    {$ifdef VISUALMOTION}
    btnConnectVMRS232.Enabled:=(NOT Success);
    btnConnectDDE.Enabled:=(NOT Success);
    editDLLFileName.Enabled:=(NOT Success);
    {$endif}

    (*
    tabProgramme.TabVisible:=VisualMotion;
    tabVMControl.TabVisible:=VisualMotion;
    tabVMAxis.TabVisible:=VisualMotion;
    tabVMTask.TabVisible:=VisualMotion;
    tabVMRegister.TabVisible:=VisualMotion;
    *)

    if DirectDrive OR SISDrive then
    begin
      // Force the activedrive change magic
      // Bit tricky ... ;-)
      // But when connecting, we directly need drive data !!
      OldDN:=ActiveDriveNumber;
      ActiveDriveNumber:=0;
      ActiveDriveNumber:=OldDN;
    end;
  end;
end;

procedure TForm1.SetInfoPanel(aPanel:TPanel;Status:boolean);
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

procedure TForm1.btnSpeedLimitClick(Sender: TObject);
var
  s          : RawByteString;
  axis       : word;
  CD         : TPARAMETERDATA;
  success    : boolean;
begin
  if CheckComms then exit;

  if CheckAxis(axis) then exit;

  CD:=Default(TPARAMETERDATA);

  // Get axis speed limit
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;
  CD.NUMID:=91;
  success:=ProcessParameter(CD,s);
  if success then
  begin
    Memo1.Lines.Append('Speed limit: '+s);
  end;
end;

procedure TForm1.GetDriveData;
const
  BLOCK        = True;
var
  c,s          : RawByteString;
  CD           : TPARAMETERDATA;
  CDStorage    : TPARAMETERDATA;
  CDResult     : TPARAMETERDATA;
  CC           : TPARAMETER;
  success      : boolean;
  i,listlength : integer;
begin
  if CheckComms then exit;

  if (DCStatus<>TDATACOLLECTION.dcBasic) then
  begin
    for CC in REALTIMEDRIVEDATA do
    begin
      CD:=COMMAND2CD(CC,GetDriveAddress(ActiveDriveNumber));
      success:=ProcessParameter(CD,s,true,false);
    end;
  end;

  if (DCStatus=TDATACOLLECTION.dcBasic) then
  begin
    for CC in BASICDRIVEDATA do
    begin
      CD:=COMMAND2CD(CC,GetDriveAddress(ActiveDriveNumber));
      success:=ProcessParameter(CD,s,(NOT BLOCK),BLOCK);
      //if BLOCK then OnCommData(s);
      if BLOCK then
      begin
        CDResult:=ProcessNormalResponse(CD,DirectDrive,s);
        ProcessCommResult(CDResult);
      end;
    end;
  end;

  CD:=Default(TPARAMETERDATA);
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=GetDriveAddress(ActiveDriveNumber);

  case DCStatus of
    TDATACOLLECTION.dcBasic:
    begin
      DCStatus:=TDATACOLLECTION.dcModes;
    end;
    TDATACOLLECTION.dcModes:
    begin
      // Get drives modes
      CD.NUMID:=DRIVE_MODELIST.NUMID;
      CD.DATA:='';
      if DirectDrive then
      begin
        CD.CSUBCLASS:=mscParameterData;
        success:=ProcessParameter(CD,s);
      end
      else
      begin
        CD.CSUBCLASS:=mscList;
        CD.STEPID:=STEPLISTSTART;
        success:=ProcessParameter(CD,s);
      end;
      DCStatus:=TDATACOLLECTION.dcIDN;
    end;
    TDATACOLLECTION.dcIDN:
    begin
      CD.CCLASS:=DRIVE_PARAMLIST.CCLASS;
      CD.NUMID:=DRIVE_PARAMLIST.NUMID;
      CD.DATA:='';
      if DirectDrive then
      begin
        CD.CSUBCLASS:=mscParameterData;
        success:=ProcessParameter(CD,s);
      end
      else
      begin
        CD.CSUBCLASS:=mscList;
        CD.STEPID:=STEPLISTSTART;
        success:=ProcessParameter(CD,s);
      end;
      DCStatus:=TDATACOLLECTION.dcNone;
    end;
    else
    begin
      DCStatus:=TDATACOLLECTION.dcNone;
    end;
  end;

end;

procedure TForm1.btnStartTaskAClick(Sender: TObject);
var
  s       : RawByteString;
  success : boolean;
  CD      : TPARAMETERDATA;
  TC      : TSERCOSREGISTER_TASKCONTROL;
  TS      : TSERCOSREGISTER_TASKSTATUS;
begin
  success:=false;

  CD:=Default(TPARAMETERDATA);

  CD.CCLASSCHAR:=VMCOMMANDCLASS[ccRegister];
  CD.CSUBCLASSCHAR:=VMREGISTERSUBCLASS[rscBinaryState];

  CD.NUMID:=2; // TaskA Control

  TC.Raw:=0;

  // Ready the task
  TC.Data.Mode:=1;
  TC.Data.Start:=0;
  TC.Data.Stop:=1;
  TC.Data.ClearTaskError:=1;
  CD.DATA:=DecimalToBinaryString(TC.Raw,DirectDrive);
  success:=ProcessParameter(CD,s);

  // Start the task
  TC.Data.Start:=1;
  TC.Data.ClearTaskError:=0;
  CD.DATA:=DecimalToBinaryString(TC.Raw,DirectDrive);
  success:=ProcessParameter(CD,s);

  repeat
    Sleep(100);
    CD.NUMID:=22; // TaskA Status
    CD.DATA:='';
    success:=ProcessParameter(CD,s);
    TS.Raw:=BinaryStringToDecimal(s);
  until ((TS.Data.Mode=0) OR (TS.Data.Running=0));
end;

procedure TForm1.btnMoveClick(Sender: TObject);
var
  s                    : RawByteString;
  i,axis               : word;
  CD,StatusCD          : TPARAMETERDATA;
  //SC13                 : TDRIVEPARAMETER_0013;
  SC346                : TDRIVEPARAMETER_0346;
  DR182                : TDRIVEPARAMETER_0182;
  DriveMode            : TOPERATIONMODE;
  success              : boolean;
begin
  if CheckComms then exit;

  if CheckAxis(axis) then exit;

  // Tricky, we might move axis that is not active !!
  DriveMode:=GetDriveMode(GetPDriveInfo(ActiveDriveNumber)^.MODE);

  if (DriveMode in DriveInternalInterpolationModes) then
  begin
    CD:=Default(TPARAMETERDATA);

    CD.SETID:=axis;
    CD.STEPID:=0;

    // Set feedrate
    CD:=SetCommand(DRIVE_FEED);
    CD.DATA:=editFeed.Text; // 100% = no changes
    success:=ProcessParameter(CD,s,false,true);

    (*
    // Set jerk
    //CD.NUMID:=193;
    //CD.DATA:='';
    //success:=ProcessParameter(CD,s,false,true);
    *)

    if (DriveMode=omRDIE1) then
    begin
      // Set relative travel distance
      CD:=SetCommand(DRIVE_DISTANCE); // only with omRDIE1
      CD.DATA:=editDist.Text;
      success:=ProcessParameter(CD,s,false,true);
    end;

    if (DriveMode=omDIE1) then
    begin
      // Set absolute target position
      CD:=SetCommand(DRIVE_TARGET); // only with omDIE1
      CD.DATA:=editDist.Text;
      success:=ProcessParameter(CD,s,false,true);
    end;


    if (DriveMode in (DriveInternalInterpolationModesRelative+PositionControlBlockModes)) then
    begin
      // Get strobe flag to toggle
      CD:=SetCommand(DRIVE_SETUPRELATIVECOMMAND);
      CD.DATA:='';
      // Get current register value
      success:=ProcessParameter(CD,s,false,true);
      StatusCD:=ProcessNormalResponse(CD,DirectDrive,s);
      SC346.Raw:=BinaryStringToDecimal(StatusCD.DATA);
      // Engage drive by toggling strobe bit
      SC346.Data.AcceptPositionToggle:=1-SC346.Data.AcceptPositionToggle; // toggle strobe bit
      SC346.Data.PositionType:=1;
      SC346.Data.Reference:=1;
      SC346.Data.TargetOverride:=1;
      CD.DATA:=DecimalToBinaryString(SC346.Raw,DirectDrive);
      success:=ProcessParameter(CD,s,false,true);
    end;

    //Sleep(1000);

    
    //CD.CCLASS:=ccDrive;
    //CD.CSUBCLASS:=mscParameterData;

    // Wait for position
    (*
    CD.NUMID:=13;
    CD.DATA:='';
    i:=0;
    repeat
      Inc(i);
      success:=ProcessParameter(CD,s);
      Memo1.Lines.Append(s);
      SC13.Raw:=BinaryStringToDecimal(s);
    until ((SC13.Data.InPosition=1) OR (i>20));
    *)

    (*

    // Wait for position
    CD:=COMMAND2CD(DRIVE_MANUFACTURER_DIAGNOSTIC_CLASS3,GetDriveAddress(ActiveDriveNumber));
    i:=0;
    repeat
      Inc(i);
      success:=ProcessParameter(CD,s);
      Memo1.Lines.Append(s);
      DR182.Raw:=BinaryStringToDecimal(s);
    until ((DR182.Data.InTargetPosition=1) OR (i>20));

    *)
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  Data:SISTelegram;
  l:Integer;
  CD:TPARAMETERDATA;
begin
  // Get supported baudrates
  FillChar({%H-}Data,SizeOf(SISTelegram),0);
  BuildSISCommand(SISServiceUserIdentification,SISSubServiceReadOutSupportedBaudRates,GetDriveAddress(ActiveDriveNumber),0,Data,l);
  // Set the baudrate
  FillChar({%H-}Data,SizeOf(SISTelegram),0);
  BuildSISCommand(SISServiceInitSISCommunications,SISSubServiceSettingBaud,GetDriveAddress(ActiveDriveNumber),0,Data,l);
  FillChar({%H-}Data,SizeOf(SISTelegram),0);
  CD:=Default(TPARAMETERDATA);
  CD:=SetCommand(DRIVE_TARGET);
  CD.SETID:=GetDriveAddress(ActiveDriveNumber);
  FillChar({%H-}Data,SizeOf(SISTelegram),0);
  BuildSISTelegram(CD,Data,l);
end;

function TForm1.CheckComms:boolean;
begin
  result:=true;
  if Assigned(ComDevice) then
  begin
    result:=(NOT ComDevice.Active);
  end;
end;

function TForm1.CheckAxis(out axis:word):boolean;
begin
  axis:=0;
  result:=false;
  if (NOT DirectDrive) then
  begin
    if (AxisActive=axisOne) then axis:=1;
    if (AxisActive=axisTwo) then axis:=2;
    if (axis=0) then
    begin
      result:=true;
      Memo1.Lines.Append('Error: Select axis first !');
    end;
  end;
end;

function TForm1.ProcessDirectDriveCommand(const Command:RawByteString; var Value:RawByteString; const prio,blocking:boolean):boolean;
var
  c,s      : RawByteString;
  ro       : boolean;
begin
  result:=true;

  c:=Command;
  s:=Value;
  ro:=(Length(s)=0);

  if (NOT ro) then c:=c+s;

  Memo1.Lines.Append('Drive command: '+c);

  c:=c+#13;
  s:='';

  if prio then
  begin
    ComDevice.WriteStringPrio(c,s);
  end
  else
  if blocking then
  begin
    ComDevice.WriteStringBlocking(c,s);
    result:=((ComDevice AS TLazSerial).SynSer.LastError=0);
  end
  else
  begin
    ComDevice.WriteString(c,s);
  end;
  if blocking then Value:=s;
end;

{$ifdef MSWindows}
procedure TForm1.HandleInfo(var Msg: TLMessage);
var
  MsgStr: PChar;
  MsgPasStr: string;
begin
  MsgStr := {%H-}PChar(Msg.lParam);
  MsgPasStr := StrPas(MsgStr);
  Memo1.Lines.Append(MsgPasStr);
  StrDispose(MsgStr);
end;

function TForm1.ProcessDDECommand(const Command:RawByteString; var Value:RawByteString; const prio,blocking:boolean):boolean;
begin
  result:=false;
  if (ActiveSerialConnection=TCONNECTION.conCLCDDE) then
  begin
    if prio then
    begin
      ComDevice.WriteStringPrio(Command,Value);
    end
    else
    if blocking then
    begin
      ComDevice.WriteStringBlocking(Command,Value);
    end
    else
    begin
      ComDevice.WriteString(Command,Value);
    end;
    result:=true;
  end;
end;
{$endif}
function TForm1.ProcessSerialCommand(const Command:RawByteString; var Value:RawByteString; const prio,blocking:boolean):boolean;
var
  s,v,c    : RawByteString;
  cs       : byte;
  ro       : boolean;
begin
  result:=false;
  c:=sERR;
  if ((ActiveSerialConnection<>TCONNECTION.conNone) AND (ActiveSerialConnection<>TCONNECTION.conCLCDDE)) then
  begin
    s:=Command;
    v:=Value;
    ro:=(Length(v)=0);
    c:='>'+chr(48+CLCADDRESS)+' '+s+' '; // add pre-amble
    if (NOT ro) then c:=c+v+' ';
    cs:=GenerateVisualMotionChecksum(c);
    c:=c+CSS+InttoHex(cs,2)+(ComDevice AS TLazSerial).Terminator;
    result:=true;
    s:='';
    if prio then
    begin
      ComDevice.WriteStringPrio(c,s);
    end
    else
    if blocking then
    begin
      ComDevice.WriteStringBlocking(c,s);
      result:=((ComDevice AS TLazSerial).SynSer.LastError=0);
    end
    else
    begin
      ComDevice.WriteString(c,s);
    end;
  end;
  if blocking then Value:=s;
end;

procedure TForm1.cmboSerialPortsSelect(Sender: TObject);
begin
  if (cmboSerialPorts.Items.Count>0) AND (cmboSerialPorts.ItemIndex<>-1) then
  begin
    (*
    if Assigned(ComDevice) then
    begin
      ComDevice.Active:=False;
      (ComDevice AS TLazSerial).Device:=cmboSerialPorts.Text;
      ComDevice.Active:=True;
      Memo1.Lines.Append('RS232/RS485 Device Connected and Active: '+cmboSerialPorts.Text);
    end;
    *)
  end;
end;

procedure TForm1.editDistKeyPress(Sender: TObject; var Key: char);
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

procedure TForm1.FormDestroy(Sender: TObject);
var
  IniFile               : TIniFile;
  i                     : integer;
begin
  //Stop all data threads
  if Assigned(ComDevice) then ComDevice.Active:=False;
  ComDevice:=nil;

  // Store drive data on disk
  for i:=1 to MAXDRIVES do
  begin
    ProcessDiskDriveData(i,True);
  end;

  IniFile := TIniFile.Create( ChangeFileExt( Application.ExeName, '.ini' ) );
  try
    IniFile.WriteInteger(Self.Name,'Top',Self.Top);
    IniFile.WriteInteger(Self.Name,'Left',Self.Left);
    IniFile.WriteInteger(Self.Name,'Width',Self.Width);
    IniFile.WriteInteger(Self.Name,'Height',Self.Height);

    IniFile.WriteInteger('Move','Direction',selectDirection.ItemIndex);

    i := StringToIntSafe(editDist.Text);
    IniFile.WriteInteger('Move','Distance',i);
    i := StringToIntSafe(editFeed.Text);
    IniFile.WriteInteger('Move','Feed',i);
    i := StringToIntSafe(editReps.Text);
    IniFile.WriteInteger('Move','Repetitions',i);
  finally
    IniFile.Free;
  end;

  MouseUpEvent.Free;
end;

procedure TForm1.ProcessDiskDriveData(const Drive: word; StoreOnDisk:boolean);
var
  IniFile               : TIniFile;
  j,m,len               : integer;
  fn,n,s                : ansistring;
  SN,CT                 : string;
  DD                    : TRegisterRecord;
  LocalCD               : TPARAMETERDATA;
  StoreCD               : TPARAMETERDATA;
  IDNIniList            : TMySortedMap;
  P                     : PRegisterRecord;
  aKey                  : TIDN;
  DriveSections         : TStrings;
  ControllerSections    : TStrings;
  Section               : TStrings;
begin
  if (DriveRegisterDataCount(Drive)=0) then exit;

  CreateRegisterData({%H-}IDNIniList);

  // Get controller type
  LocalCD:=COMMAND2CD(DRIVE_CONTROLLERTYPE,GetDriveAddress(Drive));
  StoreCD:=LoadDriveRegisterData(LocalCD);
  CT:=StoreCD.DATA;
  if (Length(CT)=0) then CT:=sUN;

  // Get motor serial
  LocalCD:=COMMAND2CD(DRIVE_MOTORSERIAL,GetDriveAddress(Drive));
  StoreCD:=LoadDriveRegisterData(LocalCD);
  SN:=StoreCD.DATA;
  if (Length(SN)=0) then SN:=sUN;

  fn:=('SN_'+SN+'.par');

  // Create hashlist from inifile, if any to retrieve any existing diskdata
  if FileExists(fn) then
  begin
    IniFile:=TMemIniFile.Create(fn);
    Section:=TStringList.Create;
    DriveSections:=TStringList.Create;
    try
      IniFile.ReadSections(DriveSections);
      for j:=0 to Pred(DriveSections.Count) do
      begin
        aKey:=DriveSections[j];
        IniFile.ReadSectionRaw(aKey,Section);
        New(P);
        P^:=Default(TRegisterRecord);
        LocalCD:=IDN2CD(aKey,GetDriveAddress(Drive));
        P^.CClass:=LocalCD.CCLASS;
        P^.IDN.Data.ParamNum:=LocalCD.NUMID;
        for m:=0 to Pred(Section.Count) do
        begin
          n:=Section.Names[m];
          s:=Section.ValueFromIndex[m];
          if n=VMCOMMANDPARAMETERSUBCLASSLONG[mscName] then P^.Name:=s;
          if n=VMCOMMANDPARAMETERSUBCLASSLONG[mscAttributes] then P^.Attribute:=BinaryStringToDecimal(s);
          if n=VMCOMMANDPARAMETERSUBCLASSLONG[mscUnits] then P^.Measure:=s;
          if n=VMCOMMANDPARAMETERSUBCLASSLONG[mscLowerLimit] then P^.Min:=s;
          if n=VMCOMMANDPARAMETERSUBCLASSLONG[mscUpperLimit] then P^.Max:=s;
          if n=VMCOMMANDPARAMETERSUBCLASSLONG[mscParameterData] then P^.Value:=s;
        end;
        SaveRegisterDataRaw(aKey,P,IDNIniList);
        Dispose(P);
      end;
    finally
      IniFile.Free;
      Section.Free;
      DriveSections.Free;
    end;
  end;

  // Fill IniFile hash with data from current drive list
  len:=DriveRegisterDataCount(Drive);
  if (len>0) then
  begin
    for j:=0 to Pred(len) do
    begin
      P:=LoadDriveRegisterDataRaw(Drive,j);
      if (NOT Assigned(P)) then continue;
      DD:=P^;
      aKey:=GetIDN(DD);
      P:=LoadRegisterDataRaw(aKey,IDNIniList);
      if (NOT Assigned(P)) then
      begin
        P:=@DD;
      end
      else
      begin
        // if we have data from drive, use it to fill the ini-data
        if (DD.IDN.Data.ParamBlock>0) then P^.IDN.Data.ParamBlock:=DD.IDN.Data.ParamBlock;
        if (DD.CClass<>ccNone) then P^.CClass:=DD.CClass;
        if (DD.IDN.Data.ParamNum>0) then P^.IDN.Data.ParamNum:=DD.IDN.Data.ParamNum;
        if (DD.Attribute>0) then P^.Attribute:=DD.Attribute;
        if (Length(DD.Min)>0) then P^.Min:=DD.Min;
        if (Length(DD.Max)>0) then P^.Max:=DD.Max;
        if (Length(DD.Measure)>0) then P^.Measure:=DD.Measure;
        if (Length(DD.Name)>0) then P^.Name:=DD.Name;
        if (Length(DD.Value)>0) then P^.Value:=DD.Value;
      end;
      SaveRegisterDataRaw(aKey,P,IDNIniList);
    end;
  end;

  // Now the ini has the stored data, combined with the current drive data !
  // Clear the current drive data and refill with ini-data
  ClearDriveRegisterData(Drive);

  //IDNIniList.Sorted:=True;
  //IDNIniList.Sort;
  len:=IDNIniList.Count;
  if (len>0) then
  begin
    if (StoreOnDisk) then
    begin
      DriveSections:=TStringList.Create;
      ControllerSections:=TStringList.Create;
    end;
    try
      for j:=0 to Pred(len) do
      begin
        // Get updated data
        P:=LoadRegisterDataRaw(j,IDNIniList);
        DD:=P^;
        aKey:=GetIDN(DD);
        P:=@DD;
        SaveDriveRegisterDataRaw(Drive,aKey,P);

        // Store drive data and controller data (= drive data, but without value)
        if (StoreOnDisk) then
        begin
          s:='['+aKey+']';
          DriveSections.Append(s);
          ControllerSections.Append(s);
          s:=VMCOMMANDPARAMETERSUBCLASSLONG[mscName] + '=' + DD.Name;
          DriveSections.Append(s);
          ControllerSections.Append(s);
          s:=VMCOMMANDPARAMETERSUBCLASSLONG[mscAttributes] + '=' + BinStr(DD.Attribute,SizeOf(TRegisterRecord.Attribute)*8);
          DriveSections.Append(s);
          ControllerSections.Append(s);
          s:=VMCOMMANDPARAMETERSUBCLASSLONG[mscUnits] + '=' + DD.Measure;
          DriveSections.Append(s);
          ControllerSections.Append(s);
          s:=VMCOMMANDPARAMETERSUBCLASSLONG[mscLowerLimit] + '=' + DD.Min;
          DriveSections.Append(s);
          ControllerSections.Append(s);
          s:=VMCOMMANDPARAMETERSUBCLASSLONG[mscUpperLimit] + '=' + DD.Max;
          DriveSections.Append(s);
          ControllerSections.Append(s);
          s:=VMCOMMANDPARAMETERSUBCLASSLONG[mscParameterData] + '=' + DD.Value;
          // Only save immutable basic lists in controller file
          DriveSections.Append(s);
          if
          (
            (aKey=GetIDN(DRIVE_PARAMLIST))
            OR
            (aKey=GetIDN(DRIVE_MODELIST))
            OR
            (aKey='S-0-0018') // IDN-list of operation data for CP2'; Value: ''),
            OR
            (aKey='S-0-0019') // IDN-list of operation data for CP3'; Value: ''),
            OR
            (aKey='S-0-0021') // IDN-list of invalid op. data for comm. Ph. 2'; Value: ''),
            OR
            (aKey='S-0-0022') // IDN-list of invalid op. data for comm. Ph. 3'; Value: ''),
            OR
            (aKey='S-0-0025') // IDN-list of all procedure commands'; Value: ''),
          )
          then
          begin
            ControllerSections.Append(s);
          end;
        end;
      end;

      if (StoreOnDisk) then
      begin
        //if (SN<>sUN) then
        begin
          // Store drive data
          fn:=('SN_'+SN+'.par');
          IniFile:=TMemIniFile.Create(fn);
          try
            TMemIniFile(IniFile).Clear;
            TMemIniFile(IniFile).SetStrings(DriveSections);
          finally
            IniFile.UpdateFile;
            IniFile.Free;
          end;
        end;
        //if (CT<>sUN) then
        begin
          // Store controller data
          fn:=('CT_'+CT+'.par');
          IniFile:=TMemIniFile.Create(fn);
          try
            TMemIniFile(IniFile).Clear;
            TMemIniFile(IniFile).SetStrings(ControllerSections);
          finally
            IniFile.UpdateFile;
            IniFile.Free;
          end;
        end;
      end;
    finally
      if (StoreOnDisk) then
      begin
        ControllerSections.Free;
        DriveSections.Free;
      end;
    end;
  end;

  // Delete temporary drive list

  ClearRegisterData(IDNIniList);
  IDNIniList.Free;
end;

procedure TForm1.panelDriveVelocityResize(Sender: TObject);
begin
  if (Assigned(ActualVelocityDisplay) AND Assigned(SetVelocityDisplay)) then
  begin
    ActualVelocityDisplay.Top:=1;
    ActualVelocityDisplay.Left:=0;
    ActualVelocityDisplay.Width:=(TControl(Sender).Width DIV 2)-6;
    ActualVelocityDisplay.Height:=(TControl(Sender).Height {DIV 2})-2-16;

    SetVelocityDisplay.Top:=ActualVelocityDisplay.Top;
    SetVelocityDisplay.Left:=ActualVelocityDisplay.Width+ActualVelocityDisplay.Left+12;
    SetVelocityDisplay.Width:=ActualVelocityDisplay.Width;
    SetVelocityDisplay.Height:=ActualVelocityDisplay.Height;
  end;
end;

procedure TForm1.selectDirectionClick(Sender: TObject);
begin
  //dfgdfg
  if (TRadioGroup(Sender).ItemIndex=0) then
  begin
  end;
end;

procedure TForm1.selectDirectionSelectionChanged(Sender: TObject);
var
  DT:TColor;
  JogOnly:boolean;
begin
  JogOnly:=(TRadioGroup(Sender).ItemIndex=2);

  shapeArrowUp.Visible:=((TRadioGroup(Sender).ItemIndex=0) OR (JogOnly));
  shapeArrowDown.Visible:=((TRadioGroup(Sender).ItemIndex=0) OR (JogOnly));
  shapeArrowRight.Visible:=((TRadioGroup(Sender).ItemIndex=1) OR (JogOnly));
  shapeArrowLeft.Visible:=((TRadioGroup(Sender).ItemIndex=1) OR (JogOnly));

  shapeArrowUp.ShowHint:=JogOnly;
  shapeArrowDown.ShowHint:=JogOnly;
  shapeArrowRight.ShowHint:=JogOnly;
  shapeArrowLeft.ShowHint:=JogOnly;

  if (JogOnly) then DT:=clBlue else DT:=clLime;
  shapeArrowUp.Brush.Color:=DT;
  shapeArrowDown.Brush.Color:=DT;
  shapeArrowRight.Brush.Color:=DT;
  shapeArrowLeft.Brush.Color:=DT;

  labelDist.Enabled:=(NOT JogOnly);
  editDist.Enabled:=(NOT JogOnly);
  labelFeed.Enabled:=(NOT JogOnly);
  editFeed.Enabled:=(NOT JogOnly);

  btnMove.Enabled:=(NOT JogOnly);

  editReps.Enabled:=(NOT JogOnly);
end;

function TForm1.GetAxisActive:TAXIS;
begin
  result:=TAXIS.axisNone;
  if (selectDirection.ItemIndex=0) then result:=TAXIS.axisOne;
  if (selectDirection.ItemIndex=1) then result:=TAXIS.axisTwo;
end;

procedure TForm1.InitMain(Data: PtrInt);
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
      cmboSerialPortsChange(cmboSerialPorts);
      break;
    end;
    Inc(i);
  end;
  {$endif UNIX}
end;

function TForm1.ProcessParameter(const CD:TPARAMETERDATA;out response:RawByteString; prio:boolean=false; blocking:boolean=false; verbose:boolean=false):boolean;
var
  s,c      : RawByteString;
  success  : boolean;
  ro       : boolean;
  LocalCD  : TPARAMETERDATA;
  StoreCD  : TPARAMETERDATA;
  wp,wb    : boolean;
  SISData  : SISTelegram;
  l,i      : Integer;
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
  end
  else
  begin
    StoreCD:=LoadCLCRegisterData(LocalCD);
    s:=StoreCD.DATA;
  end;

  if s=sERR then
  begin
    Memo1.Lines.Append('Command not known !!');
    response:='Command not known error !!';
    exit;
  end;

  if verbose OR DirectDrive then
  begin
    if (NOT ro) then
      Memo1.Lines.Append('Write command: '+s+'. Value: '+CD.DATA)
    else
      Memo1.Lines.Append('Read command: '+s+'.');
  end;

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
  if ((LocalCD.CCLASS=ccNone) AND (LocalCD.CCLASSCHAR=VMCOMMANDCLASS[ccRegister])) then LocalCD.SETID:=0;  // Register: always SetID=0

  c:=GetCLCCommandString(LocalCD);
  s:=LocalCD.DATA;

  if (ActiveSerialConnection=TCONNECTION.conCLCDDE) then
  begin
    {$ifdef MSWindows}
    ProcessDDECommand(c,s,wp,wb);
    success:=true;
    {$endif}
  end
  else
  begin
    if DirectDrive then
    begin
      c:=GetDirectDriveCommand(LocalCD);
      success:=ProcessDirectDriveCommand(c,s,wp,wb);
    end
    else
    if SISDrive then
    begin
      BuildSISTelegram(LocalCD,SISData,l);
      (ComDevice AS TLazSerial).ProcessSIS(@SISData,l);
      s:='';
      if l>0 then
      begin
        SetLength(s,l);
        for i:=1 to l do s[i]:=Chr(SISData[i]);
      end;
    end
    else
    begin
      success:=ProcessSerialCommand(c,s,wp,wb);
    end;
  end;

  response:=s;
  result:=success;
end;

procedure TForm1.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  //lblTime.Caption:=FormatDateTime('dd-mm-yyyy "UTC: "hh"h"-nn"m"-ss"s"', NowUTC);
  Done:=true;
end;

procedure TForm1.ProcessDR11(const CD: TPARAMETERDATA);
var
  DR11          : TDRIVEPARAMETER_0011;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=GetDriveAddress(ActiveDriveNumber)) then
  begin
    DR11.Raw:=BinaryStringToDecimal(CD.DATA);
  end;
end;

procedure TForm1.ProcessDR12(const CD: TPARAMETERDATA);
var
  DR12          : TDRIVEPARAMETER_0012;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=GetDriveAddress(ActiveDriveNumber)) then
  begin
    DR12.Raw:=BinaryStringToDecimal(CD.DATA);
  end;
end;

procedure TForm1.ProcessDR13(const CD: TPARAMETERDATA);
var
  DR13          : TDRIVEPARAMETER_0013;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=GetDriveAddress(ActiveDriveNumber)) then
  begin
    DR13.Raw:=BinaryStringToDecimal(CD.DATA);
  end;
end;

procedure TForm1.ProcessDR14(const CD: TPARAMETERDATA);
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

    PDI:=GetPDriveInfo(ActiveDriveNumber);
    if (PDI^.PHASE<>DP14.Data.CommPhase) then
    begin
      PDI^.PHASE:=DP14.Data.CommPhase;
    end;
  end;
end;

procedure TForm1.ProcessDR134(const CD: TPARAMETERDATA);
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

procedure TForm1.ProcessDR135(const CD: TPARAMETERDATA);
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

procedure TForm1.ProcessDR182(const CD: TPARAMETERDATA);
var
  DR182          : TDRIVEPARAMETER_0182;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  exit;
  if (CD.SETID=GetDriveAddress(ActiveDriveNumber)) then
  begin
    DR182.Raw:=BinaryStringToDecimal(CD.DATA);
    SetInfoPanel(panelInPosition,(DR182.Data.EndPosition=1));
    SetInfoPanel(panelStandstill,(DR182.Data.Velocity=1));
    SetInfoPanel(panelTargetPosition,(DR182.Data.InTargetPosition=1));
  end;
end;

procedure TForm1.ProcessRealtimeData(const CD: TPARAMETERDATA);
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=GetDriveAddress(ActiveDriveNumber)) then
  begin
    with DRIVE_SET_SPEED do if ((CD.CCLASS=CCLASS) AND (CD.NUMID=NUMID)) then ActualVelocityDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);
    with DRIVE_ACTUAL_SPEED do if ((CD.CCLASS=CCLASS) AND (CD.NUMID=NUMID)) then SetVelocityDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);
    with DRIVE_POSITIONCOMMAND do if ((CD.CCLASS=CCLASS) AND (CD.NUMID=NUMID)) then PositionDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);
    with DRIVE_POSITIONFEEDBACK do if ((CD.CCLASS=CCLASS) AND (CD.NUMID=NUMID)) then FeedbackDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);
    //with DRIVE_FOLLOWINGERROR do if ((CD.CCLASS=CCLASS) AND (CD.NUMID=NUMID)) then FeedbackDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);
    with DRIVE_TARGET do if ((CD.CCLASS=CCLASS) AND (CD.NUMID=NUMID)) then TargetDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);
    with DRIVE_DISTANCE do if ((CD.CCLASS=CCLASS) AND (CD.NUMID=NUMID)) then DistanceDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);


    SetInfoPanel(panelStandstill,(SetVelocityDisplay.Value<10));
    SetInfoPanel(panelInPosition,((Abs(PositionDisplay.Value-TargetDisplay.Value)<1)));
    //SetInfoPanel(panelTargetPosition,(DR182.Data.InTargetPosition=1));

  end;
end;

function TForm1.GetPrio(const CD:TPARAMETERDATA):boolean;
begin
  result:=false;
end;

function TForm1.GetBlocking(const CD:TPARAMETERDATA):boolean;
begin
  result:=false;
end;

procedure TForm1.SetActiveConnection(value : TCONNECTION);
begin
  if (value<>FActiveSerialConnection) then
  begin
    FActiveSerialConnection:=value;
    if (FActiveSerialConnection<>TCONNECTION.conNone) then
    begin
      DCStatus:=TDATACOLLECTION.dcBasic;
    end;

  end;
end;

procedure TForm1.OnRXUSBCData(Sender: TObject);
begin
  OnCommData(ComDevice.Data);
end;

{$ifdef MSWindows}
procedure TForm1.OnRXDDEData(Sender: TObject);
begin
  OnCommData(ComDevice.Data);
end;
{$endif}

procedure TForm1.OnCommData(const s:ansistring);
var
  CD        : TPARAMETERDATA;
  CDResult  : TPARAMETERDATA;
begin
  Memo1.Lines.Append('Received: '+s);
  CD:=Default(TPARAMETERDATA);
  CDResult:=ProcessNormalResponse(CD,DirectDrive,s);
  ProcessCommResult(CDResult);
end;

procedure TForm1.ProcessCommResult(const CD:TPARAMETERDATA);
var
  rt,list  : boolean;
  i,len    : word;
  success  : boolean;
  CC       : TPARAMETER;
  s        : RawByteString;
  ATT      : ATTRIBUTEDWORD;
  LocalCD  : TPARAMETERDATA;
  IDNCD    : TPARAMETERDATA;
begin
  LocalCD:=CD;

  if ((LocalCD.CCLASS=ccNone) OR (Length(LocalCD.ERROR)>0)) then
  begin
    s:=LocalCD.DATA;
    //if (Length(s)=0) then
    begin
      i:=HexStringToDecimal(LocalCD.ERROR);
      s:=GetDriveErrorDescription(i);
    end;
    exit;
  end;

  if ((LocalCD.CCLASS=ccNone) AND (LocalCD.CCLASSCHAR=VMCOMMANDCLASS[ccRegister])) then
  begin
    // SETID is always 0 with ccRegister
    // TODO: handle it
  end
  else
  begin
    if (LocalCD.SETID=0) then
    begin
      raise EArgumentException.Create ('Could not determine drive address from command data.');
    end;
  end;

  list:=false;
  ATT.Raw:=GetDriveAttribute(LocalCD);
  list:=((ATT.Data.List=1) AND (ATT.Data.DataLength<>0));
  if (list AND (NOT DirectDrive) AND (LocalCD.CSUBCLASS=mscParameterData)) then
  begin
    // While getting paramater data, we got a list according to its attribute!
    // Ask for its real data
    LocalCD.CSUBCLASS:=mscList;
    LocalCD.STEPID:=STEPLISTSTART;
    LocalCD.DATA:='';
    success:=ProcessParameter(LocalCD,s,true,false);
    exit;
  end;

  if (CD.DATA='ERROR') then exit;

  rt:=false;

  if (NOT (LocalCD.CSUBCLASS in [mscBlock,mscList])) then
  begin
    // We handle lists later
    SaveDriveRegisterData(LocalCD);
  end;

  // Handle parameter data for GUI
  if ((LocalCD.CSUBCLASS=mscParameterData) AND (NOT LocalCD.MEMORY)) then
  begin

    for CC in REALTIMEDRIVEDATA do
    begin
      if ((CC.CCLASS = LocalCD.CCLASS) AND (CC.CSUBCLASS = LocalCD.CSUBCLASS) AND (CC.NUMID = LocalCD.NUMID)) then
      begin
        rt:=true;
        break;
      end;
    end;

    with DRIVE_INTERFACE do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))           then ProcessDR14(LocalCD);
    with DRIVE_CONTROLWORD do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))         then ProcessDR134(LocalCD);
    with DRIVE_STATUSWORD do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))          then ProcessDR135(LocalCD);

    with DRIVE_POSITIONCOMMAND do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))     then ProcessRealtimeData(LocalCD);
    with DRIVE_TARGET do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))              then ProcessRealtimeData(LocalCD);
    with DRIVE_DISTANCE do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))            then ProcessRealtimeData(LocalCD);
    with DRIVE_POSITIONFEEDBACK do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))    then ProcessRealtimeData(LocalCD);
    with DRIVE_ACTUAL_SPEED do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))        then ProcessRealtimeData(LocalCD);
    with DRIVE_SET_SPEED do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))           then ProcessRealtimeData(LocalCD);

    with DRIVE_DIAGNOSTIC_CLASS1 do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))   then ProcessDR11(LocalCD);
    with DRIVE_DIAGNOSTIC_CLASS2 do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))   then ProcessDR12(LocalCD);
    with DRIVE_DIAGNOSTIC_CLASS3 do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))   then ProcessDR13(LocalCD);

    with DRIVE_MANUFACTURER_DIAGNOSTIC_CLASS3 do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))   then ProcessDR182(LocalCD);

  end;

  if (LocalCD.CSUBCLASS<>mscList) then
  begin
    if (NOT rt) then
    begin
      editStatus.Text:=GetIDN(LocalCD)+'. Drive '+InttoStr(LocalCD.SETID)+' '+LowerCase(VMCOMMANDPARAMETERSUBCLASSLONG[LocalCD.CSUBCLASS])+' update: '+LocalCD.DATA;
    end;
  end;

  // Handle all list data that we asked for by ourselves
  if (LocalCD.CSUBCLASS=mscList) then
  begin
    list:=false;

    if (NOT DirectDrive) then
    begin
      // Only store real list data
      if ((LocalCD.DATA<>sLISTFINISHED) AND (LocalCD.STEPID<>STEPLISTSTART) AND (LocalCD.STEPID>0)) then SaveDriveRegisterData(LocalCD);

      if (LocalCD.STEPID=STEPLISTSTART) then
      begin
        // We got then length of the list !
        // Now send commands to get the contents of the list itself
        len:=StringToIntSafe(LocalCD.DATA);
        if (len>0) then
        begin
          editStatus.Tag:=len;
          for i:=1 to (len+1) do // +1 = close the list
          begin
            LocalCD.STEPID:=i;
            LocalCD.DATA:='';
            success:=ProcessParameter(LocalCD,s);
          end;
          exit;
        end;
      end;

      if ((LocalCD.STEPID<>STEPLISTSTART) AND (LocalCD.STEPID>0)) then
      begin
        if (LocalCD.DATA=sLISTFINISHED) then
        begin
          // List is finished, so process it !
          // First, retrieve the complete list from the store
          LocalCD:=LoadDriveRegisterData(LocalCD);
          list:=True;
        end
        else
        begin
          if ((LocalCD.CCLASS=DRIVE_PARAMLIST.CCLASS) AND (LocalCD.NUMID=DRIVE_PARAMLIST.NUMID)) then
          begin
            // While IDN list item is received, update the item itself and the GUI
            IDNCD:=IDN2CD(LocalCD.DATA,LocalCD.SETID);
            // The save command automagically sets default values
            // Reload the data again with all the default values
            SaveDriveRegisterData(IDNCD);
            editStatus.Text:='Adding IDN #'+InttoStr(LocalCD.STEPID)+' from # '+InttoStr(editStatus.Tag)+' of drive '+InttoStr(LocalCD.SETID)+' into IDN list.';
          end;
        end;
      end;
    end;

    if (DirectDrive) then
    begin
      // We receive all list data at once
      // So, store it and use it !!
      SaveDriveRegisterData(LocalCD);
      list:=True
    end;
  end;

end;

procedure TForm1.ArrowMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ArrowMouse(Sender, Button, Shift, X, Y);
  while (MouseUpEvent.WaitFor(10)=wrTimeout) do
  begin
    Application.ProcessMessages;
  end;
  ArrowMouse(Sender, Button, [], X, Y);
  MouseUpEvent.ResetEvent;
end;

procedure TForm1.ArrowMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MouseUpEvent.SetEvent;
end;


procedure TForm1.ArrowMouse(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  aDir:TAXISDIRECTION;
begin
  if (AxisActive=axisNone) then
  begin
    if (Button=TMouseButton.mbLeft) then
    begin
      aDir:=TAXISDIRECTION.dirNone;
      if (Sender=shapeArrowUp) then aDir:=TAXISDIRECTION.dirUp;
      if (Sender=shapeArrowDown) then aDir:=TAXISDIRECTION.dirDown;
      if (Sender=shapeArrowLeft) then aDir:=TAXISDIRECTION.dirLeft;
      if (Sender=shapeArrowRight) then aDir:=TAXISDIRECTION.dirRight;
      JogAxis(aDir,(ssLeft in Shift));
    end;
  end;
end;

function TForm1.JogAxis(aDir:TAXISDIRECTION;Engage:boolean):boolean;
var
  s              : RawByteString;
  axis           : integer;
  success        : boolean;
  AxisControl    : TSERCOSREGISTER_AXISCONTROL;
  TaskJogControl : TSERCOSREGISTER_TASKJOGCONTROL;
  CD             : TPARAMETERDATA;
  DriveMode      : TOPERATIONMODE;
  DR4056         : TDRIVEPARAMETER_4056;
begin
  result:=false;
  success:=false;

  if CheckComms then exit;

  if (aDir=TAXISDIRECTION.dirNone) then exit;

  if aDir in [TAXISDIRECTION.dirUp,TAXISDIRECTION.dirDown] then
  begin
    axis:=0;
  end;
  if aDir in [TAXISDIRECTION.dirLeft,TAXISDIRECTION.dirRight] then
  begin
    axis:=1;
  end;

  CD:=Default(TPARAMETERDATA);

  if DirectDrive then
  begin
    // Tricky, we might move axis that is not active !!
    DriveMode:=GetDriveMode(GetPDriveInfo(ActiveDriveNumber)^.MODE);
    // This should not be necessary.
    // Drive should switch to jogmode automagically if one of the jog-inputs is set !!
    //if (DriveMode in [omJM]) then
    begin
      CD.NUMID:=4056;
      CD.CCLASS:=ccDriveSpecific;
      CD.CSUBCLASS:=mscParameterData;
      CD.SETID:=axis;
      CD.STEPID:=0;
      DR4056.Raw:=0;
      if Engage then
      begin
        if aDir in [TAXISDIRECTION.dirUp,TAXISDIRECTION.dirRight] then DR4056.Data.JogPositive:=1;
        if aDir in [TAXISDIRECTION.dirDown,TAXISDIRECTION.dirLeft] then DR4056.Data.JogNegative:=1;
      end;
      CD.DATA:=DecimalToBinaryString(DR4056.Raw,DirectDrive);
      success:=ProcessParameter(CD,s);
    end;
  end
  else
  begin
    TaskJogControl.Raw:=0;
    AxisControl.Raw:=0;
    if Engage then
    begin
      with TaskJogControl.Data do
      begin
        JogType:=%01; //Joint Jog
        ContinuousnStep:=1;
        if aDir = TAXISDIRECTION.dirUp then // TaskJogControl.Raw:=261;
        begin
          CoordinateJogReverse := 1;
          JogXCoordinate       := 1;
        end;
        if aDir = TAXISDIRECTION.dirDown then // TaskJogControl.Raw:=259;
        begin
          CoordinateJogForward := 1;
          JogXCoordinate       := 1;
        end;
        if aDir = TAXISDIRECTION.dirLeft then // TaskJogControl.Raw:=517;
        begin
          CoordinateJogReverse := 1;
          JogYCoordinate       := 1;
        end;
        if aDir = TAXISDIRECTION.dirRight then // TaskJogControl.Raw:=515;
        begin
          CoordinateJogForward := 1;
          JogYCoordinate       := 1;
        end;
      end;
      if aDir in [TAXISDIRECTION.dirUp,TAXISDIRECTION.dirLeft] then AxisControl.Data.JogForward:=1;
      if aDir in [TAXISDIRECTION.dirDown,TAXISDIRECTION.dirRight] then AxisControl.Data.JogReverse:=1;
    end;

    CD.CCLASSCHAR:=VMCOMMANDCLASS[ccRegister];
    CD.CSUBCLASSCHAR:=VMREGISTERSUBCLASS[rscDecimalState];
    CD.DATA:=InttoStr(TaskJogControl.Raw);
    CD.NUMID:=7; // Task A jog control
    success:=ProcessParameter(CD,s);

    CD.CCLASSCHAR:=VMCOMMANDCLASS[ccRegister];
    CD.CSUBCLASSCHAR:=VMREGISTERSUBCLASS[rscDecimalState];
    CD.DATA:=InttoStr(AxisControl.Raw);
    CD.NUMID:=(11+axis); // Axis control
    success:=ProcessParameter(CD,s);
  end;

  result:=success;
end;

function TForm1.GetDirectDrive:boolean;
begin
  result:=ActiveSerialConnection in [conASCIIDDRS232,conASCIIDDRS485];
end;

function TForm1.GetSISDrive:boolean;
begin
  result:=ActiveSerialConnection in [conSISDDRS232,conSISDDRS485];
end;

function TForm1.GetVisualMotion:boolean;
begin
  result:=ActiveSerialConnection in [conCLCRS232,conCLCRS485{,conCLCDDE}];
end;

procedure TForm1.SetActiveDriveNumber(value:word);
var
  Success      : boolean;
  c,s          : RawByteString;
  CD,StatusCD  : TPARAMETERDATA;
  SC0393       : TDRIVEPARAMETER_0393;
  SISData      : SISTelegram;
  l,i          : integer;
begin
  if (value<>FActiveDriveNumber) then
  begin
    FActiveDriveNumber:=value;

    if (FActiveDriveNumber>0) then
    begin
      if CheckComms then exit;

      if DirectDrive then
      begin
        // Select drive to activate serial port for that drive
        // BCD = Bus Change Drive
        c:=Format('BCD:%.2d',[GetPDriveInfo(ActiveDriveNumber)^.DRIVEADDRESS]);
        s:='';
        Success:=ProcessDirectDriveCommand(c,s,false,true);
        Memo1.Lines.Append('Select drive ASCII response: '+s);
        c:=Format('E%.2d:>',[GetPDriveInfo(ActiveDriveNumber)^.DRIVEADDRESS]);
        if s=c then Memo1.Lines.Append('Selected drive connected !');
      end;

      if SISDrive then
      begin
        FillChar({%H-}SISData,SizeOf(SISData),0);
        // Init/activate SIS serial bus for comms
        // Might be superfluous after the first time
        BuildSISCommand(SISServiceInitSISCommunications,SISSubServiceSettingBaud,GetDriveAddress(ActiveDriveNumber),0,SISData,l);
        s:='';
        if l>0 then
        begin
          for i:=1 to l do
          begin
            s:=s+InttoStr(SISData[i])+',';
          end;
        end;
        (ComDevice AS TLazSerial).ProcessSIS(@SISData,l);
        s:='';
        if l>0 then
        begin
          SetLength(s,l);
          for i:=1 to l do s[i]:=Chr(SISData[i]);
        end;
        Memo1.Lines.Append('Select drive SIS response: '+s);
      end;

      if SISDrive OR DirectDrive then
      begin
        CD:=Default(TPARAMETERDATA);
        CD.CSUBCLASS:=mscParameterData;
        CD.CCLASS:=ccDrive;
        CD.SETID:=GetDriveAddress(ActiveDriveNumber);

        // Serial config
        (*
        CD.CCLASS:=ccDriveSpecific;
        CD.NUMID:=4021; // Baud Rate
        CD.DATA:='0';
        Success:=ProcessParameter(CD,s,false,true);
        Memo1.Lines.Append(s);

        CD.NUMID:=4050; //  Delay answer
        CD.DATA:='10';
        Success:=ProcessParameter(CD,s,false,true);
        Memo1.Lines.Append(s);

        CD.CCLASS:=ccDrive;
        CD.NUMID:=265;  //  Language Selection
        CD.DATA:='1';
        Success:=ProcessParameter(CD,s,false,true);
        Memo1.Lines.Append(s);
        *)


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
        CD:=SetCommand(DRIVE_COMMANDMODE);
        CD.SETID:=GetDriveAddress(ActiveDriveNumber);
        CD.DATA:='';
        s:='';
        success:=ProcessParameter(CD,s,false,true);
        StatusCD:=ProcessNormalResponse(CD,DirectDrive,s);
        SC0393.Raw:=BinaryStringToDecimal(StatusCD.DATA);
        if (SC0393.Data.TargetPosAfter=0) then
        begin
          SC0393.Data.TargetPosAfter:=1;
          CD.DATA:=DecimalToBinaryString(SC0393.Raw,DirectDrive);
          success:=ProcessParameter(CD,s,false,true);
        end;

        // Deactivate resident memory mode to preserve EEPROM
        // Might be decided by global switch
        CD.NUMID:=269;
        CD.DATA:='1';
        s:='';
        success:=ProcessParameter(CD,s,false,true);

      end;
    end;
  end;
end;

end.

