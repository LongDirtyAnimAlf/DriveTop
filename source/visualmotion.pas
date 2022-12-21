unit visualmotion;

{$mode ObjFPC}{$H+}

{$i customdefines.inc}

interface

uses
  bits, common;

type
  TVMVARIABLECLASS                  = TVMCOMMANDCLASS.ccFloat..TVMCOMMANDCLASS.ccInteger;
  TVMCOMMANDVARIABLESUBCLASS        = (vscData,vscLabel);
  TVMCOMMANDPIDSUBCLASS             = (pscSet,pscCalculatedSetpoint,pscCalculatedFeedback,pscCalculatedOutput,pscLoopTime,pscLoopList,pscControlRegs,pscStatusRegs,pscType);
  TVMREGISTERSUBCLASS               = (rscBinaryState,rscForceStateChange,rscDecimalState,rscEraseMasks,rscForcingMask,rscBinaryForcingState,rscNameText,rscHexadecimalState);
  TVMPOINTTABLESUBCLASS             = (ptcX,ptcY,ptcZ,ptcBlendRadius,ptcMaxSpeed,ptcMaxAccel,ptcMaxDecel,ptcJerkLimit,ptcEvent1,ptcEvent2,ptcEvent3,ptcEvent4,ptcRoll,ptcPitch,ptcYaw,ptcElbow,ptcNameText,ptcListAllAbove,ptcRate,ptcListAllLabels);
  TVMEVENTSUBCLASS                  = (ecStatus,ecType,ecDirection,ecArgument,ecFunction,ecMessage,ecListAll);

const
  MAXCLC                       = 1;
  CLCADDRESS                   = 1;

  VMCOMMANDVARIABLESUBCLASS          : array[TVMCOMMANDVARIABLESUBCLASS] of TCAPSCHAR = ('P','T');
  VMCOMMANDPIDSUBCLASS               : array[TVMCOMMANDPIDSUBCLASS] of TCAPSCHAR = ('B','E','F','G','J','L','R','S','T');
  VMREGISTERSUBCLASS                 : array[TVMREGISTERSUBCLASS] of TCAPSCHAR = ('B','C','D','E','F','S','T','X');
  VMPOINTTABLESUBCLASS               : array[TVMPOINTTABLESUBCLASS] of TCAPSCHAR = ('X','Y','Z','B','S','A','D','J','1','2','3','4','R','P','W','E','T','L','R','V');
  VMEVENTSUBCLASS                    : array[TVMEVENTSUBCLASS] of TCAPSCHAR = ('S','T','D','A','F','M','L');

  VMPOINTTABLELIST                   : set of TVMPOINTTABLESUBCLASS = [ptcX..ptcNameText];
  VMEVENTLIST                        : set of TVMEVENTSUBCLASS = [ecStatus..ecMessage];

type
  TSERCOSREGISTER_SYSTEMCONTROL = bitpacked record
      case integer of
          1 : (  Data : record
                   ParameterMode      : T1BITS;
                   Reserved1          : T1BITS;
                   EmergencyStop      : T1BITS;
                   Reserved2          : T1BITS;
                   ClearAllErrors     : T1BITS;
                   PendantLiveMan     : T1BITS;
                   RebuildDoubleRing  : T1BITS;
                   ActivateProgram    : T1BITS;
                   ProgramSelect      : T41BITS;
                   Reserved3          : T1BITS;
                   PendantEnable      : T1BITS;
                   PendantLevel       : T2BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TSERCOSREGISTER_TASKCONTROL = bitpacked record
      case integer of
          1 : (  Data : record
                   Mode               : T1BITS;
                   OverrideAutoStart  : T1BITS;
                   Reserved1          : T1BITS;
                   TaskSingleStep     : T1BITS;
                   ClearTaskError     : T1BITS;
                   Start              : T1BITS;
                   Stop               : T1BITS;
                   Reserved2          : T1BITS;
                   Event              : T1BITS;
                   Tracing            : T1BITS;
                   Breakpoint         : T1BITS;
                   SeqSingleStep      : T1BITS;
                   FuncSingleStep     : T1BITS;
                   Reserved3          : T1BITS;
                   FastStop           : T1BITS;
                   Reserved4          : T1BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TSERCOSREGISTER_AXISCONTROL = bitpacked record
      case integer of
          1 : (  Data : record
                   DisableAxis      : T1BITS;
                   JogForward       : T1BITS;
                   JogReverse       : T1BITS;
                   SynchronizedJog  : T1BITS;
                   Reserved1        : T12BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TSERCOSREGISTER_AXISSTATUS = bitpacked record
      case integer of
          1 : (  Data : record
                   MultiplexChannelEnabled       : T1BITS;
                   JoggingForward                : T1BITS;
                   JoggingReverse                : T1BITS;
                   PhaseAdjusted                 : T1BITS;
                   ELSEnabled                    : T1BITS;
                   ELSSecondaryMode              : T1BITS;
                   AxisInPosition                : T1BITS;
                   AxisAligned                   : T1BITS;
                   NotUsed                       : T1BITS;
                   AxisStopped                   : T1BITS;
                   AxisHalted                    : T1BITS;
                   Class3Status                  : T1BITS;
                   Class2Warning                 : T1BITS;
                   ShutdownError                 : T1BITS;
                   DriveReadyLSB                 : T1BITS;
                   DriveReadyMSB                 : T1BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TSERCOSREGISTER_TASKJOGCONTROL = bitpacked record
      case integer of
          1 : (  Data : record
                   ContinuousnStep      : T1BITS;
                   CoordinateJogForward : T1BITS;
                   CoordinateJogReverse : T1BITS;
                   JogType              : T2BITS;
                   DistanceSpeed        : T1BITS;
                   Reserved1            : T2BITS;
                   JogXCoordinate       : T1BITS;
                   JogYCoordinate       : T1BITS;
                   JogZCoordinate       : T1BITS;
                   JogJoint4            : T1BITS;
                   JogJoint5            : T1BITS;
                   JogJoint6            : T1BITS;
                   Reserved2            : T2BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  TSERCOSREGISTER_TASKSTATUS = bitpacked record
      case integer of
          1 : (  Data : record
                   Mode        : T1BITS;
                   Coordinated : T1BITS;
                   Reserved1   : T1BITS;
                   SingleStep  : T1BITS;
                   Error       : T1BITS;
                   Running     : T1BITS;
                   Reserved2   : T1BITS;
                   InPosition  : T1BITS;
                   Reserved3   : T1BITS;
                   TraceReady  : T1BITS;
                   Breakpoint  : T1BITS;
                   Reserved4   : T3BITS;
                   FastStop    : T1BITS;
                   Reserved5   : T1BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );

  end;

  function  GetCLCCommandString(const CD:TCOMMANDDATA):string;

  function  GenerateVisualMotionChecksum(s1:ansistring):byte;

  procedure SaveCLCRegisterData(const CD:TCOMMANDDATA);
  procedure SaveCLCRegisterDataRaw(const CLCNumber:word; const RR:TRegisterRecord);overload;
  procedure SaveCLCRegisterDataRaw(const CLCNumber:word; aKey:TIDN; aValue:PRegisterRecord);overload;

  function  LoadCLCRegisterData(const CD:TCOMMANDDATA):TCOMMANDDATA;
  function  LoadCLCRegisterDataRaw(const CD:TCOMMANDDATA):PRegisterRecord;
  function  LoadCLCRegisterDataRaw(const CLCNumber:word; const index:word):PRegisterRecord;

  procedure DeleteCLCRegisterData(const CD:TCOMMANDDATA);
  procedure ClearCLCRegisterData(const CLCNumber:word);
  function  CLCRegisterDataCount(const CLCNumber:word):integer;

implementation

uses
  SysUtils;

const
{$I clcconstants.inc}

var
  IDNCLCList                : array[0..MAXCLC] of TMySortedMap;

function  GetCLCCommandString(const CD:TCOMMANDDATA):string;
var
  PW:IDNWORD;
begin
  PW.Raw:=0;
  PW.Data.Num:=CD.NUMID;
  if CD.CCLASS=TVMCOMMANDCLASS.ccDriveSpecific then PW.Data.Typ:=1;
  if CD.MEMORY then PW.Data.Blk:=7;

  if (CD.CCLASS=ccNone) then
    result:=CD.CCLASSCHAR+CD.CSUBCLASSCHAR
  else
    result:=VMCOMMANDCLASS[CD.CCLASS]+VMCOMMANDPARAMETERSUBCLASS[CD.CSUBCLASS];

  result:=Result+' '+InttoStr(CD.SETID)+'.'+InttoStr(PW.Raw);

  if (CD.STEPID<>0) then
  begin
    if CD.STEPID=STEPLISTSTART then // start of a list, bit tricky
      result:=result+'.0'
    else
      result:=result+'.'+InttoStr(CD.STEPID);
  end;
end;

function GenerateVisualMotionChecksum(s1:ansistring):byte;
var
  crc,cs:word;
  i,n:LongInt;
begin
  n:=Length(s1);
  i:=1;
  crc:=0;
  while (i<=n) do begin
    crc:=crc+Ord(s1[i]);            // add the ASCII values of all of the characters
    inc(i);
  end;
  //cs:=(crc DIV 256)+(crc MOD 256); // add the two least significant digits to the most significant digit ... tricky
  //cs:=(NOT cs)+1;                  // build the two's complement of the sum
  //result:=(cs MOD 256);
  result:=((((crc AND $00FF) + ((crc AND $FF00) SHR 8)) * $FFFF) AND $00FF);
end;

procedure SaveCLCRegisterData(const CD:TCOMMANDDATA);
begin
  SaveRegisterData(CD,IDNCLCList[CD.SETID]);
end;

procedure SaveCLCRegisterDataRaw(const CLCNumber:word; const RR:TRegisterRecord);overload;
begin
  SaveRegisterDataRaw(RR,IDNCLCList[CLCNumber]);
end;

procedure SaveCLCRegisterDataRaw(const CLCNumber:word; aKey:TIDN; aValue:PRegisterRecord);overload;
begin
  SaveRegisterDataRaw(aKey,aValue,IDNCLCList[CLCNumber]);
end;

function LoadCLCRegisterData(const CD:TCOMMANDDATA):TCOMMANDDATA;
begin
  Result:=LoadRegisterData(CD,IDNCLCList[CD.SETID]);
end;

function LoadCLCRegisterDataRaw(const CD:TCOMMANDDATA):PRegisterRecord;
begin
  result:=LoadRegisterDataRaw(CD,IDNCLCList[CD.SETID]);
end;

function  LoadCLCRegisterDataRaw(const CLCNumber:word; const index:word):PRegisterRecord;
begin
  result:=LoadRegisterDataRaw(index,IDNCLCList[CLCNumber]);
end;

procedure DeleteCLCRegisterData(const CD:TCOMMANDDATA);
begin
  DeleteRegisterData(CD,IDNCLCList[CD.SETID]);
end;

procedure ClearCLCRegisterData(const CLCNumber:word);
begin
  ClearRegisterData(IDNCLCList[CLCNumber]);
end;

function CLCRegisterDataCount(const CLCNumber:word):integer;
begin
  result:=RegisterDataCount(IDNCLCList[CLCNumber]);
end;

procedure CLCInit;
var
  RR     : TRegisterRecord;
  P      : PRegisterRecord;
  K      : TIDN;
  i,j    : integer;
begin
  for i:=Low(IDNCLCList) to High(IDNCLCList) do
  begin
    //CreateRegisterData(IDNCLCList[i]);
    IDNCLCList[i]:=TMySortedMap.Create;

    {$ifndef USEHASHLIST}
    IDNCLCList[i].Count:=Length(SERCOSSTANDARD)+Length(SERCOSSPECIFIC)+Length(SERCOSPARAMETERSMEMORY);
    {$endif}
    {$ifdef USEHASHLIST}
    IDNCLCList[i].OwnsObjects:=False;
    {$endif}

    if (i>Low(IDNCLCList)) then continue;

    j:=0;

    for RR in VMSYSTEMCOMMANDS do
    begin
      new(P);
      P^:=RR;
      K:=GetIDN(RR);
      {$ifdef USEHASHLIST}
      IDNCLCList[i].Add(K,TObject(P));
      {$else}
      IDNCLCList[i].Keys[j]:=K;
      IDNCLCList[i].Data[j]:=P;
      {$endif}
      Inc(j)
    end;

    for RR in VMREGISTERS do
    begin
      new(P);
      P^:=RR;
      K:=GetIDN(RR);
      {$ifdef USEHASHLIST}
      IDNCLCList[i].Add(K,TObject(P));
      {$else}
      IDNCLCList[i].Keys[j]:=K;
      IDNCLCList[i].Data[j]:=P;
      {$endif}
      Inc(j)
    end;

    for RR in VMTASKCOMMANDS do
    begin
      new(P);
      P^:=RR;
      K:=GetIDN(RR);
      {$ifdef USEHASHLIST}
      IDNCLCList[i].Add(K,TObject(P));
      {$else}
      IDNCLCList[i].Keys[j]:=K;
      IDNCLCList[i].Data[j]:=P;
      {$endif}
      Inc(j)
    end;

    for RR in VMAXISCOMMANDS do
    begin
      new(P);
      P^:=RR;
      K:=GetIDN(RR);
      {$ifdef USEHASHLIST}
      IDNCLCList[i].Add(K,TObject(P));
      {$else}
      IDNCLCList[i].Keys[j]:=K;
      IDNCLCList[i].Data[j]:=P;
      {$endif}
      Inc(j)
    end;

    {$ifndef USEHASHLIST}
    IDNCLCList[i].Sorted:=True;
    {$endif}
  end;
end;

procedure CLCEnd;
var
  j:integer;
begin
  for j:=Low(IDNCLCList) to High(IDNCLCList) do
  begin
    ClearCLCRegisterData(j);
    IDNCLCList[j].Free;
  end;
end;

initialization
  CLCInit;

finalization
  CLCEnd;


end.

