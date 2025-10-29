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

const
  DriveInternalInterpolationModes          = [omDIE1,omDIE2,omDIE12,omRDIE1,omRDIE2,omRDIE12];
  DriveInternalInterpolationModesRelative  = [omRDIE1,omRDIE2,omRDIE12];
  PositionControl                          = [omPCE1,omPCE2,omPCE12];
  PositionControlBlockModes                = [omPCBME1,omPCBME2,omPCBME12];

type
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
                   RealtimeControl           : T2BITS;
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
                   ControlInformation        : T3BITS;
                   CommandProcessingStatus   : T1BITS;
                   Reserved2                 : T1BITS;
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
                   Movement                 : T2BITS; // 0 0: turning right (CW) ; 0 1: turning left (CCW) ; 1 0: shortest way
                   Relative                 : T1BITS; //
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
                   DirectionMode            : T2BITS; // 0 = shortest way; 1 = positive direction; 2 = negative direction
                   TargetPosAfter           : T1BITS; // 0 = position to S-0-0258; 1 = position to actual position
                   Reserved1                : T13BITS;
                   //PositionType             : T1BITS; // 0 = absolute; 1 = relative
                   //SetpointAcceptance       : T1BITS;
                   //Reserved2                : T11BITS;
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
                   InReference              : T1BITS;
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

  TDRIVEPARAMETER_4019 = bitpacked record  // Position feedback value status
      case integer of
          1 : (  Data : record
                   Reserved1                         : T1BITS;
                   PositionMode                      : T1BITS; // 0 = absolute; 1 = relative
                   InfinitePositive                  : T1BITS;
                   InfiniteNegative                  : T1BITS;
                   BlockTransitionAtOldSpeedMode1    : T1BITS;
                   BlockTransitionAtNewSpeedMode2    : T1BITS;
                   BlockTransitionHalt               : T1BITS;
                   BlockTransitionSwitch             : T1BITS;
                   StorePath                         : T1BITS;
                   Reserved2                         : T7BITS;
                  end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TDRIVEPARAMETER_4056 = bitpacked record  // Position feedback value status
      case integer of
          1 : (  Data : record
                   JogPositive                       : T1BITS;
                   JogNegative                       : T1BITS;
                   Reserved2                         : T14BITS;
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

  DRIVE_FIRMWARE               : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 30);
  DRIVE_PRIMARYMODE            : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 32);
  DRIVE_SECONDARYMODE1         : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 33);
  DRIVE_SECONDARYMODE2         : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 34);
  DRIVE_SECONDARYMODE3         : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 35);
  DRIVE_CONTROLLERTYPE         : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 140);
  DRIVE_MOTORTYPE              : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 141);
  DRIVE_APPTYPE                : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 142);


  DRIVE_POSITIONSPINDLE        : TPARAMETER = (CCLASS: ccDrive; CSUBCLASS: mscNone; NUMID: 152);
  DRIVE_POSITIONPARAMETER      : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 154);
  DRIVE_POSITIONOFFSET         : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 180);
  DRIVE_POSITIONSPEED          : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 222);
  DRIVE_POSITIONACCEL          : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 138);
  DRIVE_POSITIONJERK           : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 349);

  DRIVE_MOTORSERIAL            : TPARAMETER = (CCLASS: ccDriveSpecific; CSUBCLASS: mscParameterData; NUMID: 4088);

  DRIVE_CONTROLWORD            : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 134);
  DRIVE_STATUSWORD             : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 135);
  DRIVE_DIAGNOSTIC             : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 95);
  DRIVE_DIAGNOSTICNUMBER       : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 390);

  DRIVE_POSITIONCOMMAND        : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 47);
  DRIVE_POSITIONFEEDBACK       : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 51);
  DRIVE_FEED                   : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 108);
  DRIVE_TARGET                 : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 258);
  DRIVE_SPEED                  : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 259);
  DRIVE_ACCEL                  : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 260);
  DRIVE_DISTANCE               : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 282);
  DRIVE_POSITIONFEEDBACKSTATUS : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 403);

  DRIVE_SCALING                : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 76);


  DRIVE_MAXSPEED               : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 91);
  DRIVE_MAXACCEL               : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 138);

  DRIVE_SETUPRELATIVECOMMAND   : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 346);
  DRIVE_COMMANDMODE            : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 393);

  DRIVE_FOLLOWINGERROR         : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 189);

  DRIVE_SET_SPEED              : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 36);
  DRIVE_ACTUAL_SPEED           : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 40);
  //DRIVE_TORQUE                 : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 84);

  DRIVE_MODELIST               : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscList;          NUMID: 292);
  DRIVE_PARAMLIST              : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscList;          NUMID: 17);

  DRIVE_SIGNAL_STATUSWORD      : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 144);
  DRIVE_SIGNAL_CONTROLWORD     : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 145);

  DRIVE_DIAGNOSTIC_CLASS1      : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 11);
  DRIVE_DIAGNOSTIC_CLASS2      : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 12);
  DRIVE_DIAGNOSTIC_CLASS3      : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 13);
  DRIVE_INTERFACE              : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 14);

  DRIVE_330                    : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 330);
  DRIVE_331                    : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 331);
  DRIVE_332                    : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 332);
  DRIVE_336                    : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 336);
  DRIVE_342                    : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 342);

  DRIVE_JOG                    : TPARAMETER = (CCLASS: ccDriveSpecific; CSUBCLASS: mscParameterData; NUMID: 4056);


  DRIVE_COMMAND_ABSOLUTE    : TPARAMETER = (CCLASS: ccDriveSpecific; CSUBCLASS: mscNone; NUMID: 12);
  DRIVE_COMMAND_PHASE2      : TPARAMETER = (CCLASS: ccDriveSpecific; CSUBCLASS: mscNone; NUMID: 4023);
  DRIVE_COMMAND_PHASE3      : TPARAMETER = (CCLASS: ccDrive; CSUBCLASS: mscNone; NUMID: 127);
  DRIVE_COMMAND_PHASE4      : TPARAMETER = (CCLASS: ccDrive; CSUBCLASS: mscNone; NUMID: 128);
  DRIVE_COMMAND_CLEARERRORS : TPARAMETER = (CCLASS: ccDrive; CSUBCLASS: mscNone; NUMID: 99);




  DRIVE_MANUFACTURER_DIAGNOSTIC_CLASS3      : TPARAMETER = (CCLASS: ccDrive;         CSUBCLASS: mscParameterData; NUMID: 182);

  function  SaveDriveRegisterData(const CD:TPARAMETERDATA):boolean;
  function  SaveDriveRegisterDataRaw(const DriveNumber:word; const RR:TRegisterRecord):boolean;overload;
  function  SaveDriveRegisterDataRaw(const DriveNumber:word; aKey:TIDN; aValue:PRegisterRecord):boolean;overload;
  function  SaveDriveRegisterDataRaw(const CD:TPARAMETERDATA; aValue:PRegisterRecord):boolean;overload;

  function  LoadDriveRegisterData(const CD:TPARAMETERDATA):TPARAMETERDATA;
  function  LoadDriveRegisterDataRaw(const CD:TPARAMETERDATA):PRegisterRecord;overload;
  function  LoadDriveRegisterDataRaw(const DriveNumber:word; const index:word):PRegisterRecord;overload;
  function  LoadDriveRegisterDataRaw(const DriveNumber:word; const aKey:TIDN):PRegisterRecord;overload;

  procedure DeleteDriveRegisterData(const CD:TPARAMETERDATA);
  procedure ClearDriveRegisterData(const DriveNumber:word);
  function  DriveRegisterDataCount(const DriveNumber:word):integer;

  function  GetDirectDriveCommand(const CD:TPARAMETERDATA):string;
  function  GetDriveAttribute(const CD:TPARAMETERDATA):dword;

  function  GetDriveModeDescription(const mw:word):string; overload;
  function  GetDriveModeDescription(const ms:string):string; overload;
  function  GetDriveMode(const mw:word):TOPERATIONMODE;

  function  DriveParameterIsDriveMode(const IDN:TIDN):boolean;

  function  GetPDriveInfo(const Drive:word):PDRIVE;
  function  GetDriveAddress(const Drive:word):byte;

  function  ProcessNormalResponse(const CD:TPARAMETERDATA; const DirectDrive:boolean; const s:RawByteString):TPARAMETERDATA;
var
  DriveOperationModes         : TOMD;
  DriveOperationModesLagLess  : TOMD;
  //BASICDRIVEDATA              : array[0..0] of TPARAMETER;
  BASICDRIVEDATA              : array[0..6] of TPARAMETER;
  REALTIMEDRIVEDATA           : array[0..12] of TPARAMETER;

implementation

uses
  visualmotion,
  Tools;

const
  {$I driveerrors.inc}
  {$I driveconstants.inc}

var
  IDNDriveList                : array[0..MAXDRIVES] of TMySortedMap;
  DriveList                   : array[1..MAXDRIVES] of TDRIVE;


function GetDriveInfo(const Drive:word):TDRIVE;
begin
  result:=DriveList[Drive];
  if (Length(result.NAME)=0) then result.NAME:=sUN;
  if (Length(result.FIRMWARE)=0) then result.FIRMWARE:=sUN;
  if (Length(result.CONTROLLER)=0) then result.CONTROLLER:=sUN;
  if (Length(result.MOTORTYPE)=0) then result.MOTORTYPE:=sUN;
  if (Length(result.MOTORSERIAL)=0) then result.MOTORSERIAL:=sUN;
end;

function GetPDriveInfo(const Drive:word):PDRIVE;
begin
  if Drive>0 then
    result:=@DriveList[Drive]
  else
    result:=nil;
  if (Drive=0) then
    raise EArgumentException.CreateFmt ('Wrong drive address : %d !',[Drive]);
end;

function GetDriveAddress(const Drive:word):byte;
begin
  if Drive>0 then
    result:=DriveList[Drive].DRIVEADDRESS
  else
    result:=$FF;
  if (Drive=0) then
    raise EArgumentException.CreateFmt ('Wrong drive address : %d !',[Drive]);
end;

function GetDirectDriveCommand(const CD:TPARAMETERDATA):string;
var
  IDN      : ansistring;
  be       : byte;
begin
  result:=sERR;

  if (NOT (CD.CCLASS in [ccDrive,ccDriveSpecific])) then exit;

  IDN:=GetIDN(CD);
  be:=GetElementNumber(CD.CSUBCLASS);

  if (Length(CD.DATA)=0) then
    result:=Format('%s,%d,r',[IDN,be])
  else
    result:=Format('%s,%d,w,',[IDN,be]);
end;

function GetDriveAttribute(const CD:TPARAMETERDATA):dword;
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

function SaveDriveRegisterData(const CD:TPARAMETERDATA):boolean;
var
  LocalCD    : TPARAMETERDATA;
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

function SaveDriveRegisterDataRaw(const CD:TPARAMETERDATA; aValue:PRegisterRecord):boolean;
begin
  result:=SaveRegisterDataRaw(CD,aValue,IDNDriveList[CD.SETID]);
end;

function LoadDriveRegisterData(const CD:TPARAMETERDATA):TPARAMETERDATA;
begin
  Result:=LoadRegisterData(CD,IDNDriveList[CD.SETID]);
end;

function LoadDriveRegisterDataRaw(const CD:TPARAMETERDATA):PRegisterRecord;
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

procedure DeleteDriveRegisterData(const CD:TPARAMETERDATA);
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

  BASICDRIVEDATA[0]:=DRIVE_APPTYPE;
  BASICDRIVEDATA[1]:=DRIVE_FIRMWARE;
  BASICDRIVEDATA[2]:=DRIVE_CONTROLLERTYPE;
  BASICDRIVEDATA[3]:=DRIVE_MOTORTYPE;
  BASICDRIVEDATA[4]:=DRIVE_MOTORSERIAL;
  BASICDRIVEDATA[5]:=DRIVE_PRIMARYMODE;
  BASICDRIVEDATA[6]:=DRIVE_SCALING;


  REALTIMEDRIVEDATA[0]:=DRIVE_TARGET;
  REALTIMEDRIVEDATA[1]:=DRIVE_POSITIONCOMMAND;
  REALTIMEDRIVEDATA[2]:=DRIVE_DISTANCE;
  REALTIMEDRIVEDATA[3]:=DRIVE_CONTROLWORD;
  REALTIMEDRIVEDATA[4]:=DRIVE_STATUSWORD;
  REALTIMEDRIVEDATA[5]:=DRIVE_DIAGNOSTIC;
  REALTIMEDRIVEDATA[6]:=DRIVE_INTERFACE;
  REALTIMEDRIVEDATA[7]:=DRIVE_MANUFACTURER_DIAGNOSTIC_CLASS3;

  //REALTIMEDRIVEDATA[8]:=DRIVE_FOLLOWINGERROR;
  REALTIMEDRIVEDATA[8]:=DRIVE_POSITIONFEEDBACK;

  REALTIMEDRIVEDATA[9]:=DRIVE_SET_SPEED;
  REALTIMEDRIVEDATA[10]:=DRIVE_ACTUAL_SPEED;

  REALTIMEDRIVEDATA[11]:=DRIVE_POSITIONFEEDBACKSTATUS;
  REALTIMEDRIVEDATA[12]:=DRIVE_332;

  //REALTIMEDRIVEDATA[13]:=DRIVE_331;
  //REALTIMEDRIVEDATA[14]:=DRIVE_336;
  //REALTIMEDRIVEDATA[15]:=DRIVE_342;



  //REALTIMEDRIVEDATA[x]:=DRIVE_DIAGNOSTIC_CLASS1;
  //REALTIMEDRIVEDATA[x]:=DRIVE_DIAGNOSTIC_CLASS2;
  //REALTIMEDRIVEDATA[x]:=DRIVE_DIAGNOSTIC_CLASS3;

  //REALTIMEDRIVEDATA[x]:=DRIVE_SIGNAL_STATUSWORD;
  //REALTIMEDRIVEDATA[x]:=DRIVE_SIGNAL_CONTROLWORD;
end;

function ProcessNormalResponse(const CD:TPARAMETERDATA; const DirectDrive:boolean; const s:RawByteString):TPARAMETERDATA;
var
  index,j            : integer;
  ro                 : boolean;
  SC_IDN             : boolean;
  cs,rcs             : byte;
  PW                 : TIDNWORD;
  cc                 : TVMCOMMANDCLASS;
  csc                : TVMCOMMANDPARAMETERSUBCLASS;
  s1,datas           : RawByteString;
begin
  Result:=Default(TPARAMETERDATA);
  datas:=s;
  if Length(datas)=0 then exit;

  if Pos('Error',datas)=1 then
  begin
    // ToDo: handle error
    Result.CCLASS:=ccError;
    Result.ERROR:='We got an error !!';
    exit;
  end;

  // Parse datastring

  if DirectDrive then
  begin
    // We might use the supplied CD, if any !!
    //Result:=CD;

    Result:=IDN2CD(datas,0);
    //Result:=IDN2CD(datas,GetDriveAddress(ActiveDriveNumber));
    if ((Result.CCLASS=ccDrive) OR (Result.CCLASS=ccDriveSpecific)) then
    try
      Delete(datas,1,9); // delete IDN and comma
      SC_IDN:=false;
      if (Length(datas)>0) then
      begin
        // Extract subclass
        j:=Ord(datas[1])-48;
        NUM2SCLASS(j,Result.CSUBCLASS);
        if j=1 then SC_IDN:=true; // This is IDN data. Must be treated special (for DirectDrive commands)
        // Delete subclass and comma
        Delete(datas,1,2);
      end;
      ro:=false;
      if (Length(datas)>0) then
      begin
        // Extract read or write indicator
        ro:=(datas[1]='r');
        // Delete indicator itself
        Delete(datas,1,1);
        // Delete the comma, folowing the write command
        // Delete all terminators following the read command
        // Data written will be after this comma
        // Data will be after these terminators
        s1:=ExtractWhileConforming(datas,[',',#10,#13]);
        Delete(datas,1,length(s1));
      end;

      if (Length(datas)>0) then
      begin
        if (NOT ro) then
        begin
          // Get the data written !
          // Look for terminator
          index:=Pos(#13,datas);
          if (index=0) then index:=Pos(#10,datas);
          if (index>0) then Result.DATA:=Copy(datas,1,index-1);
          // Delete datastring, if any
          Delete(datas,1,index);
          // Delete all remaining terminators, if any
          s1:=ExtractWhileConforming(datas,[#10,#13]);
          Delete(datas,1,length(s1));
          if SC_IDN then Result.DATA:='';
        end;
      end;

      if (Length(datas)>0) then
      begin
        // Check if we have an error
        if (datas[1]='#') then
        begin
          // Extract error
          // Look for terminator
          index:=Pos(#13,datas);
          if (index=0) then index:=Pos(#10,datas);
          if (index>0) then Result.ERROR:=Copy(datas,1,index-1);
          // Delete datastring, if any
          Delete(datas,1,index);
          // Delete all remaining terminators, if any
          s1:=ExtractWhileConforming(datas,[#10,#13]);
          Delete(datas,1,length(s1));
        end;
      end;

      if (Length(datas)>0) then
      begin
        //if (ro AND (Length(Result.ERROR)=0)) then
        //if ro then
        begin
          // Get all read data, if any
          j:=0;
          repeat
            // Look for terminator
            index:=Pos(#13,datas);
            if (index=0) then index:=Pos(#10,datas);
            if (index=0) then
            begin
              // We now should have something like "A01:>" in datas
              // So, final two characters are the terminator TERDT
              {$ifdef ALLOWCONVERRORS}
              if (Pos(TERDT,s)<>(Length(s)-Length(TERDT)+1)) then
              begin
                raise EArgumentException.Create ('Wrong or missing terminator in data string.');
              end;
              {$endif}
              // Delete leading drive character
              Delete(datas,1,1);
              s1:=ExtractWhileConforming(datas,['0'..'9']);
              Result.SETID:=StringToIntSafe(s1);
              index:=Length(Result.DATA);
              if (index>0) then
              begin
                // Delete final comma from data, if any
                if Result.DATA[index]=',' then Delete(Result.DATA,index,1);
              end;
              // Do we have a list of data ?
              // Not strong: we might have a list with only one member !!
              if (j>1) then
              begin
                Result.CSUBCLASS:=mscList;
                Result.STEPID:=STEPLISTSTART;
              end;
              // We are ready, so end the loop
              break;
            end
            else
            begin
              Inc(j); // amount of data items (important for list data !!)
            end;
            Result.DATA:=Result.DATA+Copy(datas,1,index-1)+',';
            // Delete datastring, if any
            Delete(datas,1,index);
            // Delete all remaining terminators, if any
            s1:=ExtractWhileConforming(datas,[#10,#13]);
            Delete(datas,1,length(s1));
            // Only parameter data can ever be a list of data
            //if (Result.CSUBCLASS<>mscParameterData) then datas:=''; // wrong: address must yet be parsed from 'E02:>'
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


    if ((datas[1]='>') AND ((Ord(datas[2])-48)=CLCADDRESS))   then
    begin
      index:=Pos(CSS,datas);
      if (index>0) then // process and check checksum
      begin
        rcs:=StringToIntSafe(Copy(datas,index,3));
        datas:=Copy(datas,1,index-1);
        cs:=GenerateVisualMotionChecksum(datas);
        Delete(datas,Length(datas),1);
      end;
      if ((index=0) OR (rcs=cs)) then // no checksum or correct checksum : process data
      begin
        // Delete pre-amble and space
        Delete(datas,1,3);
        for cc in TVMCOMMANDCLASS do
        begin
          if VMCOMMANDCLASS[cc]=datas[1] then
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
            if VMCOMMANDPARAMETERSUBCLASS[csc]=datas[2] then
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
          Result.CCLASSCHAR:=datas[1];
          Result.CSUBCLASSCHAR:=datas[2];
        end;
        // Delete class-id and space
        Delete(datas,1,3);
        //Extract drive-id
        s1:=ExtractWhileConforming(datas,['0'..'9']);
        Result.SETID:=StringToIntSafe(s1);
        //Delete drive-id and .
        Delete(datas,1,Length(s1)+1);

        // Extract parameter
        s1:=ExtractWhileConforming(datas,['0'..'9']);
        PW.Raw:=StringToIntSafe(s1);
        Delete(datas,1,length(s1));
        if (Result.CCLASS=ccDrive) then
        begin
          // Check special ID's
          Result.MEMORY:=(PW.Data.ParamBlock=7);
          if PW.Data.ParamType=1 then Result.CCLASS:=ccDriveSpecific;
        end;
        Result.NUMID:=PW.Data.ParamNum;
        if (Length(datas)>0) then
        begin
          if (datas[1]='.') then
          begin
            Delete(datas,1,1);
            s1:=ExtractWhileConforming(datas,['0'..'9']);
            Result.STEPID:=StringToIntSafe(s1);
            Delete(datas,1,length(s1));
            if (Result.STEPID=0) then Result.STEPID:=STEPLISTSTART;
          end;
        end;
        if ((Length(datas)>0) AND (datas[1]=' ')) then Delete(datas,1,1); // delete space in front of datastring, if any
        if (Length(datas)>0) then
        begin
          if datas[1]='!' then
          begin
            // We have an error !!
            // Get number and description
            Delete(datas,1,1);
            s1:=ExtractWhileConforming(datas,['0'..'9']);
            Result.ERROR:=s1;
            Delete(datas,1,length(s1));
            if ((Length(datas)>0) AND (datas[1]=' ')) then Delete(datas,1,1); // delete space in front of errorstring, if any
          end;
          Result.DATA:=Trim(datas);
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

