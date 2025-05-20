unit drive;

{$mode ObjFPC}{$H+}

{$i customdefines.inc}

interface

uses
  Classes, SysUtils,
  Contnrs,
  FGL,
  bits, common;

type
  TOPERATIONMODE                    = (omNone,omTC,omVC,omPCE1,omPCE2,omPCE12,omPC,omDIE1,omDIE2,omDIE12,omRDIE1,omRDIE2,omRDIE12,omPCBME1,omPCBME2,omPCBME12,omVSV,omASVE1,omASVE2,omCAMVE1,omCAMVE2,omASE1,omVS,omCAME1,omSM,omJM);
  TOMDATA = record
    Valid    : boolean;
    Lagless  : boolean;
    BitMask  : word;
    Name     : string;
  end;

  POMD = ^TOMD;
  TOMD = array[TOPERATIONMODE] of TOMDATA;

  //S-0-0011, Class 1 diagnostics
  TDRIVEPARAMETER_0011 = bitpacked record
      case integer of
          1 : (  Data : record
                   Reserved0                               : T1BITS;
                   AmplifierOvertemperatureShutdown        : T1BITS;
                   MotorOvertemperatureShutdown            : T1BITS;
                   Reserved1                               : T1BITS;
                   ControlVoltageError                     : T1BITS;
                   FeedbackError                           : T1BITS;
                   Reserved2                               : T1BITS;
                   Overcurrent                             : T1BITS;
                   Reserved3                               : T1BITS;
                   UndervoltageError                       : T1BITS;
                   Reserved4                               : T1BITS;
                   ExcessiveDeviation                      : T1BITS;
                   CommunicationError                      : T1BITS;
                   TravelLimitSwitchExceeded               : T1BITS;
                   Reserved5                               : T1BITS;
                   ManufacturerSpecificError               : T1BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;


  //S-0-0012, Class 2 diagnostics
  TDRIVEPARAMETER_0012 = bitpacked record
      case integer of
          1 : (  Data : record
                   OverloadWarning                         : T1BITS;
                   AmplifierOvertemperatureWarning         : T1BITS;
                   MotorOvertemperatureWarning             : T1BITS;
                   Reserved1                               : T2BITS;
                   PositioningVelocity                     : T1BITS;
                   Reserved2                               : T7BITS;
                   TargetPositionOutsideTravellimitSwitch  : T1BITS;
                   Reserved3                               : T1BITS;
                   ManufacturerSpecificWarning             : T1BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  //S-0-0013, Class 3 diagnostics
  TDRIVEPARAMETER_0013 = bitpacked record
      case integer of
          1 : (  Data : record
                   VelocityCommand          : T1BITS;
                   VelocityLow              : T1BITS;
                   VelocityLimit            : T1BITS;
                   MDgetMDx                 : T1BITS;
                   MDgetMDLimit             : T1BITS;
                   Reserved1                : T1BITS;
                   InPosition               : T1BITS;
                   PgtPx                    : T1BITS;
                   Reserved2                : T4BITS;
                   PositionReached          : T1BITS;
                   Reserved3                : T3BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_0014 = bitpacked record
      case integer of
          1 : (  Data : record
                   CommPhase                : T3BITS;
                   Reserved1                : T1BITS;
                   MDTFailure               : T1BITS;
                   InvalidPhase             : T1BITS;
                   PhaseUpError             : T1BITS;
                   PhaseDownError           : T1BITS;
                   PhaseSwitchMessage       : T1BITS;
                   Reserved2                : T7BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_0076 = bitpacked record
      case integer of
          1 : (  Data : record
                   ScalingType              : T3BITS;
                   ScalingSelection         : T1BITS;
                   LengthUnit               : T1BITS;
                   Reserved1                : T1BITS;
                   DataReference            : T1BITS;
                   ProcessingFormat         : T1BITS;
                   Reserved2                : T8BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_0134 = bitpacked record
      case integer of
          1 : (  Data : record
                   ControlInfoServiceChannel : T6BITS;
                   RealtimeStatus            : T2BITS;
                   CommandMode               : T2BITS;
                   IPOSYNC                   : T1BITS;
                   Reserved1                 : T2BITS;
                   DriveHalt                 : T1BITS;
                   DriveEnable               : T1BITS;
                   DriveOn                   : T1BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_0135 = bitpacked record
      case integer of
          1 : (  Data : record
                   ControlInfoServiceChannel : T2BITS;
                   Reserved1                 : T3BITS;
                   ChangeCommands            : T1BITS;
                   RealtimeStatus            : T2BITS;
                   ActualMode                : T3BITS;
                   ChangeClass3Diag          : T1BITS;
                   ChangeClass2Diag          : T1BITS;
                   ChangeClass1Diag          : T1BITS;
                   DriveReady                : T2BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_0147 = bitpacked record
      case integer of
          1 : (  Data : record
                   StartDirection           : T1BITS;
                   Reserved1                : T1BITS;
                   HomeSwitchConnected      : T1BITS;
                   FeedbackSelection        : T1BITS;
                   Reserved2                : T1BITS;
                   HomeSwitchEvaluation     : T1BITS;
                   ReferenceMarkEvaluation  : T1BITS;
                   PositionAfterHoming      : T1BITS;
                   ReferencingPath          : T1BITS;
                   Reserved3                : T7BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_0154 = bitpacked record
      case integer of
          1 : (  Data : record
                   Direction          : T2BITS; // 0 = clockwise ; 1 = counter-clockwise ; 2 = shortest
                   TraversingMethod   : T1BITS; // 0 = spindle angular position ; 1 = spindle path
                   Encoder            : T1BITS; // 0 = moto ; 1 = external
                   Reserved5          : T12BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  //S-0-0182, Manufacturer Class 3 Diagnostics
  TDRIVEPARAMETER_0182 = bitpacked record
      case integer of
          1 : (  Data : record
                   Reserved1          : T1BITS;
                   Velocity           : T1BITS;
                   Reserved2          : T4BITS;
                   IZP                : T1BITS;
                   Load               : T1BITS;
                   Reserved3          : T2BITS;
                   InTargetPosition   : T1BITS;
                   AHQ                : T1BITS;
                   EndPosition        : T1BITS;
                   Reserved4          : T3BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_0342 = bitpacked record
      case integer of
          1 : (  Data : record
                   PositionReached          : T1BITS;
                   Reserved5                : T15BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;


  TDRIVEPARAMETER_0346 = bitpacked record
      case integer of
          1 : (  Data : record
                   AcceptPositionToggle     : T1BITS;
                   PositioningJogging       : T2BITS; // 00 = Positioning active [toggling bit 0]; 01 = jogging + ; 10 = jogging - ; 11 = positioning stop
                   PositionType             : T1BITS; // 0 = absolute; 1 = relative
                   Reference                : T1BITS; // 0 = reference for positioning is the "last effective target position S-0-0430" ; 1 = reference for positioning is the current actual position value S-0-386
                   TargetOverride           : T1BITS; // 0 = drive moves to current target position before moving to new target ; 1 = directly to new target
                   SequentialBlockBehavior  : T2BITS; // 00 = halt at target ; 01 = overrunning mode 1 ; 10 = overrunning mode 2
                   Reserved2                : T8BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_0393 = bitpacked record
      case integer of
          1 : (  Data : record
                   Mode                     : T2BITS; // 0 = shortest way; 1 = positive direction; 2 = negative direction
                   TargetPosAfter           : T1BITS; // 0 = position to S-0-0258; 1 = position to actual position
                   PositionType             : T1BITS; // 0 = absolute; 1 = relative
                   SetpointAcceptance       : T1BITS;
                   Reserved2                : T11BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_0403 = bitpacked record  // Position feedback value status
      case integer of
          1 : (  Data : record
                   PositionFeedbackValues   : T1BITS;
                   StatusMotorFeedback      : T1BITS;
                   StatusFeedback2          : T1BITS;
                   Reserved1                : T13BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEMODE = bitpacked record  // Position feedback value status
      case integer of
          1 : (  Data : record
                   BasicOperationMode        : T3BITS;
                   Lagless                   : T1BITS;
                   ExpandedOperationMode     : T4BITS;
                   TransitionSupport         : T1BITS;
                   AxisControl               : T1BITS;
                   Reserved                  : T5BITS;
                   ManufacturerOperationMode : T1BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

const
  MAXDRIVES                    = 255;

  SCALINGMODE                  : array [0..2] of string = ('not scaled','linear scaling','rotary scaling');
  SCALINGSELECTION             : array [0..1] of string = ('preferred scaling','parameter scaling');
  SCALINGUNIT                  : array [0..1] of string = ('meter','inch');
  SCALINGRELATION              : array [0..1] of string = ('to the motor cam','to the load');
  SCALINGFORMAT                : array [0..1] of string = ('absolute','modulo');
  MODULOCOMMANDMODE            : array [0..2] of string = ('shortest path','positive direction','negative direction');

  DRIVE_FIRMWARE               : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 30);
  DRIVE_PRIMARYMODE            : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 32);
  DRIVE_SECONDARYMODE1         : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 33);
  DRIVE_SECONDARYMODE2         : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 34);
  DRIVE_SECONDARYMODE3         : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 35);
  DRIVE_CONTROLLERTYPE         : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 140);
  DRIVE_MOTORTYPE              : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 141);
  DRIVE_APPTYPE                : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 142);
  DRIVE_MOTORSERIAL            : TCOMMAND = (CCLASS: ccDriveSpecific; CSUBCLASS: mscParameterData; NUMID: 4088);

  DRIVE_CONTROLWORD            : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 134);
  DRIVE_STATUSWORD             : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 135);
  DRIVE_DIAGNOSTIC             : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 95);
  DRIVE_INTERFACE              : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 14);

  DRIVE_POSITION               : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 51);
  DRIVE_TARGET                 : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 47);
  DRIVE_SPEED                  : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 40);
  DRIVE_TORQUE                 : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 84);

  DRIVE_MODELIST               : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscList;          NUMID: 292);
  DRIVE_PARAMLIST              : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscList;          NUMID: 17);

  DRIVE_SIGNAL_STATUSWORD      : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 144);
  DRIVE_SIGNAL_CONTROLWORD     : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 145);

  DRIVE_DIAGNOSTIC_CLASS1                   : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 11);
  DRIVE_DIAGNOSTIC_CLASS2                   : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 12);
  DRIVE_DIAGNOSTIC_CLASS3                   : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 13);
  DRIVE_MANUFACTURER_DIAGNOSTIC_CLASS3      : TCOMMAND = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 182);

  function  SaveDriveRegisterData(const CD:TCOMMANDDATA):boolean;
  function  SaveDriveRegisterDataRaw(const DriveNumber:word; const RR:TRegisterRecord):boolean;overload;
  function  SaveDriveRegisterDataRaw(const DriveNumber:word; aKey:TIDN; aValue:PRegisterRecord):boolean;overload;
  function  SaveDriveRegisterDataRaw(const CD:TCOMMANDDATA; aValue:PRegisterRecord):boolean;overload;

  function  LoadDriveRegisterData(const CD:TCOMMANDDATA):TCOMMANDDATA;
  function  LoadDriveRegisterDataRaw(const CD:TCOMMANDDATA):PRegisterRecord;overload;
  function  LoadDriveRegisterDataRaw(const DriveNumber:word; const index:word):PRegisterRecord;overload;
  function  LoadDriveRegisterDataRaw(const DriveNumber:word; const aKey:TIDN):PRegisterRecord;overload;

  procedure DeleteDriveRegisterData(const CD:TCOMMANDDATA);
  procedure ClearDriveRegisterData(const DriveNumber:word);
  function  DriveRegisterDataCount(const DriveNumber:word):integer;


  function  GetDirectDriveCommand(const CD:TCOMMANDDATA):string;
  function  GetDriveAttribute(const CD:TCOMMANDDATA):dword;

  function  GetDriveModeDescription(const mw:word):string; overload;
  function  GetDriveModeDescription(const ms:string):string; overload;
  function  GetDriveMode(const mw:word):TOPERATIONMODE;

  function  DriveParameterIsDriveMode(const IDN:TIDN):boolean;

  function  GetDriveInfo(const Drive:word):TDRIVE;
  procedure SetDriveInfo(const Drive:word; value:TDRIVE);

  function GetDriveErrorDescription(derr:word):string;

var
  DriveOperationModes         : TOMD;
  DriveOperationModesLagLess  : TOMD;
  BASICDRIVEDATA              : array[0..5] of TCOMMAND;
  REALTIMEDRIVEDATA           : array[0..8] of TCOMMAND;

implementation

const
{$I driveconstants.inc}

var
  IDNDriveList                : array[0..MAXDRIVES] of TMySortedMap;
  DriveList                   : array[1..MAXDRIVES] of TDRIVE;

function  GetDriveInfo(const Drive:word):TDRIVE;
begin
  result:=DriveList[Drive];
  if (Length(result.NAME)=0) then result.NAME:=sUN;
  if (Length(result.FIRMWARE)=0) then result.FIRMWARE:=sUN;
  if (Length(result.CONTROLLER)=0) then result.CONTROLLER:=sUN;
  if (Length(result.MOTORTYPE)=0) then result.MOTORTYPE:=sUN;
  if (Length(result.MOTORSERIAL)=0) then result.MOTORSERIAL:=sUN;
end;

procedure SetDriveInfo(const Drive:word; value:TDRIVE);
begin
  DriveList[Drive]:=value;
end;

function GetDirectDriveCommand(const CD:TCOMMANDDATA):string;
const
  //--------------------------------------------------------------------------------------------
  // Data Block Elements
  //--------------------------------------------------------------------------------------------
  CSMD_SERC_ELEM0            = 0;   // Close Service Channel
  CSMD_SERC_ELEM1            = 1;   // IDN
  CSMD_SERC_ELEM2            = 2;   // Name
  CSMD_SERC_ELEM3            = 3;   // Attribute
  CSMD_SERC_ELEM4            = 4;   // Unit
  CSMD_SERC_ELEM5            = 5;   // Min. Value
  CSMD_SERC_ELEM6            = 6;   // Max. Value
  CSMD_SERC_ELEM7            = 7;   // Data
var
  IDN      : string;
  be       : byte;
begin
  result:=sERR;

  if (NOT (CD.CCLASS in [ccDrive,ccDriveSpecific])) then exit;

  IDN:=GetIDN(CD);

  case CD.CSUBCLASS of
    mscNone          : be:=CSMD_SERC_ELEM1;
    mscAttributes    : be:=CSMD_SERC_ELEM3;
    mscUpperLimit    : be:=CSMD_SERC_ELEM6;
    mscLowerLimit    : be:=CSMD_SERC_ELEM5;
    mscParameterData,
    mscBlock,
    mscList          : be:=CSMD_SERC_ELEM7;
    mscName          : be:=CSMD_SERC_ELEM2;
    mscUnits         : be:=CSMD_SERC_ELEM4;
  end;

  if (Length(CD.DATA)=0) then
    result:=Format('%s,%d,r',[IDN,be])
  else
    result:=Format('%s,%d,w,',[IDN,be]);
end;

function GetDriveAttribute(const CD:TCOMMANDDATA):dword;
begin
  result:=GetAttribute(IDNDriveList[CD.SETID],CD);
end;

function GetDriveModeDescription(const mw:word):string;
var
  DW        : DATAWORD;
  Lagless   : boolean;
  OMD       : TOMDATA;
  OM        : TOPERATIONMODE;
begin
  Result:='';
  DW.Raw:=mw;
  Lagless:=(DW.Bits[3]=1);
  DW.Bits[3]:=0;
  for OM in TOPERATIONMODE do
  begin
    OMD:=TOPERATIONMODES[OM];
    if DW.Raw=OMD.BitMask then
    begin
      Result:=OMD.Name;
      if (OM=omJM) then Lagless:=False;
      break;
    end;
  end;
  if (Lagless AND (Length(Result)>0))then Result:=Result+' (lagless)';
end;

function GetDriveModeDescription(const ms:string):string; overload;
var
  mw:word;
begin
  mw:=BinaryStringToDecimal(ms);
  result:=GetDriveModeDescription(mw);
end;

function GetDriveMode(const mw:word):TOPERATIONMODE;
var
  DW       : DATAWORD;
  OM       : TOPERATIONMODE;
begin
  Result:=TOPERATIONMODE.omNone;
  DW.Raw:=mw;
  DW.Bits[3]:=0;
  for OM in TOPERATIONMODE do
  begin
    if DW.Raw=TOPERATIONMODES[OM].BitMask then
    begin
      Result:=OM;
      break;
    end;
  end;
end;

function DriveParameterIsDriveMode(const IDN:TIDN):boolean;
var
  LocalIDN:TIDN;
begin
  result:=false;

  if NOT result then
  begin
    LocalIDN:=GetIDN(DRIVE_PRIMARYMODE);
    result:=(LocalIDN=IDN);
  end;
  if NOT result then
  begin
    LocalIDN:=GetIDN(DRIVE_SECONDARYMODE1);
    result:=(LocalIDN=IDN);
  end;
  if NOT result then
  begin
    LocalIDN:=GetIDN(DRIVE_SECONDARYMODE2);
    result:=(LocalIDN=IDN);
  end;
  if NOT result then
  begin
    LocalIDN:=GetIDN(DRIVE_SECONDARYMODE3);
    result:=(LocalIDN=IDN);
  end;
end;

function SaveDriveRegisterData(const CD:TCOMMANDDATA):boolean;
var
  LocalCD    : TCOMMANDDATA;
  PRR        : PRegisterRecord;
  PRRStore   : PRegisterRecord;
begin
  result:=SaveRegisterData(CD,IDNDriveList[CD.SETID]);

  //try to load some default values from datastore, if any, on a new data record
  if (NOT result) then
  begin
    LocalCD:=CD;
    LocalCD.SETID:=0;
    PRRStore:=LoadDriveRegisterDataRaw(LocalCD);
    if (NOT Assigned(PRRStore)) then
    begin
      if LocalCD.MEMORY then
      begin
        LocalCD.MEMORY:=false;
        PRRStore:=LoadDriveRegisterDataRaw(LocalCD);
        if Assigned(PRRStore) then PRRStore^.IDN.Data.ParamBlock:=7;
        LocalCD.MEMORY:=true;
      end;
    end;
    if Assigned(PRRStore) then
    begin
      PRR:=LoadDriveRegisterDataRaw(CD);
      if LocalCD.MEMORY then PRR^.IDN.Data.ParamBlock:=PRRStore^.IDN.Data.ParamBlock;
      if (PRRStore^.Attribute=0) then PRRStore^.Attribute:=GetAttributeDefault;
      if (PRR^.Attribute=0) then PRR^.Attribute:=PRRStore^.Attribute;
      if Length(PRR^.Min)=0 then PRR^.Min:=PRRStore^.Min;
      if Length(PRR^.Max)=0 then PRR^.Max:=PRRStore^.Max;
      if Length(PRR^.Measure)=0 then PRR^.Measure:=PRRStore^.Measure;
      if Length(PRR^.Name)=0 then PRR^.Name:=PRRStore^.Name;
      SaveDriveRegisterDataRaw(CD,PRR);
    end;
  end;
end;

function SaveDriveRegisterDataRaw(const DriveNumber:word; const RR:TRegisterRecord):boolean;overload;
begin
  result:=SaveRegisterDataRaw(RR,IDNDriveList[DriveNumber]);
end;

function SaveDriveRegisterDataRaw(const DriveNumber:word; aKey:TIDN; aValue:PRegisterRecord):boolean;
begin
  result:=SaveRegisterDataRaw(aKey,aValue,IDNDriveList[DriveNumber]);
end;

function SaveDriveRegisterDataRaw(const CD:TCOMMANDDATA; aValue:PRegisterRecord):boolean;
begin
  result:=SaveRegisterDataRaw(CD,aValue,IDNDriveList[CD.SETID]);
end;

function LoadDriveRegisterData(const CD:TCOMMANDDATA):TCOMMANDDATA;
begin
  Result:=LoadRegisterData(CD,IDNDriveList[CD.SETID]);
end;

function LoadDriveRegisterDataRaw(const CD:TCOMMANDDATA):PRegisterRecord;
begin
  result:=LoadRegisterDataRaw(CD,IDNDriveList[CD.SETID]);
end;

function  LoadDriveRegisterDataRaw(const DriveNumber:word; const index:word):PRegisterRecord;
begin
  result:=LoadRegisterDataRaw(index,IDNDriveList[DriveNumber]);
end;

function  LoadDriveRegisterDataRaw(const DriveNumber:word; const aKey:TIDN):PRegisterRecord;
begin
  result:=LoadRegisterDataRaw(aKey,IDNDriveList[DriveNumber]);
end;

procedure DeleteDriveRegisterData(const CD:TCOMMANDDATA);
begin
  DeleteRegisterData(CD,IDNDriveList[CD.SETID]);
end;

procedure ClearDriveRegisterData(const DriveNumber:word);
begin
  ClearRegisterData(IDNDriveList[DriveNumber]);
end;

function DriveRegisterDataCount(const DriveNumber:word):integer;
begin
  result:=RegisterDataCount(IDNDriveList[DriveNumber]);
end;

function GetDriveErrorDescription(derr:word):string;
var
 error:TERROR;
begin
  result:=sUN;
  for error in DRIVE_ERRORS do
  begin
    if (error.NUMBER=derr) then
    begin
      result:=error.EXPLANATION;
      break;
    end;
  end;
end;

procedure ModeInit;
var
  OM       : TOPERATIONMODE;
  DM       : TDRIVEMODE;
begin
  for OM in TOPERATIONMODE do
  begin
    DriveOperationModes[OM]:=TOPERATIONMODES[OM];
    DriveOperationModesLagLess[OM]:=TOPERATIONMODES[OM];
    DM.Raw:=DriveOperationModesLagLess[OM].BitMask;
    DriveOperationModesLagLess[OM].BitMask:=DM.Raw;
    DriveOperationModesLagLess[OM].Lagless:=True;
    // Joystick mode has lagless bit set, but do not mention it, it has another meaning in this mode.
    if (OM<>omJM) then DriveOperationModesLagLess[OM].Name:=DriveOperationModesLagLess[OM].Name+' (lagless)';
  end;
end;

procedure DriveInit;
var
  RR:TRegisterRecord;
  P:PRegisterRecord;
  K:TIDN;
  i,j:word;
begin
  for i:=Low(IDNDriveList) to High(IDNDriveList) do
  begin
    //CreateRegisterData(IDNDriveList[i]);
    IDNDriveList[i]:=TMySortedMap.Create;

    {$ifdef USEHASHLIST}
    IDNDriveList[i].OwnsObjects:=False;
    {$endif}

    if (i>Low(IDNDriveList)) then continue;

    {$ifndef USEHASHLIST}
    IDNDriveList[i].Count:=Length(SERCOSSTANDARD)+Length(SERCOSSPECIFIC)+Length(SERCOSPARAMETERSMEMORY);
    {$endif}

    j:=0;

    for RR in SERCOSSTANDARD do
    begin
      new(P);
      P^:=RR;
      K:=GetIDN(RR);
      {$ifdef USEHASHLIST}
      IDNDriveList[i].Add(K,TObject(P));
      {$else}
      IDNDriveList[i].Keys[j]:=K;
      IDNDriveList[i].Data[j]:=P;
      {$endif}
      Inc(j)
    end;

    for RR in SERCOSSPECIFIC do
    begin
      new(P);
      P^:=RR;
      K:=GetIDN(RR);
      {$ifdef USEHASHLIST}
      IDNDriveList[i].Add(K,TObject(P));
      {$else}
      IDNDriveList[i].Keys[j]:=K;
      IDNDriveList[i].Data[j]:=P;
      {$endif}
      Inc(j)
    end;

    for RR in SERCOSPARAMETERSMEMORY do
    begin
      new(P);
      P^:=RR;
      K:=GetIDN(RR);
      {$ifdef USEHASHLIST}
      IDNDriveList[i].Add(K,TObject(P));
      {$else}
      IDNDriveList[i].Keys[j]:=K;
      IDNDriveList[i].Data[j]:=P;
      {$endif}
      Inc(j)
    end;

    {$ifndef USEHASHLIST}
    IDNDriveList[i].Sorted:=True;
    {$endif}
  end;

  // Init driveinfo to unknown
  for i:=Low(DriveList) to High(DriveList) do GetDriveInfo(i);

  BASICDRIVEDATA[0]:=DRIVE_FIRMWARE;
  BASICDRIVEDATA[1]:=DRIVE_CONTROLLERTYPE;
  BASICDRIVEDATA[2]:=DRIVE_MOTORTYPE;
  BASICDRIVEDATA[3]:=DRIVE_APPTYPE;
  BASICDRIVEDATA[4]:=DRIVE_MOTORSERIAL;
  BASICDRIVEDATA[5]:=DRIVE_PRIMARYMODE;

  REALTIMEDRIVEDATA[0]:=DRIVE_POSITION;
  REALTIMEDRIVEDATA[1]:=DRIVE_TARGET;
  REALTIMEDRIVEDATA[2]:=DRIVE_SPEED;
  REALTIMEDRIVEDATA[3]:=DRIVE_TORQUE;
  REALTIMEDRIVEDATA[4]:=DRIVE_CONTROLWORD;
  REALTIMEDRIVEDATA[5]:=DRIVE_STATUSWORD;
  REALTIMEDRIVEDATA[6]:=DRIVE_DIAGNOSTIC;
  REALTIMEDRIVEDATA[7]:=DRIVE_INTERFACE;
  REALTIMEDRIVEDATA[8]:=DRIVE_MANUFACTURER_DIAGNOSTIC_CLASS3;
  //REALTIMEDRIVEDATA[9]:=DRIVE_DIAGNOSTIC_CLASS1;
  //REALTIMEDRIVEDATA[10]:=DRIVE_DIAGNOSTIC_CLASS2;
  //REALTIMEDRIVEDATA[11]:=DRIVE_DIAGNOSTIC_CLASS3;

  //REALTIMEDRIVEDATA[12]:=DRIVE_SIGNAL_STATUSWORD;
  //REALTIMEDRIVEDATA[13]:=DRIVE_SIGNAL_CONTROLWORD;
end;

procedure DriveEnd;
var
  j:integer;
begin
  for j:=Low(IDNDriveList) to High(IDNDriveList) do
  begin
    ClearDriveRegisterData(j);
    IDNDriveList[j].Free;
  end;
end;

initialization
  ModeInit;
  DriveInit;

finalization
  DriveEnd;

end.

