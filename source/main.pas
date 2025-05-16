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

type
  TCONNECTION                       = (conNone,conDDRS232,conDDRS485,conCLCDDE,conCLCRS232,conCLCRS485);
  TAXISDIRECTION                    = (dirNone,dirLeft,dirRight,dirUp,dirDown);
  TAXIS                             = (axisNone,axisOne,axisTwo);
  TDATACOLLECTION                   = (dcNone,dcBasic,dcModes,dcIDN,dcIDNData,dcIDNAttribute);


  { TForm1 }
  TForm1 = class(TForm)
    btnAxisHome: TButton;
    btnAxisStatus: TButton;
    btnClearErrors: TButton;
    btnConnectDDE: TButton;
    btnConnectDriveRS232: TButton;
    btnDriveInfo: TButton;
    btnGetEvents: TButton;
    btnGetLists: TButton;
    btnManualAxis: TButton;
    btnMove: TButton;
    btnPhase2: TButton;
    btnPhase3: TButton;
    btnPhase4: TButton;
    btnResetAxis: TButton;
    btnConnectDriveRS485: TButton;
    btnSendReceive: TButton;
    btnSetMode: TButton;
    btnSpeedLimit: TButton;
    btnStart: TButton;
    btnTest: TButton;
    btnStartTaskA: TButton;
    btnGetPoints: TButton;
    btnRefreshDriveData: TButton;
    btnConnectVMRS232: TButton;
    Button1: TButton;
    btnStop: TButton;
    btnGetDriveData: TButton;
    chkAutoLoadDriveData: TCheckBox;
    cmboSerialPorts: TComboBox;
    comboDriveModes: TComboBox;
    editStatus: TEdit;
    editCommand: TEdit;
    editValue: TEdit;
    grpDriveDashBoard: TGroupBox;
    grpDriveInfo: TGroupBox;
    grpDriveStatus: TGroupBox;
    lbDriveModes: TListBox;
    lblTime: TLabel;
    panelDriveFeedback: TPanel;
    panelDrivePosition: TPanel;
    panelDriveStatus: TPanel;
    PanelControl: TPanel;
    PanelEnable: TPanel;
    PanelHalt: TPanel;
    panelInPosition: TPanel;
    PanelPhase2: TPanel;
    PanelPhase3: TPanel;
    PanelPhase4: TPanel;
    PanelPower: TPanel;
    panelStandstill: TPanel;
    panelTargetPosition: TPanel;
    shapeAlive: TShape;
    stDriveName: TStaticText;
    stDriveAddress: TStaticText;
    stControllerType: TStaticText;
    stFirmware: TStaticText;
    stDriveDiagnostic: TStaticText;
    stMotorSerial: TStaticText;
    stMotorType: TStaticText;
    synDataUpdate: TSynEdit;
    editAccel: TEdit;
    editDist: TEdit;
    editReps: TEdit;
    editDLLFileName: TEdit;
    editSpeed: TEdit;
    grpAxisCommands: TGroupBox;
    grpSettings: TGroupBox;
    labelAccel: TLabel;
    labelDist: TLabel;
    labelReps: TLabel;
    labelSpeed: TLabel;
    lbSERCOSCOMMANDS: TListBox;
    lbSERCOSPARAMS: TListBox;
    lbVMAXISCOMMANDS: TListBox;
    lbVMREGISTERS: TListBox;
    lbVMSYSTEMCOMMANDS: TListBox;
    lbVMTASKCOMMANDS: TListBox;
    lvParameters: TListView;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    DDL: TMenuItem;
    pageRawCommands: TPageControl;
    PageControl2: TPageControl;
    EventEditor: TValueListEditor;
    rgSubClass: TRadioGroup;
    selectDirection: TRadioGroup;
    Serial: TMenuItem;
    Options: TMenuItem;
    OpenDialog1: TOpenDialog;
    shapeBase: TShape;
    shapeWork: TShape;
    shapeStar: TShape;
    shapeArrowUp: TShape;
    shapeArrowDown: TShape;
    shapeArrowRight: TShape;
    shapeArrowLeft: TShape;
    TabControl1: TTabControl;
    tabRawCommands: TTabSheet;
    tabMove: TTabSheet;
    tabProgramme: TTabSheet;
    TabSheet1: TTabSheet;
    tabVMAxis: TTabSheet;
    tabVMControl: TTabSheet;
    tabVMDrive: TTabSheet;
    tabVMRegister: TTabSheet;
    tabVMTask: TTabSheet;
    Timer1: TTimer;
    UpDownDriveAddress: TUpDown;
    ValueListEditor1: TValueListEditor;
    PointTableEditor: TValueListEditor;
    vleParamDetails: TValueListEditor;
    procedure btnAxisHomeClick({%H-}Sender: TObject);
    procedure btnAxisCommandClick(Sender: TObject);
    procedure btnAxisStatusClick({%H-}Sender: TObject);
    procedure btnConnectSerialClick(Sender: TObject);
    procedure btnGetTableClick(Sender: TObject);
    procedure btnMoveClick({%H-}Sender: TObject);
    procedure btnRefreshDriveDataClick({%H-}Sender: TObject);
    procedure btnResetAxisClick({%H-}Sender: TObject);
    procedure btnConnectDDEClick({%H-}Sender: TObject);
    procedure btnSendReceiveClick({%H-}Sender: TObject);
    procedure btnSetModeClick({%H-}Sender: TObject);
    procedure btnSpeedLimitClick({%H-}Sender: TObject);
    procedure btnStartClick({%H-}Sender: TObject);
    procedure btnStartTaskAClick({%H-}Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnTestClick({%H-}Sender: TObject);
    procedure btnGetListsClick({%H-}Sender: TObject);
    procedure btnManualAxisClick({%H-}Sender: TObject);
    procedure btnDriveInfoClick({%H-}Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnGetDriveDataClick(Sender: TObject);
    procedure cmboSerialPortsChange({%H-}Sender: TObject);
    procedure editDistKeyPress(Sender: TObject; var Key: char);
    procedure editStatusChange(Sender: TObject);
    procedure lvParametersSelectItem({%H-}Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure MenuConnectionClick(Sender: TObject);
    procedure editDLLFileNameClick(Sender: TObject);
    procedure lbCOMMANDSDblClick(Sender: TObject);
    procedure pageRawCommandsChange(Sender: TObject);
    procedure FormCreate({%H-}Sender: TObject);
    procedure FormDestroy({%H-}Sender: TObject);
    procedure panelDriveFeedbackResize(Sender: TObject);
    procedure selectDirectionClick(Sender: TObject);
    procedure selectDirectionSelectionChanged(Sender: TObject);
    procedure ArrowMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ArrowMouseUp({%H-}Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
    procedure TabControl1Change(Sender: TObject);
    procedure Timer1Timer({%H-}Sender: TObject);
    procedure UpDownDriveAddressClick(Sender: TObject; Button: TUDBtnType);
    procedure ValueListEditor1DblClick(Sender: TObject);
    procedure vleParamDetailsDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure vleParamDetailsEditingDone(Sender: TObject);
    procedure vleParamDetailsSelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
  private
    { private declarations }
    FActiveConnection      : TCONNECTION;
    FActiveDrive           : word;
    FDirectDrive           : boolean;
    FDataFormatSettings    : TFormatSettings;
    FComDevice             : ICommInterface;
    FDCStatus              : TDATACOLLECTION;

    VelocityDisplay        : TdsSevenSegmentMultiDisplay;
    PositionDisplay        : TdsSevenSegmentMultiDisplay;
    ForceDisplay           : TdsSevenSegmentMultiDisplay;

    MouseUpEvent           : TSimpleEvent;


    procedure IDNCompare(Sender: TObject; Item1, Item2: TListItem; {%H-}Data: Integer; var Compare: Integer);
    procedure ShowDataUpdateInfo(s:string);
    procedure SetActiveConnection(value : TCONNECTION);

    function  GetDrive:TDRIVE;
    procedure SetDrive(value:TDRIVE);

    procedure InitMain({%H-}Data: PtrInt);
    procedure SetInfoPanel(aPanel:TPanel;Status:boolean);
    function  CommandExecuteAndWait(const aCD: TCOMMANDDATA):boolean;
    {$ifdef MSWindows}
    procedure HandleInfo(var Msg: TLMessage); message WM_DDEINFO;
    function  ProcessDDECommand(const Command:string; var Value:string; const prio,blocking:boolean):boolean;
    {$endif}
    function  ProcessSerialCommand(const Command:string; var Value:string; const prio,blocking:boolean):boolean;
    function  ProcessDirectDriveCommand(const Command:string; var Value:string; const prio,blocking:boolean):boolean;
    procedure ArrowMouse(Sender: TObject; Button: TMouseButton; Shift: TShiftState; {%H-}X, {%H-}Y: Integer);
    function  GetAxisActive:TAXIS;
    procedure ApplicationIdle({%H-}Sender: TObject; var Done: Boolean);
    function  ConnectDDE:boolean;
    function  ConnectRS232:boolean;
    function  CheckAxis(out axis:word):boolean;
    function  MoveAxis:boolean;
    function  SpindleAxis(Reps:word = 1):boolean;
    property  DataFormatSettings:TFormatSettings read FDataFormatSettings;
    property  AxisActive:TAXIS read GetAxisActive;
    property  DirectDrive : boolean read FDirectDrive;
    property  ActiveConnection : TCONNECTION read FActiveConnection write SetActiveConnection;
    property  ActiveDrive : word read FActiveDrive write FActiveDrive;
    property  ActiveDriveInfo : TDrive read GetDrive write SetDrive;

    procedure OnRXUSBCData({%H-}Sender: TObject);
    {$ifdef MSWindows}
    procedure OnRXDDEData({%H-}Sender: TObject);
    {$endif}

    function  ProcessCommDataString(s:string):TCOMMANDDATA;
    procedure ProcessCommResult(const CD:TCOMMANDDATA);

    procedure ProcessModeList(const CD: TCOMMANDDATA);
    procedure ProcessIDNList(const CD:TCOMMANDDATA);
    procedure AddIDNListItem(const CD: TCOMMANDDATA);
    procedure AddIDNListValue(const CD:TCOMMANDDATA);
    procedure SetParamDetails(const CD:TCOMMANDDATA);overload;
    procedure SetParamDetails(const RR:TRegisterRecord);overload;

    function  GetPrio(const {%H-}CD:TCOMMANDDATA):boolean;
    function  GetBlocking(const {%H-}CD:TCOMMANDDATA):boolean;

    procedure GetDriveData;
    procedure SetDriveMode;

    procedure ProcessMotorSerial(const CD:TCOMMANDDATA);

    procedure ProcessDR14(const CD: TCOMMANDDATA);
    procedure ProcessDR134(const CD: TCOMMANDDATA);
    procedure ProcessDR135(const CD: TCOMMANDDATA);
    procedure ProcessDR144(const CD: TCOMMANDDATA);
    procedure ProcessDR145(const CD: TCOMMANDDATA);
    procedure ProcessDR182(const CD: TCOMMANDDATA);
    procedure ProcessControllerType(const CD:TCOMMANDDATA);
    procedure ProcessAppType(const CD:TCOMMANDDATA);
    procedure ProcessMotorType(const CD:TCOMMANDDATA);
    procedure ProcessFirmware(const CD:TCOMMANDDATA);
    procedure ProcessDiagnostic(const CD:TCOMMANDDATA);
    procedure ProcessMode(const CD: TCOMMANDDATA);
    procedure ProcessVelocity(const CD: TCOMMANDDATA);
    procedure ProcessPosition(const CD: TCOMMANDDATA);
    procedure ProcessForce(const CD: TCOMMANDDATA);

    procedure ProcessDiskDriveData(const Drive: word; StoreOnDisk:boolean);

    procedure OnCommData(const s:string);
  public
    { public declarations }
    function  ProcessCommand(const CD:TCOMMANDDATA;out response:string; prio:boolean=false; blocking:boolean=false; verbose:boolean=false):boolean;
    function  JogAxis(aDir:TAXISDIRECTION;Engage:boolean):boolean;
  end;

var
  Form1            : TForm1;

implementation

{$R *.lfm}

uses
  StrUtils, IniFiles,
  InterfaceBase,
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
  Self.Caption := 'DriveTop'+ ' for ' + GetTargetCPUOS+ '-'+  s;

  for i:=1 to MAXDRIVES do
  begin
    FActiveDrive:=i;
    DI:=ActiveDriveInfo;
    DI:=Default(TDRIVE);
    DI.DRIVEADDRESS:=i;
    ActiveDriveInfo:=DI;
  end;
  FActiveDrive:=1;

  ActiveConnection:=conNone;
  FDirectDrive:=False;
  FDCStatus:=TDATACOLLECTION.dcNone;

  lvParameters.OnCompare:=@IDNCompare;

  //vleParamDetails.Strings.MissingNameValueSeparatorAction:=TMissingNameValueSeparatorAction.mnvaEmpty;
  for i:=0 to Pred(vleParamDetails.RowCount) do
  begin
    vleParamDetails.ItemProps[i].ReadOnly:=true;
  end;
  // Value might be edited
  i:=Pred(vleParamDetails.RowCount);
  vleParamDetails.ItemProps[i].ReadOnly:=false;

  synDataUpdate.Font.Size:=8;
  ShowDataUpdateInfo('Data update log screen.');

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
    OnColor:=clAqua;
    OffColor:=ChangeBrightness(OnColor,0.1);
    DisplayCount:=7;
    BorderWidth:=4;
    //Anchors:=[akLeft,akRight];
    //AnchorSide[akLeft].Control:=nil;
    //AnchorSide[akTop].Control:=nil;
    Align:=alClient;
    Hint:='Drive position';
    ShowHint:=True;
  end;

  VelocityDisplay:=TdsSevenSegmentMultiDisplay.Create(panelDriveFeedback);
  with VelocityDisplay do
  begin
    Parent:=panelDriveFeedback;
    OnColor:=clRed;
    OffColor:=ChangeBrightness(OnColor,0.1);
    BorderWidth:=2;
    //Anchors:=[akLeft,akRight];
    //AnchorSide[akLeft].Control:=nil;
    //AnchorSide[akTop].Control:=nil;
    //Align:=alNone;
    Hint:='Drive speed';
    ShowHint:=True;
  end;
  ForceDisplay:=TdsSevenSegmentMultiDisplay.Create(panelDriveFeedback);
  with ForceDisplay do
  begin
    Parent:=panelDriveFeedback;
    OnColor:=clYellow;
    OffColor:=ChangeBrightness(OnColor,0.1);
    BorderWidth:=2;
    //Anchors:=[akLeft,akRight];
    //AnchorSide[akLeft].Control:=nil;
    //AnchorSide[akTop].Control:=nil;
    //Align:=alNone;
    Hint:='Drive force/torque';
    ShowHint:=True;
  end;

  ActiveConnection:=conNone;
  FComDevice:=nil;

  MouseUpEvent:=TSimpleEvent.Create;

  Memo1.Append(DateTimeToStr(NowUTC)+' : '+'System started.');

  for i:=0 to Pred(CLCRegisterDataCount(0)) do
  begin
    DD:=LoadCLCRegisterDataRaw(0,i)^;
    if DD.CClass=ccControl then
    begin
      s:=Format('S-0-%.4d', [DD.IDN.Data.ParamNum]);
      lbVMSYSTEMCOMMANDS.Items.AddObject(s+' : '+DD.Name,TObject(PtrInt(DD.IDN.Data.ParamNum)));
    end;
    if DD.CClass=ccAxis then
    begin
      s:=Format('A-0-%.4d', [DD.IDN.Data.ParamNum]);
      lbVMAXISCOMMANDS.Items.AddObject(s+' : '+DD.Name,TObject(PtrInt(DD.IDN.Data.ParamNum)));
    end;
    if DD.CClass=ccTask then
    begin
      s:=Format('T-0-%.4d', [DD.IDN.Data.ParamNum]);
      lbVMTASKCOMMANDS.Items.AddObject(s+' : '+DD.Name,TObject(PtrInt(DD.IDN.Data.ParamNum)));
    end;
    if DD.CClass=ccRegister then
    begin
      s:=Format('Register %.4d', [DD.IDN.Data.ParamNum]);
      lbVMREGISTERS.Items.AddObject(s+' : '+DD.Name,TObject(PtrInt(DD.IDN.Data.ParamNum)));
    end;
  end;

  for i:=0 to Pred(DriveRegisterDataCount(0)) do
  begin
    DD:=LoadDriveRegisterDataRaw(0,i)^;
    if DD.CClass=ccDrive then
    begin
      s:=Format('S-0-%.4d', [DD.IDN.Data.ParamNum]);
      lbSERCOSCOMMANDS.Items.AddObject(s+' : '+DD.Name,TObject(PtrInt(DD.IDN.Data.ParamNum)));
    end;
    if DD.CClass=ccDriveSpecific then
    begin
      s:=Format('P-0-%.4d', [DD.IDN.Data.ParamNum]);
      lbSERCOSPARAMS.Items.AddObject(s+' : '+DD.Name,TObject(PtrInt(DD.IDN.Data.ParamNum)));
    end;
  end;

  pageRawCommandsChange(nil);
  TabControl1Change(nil);

  Ini := TIniFile.Create( ChangeFileExt( Application.ExeName, '.ini' ) );
  try
    Self.Top          := ini.ReadInteger(Self.Name,'Top',Self.Top);
    Self.Left         := ini.ReadInteger(Self.Name,'Left',Self.Left);
    Self.Width        := ini.ReadInteger(Self.Name,'Width',Self.Width);
    Self.Height       := ini.ReadInteger(Self.Name,'Height',Self.Height);

    lbVMTASKCOMMANDS.ItemIndex    := ini.ReadInteger('Defaults','TC',lbVMTASKCOMMANDS.ItemIndex);
    lbVMSYSTEMCOMMANDS.ItemIndex  := ini.ReadInteger('Defaults','SC',lbVMSYSTEMCOMMANDS.ItemIndex);
    lbSERCOSPARAMS.ItemIndex      := ini.ReadInteger('Defaults','DP',lbSERCOSPARAMS.ItemIndex);
    lbSERCOSCOMMANDS.ItemIndex    := ini.ReadInteger('Defaults','DC',lbSERCOSCOMMANDS.ItemIndex);
    lbVMAXISCOMMANDS.ItemIndex    := ini.ReadInteger('Defaults','AC',lbVMAXISCOMMANDS.ItemIndex);
    lbVMREGISTERS.ItemIndex       := ini.ReadInteger('Defaults','SR',lbVMREGISTERS.ItemIndex);

    selectDirection.ItemIndex     := ini.ReadInteger('Move','Direction',0);

    i                             := StrToIntDef(editDist.Text,0);
    i                             := ini.ReadInteger('Move','Distance',i);
    editDist.Text                 := InttoStr(i);

    i                             := StrToIntDef(editSpeed.Text,0);
    i                             := ini.ReadInteger('Move','Speed',i);
    editSpeed.Text                 := InttoStr(i);

    i                             := StrToIntDef(editAccel.Text,0);
    i                             := ini.ReadInteger('Move','Acceleration',i);
    editAccel.Text                 := InttoStr(i);

    i                             := StrToIntDef(editReps.Text,0);
    i                             := ini.ReadInteger('Move','Repetitions',i);
    editReps.Text                 := InttoStr(i);

    editDLLFileName.Text          := ini.ReadString('DDE','Location',editDLLFileName.Text);
    DDL.Checked                   := ini.ReadBool('DDE','Enabled',DDL.Checked);
    MenuConnectionClick(DDL);

    Serial.Checked                := ini.ReadBool('Serial','Enabled',Serial.Checked);
    MenuConnectionClick(Serial);
  finally
    Ini.Free;
  end;

  // Get comport list after form has been created
  Application.QueueAsyncCall(@InitMain,0);
end;

function TForm1.GetDrive:TDRIVE;
begin
  result:=GetDriveInfo(ActiveDrive);
end;

procedure TForm1.SetDrive(value:TDRIVE);
begin
  SetDriveInfo(ActiveDrive,value);
end;


procedure TForm1.lbCOMMANDSDblClick(Sender: TObject);
var
  LB                : TListBox;
  CD                : TCOMMANDDATA;
  id                : word;
  CommandString     : string;
  SUBCLASSIDARRAY   : PSCA;
begin
  LB:=TListBox(Sender);
  CD:=Default(TCOMMANDDATA);
  CommandString:=sUN;

  if Sender=lbVMSYSTEMCOMMANDS then CD.CCLASS:=ccControl;
  if Sender=lbVMAXISCOMMANDS then CD.CCLASS:=ccAxis;
  if Sender=lbVMTASKCOMMANDS then CD.CCLASS:=ccTask;
  if Sender=lbSERCOSCOMMANDS then CD.CCLASS:=ccDrive;
  if Sender=lbSERCOSPARAMS then CD.CCLASS:=ccDriveSpecific;

  id := ActiveDrive;
  if ((Sender=lbVMAXISCOMMANDS) OR (Sender=lbSERCOSCOMMANDS) OR (Sender=lbSERCOSPARAMS)) then
  begin
    if (AxisActive=axisOne) then id:=1;
    if (AxisActive=axisTwo) then id:=2;
  end;
  if (Sender=lbVMTASKCOMMANDS) then
  begin
    id := 1; // Task A
  end;
  if Sender=lbVMREGISTERS then
  begin
    id := 0; // For registers always 0
  end;
  CD.SETID:=id;
  CD.NUMID:=PtrInt(LB.Items.Objects[LB.ItemIndex]);

  SUBCLASSIDARRAY:=@VMCOMMANDPARAMETERSUBCLASS;

  if DirectDrive then
  begin
    CD.CSUBCLASS:=TVMCOMMANDPARAMETERSUBCLASS(rgSubClass.ItemIndex+1);
    CommandString:=GetDirectDriveCommand(CD);
  end
  else
  begin
    CD.CCLASSCHAR:=VMCOMMANDCLASS[CD.CCLASS];
    if Sender=lbVMREGISTERS then
    begin
      CD.CCLASSCHAR:=VMCOMMANDCLASS[ccRegister];
      SUBCLASSIDARRAY:=@VMREGISTERSUBCLASS;
    end;
    CD.CSUBCLASSCHAR:=SUBCLASSIDARRAY^[rgSubClass.ItemIndex+1];
    CD.CCLASS:=ccNone; // force the use of the class and subclass chars
    CommandString:=GetCLCCommandString(CD);
  end;

  editCommand.Text:=CommandString;
end;

procedure TForm1.pageRawCommandsChange(Sender: TObject);
var
  Param:TVMCOMMANDPARAMETERSUBCLASS;
  Reg:TVMREGISTERSUBCLASS;
  s:string;
begin
  if ((Sender<>nil) AND (TPageControl(Sender).ActivePage=tabVMRegister)) then
  begin
    if (rgSubClass.Tag<>2) then
    begin
      rgSubClass.Items.Clear;
      for Reg in TVMREGISTERSUBCLASS do
      begin
        s:=GetEnumNameUnCamel(TypeInfo(TVMREGISTERSUBCLASS),Ord(Reg));
        rgSubClass.Items.Append(s);
      end;
      rgSubClass.ItemIndex:=Ord(TVMREGISTERSUBCLASS.rscDecimalState);
      rgSubClass.Tag:=2;
    end;
  end
  else
  begin
    if (rgSubClass.Tag<>1) then
    begin
      rgSubClass.Items.Clear;
      for Param in TVMCOMMANDPARAMETERSUBCLASS do
      begin
        if Param=mscNone then continue;
        s:=GetEnumNameUnCamel(TypeInfo(TVMCOMMANDPARAMETERSUBCLASS),Ord(Param));
        rgSubClass.Items.Append(s);
      end;
      rgSubClass.ItemIndex:=Ord(TVMCOMMANDPARAMETERSUBCLASS.mscParameterData)-1;
      rgSubClass.Tag:=1;
    end;
  end;
end;

procedure TForm1.btnConnectDDEClick(Sender: TObject);
var
  Success:boolean;
begin
  Success:=ConnectDDE;
  if Success then
  begin
    ActiveConnection:=TCONNECTION.conCLCDDE;
  end;
end;

function TForm1.CommandExecuteAndWait(const aCD: TCOMMANDDATA):boolean;
var
  c,s     : string;
  i       : word;
  SCS     : SERCOSCOMMAND_STATUS;
  success : boolean;
  CD      : TCOMMANDDATA;
begin
  result:=false;

  CD:=aCD;
  CD.CSUBCLASS:=mscParameterData;

  // Execute command
  SCS.Raw:=0;
  SCS.Data.CommandSetInDrive:=1;
  SCS.Data.ExecutionOfCommandInDriveEnabled:=1;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,2,DirectDrive);
  success:=ProcessCommand(CD,s,false,true);

  // Sleep at least 64 ms
  Sleep(100);

  while true do
  begin
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
      success:=ProcessCommand(CD,s,false,true);
    end;
    CD:=ProcessCommDataString(s);

    sleep(150);

    if (NOT success) then break;
    if (Length(CD.ERROR)>0) then break;
    //success:=(s<>sERR);
    //if (NOT success) then break;
    if DirectDrive then
      i:=HexStringToDecimal(CD.DATA)
    else
      i:=BinaryStringToDecimal(CD.DATA);
      //i:=StringToIntSafe(CD.DATA);
    SCS.Raw:=i;
    //Detect command error.
    success:=((SCS.Data.CommandSetInDrive=1) AND (SCS.Data.ExecutionOfCommandInDriveEnabled=1) AND (SCS.Data.ExecutionOfCommandIsNotPossible=0));
    if (NOT success) then break;
    if (SCS.Data.CommandNotYetExecuted=0) then break; // Command ready !
  end;

  // Clear command
  CD:=aCD;
  CD.CSUBCLASS:=mscParameterData;
  SCS.Raw:=0;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,2,DirectDrive);
  success:=ProcessCommand(CD,s,false,true);
  //success:=(s<>sERR);

  result:=success;
end;

procedure TForm1.btnResetAxisClick(Sender: TObject);
var
  s       : string;
  axis    : word;
  CD      : TCOMMANDDATA;
  SCS     : SERCOSCOMMAND_STATUS;
  SC0393  : TDRIVEPARAMETER_0393;
  SC0403  : TDRIVEPARAMETER_0403;
  success : boolean;
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

  if CheckAxis(axis) then exit;

  CD:=Default(TCOMMANDDATA);

  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;
  CD.STEPID:=0;

  // Stop command "position spindle"
  CD.NUMID:=152;
  SCS.Raw:=0;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,DirectDrive);
  success:=ProcessCommand(CD,s);

  // Preset value for encoder 1
  CD.NUMID:=52;
  CD.DATA:='0';
  success:=ProcessCommand(CD,s);

  // Preset value for encoder 2
  CD.NUMID:=54;
  CD.DATA:='0';
  success:=ProcessCommand(CD,s);

  // Offset value for encoder 1
  CD.NUMID:=150;
  CD.DATA:='0';
  success:=ProcessCommand(CD,s);

  // Offset value for encoder 2
  CD.NUMID:=151;
  CD.DATA:='0';
  success:=ProcessCommand(CD,s);

  // Execute command "set absolute measuring"
  // C300 Command Set absolute measuring
  CD.CCLASS:=ccDriveSpecific;
  CD.CSUBCLASS:=mscParameterData;
  CD.NUMID:=12;
  success:=CommandExecuteAndWait(CD);

  // Position to actual position when activated
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.NUMID:=393;
  SC0393.Raw:=0;
  SC0393.Data.Mode:=0;
  //SC0393.Data.PositionType:=1;
  //SC0393.Data.TargetPosAfter:=1;
  CD.DATA:=DecimalToBinaryString(SC0393.Raw,DirectDrive);
  //CD.DATA:=IntToStr(DW.Raw);
  success:=ProcessCommand(CD,s);

  // Check success of P-0-0012, C300 Command
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.NUMID:=403;
  CD.DATA:='';
  success:=ProcessCommand(CD,s);
  //success:=(s<>sERR);
  SC0403.Raw:=StringToIntSafe(s);
  if (SC0403.Data.PositionFeedbackValues=1) then
  begin
    // Success !!!
    Memo1.Lines.Append('P-0-0012, C300 Command success !');
  end;
end;

function TForm1.ConnectDDE:boolean;
begin
  Result:=false;
  ActiveConnection:=conNone;
  FDirectDrive:=False;

  {$ifdef MSWindows}
  FComDevice:=TDDEComm.Create(Self);
  FComDevice.Active:=False;
  with (FComDevice AS TDDEComm) do
  begin
    ConnectionAddress:=CLCADDRESS;
  end;
  FComDevice.OnRxData:=@OnRXDDEData;
  FComDevice.Active:=True;
  if FComDevice.Active=True then
  begin
    Result:=True;
    Memo1.Lines.Append('DDE connection active.');
  end
  else
  begin
    FComDevice:=nil;
  end;
  {$endif}
end;


function TForm1.ConnectRS232:boolean;
begin
  Result:=false;
  ActiveConnection:=conNone;
  FDirectDrive:=False;

  FComDevice:=TLazSerial.Create(Self);
  FComDevice.Active:=False;
  with (FComDevice AS TLazSerial) do
  begin
    Device:=cmboSerialPorts.Text;
    BaudRate:=br__9600;
    FlowControl:=fcNone;
    Parity:=pNone;
    DataBits:=db8bits;
    StopBits:=sbOne;
  end;
  FComDevice.OnRxData:=@OnRXUSBCData;
  FComDevice.Active:=True;

  if (FComDevice.Active=True) then
  begin
    Result:=True;
    Memo1.Lines.Append('RS232/RS485 device connected and active: '+cmboSerialPorts.Text);
  end
  else
  begin
    FComDevice:=nil;
  end;
end;

procedure TForm1.btnConnectSerialClick(Sender: TObject);
var
  Success      : boolean;
  c,s          : string;
  CD           : TCOMMANDDATA;
begin
  Success:=ConnectRS232;
  if Success then
  begin
    if (Sender=btnConnectDriveRS232) then ActiveConnection:=conDDRS232;
    if (Sender=btnConnectDriveRS485) then ActiveConnection:=conDDRS485;
    if (Sender=btnConnectVMRS232) then ActiveConnection:=conCLCRS232;
  end;
  FDirectDrive:=((ActiveConnection=conDDRS232) OR (ActiveConnection=conDDRS485));

    (*
    btnConnectDriveRS232.Enabled:=False;;
    btnConnectVMRS232.Enabled:=False;
    btnConnectDDE.Enabled:=False;
    cmboSerialPorts.Enabled:=False;
    editDLLFileName.Enabled:=False;

    tabMove.TabVisible:=(Sender<>btnConnectDriveRS232);
    tabProgramme.TabVisible:=(Sender<>btnConnectDriveRS232);

    tabVMControl.TabVisible:=(Sender<>btnConnectDriveRS232);
    tabVMAxis.TabVisible:=(Sender<>btnConnectDriveRS232);
    tabVMTask.TabVisible:=(Sender<>btnConnectDriveRS232);
    tabVMRegister.TabVisible:=(Sender<>btnConnectDriveRS232);
    *)

  if DirectDrive then
  begin
    (FComDevice AS TLazSerial).Terminator:=TERDT;

    CD:=Default(TCOMMANDDATA);
    CD.CCLASS:=ccDriveSpecific;
    CD.CSUBCLASS:=mscParameterData;

    CD.NUMID:=4021;
    CD.DATA:='0';
    Success:=ProcessCommand(CD,s,false,true);
    Memo1.Lines.Append(s);

    CD.NUMID:=4050;
    CD.DATA:='10';
    Success:=ProcessCommand(CD,s,false,true);
    Memo1.Lines.Append(s);

    CD.CCLASS:=ccDrive;
    CD.NUMID:=265;
    CD.DATA:='1';
    Success:=ProcessCommand(CD,s,false,true);
    Memo1.Lines.Append(s);

    CD.CCLASS:=ccDriveSpecific;
    CD.NUMID:=5;
    CD.DATA:='1';
    Success:=ProcessCommand(CD,s,false,true);
    Memo1.Lines.Append(s);

    c:=Format('BCD:%.2d',[ActiveDriveInfo.DRIVEADDRESS]);
    s:='';
    Success:=ProcessDirectDriveCommand(c,s,false,true);
    Memo1.Lines.Append('Select drive response: '+s);
  end
  else
  begin
    (FComDevice AS TLazSerial).Terminator:=CRLF;
  end;

end;

procedure TForm1.btnGetTableClick(Sender: TObject);
type
  TPTCArray = array [TVMPOINTTABLESUBCLASS] of string;
  TPTC = record
    PTCArray : TPTCArray;
  end;
  TEventArray = array [TVMEVENTSUBCLASS] of string;
  TEvent = record
    EventArray : TEventArray;
  end;
var
  s          : string;
  i,j        : word;
  listlength : word;
  CD         : TCOMMANDDATA;
  success    : boolean;
  ptc        : TVMPOINTTABLESUBCLASS;
  ec         : TVMEVENTSUBCLASS;
  ptclistall : array of TPTC;
  eventlistall : array of TEvent;
begin
  CD:=Default(TCOMMANDDATA);

  if Sender=btnGetPoints then
  begin
    CD.CCLASSCHAR:=VMCOMMANDCLASS[ccAbsPointTable];
    CD.CSUBCLASSCHAR:=VMPOINTTABLESUBCLASS[ptcListAllAbove];
  end;
  if Sender=btnGetEvents then
  begin
    CD.CCLASSCHAR:=VMCOMMANDCLASS[ccEventTable];
    CD.CSUBCLASSCHAR:=VMEVENTSUBCLASS[ecListAll];
  end;

  // Get the list length
  CD.SETID:=0; // Current program
  CD.NUMID:=0; // List all
  success:=ProcessCommand(CD,s);
  //success:=(s<>sERR);
  s:=ExtractWord(1,s,[' ']);
  listlength:=StringToIntSafe(s);
  success:=(listlength>0);

  if success then
  begin

    if Sender=btnGetPoints then
    begin
      SetLength({%H-}ptclistall,listlength);
      for i:=0 to Pred(listlength) do
      begin
        ptclistall[i]:=Default(TPTC);
      end;
    end;
    if Sender=btnGetEvents then
    begin
      SetLength({%H-}eventlistall,listlength);
      for i:=0 to Pred(listlength) do
      begin
        eventlistall[i]:=Default(TEvent);
      end;
    end;

    for i:=0 to Pred(listlength) do
    begin
      CD.NUMID:=(i+1);
      success:=ProcessCommand(CD,s);
      j:=WordCount(s,[' ']);
      if Sender=btnGetPoints then
      begin
        if (j>=CountSetItems(integer(VMPOINTTABLELIST))) then
        begin
          j:=1;
          for ptc in (VMPOINTTABLELIST -[ptcNameText]) do
          begin
            ptclistall[i].PTCArray[ptc]:=ExtractWord(j,s,[' ']);
            Inc(j);
          end;
          while (j<=WordCount(s,[' '])) do
          begin
            ptclistall[i].PTCArray[ptcNameText]:=ptclistall[i].PTCArray[ptcNameText]+ExtractWord(j,s,[' ']);
            Inc(j)
          end;

        end;
      end;

      if Sender=btnGetEvents then
      begin
        // Message can contain spaces !! So wordcount me be greater than element count.
        if (j>=CountSetItems(integer(VMEVENTLIST))) then
        begin
          j:=1;
          for ec in (VMEVENTLIST-[ecMessage]) do
          begin
            eventlistall[i].EventArray[ec]:=ExtractWord(j,s,[' ']);
            Inc(j);
          end;
          while (j<=WordCount(s,[' '])) do
          begin
            eventlistall[i].EventArray[ecMessage]:=eventlistall[i].EventArray[ecMessage]+' '+ExtractWord(j,s,[' ']);
            Inc(j)
          end;
        end;
      end;

    end;

    if Sender=btnGetPoints then
    begin
      PointTableEditor.Strings.Clear;
      for i:=0 to Pred(listlength) do
      begin
        s:=ptclistall[i].PTCArray[ptcX]+'-'+ptclistall[i].PTCArray[ptcY]+'-'+ptclistall[i].PTCArray[ptcZ];
        PointTableEditor.Strings.AddPair(InttoStr(i+1),s);
      end;
    end;
    if Sender=btnGetEvents then
    begin
      EventEditor.Strings.Clear;
      for i:=0 to Pred(listlength) do
      begin
        s:=eventlistall[i].EventArray[ecFunction]+' : '+eventlistall[i].EventArray[ecMessage];
        EventEditor.Strings.AddPair(InttoStr(i+1),s);
      end;
    end;

  end;

end;

procedure TForm1.btnMoveClick(Sender: TObject);
begin
  SpindleAxis;
end;

procedure TForm1.btnRefreshDriveDataClick(Sender: TObject);
begin
  // This will never work on multiple drives.
  //FDCStatus:=TDATACOLLECTION.dcIDNData;
  FDCStatus:=TDATACOLLECTION.dcModes;
  //GetDriveData;
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

procedure TForm1.btnAxisCommandClick(Sender: TObject);
var
  m          : string;
  axis       : word;
  CD         : TCOMMANDDATA;
  success    : boolean;
  DP14       : TDRIVEPARAMETER_0014;
begin
  if CheckAxis(axis) then exit;

  CD:=Default(TCOMMANDDATA);

  CD.SETID:=ActiveDrive;

  if (Sender=btnPhase2) then
  begin
    // C400 Communication phase 2 transition
    CD.CCLASS:=ccDriveSpecific;
    //CD.CSUBCLASS:=mscParameterData;
    CD.NUMID:=4023;
    m:='Axis back in Phase 2';
  end;

  if (Sender=btnPhase3) then
  begin
    // C100 Communication phase 3 transition check
    CD.CCLASS:=ccDrive;
    //CD.CSUBCLASS:=mscParameterData;
    CD.NUMID:=127;
    m:='Axis from Phase 2 to Phase 3';
  end;

  if (Sender=btnPhase4) then
  begin
    // C200 Communication phase 4 transition check
    CD.CCLASS:=ccDrive;
    //CD.CSUBCLASS:=mscParameterData;
    CD.NUMID:=128;
    m:='Axis from Phase 3 to Phase 4'
  end;

  if (Sender=btnClearErrors) then
  begin
    // C500 Reset class 1 diagnostics
    CD.CCLASS:=ccDrive;
    //CD.CSUBCLASS:=mscParameterData;
    CD.NUMID:=99;
    m:='Cleared all drive errors';
  end;

  success:=CommandExecuteAndWait(CD);
  if success then
  begin
    Memo1.Lines.Append(m);
    CD:=COMMAND2CD(DRIVE_INTERFACE,ActiveDrive);
    DP14.Raw:=0;
    if (Sender=btnPhase2) then DP14.Data.CommPhase:=2;
    if (Sender=btnPhase3) then DP14.Data.CommPhase:=3;
    if (Sender=btnPhase4) then DP14.Data.CommPhase:=4;
    CD.DATA:=DecimalToBinaryString(DP14.Raw,DirectDrive);
    success:=ProcessCommand(CD,m,false,true);
  end;
end;

procedure TForm1.btnAxisHomeClick(Sender: TObject);
var
  s       : string;
  axis    : word;
  CD      : TCOMMANDDATA;
  SC0403  : TDRIVEPARAMETER_0403;
  SC0147  : TDRIVEPARAMETER_0147;
  success : boolean;
begin
  success:=false;

  if CheckAxis(axis) then exit;

  CD:=Default(TCOMMANDDATA);

  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;
  CD.STEPID:=0;

  // Set absolute distance 1
  CD.NUMID:=177;
  CD.DATA:=InttoStr(0);
  success:=ProcessCommand(CD,s);

  // Set acceleration
  CD.NUMID:=260;
  CD.DATA:=InttoStr(200);
  success:=ProcessCommand(CD,s);

  // Set Homing Parameter
  CD.NUMID:=147;
  SC0147.Raw:=0;
  SC0147.Data.HomeSwitchEvaluation:=1; // do NOT evaluate HomeSwitch
  SC0147.Data.ReferenceMarkEvaluation:=1; // do NOT evaluate ReferenceMark
  CD.DATA:=DecimalToBinaryString(SC0147.Raw,DirectDrive);
  success:=ProcessCommand(CD,s);

  // Execute command Drive-Controlled Homing Procedure
  // C600 Drive-controlled homing procedure command
  CD.NUMID:=148;
  success:=CommandExecuteAndWait(CD);

  // Check success of P-0-0148, C600 Command
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.NUMID:=403;
  CD.DATA:='';
  success:=ProcessCommand(CD,s);
  //success:=(s<>sERR);
  SC0403.Raw:=StringToIntSafe(s);
  if (SC0403.Data.PositionFeedbackValues=1) then
  begin
    // Success !!!
    Memo1.Lines.Append('P-0-0148, C600 Command success !');
  end;

end;

procedure TForm1.btnAxisStatusClick(Sender: TObject);
var
  s          : string;
  i,axis     : word;
  success    : boolean;
  CD         : TCOMMANDDATA;
  DW         : DATAWORD;
  SC76       : TDRIVEPARAMETER_0076;
  SC135      : TDRIVEPARAMETER_0135;
  SC0393     : TDRIVEPARAMETER_0393;
  AxisAlert  : boolean;
begin
  if CheckAxis(axis) then exit;

  AxisAlert:=false;

  CD:=Default(TCOMMANDDATA);

  // Get axis status
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;
  CD.NUMID:=135;
  success:=ProcessCommand(CD,s);
  if success then
  begin
    Memo1.Lines.Append('Axis status. Data: '+s);
    SC135.Raw:=StringToIntSafe(s);
    // Check drive error
    // Check class 1 to 3
    for i:=1 to 3 do
    begin
      AxisAlert:=false;
      if (i=1) then AxisAlert:=(SC135.Data.ChangeClass1Diag=1);
      if (i=2) then AxisAlert:=(SC135.Data.ChangeClass2Diag=1);
      if (i=3) then AxisAlert:=(SC135.Data.ChangeClass3Diag=1);
      if AxisAlert then
      begin
        AxisAlert:=false;
        CD.CCLASS:=ccDrive;
        CD.CSUBCLASS:=mscParameterData;
        CD.SETID:=axis;
        CD.NUMID:=(11+i-1);
        success:=ProcessCommand(CD,s);
        if success then
        begin
          DW.Raw:=StringToIntSafe(s);
          // Do we have an error ?
          AxisAlert:=(DW.Bits[15]=1);
        end;
      end;
      if AxisAlert then
      begin
        // Get axis diag number
        CD.CCLASS:=ccDrive;
        CD.CSUBCLASS:=mscParameterData;
        CD.SETID:=axis;
        CD.NUMID:=390;
        success:=ProcessCommand(CD,s);
        if success then
        begin
          DW.Raw:=StringToIntSafe(s);
          Memo1.Lines.Append('Axis diagnostic class '+InttoStr(i)+'. Number: '+s);
        end;
        // Get axis diag message
        CD.CCLASS:=ccDrive;
        CD.CSUBCLASS:=mscParameterData;
        CD.SETID:=axis;
        CD.NUMID:=95;
        success:=ProcessCommand(CD,s);
        if success then
        begin
          Memo1.Lines.Append('Axis diagnostic class '+InttoStr(i)+'. Message: '+s);
        end;
      end;
    end;
  end;

  // Get diagnostic message
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;
  CD.NUMID:=95;
  success:=ProcessCommand(CD,s);
  if (success AND (s<>sERR)) then
  begin
    Memo1.Lines.Append('Drive diagnostic message: '+s);
  end;

  // Get Position Data Scaling Type
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;
  CD.NUMID:=76;
  success:=ProcessCommand(CD,s);
  if (success AND (s<>sERR)) then
  begin
    SC76.Raw:=BinaryStringToDecimal(s);
    Memo1.Lines.Append('Drive position data scaling mode: '+SCALINGMODE[SC76.Data.ScalingType]);
    Memo1.Lines.Append('Drive position data scaling selection: '+SCALINGSELECTION[SC76.Data.ScalingSelection]);
    Memo1.Lines.Append('Drive position data unit: '+SCALINGUNIT[SC76.Data.LengthUnit]);
    Memo1.Lines.Append('Drive position data reference: '+SCALINGRELATION[SC76.Data.DataReference]);
    Memo1.Lines.Append('Drive position data format: '+SCALINGFORMAT[SC76.Data.ProcessingFormat]);
  end;

  // Command value mode for modulo format
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;
  CD.NUMID:=393;
  success:=ProcessCommand(CD,s);
  if (success AND (s<>sERR)) then
  begin
    SC0393.Raw:=StringToIntSafe(s);
    Memo1.Lines.Append('Drive command value mode for modulo format: '+MODULOCOMMANDMODE[SC0393.Data.Mode]);
  end;

end;

procedure TForm1.btnSendReceiveClick(Sender: TObject);
var
  c,s      : string;
  ro       : boolean;
begin
  c:=editCommand.Text;
  s:=editValue.Text;
  ro:=(Length(s)=0);

  if (ActiveConnection<>TCONNECTION.conNone) then
  begin
    if (ActiveConnection=TCONNECTION.conCLCDDE) then
    begin
      {$ifdef MSWindows}
      if (NOT ProcessDDECommand(c,s,false,true)) then c:='DDE error !';
      {$endif}
    end
    else
    begin
      if DirectDrive then
      begin
        if (NOT ro) then
        begin
          if c[Length(c)]='r' then c[Length(c)]:='w';
          if c[Length(c)]='w' then c:=c+',';
        end;
        if (NOT ProcessDirectDriveCommand(c,s,false,true)) then c:='Serial error !';
      end
      else
      begin
        if (NOT ProcessSerialCommand(c,s,false,true)) then c:='Serial error !';
      end;
    end;
  end;

  if ro then
    Memo1.Lines.Append('Read. '+c+' : ['+s+']')
  else
    Memo1.Lines.Append('Write. '+c+' {'+s+'}');
  editValue.Text:='';
end;

procedure TForm1.btnSetModeClick(Sender: TObject);
begin
  SetDriveMode;
end;

procedure TForm1.btnSpeedLimitClick(Sender: TObject);
var
  s          : string;
  axis       : word;
  CD         : TCOMMANDDATA;
  success    : boolean;
begin
  if CheckAxis(axis) then exit;

  CD:=Default(TCOMMANDDATA);

  // Get axis speed limit
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;
  CD.NUMID:=91;
  success:=ProcessCommand(CD,s);
  if success then
  begin
    Memo1.Lines.Append('Speed limit: '+s);
  end;
end;

procedure TForm1.SetDriveMode;
var
  s          : string;
  CD         : TCOMMANDDATA;
  success    : boolean;
  OM         : TOPERATIONMODE;
  DM         : TDRIVEMODE;
  DB         : DATABYTE;
  LagLess    : boolean;
  OMData     : POMD;
begin
  CD:=COMMAND2CD(DRIVE_PRIMARYMODE,ActiveDrive);
  if (comboDriveModes.ItemIndex<>-1) then
  begin
    DB.Raw:=({%H-}PtrUInt(Pointer(comboDriveModes.Items.Objects[comboDriveModes.ItemIndex])) AND $FF);
    LagLess:=(DB.Bits[7]=1); // if bit 7 is set, we have selected a lagless mode
    DB.Bits[7]:=0;
    if LagLess then
      OMData:=@DriveOperationModesLagLess
    else
      OMData:=@DriveOperationModes;
    OM:=TOPERATIONMODE(DB.Raw);
    if (OM<>TOPERATIONMODE.omNone) then
    begin
      DM.Raw:=OMData^[OM].BitMask;
      CD.DATA:=DecimalToBinaryString(DM.Raw,DirectDrive);
      success:=ProcessCommand(CD,s,false,true);
    end;
  end;
end;

procedure TForm1.GetDriveData;
const
  BLOCK        = True;
var
  c,s          : string;
  CD           : TCOMMANDDATA;
  CDStorage    : TCOMMANDDATA;
  CC           : TCOMMAND;
  success      : boolean;
  i,listlength : integer;
  DI           : TDRIVE;
begin
  if (FDCStatus<>TDATACOLLECTION.dcBasic) then
  begin
    if shapeAlive.Brush.Color=clLime then shapeAlive.Brush.Color:=clRed else shapeAlive.Brush.Color:=clLime;
    for CC in REALTIMEDRIVEDATA do
    begin
      CD:=COMMAND2CD(CC,ActiveDrive);
      success:=ProcessCommand(CD,s,true,false);
    end;
  end;

  DI:=ActiveDriveInfo;

  if (FDCStatus=TDATACOLLECTION.dcBasic) then
  begin
    for CC in BASICDRIVEDATA do
    begin
      CD:=COMMAND2CD(CC,ActiveDrive);
      success:=ProcessCommand(CD,s,(NOT BLOCK),BLOCK);
      if BLOCK then OnCommData(s);
    end;
  end;

  CD:=Default(TCOMMANDDATA);
  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=ActiveDrive;

  case FDCStatus of
    TDATACOLLECTION.dcBasic:
    begin
      FDCStatus:=TDATACOLLECTION.dcModes;
    end;
    TDATACOLLECTION.dcModes:
    begin
      // Get drives modes
      ShowDataUpdateInfo('Getting drive modes.');
      CD.NUMID:=DRIVE_MODELIST.NUMID;
      CD.DATA:='';
      if DirectDrive then
      begin
        CD.CSUBCLASS:=mscParameterData;
        success:=ProcessCommand(CD,s);
      end
      else
      begin
        CD.CSUBCLASS:=mscList;
        CD.STEPID:=STEPLISTSTART;
        success:=ProcessCommand(CD,s);
      end;
      FDCStatus:=TDATACOLLECTION.dcIDN;
    end;
    TDATACOLLECTION.dcIDN:
    begin
      ShowDataUpdateInfo('Getting/checking parameters.');
      CD.CCLASS:=DRIVE_PARAMLIST.CCLASS;
      CD.NUMID:=DRIVE_PARAMLIST.NUMID;
      CD.DATA:='';
      if DirectDrive then
      begin
        CD.CSUBCLASS:=mscParameterData;
        success:=ProcessCommand(CD,s);
      end
      else
      begin
        CD.CSUBCLASS:=mscList;
        CD.STEPID:=STEPLISTSTART;
        success:=ProcessCommand(CD,s);
      end;
      FDCStatus:=TDATACOLLECTION.dcNone;
    end;
    TDATACOLLECTION.dcIDNData:
    begin
      ShowDataUpdateInfo('Getting parameters attributes and values.');
      listlength:=lvParameters.Items.Count;
      for i:=0 to Pred(listlength) do
      begin
        c:=lvParameters.Items.Item[i].Caption;
        CD:=IDN2CD(c,ActiveDrive);
        if (CD.CCLASS<>ccNone) then
        begin
          // First, get the attributes to be able to identify the data types, if needed
          CD.CSUBCLASS:=mscAttributes;
          CDStorage:=LoadDriveRegisterData(CD);
          if (Length(CDStorage.DATA)=0) then success:=ProcessCommand(CD,s);
          // Second, get the data itself
          CD.CSUBCLASS:=mscParameterData;
          CD.DATA:='';
          CDStorage:=LoadDriveRegisterData(CD);
          if (Length(CDStorage.DATA)=0) then success:=ProcessCommand(CD,s) else
          begin
            // Skip motorserial to prevent auto-update of data from ProcessMotorSerial
            if ((CD.CCLASS=DRIVE_MOTORSERIAL.CCLASS) AND (CD.NUMID=DRIVE_MOTORSERIAL.NUMID)) then continue;
            // Skip IDN list. Already done
            if ((CD.CCLASS=DRIVE_PARAMLIST.CCLASS) AND (CD.NUMID=DRIVE_PARAMLIST.NUMID)) then continue;
            // Skip Mode list. Already done
            if ((CD.CCLASS=DRIVE_MODELIST.CCLASS) AND (CD.NUMID=DRIVE_MODELIST.NUMID)) then continue;
            success:=ProcessCommand(CD,s);
          end;
        end;
      end;
      FDCStatus:=TDATACOLLECTION.dcIDNAttribute;
    end;
    TDATACOLLECTION.dcIDNAttribute:
    //TDATACOLLECTION.dcIDNData:
    begin
      ShowDataUpdateInfo('Getting name, units and limits of data');
      listlength:=lvParameters.Items.Count;
      for i:=0 to Pred(listlength) do
      begin
        c:=lvParameters.Items.Item[i].Caption;
        CD:=IDN2CD(c,ActiveDrive);
        if (CD.CCLASS<>ccNone) then
        begin
          CD.CSUBCLASS:=mscName;
          CDStorage:=LoadDriveRegisterData(CD);
          if (Length(CDStorage.DATA)=0) then success:=ProcessCommand(CD,s);

          CD.CSUBCLASS:=mscUnits;
          CDStorage:=LoadDriveRegisterData(CD);
          if (Length(CDStorage.DATA)=0) then success:=ProcessCommand(CD,s);

          CD.CSUBCLASS:=mscUpperLimit;
          CDStorage:=LoadDriveRegisterData(CD);
          if (Length(CDStorage.DATA)=0) then success:=ProcessCommand(CD,s);

          CD.CSUBCLASS:=mscLowerLimit;
          CDStorage:=LoadDriveRegisterData(CD);
          if (Length(CDStorage.DATA)=0) then success:=ProcessCommand(CD,s);
        end;
      end;
      FDCStatus:=TDATACOLLECTION.dcNone;
    end;
    else
    begin
      FDCStatus:=TDATACOLLECTION.dcNone;
    end;
  end;

end;

procedure TForm1.btnStartClick(Sender: TObject);
var
  Count:integer;
begin
  Count:=StringToIntSafe(editReps.Text);
  SpindleAxis(Count);
end;

procedure TForm1.btnStartTaskAClick(Sender: TObject);
var
  s       : string;
  success : boolean;
  CD      : TCOMMANDDATA;
  TC      : TSERCOSREGISTER_TASKCONTROL;
  TS      : TSERCOSREGISTER_TASKSTATUS;
begin
  success:=false;

  CD:=Default(TCOMMANDDATA);

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
  success:=ProcessCommand(CD,s);

  // Start the task
  TC.Data.Start:=1;
  TC.Data.ClearTaskError:=0;
  CD.DATA:=DecimalToBinaryString(TC.Raw,DirectDrive);
  success:=ProcessCommand(CD,s);

  repeat
    Sleep(100);
    CD.NUMID:=22; // TaskA Status
    CD.DATA:='';
    success:=ProcessCommand(CD,s);
    TS.Raw:=BinaryStringToDecimal(s);
  until ((TS.Data.Mode=0) OR (TS.Data.Running=0));
end;

procedure TForm1.btnStopClick(Sender: TObject);
begin
  if Assigned(FComDevice) then
  begin
    FComDevice.Active:=False;
    FComDevice:=nil;
  end;
  ActiveConnection:=conNone;
  FDirectDrive:=False;
end;

procedure TForm1.btnTestClick(Sender: TObject);
begin
  MoveAxis;
end;

procedure TForm1.btnGetListsClick(Sender: TObject);
var
  s          : string;
  i          : word;
  listlength : word;
  CD         : TCOMMANDDATA;
  success    : boolean;
begin
  CD:=Default(TCOMMANDDATA);

  CD.CCLASSCHAR:=VMCOMMANDCLASS[ccProgram];
  CD.CSUBCLASSCHAR:='V'; // Program variable labels
  CD.SETID:=0;           // Active Program

  // Get the list length
  CD.NUMID:=0;
  success:=ProcessCommand(CD,s);
  listlength:=StringToIntSafe(s);
  //success:=(s<>sERR);

  if (listlength>0) then
  begin
    // Get the list
    for i:=1 to listlength do
    begin
      CD.NUMID:=i;
      success:=ProcessCommand(CD,s);
      if success then
      begin
        Memo1.Lines.Append('Program variables: '+s);
      end;
      if (NOT success) then break
    end;
    // Close the list
    CD.STEPID:=(listlength+1);
    success:=ProcessCommand(CD,s);
  end;

  //RD 0.20

  CD:=Default(TCOMMANDDATA);

  CD.CCLASSCHAR:=VMCOMMANDCLASS[ccProgram];
  CD.CSUBCLASSCHAR:='H'; // Program info
  CD.SETID:=0;           // Active Program

  // Get the list length
  CD.NUMID:=0;
  success:=ProcessCommand(CD,s);
  listlength:=StringToIntSafe(s);
  //success:=(s<>sERR);

  if (listlength>0) then
  begin
    // Get the list
    for i:=1 to listlength do
    begin
      CD.NUMID:=i;
      success:=ProcessCommand(CD,s);
      if success then
      begin
        Memo1.Lines.Append('Program info: '+s);
      end;
      if (NOT success) then break
    end;
    // Close the list
    CD.STEPID:=(listlength+1);
    success:=ProcessCommand(CD,s);
  end;


end;

procedure TForm1.btnManualAxisClick(Sender: TObject);
var
  s                    : string;
  CD                   : TCOMMANDDATA;
  success              : boolean;
  axis                 : integer;
  SystemControl        : TSERCOSREGISTER_SYSTEMCONTROL;
begin
  CD:=Default(TCOMMANDDATA);

  // Switch to parameter mode
  CD.CCLASSCHAR:=VMCOMMANDCLASS[ccRegister];
  CD.CSUBCLASSCHAR:=VMREGISTERSUBCLASS[rscDecimalState];
  CD.DATA:='';
  CD.NUMID:=1;
  success:=ProcessCommand(CD,s);
  if success then
  begin
    SystemControl.Raw:=StringToIntSafe(s);
    SystemControl.Data.ParameterMode:=1;
    CD.DATA:=InttoStr(SystemControl.Raw);
    success:=ProcessCommand(CD,s);
  end;

  CD:=Default(TCOMMANDDATA);
  CD.CCLASS:=ccAxis;
  CD.CSUBCLASS:=mscParameterData;
  //for axis:=1 to 2 do
  for axis:=ActiveDrive to ActiveDrive do
  begin
    CD.SETID:=axis;

    CD.NUMID:=7;
    //CD.DATA:='0'; // 0 = init with task
    CD.DATA:='1'; // 1 = init without task
    //CD.DATA:='2'; // 2 = no init
    success:=ProcessCommand(CD,s);

    CD.NUMID:=26;
    CD.DATA:='80000';
    success:=ProcessCommand(CD,s);

    CD.NUMID:=23;
    CD.DATA:='100';
    success:=ProcessCommand(CD,s);
  end;

  // Switch back to run mode
  if (SystemControl.Data.ParameterMode=1) then
  begin
    SystemControl.Data.ParameterMode:=0;
    CD:=Default(TCOMMANDDATA);
    CD.CCLASSCHAR:=VMCOMMANDCLASS[ccRegister];
    CD.CSUBCLASSCHAR:=VMREGISTERSUBCLASS[rscDecimalState];
    CD.NUMID:=1;
    CD.DATA:=InttoStr(SystemControl.Raw);
    success:=ProcessCommand(CD,s);
  end;
end;

procedure TForm1.btnDriveInfoClick(Sender: TObject);
const
  DRIVECOMMANDS     : array [0..3] of word =(141,142,30,32);
  TELEGRAMCOMMANDS  : array [0..1] of word =(16,24);
var
  s,data       : string;
  success      : boolean;
  CD           : TCOMMANDDATA;
  listlength   : integer;
  i,j          : integer;
  ADriveList   : TStringList;
  c            : word;
begin
  CD:=Default(TCOMMANDDATA);

  // Get the list length by a block command ... faster !
  CD.CCLASS:=ccControl;
  CD.CSUBCLASS:=mscBlock;
  CD.NUMID:=2011;
  CD.SETID:=ActiveDrive;

  CD.STEPID:=STEPLISTSTART;
  success:=ProcessCommand(CD,s);
  listlength:=StringToIntSafe(s);
  //success:=(s<>sERR);

  if (listlength>0) then
  begin
    ADriveList:=TStringList.Create;
    ADriveList.Delimiter:=' ';
    ADriveList.StrictDelimiter:=true;
    try
      CD.STEPID:=1;
      success:=ProcessCommand(CD,s);
      if (success AND (s<>sERR)) then
      begin
        ADriveList.DelimitedText:=s;

        CD:=Default(TCOMMANDDATA);
        CD.CCLASS:=ccDrive;

        // Get drive details
        for i:=0 to Pred(ADriveList.Count) do
        begin
          s:=ADriveList[i];
          CD.SETID:=StringToIntSafe(s);
          if (CD.SETID=0) then continue;
          Memo1.Lines.Append('Drive: '+s);
          data:='Drive '+ADriveList[i]+'. ';

          for c in DRIVECOMMANDS do
          begin
            CD.NUMID:=c;
            CD.CSUBCLASS:=mscName;
            CD.DATA:='';
            success:=ProcessCommand(CD,s);
            data:=data+s+': ';

            CD.CSUBCLASS:=mscParameterData;
            CD.DATA:='';
            success:=ProcessCommand(CD,s);
            if (success AND (s<>sERR) AND (CD.NUMID=32)) then s:=GetDriveModeDescription(s);
            data:=data+s+'. ';
          end;

          Memo1.Lines.Append(data);
        end;

        CD:=Default(TCOMMANDDATA);
        CD.CCLASS:=ccDrive;
        CD.CSUBCLASS:=mscList;

        for i:=0 to Pred(ADriveList.Count) do
        begin
          s:=ADriveList[i];
          CD.SETID:=StringToIntSafe(s);
          if (CD.SETID=0) then continue;
          for c in TELEGRAMCOMMANDS do
          begin
            CD.NUMID:=c;
            Memo1.Lines.Append('Drive: '+s);
            CD.STEPID:=STEPLISTSTART;
            success:=ProcessCommand(CD,s);
            listlength:=StringToIntSafe(s);
            for j:=1 to listlength do
            begin
              CD.STEPID:=j;
              success:=ProcessCommand(CD,s);
              //Memo1.Lines.Append(GetCommandDescription(CD.CCLASS,CD.NUMID)+': '+s);
              Dec(listlength);
            end;
          end;
        end;

      end;
    finally
      ADriveList.Free;
    end;

  end;

end;

procedure TForm1.Button1Click(Sender: TObject);
var
  DataString,s:string;
  CD:TCOMMANDDATA;
begin
  //FDirectDrive:=True;
  //s:='S-0-0292,7,r';
  //s:='S-0-0128,7,w,0000000000000011b';


  DataString:='>1 DP 1.104 !05 Greater than maximum value'#13#10;


  if s='S-0-0032,7,r' then DataString:=s+#13+'0000000000001011b'+#13+'A01:>';
  if s='S-0-0292,7,r' then DataString:=s+#13+'0001h'+#13+'0002h'+#13+'0003h'+#13+'000Bh'+#13+'0013h'+#13+'001Bh'+#13+'0004h'+#13+'000Ch'+#13+'!19 List is finished'+#13+'A01:>';
  if s='S-0-0040,7,r' then DataString:=s+#13+'34.872'+#13+'A01:>';
  if s='S-0-0134,7,r' then DataString:=s+#13+'1110000000000000b'+#13+'A01:>';
  if s='S-0-0135,7,r' then DataString:=s+#13+'1100000000000000b'+#13+'A01:>';

  if s='S-0-0127,7,w,0000000000000011b' then DataString:='S-0-0127,7,w,0000000000000011b'#$0D#$0D#$0A'#7005'#$0D#$0A#$0D'E02:>';
  if s='S-0-0128,7,w,0000000000000011b' then DataString:='S-0-0127,7,w,0000000000000011b'#$0D#$0A#$0D'E02:>';


  CD:=ProcessCommDataString(DataString);
  ProcessCommResult(CD);
end;

procedure TForm1.btnGetDriveDataClick(Sender: TObject);
begin
  GetDriveData;
end;

function TForm1.SpindleAxis(Reps:word):boolean;
var
  s          : string;
  axis,rep   : word;
  success    : boolean;
  DW         : DATAWORD;
  CD         : TCOMMANDDATA;
  SCS        : SERCOSCOMMAND_STATUS;
  SC154      : TDRIVEPARAMETER_0154;
function WaitForPosition:boolean;
var
  i          : integer;
begin
  result:=false;
  // Read position during move
  for i:=1 to 50 do
  begin
    // Position reached ?
    CD.NUMID:=336;
    CD.DATA:='';
    success:=ProcessCommand(CD,s);
    DW.Raw:=BinaryStringToDecimal(s);
    if (DW.Bits[0]=1) then
    begin
      result:=true;
      Memo1.Lines.Append('Position ready');
      break;
    end;
    //sleep(100);
  end;
  if (NOT result) then Memo1.Lines.Append('Position skip');
  result:=true;
end;
begin
  result:=false;

  if CheckAxis(axis) then exit;

  CD:=Default(TCOMMANDDATA);

  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;

  // Stop command "position spindle", just to be sure
  CD.NUMID:=152;
  SCS.Raw:=0;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,DirectDrive);
  success:=ProcessCommand(CD,s);

  // Set relative via relative offset
  // If relative, use 0180 for offset
  // If absolute, use 0153 for absolute position
  CD.NUMID:=154;
  SC154.Raw:=0;
  SC154.Data.Direction:=%10;         // = shortest
  SC154.Data.TraversingMethod:=1;    // = relative
  SC154.Data.Encoder:=0;             // = motor
  CD.DATA:=DecimalToBinaryString(SC154.Raw,DirectDrive);
  success:=ProcessCommand(CD,s);

  // Spindle acceleration, method 1
  CD.NUMID:=138;
  CD.DATA:=editAccel.Text;
  success:=ProcessCommand(CD,s);

  // Spindle speed
  CD.NUMID:=222;
  CD.DATA:=editSpeed.Text;;
  success:=ProcessCommand(CD,s);

  // Homing acceleration
  CD.NUMID:=42;
  CD.DATA:=editAccel.Text;
  success:=ProcessCommand(CD,s);

  // Homing speed
  CD.NUMID:=41;
  CD.DATA:=editSpeed.Text;;
  success:=ProcessCommand(CD,s);

  // Set offset to zero, just to be sure
  CD.NUMID:=180;
  CD.DATA:=IntToStr(integer(0));
  success:=ProcessCommand(CD,s);

  // Start command "position spindle"
  CD.NUMID:=152;
  SCS.Raw:=0;
  SCS.Data.CommandSetInDrive:=1;
  SCS.Data.ExecutionOfCommandInDriveEnabled:=1;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,DirectDrive);
  success:=ProcessCommand(CD,s);

  rep:=Reps;
  while (rep>0) do
  begin
    Dec(rep);

    // Set offset
    CD.NUMID:=180;
    CD.DATA:=editDist.Text;
    success:=ProcessCommand(CD,s);
    sleep(100);

    // Read position during move
    repeat sleep(500) until WaitForPosition;

    // Set offset
    CD.NUMID:=180;
    CD.DATA:='-'+editDist.Text;;
    success:=ProcessCommand(CD,s);
    sleep(100);

    // Read position during move
    repeat sleep(50) until WaitForPosition;
  end;

  // Stop command "position spindle"
  CD.NUMID:=152;
  SCS.Raw:=0;
  CD.DATA:=DecimalToBinaryString(SCS.Raw,DirectDrive);
  success:=ProcessCommand(CD,s);

  result:=success;
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

function TForm1.MoveAxis:boolean;
var
  s                    : string;
  i,axis                 : word;
  CD                   : TCOMMANDDATA;
  //SC13                 : TDRIVEPARAMETER_0013;
  SC346                : TDRIVEPARAMETER_0346;
  DR182                : TDRIVEPARAMETER_0182;
  success              : boolean;
begin
  // This only works when mode in in "drive interpolated"  = omRDIE1 !!!!!
  result:=false;
  success:=false;

  if CheckAxis(axis) then exit;

  CD:=Default(TCOMMANDDATA);

  CD.CCLASS:=ccDrive;
  CD.CSUBCLASS:=mscParameterData;
  CD.SETID:=axis;
  CD.STEPID:=0;

  // Set travel distance
  CD.NUMID:=258; // with omDIE1
  //CD.NUMID:=282; // with omRDIE1
  CD.DATA:=editDist.Text;
  success:=ProcessCommand(CD,s);

  // Set speed
  CD.NUMID:=259;
  CD.DATA:=editSpeed.Text;
  success:=ProcessCommand(CD,s);

  // Set acceleration
  CD.NUMID:=260;
  CD.DATA:=editAccel.Text;
  success:=ProcessCommand(CD,s);

  // Set jerk
  //CD.NUMID:=193;
  //CD.DATA:='';
  //success:=ProcessCommand(CD,s);

  // Get strobe flag to toggle
  CD.NUMID:=346;
  CD.DATA:='';
  success:=ProcessCommand(CD,s);
  SC346.Raw:=BinaryStringToDecimal(s);
  // Engage drive by toggling stobe bit
  SC346.Data.AcceptPositionStrobe:=1-SC346.Data.AcceptPositionStrobe; // toggle strobe bit
  CD.NUMID:=346;
  CD.DATA:=DecimalToBinaryString(SC346.Raw,DirectDrive);
  success:=ProcessCommand(CD,s);

  //Sleep(1000);

  // Wait for position
  (*
  CD.NUMID:=13;
  CD.DATA:='';
  i:=0;
  repeat
    Inc(i);
    success:=ProcessCommand(CD,s);
    Memo1.Lines.Append(s);
    SC13.Raw:=BinaryStringToDecimal(s);
  until ((SC13.Data.InPosition=1) OR (i>20));
  *)

  // Wait for position
  CD:=COMMAND2CD(DRIVE_DIAGNOSTIC_CLASS3,ActiveDrive);
  i:=0;
  repeat
    Inc(i);
    success:=ProcessCommand(CD,s);
    Memo1.Lines.Append(s);
    DR182.Raw:=BinaryStringToDecimal(s);
  until ((DR182.Data.InTargetPosition=1) OR (i>20));

  result:=success;
end;

function TForm1.ProcessDirectDriveCommand(const Command:string; var Value:string; const prio,blocking:boolean):boolean;
var
  c,s      : string;
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
    FComDevice.WriteStringPrio(c,s);
  end
  else
  if blocking then
  begin
    FComDevice.WriteStringBlocking(c,s);
    result:=((FComDevice AS TLazSerial).SynSer.LastError=0);
  end
  else
  begin
    FComDevice.WriteString(c,s);
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

function TForm1.ProcessDDECommand(const Command:string; var Value:string; const prio,blocking:boolean):boolean;
begin
  result:=false;
  if (ActiveConnection=TCONNECTION.conCLCDDE) then
  begin
    if prio then
    begin
      FComDevice.WriteStringPrio(Command,Value);
    end
    else
    if blocking then
    begin
      FComDevice.WriteStringBlocking(Command,Value);
    end
    else
    begin
      FComDevice.WriteString(Command,Value);
    end;
    result:=true;
  end;
end;
{$endif}
function TForm1.ProcessSerialCommand(const Command:string; var Value:string; const prio,blocking:boolean):boolean;
var
  s,v,c    : string;
  cs       : byte;
  ro       : boolean;
begin
  result:=false;
  c:=sERR;
  if ((ActiveConnection<>TCONNECTION.conNone) AND (ActiveConnection<>TCONNECTION.conCLCDDE)) then
  begin
    s:=Command;
    v:=Value;
    ro:=(Length(v)=0);
    c:='>'+chr(48+CLCADDRESS)+' '+s+' '; // add pre-amble
    if (NOT ro) then c:=c+v+' ';
    cs:=GenerateVisualMotionChecksum(c);
    c:=c+CSS+InttoHex(cs,2)+(FComDevice AS TLazSerial).Terminator;
    result:=true;
    s:='';
    if prio then
    begin
      FComDevice.WriteStringPrio(c,s);
    end
    else
    if blocking then
    begin
      FComDevice.WriteStringBlocking(c,s);
      result:=((FComDevice AS TLazSerial).SynSer.LastError=0);
    end
    else
    begin
      FComDevice.WriteString(c,s);
    end;
  end;
  if blocking then Value:=s;
end;

procedure TForm1.cmboSerialPortsChange(Sender: TObject);
begin
  if (cmboSerialPorts.Items.Count>0) AND (cmboSerialPorts.ItemIndex<>-1) then
  begin
    if Assigned(FComDevice) then
    begin
      FComDevice.Active:=False;
      (FComDevice AS TLazSerial).Device:=cmboSerialPorts.Text;
      FComDevice.Active:=True;
      Memo1.Lines.Append('RS232/RS485 Device Connected and Active: '+cmboSerialPorts.Text);
    end;
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

procedure TForm1.editStatusChange(Sender: TObject);
begin
  Timer1.Tag:=0;
end;

procedure TForm1.SetParamDetails(const CD:TCOMMANDDATA);
var
  IDN     : TIDN;
  s       : string;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    vleParamDetails.BeginUpdate;
    IDN:=GetIDN(CD);
    vleParamDetails.Strings.ValueFromIndex[0]:=IDN;
    if (CD.CCLASS<>ccNone) then
    begin
      s:=CD.DATA;
      if (CD.CSUBCLASS=mscParameterData) then
      begin
        if DriveParameterIsDriveMode(IDN) then s:=GetDriveModeDescription(CD.DATA);
      end;
      if (Length(s)=0) then s:='-';
      case CD.CSUBCLASS of
        mscAttributes       : vleParamDetails.Strings.ValueFromIndex[5]:=s;
        mscUpperLimit       : vleParamDetails.Strings.ValueFromIndex[4]:=s;
        mscLowerLimit       : vleParamDetails.Strings.ValueFromIndex[3]:=s;
        mscParameterData    : vleParamDetails.Strings.ValueFromIndex[6]:=s;
        mscName             : vleParamDetails.Strings.ValueFromIndex[1]:=s;
        mscUnits            : vleParamDetails.Strings.ValueFromIndex[2]:=s;
      else
        // we should never be here !!!
        raise EArgumentException.Create ('Wrong subclass used to get data from datastore !');
      end;
    end;
    vleParamDetails.EndUpdate;
  end;
end;

procedure TForm1.SetParamDetails(const RR:TRegisterRecord);
var
  s:string;
  IDN:TIDN;
begin
  vleParamDetails.BeginUpdate;
  IDN:=GetIDN(RR);
  vleParamDetails.Strings.ValueFromIndex[0]:=IDN;
  s:=RR.Name;
  if (Length(s)=0) then s:='-';
  vleParamDetails.Strings.ValueFromIndex[1]:=s;
  s:=RR.Measure;
  if (Length(s)=0) then s:='-';
  vleParamDetails.Strings.ValueFromIndex[2]:=s;
  s:=RR.Min;
  if (Length(s)=0) then s:='-';
  vleParamDetails.Strings.ValueFromIndex[3]:=s;
  s:=RR.Max;
  if (Length(s)=0) then s:='-';
  vleParamDetails.Strings.ValueFromIndex[4]:=s;
  s:=DecimalToBinaryString(RR.Attribute);
  if (Length(s)=0) then s:='-';
  vleParamDetails.Strings.ValueFromIndex[5]:=s;
  s:=RR.Value;
  if (Length(s)=0) then s:='-';
  vleParamDetails.Strings.ValueFromIndex[6]:=s;
  vleParamDetails.EndUpdate;
end;

procedure TForm1.lvParametersSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  IDN:TIDN;
  PRR:PRegisterRecord;
begin
  if Selected then
  begin
    IDN:=Item.Caption;
    PRR:=LoadDriveRegisterDataRaw(ActiveDrive,IDN);
    if Assigned(PRR) then SetParamDetails(PRR^);
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  IniFile               : TIniFile;
  i                     : integer;
begin
  //Stop dataTimer
  Timer1.Enabled:=False;

  //Stop all data threads
  if Assigned(FComDevice) then FComDevice.Active:=False;
  FComDevice:=nil;

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

    IniFile.WriteInteger('Defaults','TC',lbVMTASKCOMMANDS.ItemIndex);
    IniFile.WriteInteger('Defaults','SC',lbVMSYSTEMCOMMANDS.ItemIndex);
    IniFile.WriteInteger('Defaults','DP',lbSERCOSPARAMS.ItemIndex);
    IniFile.WriteInteger('Defaults','DC',lbSERCOSCOMMANDS.ItemIndex);
    IniFile.WriteInteger('Defaults','AC',lbVMAXISCOMMANDS.ItemIndex);
    IniFile.WriteInteger('Defaults','SR',lbVMREGISTERS.ItemIndex);

    IniFile.WriteInteger('Move','Direction',selectDirection.ItemIndex);

    i := StringToIntSafe(editDist.Text);
    IniFile.WriteInteger('Move','Distance',i);
    i := StringToIntSafe(editSpeed.Text);
    IniFile.WriteInteger('Move','Speed',i);
    i := StringToIntSafe(editAccel.Text);
    IniFile.WriteInteger('Move','Acceleration',i);
    i := StringToIntSafe(editReps.Text);
    IniFile.WriteInteger('Move','Repetitions',i);

    IniFile.WriteString('DDE','Location',editDLLFileName.Text);
    IniFile.WriteBool('DDE','Enabled',DDL.Checked);

    IniFile.WriteBool('Serial','Enabled',Serial.Checked);
  finally
    IniFile.Free;
  end;

  MouseUpEvent.Free;
end;

procedure TForm1.ProcessDiskDriveData(const Drive: word; StoreOnDisk:boolean);
var
  IniFile               : TIniFile;
  j,m,len               : integer;
  fn,n,s                : string;
  SN,CT                 : string;
  DD                    : TRegisterRecord;
  LocalCD               : TCOMMANDDATA;
  StoreCD               : TCOMMANDDATA;
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
  LocalCD:=COMMAND2CD(DRIVE_CONTROLLERTYPE,Drive);
  StoreCD:=LoadDriveRegisterData(LocalCD);
  CT:=StoreCD.DATA;
  if (Length(CT)=0) then CT:=sUN;

  // Get motor serial
  LocalCD:=COMMAND2CD(DRIVE_MOTORSERIAL,Drive);
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
        LocalCD:=IDN2CD(aKey,Drive);
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

procedure TForm1.panelDriveFeedbackResize(Sender: TObject);
begin
  if (Assigned(VelocityDisplay) AND Assigned(ForceDisplay)) then
  begin
    VelocityDisplay.Top:=1;
    VelocityDisplay.Left:=0;
    VelocityDisplay.Width:=(TControl(Sender).Width DIV 2)-6;
    VelocityDisplay.Height:=(TControl(Sender).Height {DIV 2})-2;

    ForceDisplay.Top:=VelocityDisplay.Top;
    ForceDisplay.Left:=VelocityDisplay.Width+VelocityDisplay.Left+12;
    ForceDisplay.Width:=VelocityDisplay.Width;
    ForceDisplay.Height:=VelocityDisplay.Height;
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
  labelSpeed.Enabled:=(NOT JogOnly);
  editSpeed.Enabled:=(NOT JogOnly);
  labelAccel.Enabled:=(NOT JogOnly);
  editAccel.Enabled:=(NOT JogOnly);

  btnTest.Enabled:=(NOT JogOnly);
  btnResetAxis.Enabled:=(NOT JogOnly);
  btnAxisStatus.Enabled:=(NOT JogOnly);

  editReps.Enabled:=(NOT JogOnly);
  btnStart.Enabled:=(NOT JogOnly);
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

procedure TForm1.TabControl1Change(Sender: TObject);
var
  OldDI,NewDI    : TDRIVE;
  TE             : boolean;
  CD             : TCOMMANDDATA;
  DP14           : TDRIVEPARAMETER_0014;
  RR             : TRegisterRecord;
begin
  TE:=Timer1.Enabled;
  if TE then Timer1.Enabled:=false;

  OldDI:=ActiveDriveInfo;
  if Assigned(Sender) then ActiveDrive:=(TTabControl(Sender).TabIndex+1);
  NewDI:=ActiveDriveInfo;

  stDriveAddress.Caption:=InttoStr(NewDI.DRIVEADDRESS);

  // Cleanup old drive data from GUI

  CD:=Default(TCOMMANDDATA);
  CD.CCLASS:=ccDrive;
  CD.SETID:=ActiveDrive;
  CD.DATA:='';

  RR:=Default(TRegisterRecord);
  SetParamDetails(RR);

  ProcessDR14(CD);
  ProcessDR134(CD);
  ProcessDR135(CD);
  ProcessDR144(CD);
  ProcessDR145(CD);
  ProcessDR182(CD);

  VelocityDisplay.Value:=0;
  PositionDisplay.Value:=0;
  ForceDisplay.Value:=0;

  CD.DATA:=sUN;
  ProcessMode(CD);
  ProcessDiagnostic(CD);

  // Get new drive data for GUI

  if (NewDI.MODE<>OldDI.MODE) then
  begin
    CD.DATA:=DecimalToBinaryString(NewDI.MODE);
    ProcessMode(CD);
  end;
  if (NewDI.PHASE<>OldDI.PHASE) then
  begin
    DP14.Raw:=0;
    DP14.Data.CommPhase:=NewDI.PHASE;
    CD.DATA:=DecimalToBinaryString(DP14.Raw);
    ProcessDR14(CD);
  end;
  if (NewDI.FIRMWARE<>OldDI.FIRMWARE) then
  begin
    CD.DATA:=NewDI.FIRMWARE;
    ProcessFirmware(CD);
  end;
  if (NewDI.MOTORTYPE<>OldDI.MOTORTYPE) then
  begin
    CD.DATA:=NewDI.MOTORTYPE;
    ProcessMotorType(CD);
  end;
  if (NewDI.CONTROLLER<>OldDI.CONTROLLER) then
  begin
    CD.DATA:=NewDI.CONTROLLER;
    ProcessControllerType(CD);
  end;
  if (NewDI.MOTORSERIAL<>OldDI.MOTORSERIAL) then
  begin
    CD.DATA:=NewDI.MOTORSERIAL;
    ProcessMotorSerial(CD);
  end;

  // Fill lists with new drive data

  CD:=COMMAND2CD(DRIVE_PARAMLIST,ActiveDrive);
  CD:=LoadDriveRegisterData(CD);
  ProcessIDNList(CD);
  CD:=COMMAND2CD(DRIVE_MODELIST,ActiveDrive);
  CD:=LoadDriveRegisterData(CD);
  ProcessModeList(CD);

  if TE then Timer1.Enabled:=true;
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
  s              : string;
  axis           : integer;
  success        : boolean;
  AxisControl    : TSERCOSREGISTER_AXISCONTROL;
  TaskJogControl : TSERCOSREGISTER_TASKJOGCONTROL;
  CD             : TCOMMANDDATA;
begin
  result:=false;

  if (aDir=TAXISDIRECTION.dirNone) then exit;

  CD:=Default(TCOMMANDDATA);

  if aDir in [TAXISDIRECTION.dirUp,TAXISDIRECTION.dirDown] then
  begin
    axis:=0;
  end;
  if aDir in [TAXISDIRECTION.dirLeft,TAXISDIRECTION.dirRight] then
  begin
    axis:=1;
  end;

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
  success:=ProcessCommand(CD,s);

  CD.CCLASSCHAR:=VMCOMMANDCLASS[ccRegister];
  CD.CSUBCLASSCHAR:=VMREGISTERSUBCLASS[rscDecimalState];
  CD.DATA:=InttoStr(AxisControl.Raw);
  CD.NUMID:=(11+axis); // Axis control
  success:=ProcessCommand(CD,s);

  result:=success;
end;

procedure TForm1.MenuConnectionClick(Sender: TObject);
var
  MI:TMenuItem;
begin
  MI:=TMenuItem(Sender);
  if (Sender=DDL) then
  begin
    btnConnectDDE.Enabled:=MI.Checked;
    editDLLFileName.Enabled:=MI.Checked;
  end;
  if (Sender=Serial) then
  begin
    btnConnectVMRS232.Enabled:=MI.Checked;
    btnConnectDriveRS232.Enabled:=MI.Checked;
    cmboSerialPorts.Enabled:=MI.Checked;
  end;
end;

procedure TForm1.editDLLFileNameClick(Sender: TObject);
var
  FD:string;
begin
  FD:=ExtractFilePath(TEdit(Sender).Text);
  if Length(FD)=0 then FD:=Application.Location;
  OpenDialog1.InitialDir:=FD;
  if OpenDialog1.Execute then
  begin
    TEdit(Sender).Text:=OpenDialog1.FileName;
  end;
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

function TForm1.ProcessCommand(const CD:TCOMMANDDATA;out response:string; prio:boolean=false; blocking:boolean=false; verbose:boolean=false):boolean;
var
  s,c      : string;
  success  : boolean;
  ro       : boolean;
  LocalCD  : TCOMMANDDATA;
  StoreCD  : TCOMMANDDATA;
  wp,wb    : boolean;
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

  if (ActiveConnection=TCONNECTION.conNone) then exit;

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

  if (ActiveConnection=TCONNECTION.conCLCDDE) then
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
    begin
      success:=ProcessSerialCommand(c,s,wp,wb);
    end;
  end;

  response:=s;
  result:=success;
end;

procedure TForm1.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
  lblTime.Caption:=FormatDateTime('dd-mm-yyyy "UTC: "hh"h"-nn"m"-ss"s"', NowUTC);
  Done:=true;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  lblTime.Caption:=FormatDateTime('dd-mm-yyyy "UTC: "hh"h"-nn"m"-ss"s"', NowUTC);
  TTimer(Sender).Tag:=TTimer(Sender).Tag+1;
  if (TTimer(Sender).Tag>5) then editStatus.Text:='';
  if (ActiveConnection<>conNone) then
  begin
    Timer1.Enabled:=false;
    GetDriveData;
    Timer1.Enabled:=true;
  end;
end;

procedure TForm1.UpDownDriveAddressClick(Sender: TObject; Button: TUDBtnType);
var
  DI:TDRIVE;
begin
  if (ActiveConnection<>conNone) then exit;
  DI:=ActiveDriveInfo;
  if (Button=btNext) then DI.DRIVEADDRESS:=DI.DRIVEADDRESS+1;
  if (Button=btPrev) then
  begin
    if (DI.DRIVEADDRESS>1) then DI.DRIVEADDRESS:=DI.DRIVEADDRESS-1;
  end;
  ActiveDriveInfo:=DI;
  stDriveAddress.Caption:=InttoStr(DI.DRIVEADDRESS);
end;

procedure TForm1.ValueListEditor1DblClick(Sender: TObject);
type
  TLookup = record
    Name:string;
    CClass:TVMCOMMANDCLASS;
  end;
const
  CLASSLOOKUP :array[0..6] of TLookup =
   (
   (Name:'I';CClass:ccInteger),
   (Name:'GI';CClass:ccGlobalInteger),
   (Name:'F';CClass:ccFloat),
   (Name:'GF';CClass:ccGlobalFloat),
   (Name:'ABS';CClass:ccAbsPointTable),
   (Name:'REL';CClass:ccRelPointTable),
   (Name:'R';CClass:ccRegister)
   );
var
  VLE:TValueListEditor;
  VC:TVMCOMMANDCLASS;
  s,cc:string;
  i:integer;
begin
  VLE:=TValueListEditor(Sender);
  s:=VLE.Keys[VLE.Row];
  cc:=ExtractWhileConforming(s,['A'..'Z']);
  Delete(s,1,Length(cc));
  for i:=Low(CLASSLOOKUP) to High(CLASSLOOKUP) do
  begin
    if cc=CLASSLOOKUP[i].Name then
    begin
      VC:=CLASSLOOKUP[i].CClass;
      editCommand.Text:=VMCOMMANDCLASS[VC]+VMCOMMANDVARIABLESUBCLASS[TVMCOMMANDVARIABLESUBCLASS.vscData]+' 0.'+s;
      break;
    end;
  end;
end;

procedure TForm1.vleParamDetailsDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  aTextStyle   : TTextStyle;
  s            : string;
  pw           : dword;
  ro           : boolean;
  vle          : TValueListEditor;
begin
  vle:=TValueListEditor(Sender);
  ro:=false;
  s:=vle.Cells[1,5];
  if (s<>'-') then
  begin
    pw:=BinaryStringToDecimal(s);
    ro:=ParameterIsReadOnly(pw,0);
    if (NOT ro) then ro:=ParameterIsReadOnly(pw,ActiveDriveInfo.PHASE);
  end;
  with TValueListEditor(Sender) do
  begin
    //DefaultDrawCell(aCol,aRow,aRect,aState);
    //exit;
    if ((aCol=1) and (aRow=5)) then
    begin
      // Attribute
      s:=Cells[aCol,aRow];
      if (s<>'-') then
      begin
        //aTextStyle:=Canvas.TextStyle;
        //aTextStyle.Alignment := taLeftJustify;
        //Canvas.TextStyle:=aTextStyle;
        //Canvas.Font.Style:=[fsBold];
        pw:=BinaryStringToDecimal(s);
        s:='';
        if ParameterIsReadOnly(pw,0) then s:=s+'RO;';
        if (NOT ParameterIsReadOnly(pw,2)) then s:=s+'P2;';
        if (NOT ParameterIsReadOnly(pw,3)) then s:=s+'P3;';
        if (NOT ParameterIsReadOnly(pw,4)) then s:=s+'P4;';
        if ParameterIsCommand(pw) then s:=s+'CMD;';
        if ParameterIsTime(pw) then s:=s+'TIME;';
        if ParameterIsIDN(pw) then s:=s+'IDN;';
        if ParameterIsChar(pw) then s:=s+'CHAR;';
        if ParameterIsUInt(pw) then s:=s+'UINT;';
        if ParameterIsInt(pw) then s:=s+'INT;';
        if ParameterIsFloat(pw) then s:=s+'FLOAT;';
        if ParameterIsBinary(pw) then s:=s+'BIN;';
        if ParameterIsHex(pw) then s:=s+'HEX;';
        if ParameterIsByteList(pw) then s:=s+'Byte';
        if ParameterIsWordList(pw) then s:=s+'Word';
        if ParameterIsDWordList(pw) then s:=s+'DWord';
        if ParameterIsFloatList(pw) then s:=s+'Float';
        if ParameterIsList(pw) then s:=s+'List;';
        //s:=s+'CV:'+InttoStr(ParameterConversionFactor(IDN))+';';
        s:=s+'Size:'+InttoStr(ParameterSizeOf(pw))+';';
        if (Length(s)=0) then s:=Cells[aCol,aRow];
        Canvas.TextRect(aRect,aRect.Left+1,aRect.Top+1,s);
      end
      else
      begin
        DefaultDrawCell(aCol,aRow,aRect,aState);
      end;
    end
    else
    begin
      // Value
      if ((aCol=1) and (aRow=6)) then
      begin
        if (NOT ro) then
        begin
          Canvas.Brush.Color := clGreen;
          Canvas.Font.Color:=clWhite;
        end;
      end;
      DefaultDrawCell(aCol,aRow,aRect,aState);
    end;
  end;
end;

procedure TForm1.vleParamDetailsEditingDone(Sender: TObject);
var
  vle:TValueListEditor;
  li:TListItem;
  IDN,s,data:string;
  CD:TCOMMANDDATA;
begin
  vle:=TValueListEditor(Sender);
  if vle.Modified then
  begin
    li:=lvParameters.LastSelected;
    if Assigned(li) then
    begin
      s:='';
      if (li.SubItems.Count>0) then s:=li.SubItems[0];
      data:=vle.Cells[1,6];
      if (s<>data) then
      begin
        IDN:=li.Caption;
        CD:=IDN2CD(IDN,ActiveDrive);
        if (CD.CCLASS<>ccNone) then
        begin
          CD.CSUBCLASS:=mscParameterData;
          CD.DATA:=data;
          ProcessCommand(CD,s,true,false);
        end;
      end;
    end;
  end;
end;

procedure TForm1.vleParamDetailsSelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
var
  li:TListItem;
  IDN:TIDN;
begin
  li:=lvParameters.LastSelected;
  if Assigned(li) then
  begin
    IDN:=li.Caption;
    //if (TComponent(Sender).Tag=1) then Editor:=nil;
  end;
end;

procedure TForm1.ProcessDR14(const CD: TCOMMANDDATA);
var
  DP14    : TDRIVEPARAMETER_0014;
  DI      : TDRIVE;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    DP14.Raw:=BinaryStringToDecimal(CD.DATA);
    //SetInfoPanel(PanelPhase1,(DP14.Data.CommPhase=1));
    SetInfoPanel(PanelPhase2,(DP14.Data.CommPhase=2));
    SetInfoPanel(PanelPhase3,(DP14.Data.CommPhase=3));
    SetInfoPanel(PanelPhase4,(DP14.Data.CommPhase=4));

    btnPhase2.Enabled:=(DP14.Data.CommPhase<>2);
    btnPhase3.Enabled:=(DP14.Data.CommPhase<>3);
    btnPhase4.Enabled:=(DP14.Data.CommPhase<>4);

    DI:=ActiveDriveInfo;
    if (DI.PHASE<>DP14.Data.CommPhase) then
    begin
      DI.PHASE:=DP14.Data.CommPhase;
      ActiveDriveInfo:=DI;
      vleParamDetails.Invalidate;
    end;
  end;
end;

procedure TForm1.ProcessDR134(const CD: TCOMMANDDATA);
var
  SC134      : TDRIVEPARAMETER_0134;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    SC134.Raw:=BinaryStringToDecimal(CD.DATA);
    if ((SC134.Data.DriveEnable=1) AND (SC134.Data.DriveOn=1)) then
      SetInfoPanel(PanelHalt,(SC134.Data.DriveHalt=0))
    else
      SetInfoPanel(PanelHalt,False);
    SetInfoPanel(PanelHalt,(SC134.Data.DriveOn=1));
  end;
end;

procedure TForm1.ProcessDR135(const CD: TCOMMANDDATA);
var
  SC135      : TDRIVEPARAMETER_0135;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    SC135.Raw:=BinaryStringToDecimal(CD.DATA);
    SetInfoPanel(PanelControl,(SC135.Data.DriveReady>0));
    SetInfoPanel(PanelPower,(SC135.Data.DriveReady>1));
    SetInfoPanel(PanelEnable,(SC135.Data.DriveReady>2));
  end;
end;

procedure TForm1.ProcessDR144(const CD: TCOMMANDDATA);
begin

end;
procedure TForm1.ProcessDR145(const CD: TCOMMANDDATA);
begin

end;

procedure TForm1.ProcessDR182(const CD: TCOMMANDDATA);
var
  DR182          : TDRIVEPARAMETER_0182;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    DR182.Raw:=BinaryStringToDecimal(CD.DATA);
    SetInfoPanel(panelInPosition,(DR182.Data.EndPosition=1));
    SetInfoPanel(panelStandstill,(DR182.Data.AHQ=1));
    SetInfoPanel(panelTargetPosition,(DR182.Data.InTargetPosition=1));
  end;
end;

procedure TForm1.ProcessMotorSerial(const CD: TCOMMANDDATA);
var
  DI             : TDRIVE;
  LocalCD        : TCOMMANDDATA;
  StoreCD        : TCOMMANDDATA;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    DI:=ActiveDriveInfo;
    DI.MOTORSERIAL:=CD.DATA;
    ActiveDriveInfo:=DI;
    stMotorSerial.Caption:=DI.MOTORSERIAL;
    if ((DI.MOTORSERIAL<>sUN) AND (chkAutoLoadDriveData.Checked)) then
    begin
      ProcessDiskDriveData(ActiveDrive,false);
      // First, retrieve the complete list from the store
      LocalCD:=COMMAND2CD(DRIVE_PARAMLIST,CD.SETID);
      StoreCD:=LoadDriveRegisterData(LocalCD);
      ProcessIDNList(StoreCD);
    end;
  end;
end;

procedure TForm1.ProcessMode(const CD: TCOMMANDDATA);
var
  DI:TDRIVE;
begin
  if (CD.DATA=sUN) then exit;
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    DI:=ActiveDriveInfo;
    DI.MODE:=BinaryStringToDecimal(CD.DATA);
    ActiveDriveInfo:=DI;
    comboDriveModes.Text:=GetDriveModeDescription(DI.MODE);
  end;
end;

procedure TForm1.ProcessMotorType(const CD: TCOMMANDDATA);
var
  DI:TDRIVE;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    DI:=ActiveDriveInfo;
    DI.MOTORTYPE:=CD.DATA;
    ActiveDriveInfo:=DI;
    stMotorType.Caption:=DI.MOTORTYPE;
  end;
end;

procedure TForm1.ProcessFirmware(const CD: TCOMMANDDATA);
var
  DI:TDRIVE;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    DI:=ActiveDriveInfo;
    DI.FIRMWARE:=CD.DATA;
    ActiveDriveInfo:=DI;
    stFirmware.Caption:=DI.FIRMWARE;
  end;
end;

procedure TForm1.ProcessControllerType(const CD: TCOMMANDDATA);
var
  DI             : TDRIVE;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    DI:=ActiveDriveInfo;
    DI.CONTROLLER:=CD.DATA;
    ActiveDriveInfo:=DI;
    stControllerType.Caption:=DI.CONTROLLER;
  end;
end;

procedure TForm1.ProcessAppType(const CD:TCOMMANDDATA);
var
  DI             : TDRIVE;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    DI:=ActiveDriveInfo;
    DI.NAME:=CD.DATA;
    ActiveDriveInfo:=DI;
    stDriveName.Caption:=DI.NAME;
  end;
end;

procedure TForm1.ProcessDiagnostic(const CD: TCOMMANDDATA);
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    stDriveDiagnostic.Caption:=CD.DATA;
  end;
end;

procedure TForm1.ProcessVelocity(const CD: TCOMMANDDATA);
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    VelocityDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);
  end;
end;

procedure TForm1.ProcessPosition(const CD: TCOMMANDDATA);
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    PositionDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);
  end;
end;

procedure TForm1.ProcessForce(const CD: TCOMMANDDATA);
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    ForceDisplay.Value:=StrToFloatDef(CD.DATA,0,DataFormatSettings);
  end;
end;


procedure TForm1.ProcessIDNList(const CD: TCOMMANDDATA);
var
  IDNList     : TStringList;
  LocalDrive  : word;
  i,j,len     : integer;
  aKey        : TIDN;
  LocalCD     : TCOMMANDDATA;
  CC          : TCOMMAND;
  RR          : PRegisterRecord;
  StoreRR     : array of TRegisterRecord;
  te          : boolean;
  li          : TListItem;
begin
  te:=Timer1.Enabled;
  if te then Timer1.Enabled:=false;
  len:=0;
  LocalDrive:=CD.SETID;
  begin
    Memo1.Lines.Append('IDN list drive' +InttoStr(LocalDrive)+' ready.');
    Memo1.Lines.Append('Cleanup drivelist.');

    // We now have the actual IDN list of the drive.
    // Cleanup everything and only use this list !

    IDNList:=TStringList.Create;
    try
      IDNList.CommaText:=CD.DATA;

      IDNList.Sorted:=True;
      IDNList.Duplicates:=dupIgnore;

      // Always add realtime data
      for CC in REALTIMEDRIVEDATA do
      begin
        LocalCD:=COMMAND2CD(CC,LocalDrive);
        aKey:=GetIDN(LocalCD);
        IDNList.Append(aKey);
      end;

      // Always add basic data
      for CC in BASICDRIVEDATA do
      begin
        LocalCD:=COMMAND2CD(CC,LocalDrive);
        aKey:=GetIDN(LocalCD);
        IDNList.Append(aKey);
      end;

      len:=IDNList.Count;
      SetLength({%H-}StoreRR,len+3);
      // Store all valid data in a temporary array
      j:=0;
      if (len>0) then
      begin
        for i:=0 to Pred(len) do
        begin
          aKey:=IDNList[i];
          LocalCD:=IDN2CD(aKey,LocalDrive);
          RR:=LoadDriveRegisterDataRaw(LocalCD);
          if Assigned(RR) then
          begin
            StoreRR[j]:=RR^;
            Inc(j);
          end
          else
          begin
            LocalCD.SETID:=0;
            RR:=LoadDriveRegisterDataRaw(LocalCD);
            if Assigned(RR) then
            begin
              StoreRR[j]:=RR^;
              Inc(j);
            end;
          end;
        end;
      end;

      len:=j;

      // Clear all data in memory
      ClearDriveRegisterData(LocalDrive);

      // Save cleanup data in memory
      if (len>0) then for i:=0 to Pred(len) do SaveDriveRegisterDataRaw(LocalDrive,StoreRR[i]);

      // This is a GUI update, so only process if we have data of the current visible drive
      if (CD.SETID=ActiveDrive) then
      begin
        lvParameters.BeginUpdate;
        lvParameters.Clear;
        if (len>0) then
        begin
          for i:=0 to Pred(len) do
          begin
            aKey:=GetIDN(StoreRR[i]);
            li:=lvParameters.Items.Add;
            li.Caption:=aKey;
            li.SubItems.Append(StoreRR[i].Value);
            li.SubItems.Append(StoreRR[i].Name);
          end;
        end;
        lvParameters.EndUpdate;
        lvParameters.Sort;
      end;

    finally
      IDNList.Free;
    end;

  end;
  if (len>0) then
  begin
    FDCStatus:=TDATACOLLECTION.dcIDNData;
  end;
  if te then Timer1.Enabled:=true;
end;

procedure TForm1.AddIDNListItem(const CD: TCOMMANDDATA);
var
  li:TListItem;
  IDN:TIDN;
  PRR:PRegisterRecord;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    IDN:=GetIDN(CD);
    li:=lvParameters.Items.FindCaption(0,IDN,false,true,false,true);
    if (NOT Assigned(li)) then
    begin
      li:=lvParameters.Items.Add;
      li.Caption:=IDN;
      li.SubItems.Append('');
      li.SubItems.Append('');
    end;
    PRR:=LoadDriveRegisterDataRaw(CD);
    if Assigned(PRR) then
    begin
      li.SubItems[0]:=PRR^.Value;
      li.SubItems[1]:=PRR^.Name;
    end;
  end;
end;

procedure TForm1.AddIDNListValue(const CD:TCOMMANDDATA);
var
  li        : TListItem;
  IDN       : TIDN;
  s         : string;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    if CD.CCLASS in [ccDrive,ccDriveSpecific] then
    begin
      s:=CD.DATA;
      IDN:=GetIDN(CD);

      if (CD.CSUBCLASS=mscParameterData) then
      begin
        if DriveParameterIsDriveMode(IDN) then s:=GetDriveModeDescription(s);
      end;

      if CD.CSUBCLASS in [mscParameterData,mscName] then
      begin
        li:=lvParameters.Items.FindCaption(0,IDN,false,true,false,true);
        if Assigned(li) then
        begin
          if (CD.CSUBCLASS=mscParameterData) then
          begin
            li.SubItems.Strings[0]:=s;
          end;
          if (CD.CSUBCLASS=mscName) then
          begin
            li.SubItems.Strings[1]:=s;
          end;
        end;
      end;

      if (IDN=vleParamDetails.Strings.ValueFromIndex[0]) then
      begin
        SetParamDetails(CD);
      end;
    end;
  end;
end;

procedure TForm1.ShowDataUpdateInfo(s:string);
begin
  //memoDataUpdate.Lines.Append(s);
  //memoDataUpdate.CaretPos.SetLocation(0,memoDataUpdate.Lines.Count);

  synDataUpdate.Lines.Append(s);
  synDataUpdate.CaretX:=0;
  synDataUpdate.CaretY:=synDataUpdate.Lines.Count;
end;

procedure TForm1.ProcessModeList(const CD: TCOMMANDDATA);
var
  s,d      : string;
  i        : word;
  DW       : DATAWORD;
  DB       : DATABYTE;
  OM       : TOPERATIONMODE;
  LagLess  : boolean;
  OMData   : POMD;
begin
  // This is a GUI update, so only process if we have data of the current visible drive
  if (CD.SETID=ActiveDrive) then
  begin
    comboDriveModes.Items.Clear;
    lbDriveModes.Items.Clear;
    for OM in TOPERATIONMODE do
    begin
      DriveOperationModes[OM].Valid:=False;
      DriveOperationModesLagLess[OM].Valid:=False;
    end;

    s:=CD.DATA;
    // Get data
    repeat
      i:=Pos(',',s);
      if (i=0) then
      begin
        d:=s;
      end
      else
      begin
        d:=Copy(s,1,i-1);
        Delete(s,1,i);
      end;
      if (Pos(sLISTFINISHED,d)=1) then break;
      DW.Raw:=HexStringToDecimal(d);
      OM:=GetDriveMode(DW.Raw);
      if (OM<>TOPERATIONMODE.omNone) then
      begin
        LagLess:=(DW.Bits[3]=1);
        if LagLess then
          OMData:=@DriveOperationModesLagLess
        else
          OMData:=@DriveOperationModes;
        OMData^[OM].Valid:=True;
      end;
      if i=0 then break;
    until false;

    for OM in TOPERATIONMODE do
    begin
      for LagLess in boolean do
      begin
        OMData:=nil;
        if LagLess then
          OMData:=@DriveOperationModesLagLess
        else
          OMData:=@DriveOperationModes;
        if (OMData^[OM].Valid) then
        begin
          DB.Raw:=Ord(OM);
          if OMData^[OM].Lagless then DB.Bits[7]:=1; // set bit 7, we have a lagless mode
          comboDriveModes.Items.AddObject(OMData^[OM].Name,TObject(PtrUInt(DB.Raw)));
          lbDriveModes.Items.AddObject(OMData^[OM].Name,TObject(PtrUInt(DB.Raw)));
          s:=OMData^[OM].Name;
          s:=s+'.';
          Memo1.Lines.Append('List data. Mode: '+s);
        end;
      end;
    end;
  end;
end;

function TForm1.GetPrio(const CD:TCOMMANDDATA):boolean;
begin
  result:=false;
end;

function TForm1.GetBlocking(const CD:TCOMMANDDATA):boolean;
begin
  result:=false;
end;

procedure TForm1.SetActiveConnection(value : TCONNECTION);
begin
  if (value<>FActiveConnection) then
  begin
    FActiveConnection:=value;
    if (FActiveConnection<>TCONNECTION.conNone) then
    begin
      FDCStatus:=TDATACOLLECTION.dcBasic;
    end;

  end;
end;

procedure TForm1.OnRXUSBCData(Sender: TObject);
begin
  OnCommData(FComDevice.Data);
end;

{$ifdef MSWindows}
procedure TForm1.OnRXDDEData(Sender: TObject);
begin
  OnCommData(FComDevice.Data);
end;
{$endif}

procedure TForm1.OnCommData(const s:string);
var
  CD:TCOMMANDDATA;
begin
  Memo1.Lines.Append('Received: '+s);
  CD:=ProcessCommDataString(s);
  ProcessCommResult(CD);
end;

function TForm1.ProcessCommDataString(s:string):TCOMMANDDATA;
var
  index,j:integer;
  ro:boolean;
  SC_IDN:boolean;
  cs,rcs:byte;
  PW:IDNWORD;
  cc:TVMCOMMANDCLASS;
  csc:TVMCOMMANDPARAMETERSUBCLASS;
  s1:string;
  data:string;
begin
  Result:=Default(TCOMMANDDATA);

  // Parse datastring from serial port

  data:=s;

  if Pos('Error',data)=1 then
  begin
    // ToDo: handle error
    Result.CCLASS:=ccError;
    Result.ERROR:='We got an error !!';
    exit;
  end;

  if DirectDrive then
  begin
    Result:=IDN2CD(s,0);
    //Result:=IDN2CD(s,ActiveDrive);
    if ((Result.CCLASS=ccDrive) OR (Result.CCLASS=ccDriveSpecific)) then
    try
      Delete(s,1,9); // delete IDN and comma
      SC_IDN:=false;
      if (Length(s)>0) then
      begin
        // Extract subclass
        j:=Ord(s[1])-48;
        case j of
          1: SC_IDN:=true; // This is IDN data. Must be treated special (for DirectDrive commands)
          //1: Result.CSUBCLASS:=mscParameterData; // This is IDN data. Not sure what to do with it.
          2: Result.CSUBCLASS:=mscName;
          3: Result.CSUBCLASS:=mscAttributes;
          4: Result.CSUBCLASS:=mscUnits;
          5: Result.CSUBCLASS:=mscLowerLimit;
          6: Result.CSUBCLASS:=mscUpperLimit;
          7: Result.CSUBCLASS:=mscParameterData;
        else
          // we should never be here !!!
          raise EArgumentException.Create ('Wrong subclass in DirectData response from Drive !');
        end;
        // Delete subclass and comma
        Delete(s,1,2);
      end;
      ro:=false;
      if (Length(s)>0) then
      begin
        // Extract read or write indicator
        ro:=(s[1]='r');
        // Delete indicator itself
        Delete(s,1,1);
        // Delete the comma, folowing the write command
        // Delete all terminators following the read command
        // Data written will be after this comma
        // Data will be after these terminators
        s1:=ExtractWhileConforming(s,[',',#10,#13]);
        Delete(s,1,length(s1));
      end;

      if (Length(s)>0) then
      begin
        if (NOT ro) then
        begin
          // Get the data written !
          // Look for terminator
          index:=Pos(#13,s);
          if (index=0) then index:=Pos(#10,s);
          if (index>0) then Result.DATA:=Copy(s,1,index-1);
          // Delete datastring, if any
          Delete(s,1,index);
          // Delete all remaining terminators, if any
          s1:=ExtractWhileConforming(s,[#10,#13]);
          Delete(s,1,length(s1));
          if SC_IDN then Result.DATA:='';
        end;
      end;

      if (Length(s)>0) then
      begin
        // Check if we have an error
        if (s[1]='#') then
        begin
          // Extract error
          // Look for terminator
          index:=Pos(#13,s);
          if (index=0) then index:=Pos(#10,s);
          if (index>0) then Result.ERROR:=Copy(s,1,index-1);
          // Delete datastring, if any
          Delete(s,1,index);
          // Delete all remaining terminators, if any
          s1:=ExtractWhileConforming(s,[#10,#13]);
          Delete(s,1,length(s1));
        end;
      end;

      if (Length(s)>0) then
      begin
        //if (ro AND (Length(Result.ERROR)=0)) then
        //if ro then
        begin
          // Get all read data, if any
          repeat
            // Look for terminator
            index:=Pos(#13,s);
            if (index=0) then index:=Pos(#10,s);
            if (index=0) then
            begin
              // We now should have something like "A01:>" in s
              // So, final two characters are the terminator TERDT
              {$ifdef ALLOWCONVERRORS}
              if (Pos(TERDT,s)<>(Length(s)-Length(TERDT)+1)) then
              begin
                raise EArgumentException.Create ('Wrong or missing terminator in data string.');
              end;
              {$endif}
              // Delete leading drive character
              Delete(s,1,1);
              s1:=ExtractWhileConforming(s,['0'..'9']);
              Result.SETID:=StringToIntSafe(s1);
              index:=Length(Result.DATA);
              if (index>0) then
              begin
                // Delete final comma from data, if any
                if Result.DATA[index]=',' then Delete(Result.DATA,index,1);
              end;
              // Do we have a list of data ?
              if (Pos(',',Result.DATA)>0) then
              begin
                Result.CSUBCLASS:=mscList;
                Result.STEPID:=STEPLISTSTART;
                //index:=OccurrencesOfChar(Result.DATA,',');
                //Result.DATA:=InttoStr(Succ(index))+','+Result.DATA;
              end;
              // We are ready, so end the loop
              break;
            end;
            Result.DATA:=Result.DATA+Copy(s,1,index-1)+',';
            // Delete datastring, if any
            Delete(s,1,index);
            // Delete all remaining terminators, if any
            s1:=ExtractWhileConforming(s,[#10,#13]);
            Delete(s,1,length(s1));
            // Only parameter data can ever be a list of data
            //if (Result.CSUBCLASS<>mscParameterData) then s:=''; // wrong: address must yet be parsed from 'E02:>'
          until false;
        end;
      end;
    except
      Result.CCLASS:=ccNone;
      Result.SETID:=0;
    end;
  end
  else
  begin
    // NON directdrive have a connection address if RS232 is used for comms


    if ((s[1]='>') AND ((Ord(s[2])-48)=CLCADDRESS))   then
    begin
      index:=Pos(CSS,s);
      if (index>0) then // process and check checksum
      begin
        rcs:=StringToIntSafe(Copy(s,index,3));
        s:=Copy(s,1,index-1);
        cs:=GenerateVisualMotionChecksum(s);
        Delete(s,Length(s),1);
      end;
      if ((index=0) OR (rcs=cs)) then // no checksum or correct checksum : process data
      begin
        // Delete pre-amble and space
        Delete(s,1,3);
        for cc in TVMCOMMANDCLASS do
        begin
          if VMCOMMANDCLASS[cc]=s[1] then
          begin
            Result.CCLASS:=cc;
            break;
          end;
        end;
        if IsParameterClass(Result.CCLASS) then
        begin
          for csc in TVMCOMMANDPARAMETERSUBCLASS do
          begin
            if csc=mscNone then continue;
            if VMCOMMANDPARAMETERSUBCLASS[csc]=s[2] then
            begin
              Result.CSUBCLASS:=csc;
              break;
            end;
          end;
          // If we have a list, prepare the stepid already
          if (Result.CSUBCLASS=mscList) then Result.STEPID:=STEPLISTSTART;
        end
        else
        begin
          Result.CCLASS:=ccNone;
          Result.CCLASSCHAR:=s[1];
          Result.CSUBCLASSCHAR:=s[2];
        end;
        // Delete class-id and space
        Delete(s,1,3);
        //Extract drive-id
        s1:=ExtractWhileConforming(s,['0'..'9']);
        Result.SETID:=StringToIntSafe(s1);
        //Delete drive-id and .
        Delete(s,1,Length(s1)+1);

        // Extract parameter
        s1:=ExtractWhileConforming(s,['0'..'9']);
        PW.Raw:=StringToIntSafe(s1);
        Delete(s,1,length(s1));
        if (Result.CCLASS=ccDrive) then
        begin
          // Check special ID's
          Result.MEMORY:=(PW.Data.ParamBlock=7);
          if PW.Data.ParamType=1 then Result.CCLASS:=ccDriveSpecific;
        end;
        Result.NUMID:=PW.Data.ParamNum;
        if (Length(s)>0) then
        begin
          if (s[1]='.') then
          begin
            Delete(s,1,1);
            s1:=ExtractWhileConforming(s,['0'..'9']);
            Result.STEPID:=StringToIntSafe(s1);
            Delete(s,1,length(s1));
            if (Result.STEPID=0) then Result.STEPID:=STEPLISTSTART;
          end;
        end;
        if ((Length(s)>0) AND (s[1]=' ')) then Delete(s,1,1); // delete space in front of datastring, if any
        if (Length(s)>0) then
        begin
          if s[1]='!' then
          begin
            // We have an error !!
            // Get number and description
            Delete(s,1,1);
            s1:=ExtractWhileConforming(s,['0'..'9']);
            Result.ERROR:=s1;
            Delete(s,1,length(s1));
            if ((Length(s)>0) AND (s[1]=' ')) then Delete(s,1,1); // delete space in front of errorstring, if any
          end;
          Result.DATA:=Trim(s);
        end;
      end;
    end;
  end;

  {$ifdef ALLOWCONVERRORS}
  if (Result.SETID=0) then
  begin
    raise EArgumentException.Create ('Could not determine drive address from raw datastring.');
  end;
  {$endif}

end;

procedure TForm1.ProcessCommResult(const CD:TCOMMANDDATA);
var
  rt,list  : boolean;
  i,len    : word;
  success  : boolean;
  CC       : TCOMMAND;
  s        : string;
  ATT      : ATTRIBUTEDWORD;
  LocalCD  : TCOMMANDDATA;
  IDNCD    : TCOMMANDDATA;
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
    ShowDataUpdateInfo('Error !!!');
    ShowDataUpdateInfo('Error message: '+s);
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
    success:=ProcessCommand(LocalCD,s,true,false);
    exit;
  end;

  if (CD.DATA='ERROR') then exit;

  rt:=false;

  if (NOT (LocalCD.CSUBCLASS in [mscBlock,mscList])) then
  begin
    // We handle lists later
    SaveDriveRegisterData(LocalCD);
  end;

  if CD.CSUBCLASS in [mscParameterData,mscName] then
  begin
    AddIDNListValue(LocalCD);
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
    // Do not report the realtime data
    if (NOT rt) then
    begin
      ShowDataUpdateInfo(GetIDN(LocalCD)+'. Drive '+InttoStr(LocalCD.SETID)+' '+LowerCase(VMCOMMANDPARAMETERSUBCLASSLONG[LocalCD.CSUBCLASS])+' update: '+LocalCD.DATA);
    end;

    with DRIVE_PRIMARYMODE do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))         then ProcessMode(LocalCD);
    with DRIVE_SPEED do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))               then ProcessVelocity(LocalCD);
    with DRIVE_POSITION do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))            then ProcessPosition(LocalCD);
    with DRIVE_TORQUE do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))              then ProcessForce(LocalCD);
    with DRIVE_INTERFACE do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))           then ProcessDR14(LocalCD);
    with DRIVE_CONTROLWORD do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))         then ProcessDR134(LocalCD);
    with DRIVE_STATUSWORD do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))          then ProcessDR135(LocalCD);
    with DRIVE_SIGNAL_STATUSWORD do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))   then ProcessDR144(LocalCD);
    with DRIVE_SIGNAL_CONTROLWORD do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))  then ProcessDR145(LocalCD);
    with DRIVE_DIAGNOSTIC_CLASS3 do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))   then ProcessDR182(LocalCD);
    with DRIVE_DIAGNOSTIC do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))          then ProcessDiagnostic(LocalCD);
    with DRIVE_APPTYPE do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))             then ProcessAppType(LocalCD);
    with DRIVE_FIRMWARE do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))            then ProcessFirmware(LocalCD);
    with DRIVE_MOTORTYPE do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))           then ProcessMotorType(LocalCD);
    with DRIVE_CONTROLLERTYPE do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))      then ProcessControllerType(LocalCD);
    with DRIVE_MOTORSERIAL do if ((LocalCD.CCLASS=CCLASS) AND (LocalCD.NUMID=NUMID))         then ProcessMotorSerial(LocalCD);
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
            success:=ProcessCommand(LocalCD,s);
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
            AddIDNListItem(IDNCD);
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

    if list then
    begin
      editStatus.Text:='List '+GetIDN(LocalCD)+' of drive '+InttoStr(LocalCD.SETID)+' ready !';

      // And process complete list data !
      if (LocalCD.NUMID=DRIVE_MODELIST.NUMID) then
      begin
        ProcessModeList(LocalCD);
      end
      else
      if (LocalCD.NUMID=DRIVE_PARAMLIST.NUMID) then
      begin
        ProcessIDNList(LocalCD);
      end
      else
      begin
        LocalCD.CSUBCLASS:=mscParameterData;
        AddIDNListValue(LocalCD);
      end;
    end;

  end;

end;

end.

