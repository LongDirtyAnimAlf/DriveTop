unit common;

{$mode ObjFPC}{$H+}

{$i customdefines.inc}

interface

uses
  Classes, SysUtils,
  Contnrs,
  FGL,
  Bits;

const
  sERR                              = 'Error';
  sUN                               = 'unknown';
  sLISTFINISHED                     = '!19 List is finished';

type
  TCAPSCHAR                         = 'A'..'Z';
  PSCA = ^TSCA;
  TSCA = array[0..(MaxInt div SizeOf(TCAPSCHAR)) -1] of TCAPSCHAR;

  TVMCOMMANDCLASS                   = (ccNone,ccAxis,ccControl,ccDrive,ccDriveSpecific,ccTask,ccFloat,ccGlobalFloat,ccGlobalInteger,ccInteger,ccPID,ccAbsPointTable,ccRelPointTable,ccEventTable,ccProgram,ccELS,ccFunction,ccRegister,ccSequencerList,ccSequenceTable,ccPLS,ccZones);
  TVMPARAMETERCLASS                 = TVMCOMMANDCLASS.ccNone..TVMCOMMANDCLASS.ccTask;
  TVMCOMMANDPARAMETERSUBCLASS       = (mscNone,mscAttributes,mscBlock,mscList,mscUpperLimit,mscLowerLimit,mscParameterData,mscName,mscUnits);

const
  STEPLISTSTART                      : word = word(-1);
  CAPSCHARS                          : set of TCAPSCHAR = ['A'..'Z'];

  VMCOMMANDCLASS                     : array[TVMCOMMANDCLASS] of TCAPSCHAR = ('-','A','C','D','D','T','F','G','H','I','M','X','Y','E','P','K','S','R','L','Q','W','Z');
  VMCOMMANDPARAMETERSUBCLASS         : array[TVMCOMMANDPARAMETERSUBCLASS] of TCAPSCHAR = ('-','A','B','D','H','L','P','T','U');
  VMCOMMANDPARAMETERSUBCLASSLONG     : array[TVMCOMMANDPARAMETERSUBCLASS] of ansistring = ('None','Attribute','Block','List','Max','Min','Value','Name','Unit');


type
  TCOMMANDDATA = record
    CCLASS         : TVMPARAMETERCLASS;
    CCLASSCHAR     : TCAPSCHAR;
    CSUBCLASS      : TVMCOMMANDPARAMETERSUBCLASS;
    CSUBCLASSCHAR  : TCAPSCHAR;
    MEMORY         : boolean;
    SETID          : word;
    NUMID          : word;
    STEPID         : word;
    DATA           : string;
    ERROR          : string;
  end;

  TCOMMAND = record
    CCLASS         : TVMPARAMETERCLASS;
    CSUBCLASS      : TVMCOMMANDPARAMETERSUBCLASS;
    NUMID          : word;
  end;

  TDRIVE = record
    DRIVEADDRESS   : byte;
    PHASE          : byte;
    MODE           : word;
    NAME           : string;
    FIRMWARE       : string;
    CONTROLLER     : string;
    MOTORTYPE      : string;
    MOTORSERIAL    : string;
  end;

  IDNWORD = bitpacked record
      case integer of
          1 : (  Data : record
               /// Bit 0-11: The parameter number [0..4095], e.g. P-0-*1177*, includes 1177 as ParamNumber.
               Num                           : T12BITS;
               /// Bit 12-15: The parameter block [0..7], e.g. P-*0*-1177, includes 0 as ParamSet.
               Blk                           : T3BITS;
               // Bit 16: Parameter variant:
               /// * 0: S-Parameter (drive)
               /// * 1: P-Parameter (drive).
               Typ                           : T1BITS;
             end
             );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );
  end;

  TRegisterRecord = record
    CClass         : TVMCOMMANDCLASS;
    IDN            : IDNWORD;
    Attribute      : dword;
    Min            : string;
    Max            : string;
    Measure        : string;
    Name           : string;
    Value          : string;
  end;
  PRegisterRecord = ^TRegisterRecord;

  TIDN                              = string[8];
  {$ifdef USEHASHLIST}
  TMySortedMap                      = TFPHashObjectList;
  {$else}
  TMySortedMap                      = specialize TFPGMap<TIDN, PRegisterRecord>;
  {$endif}

  DATABYTE = bitpacked record
      case integer of
          1 : (
               Bits            : bitpacked array[0..7] of T1BITS;
              );
          2 : (
               Raw             : byte;
              );
  end;

  DATAWORD = bitpacked record
      case integer of
          1 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          2 : (
               Raw             : Word;
              );
  end;

  DATADWORD = bitpacked record
      case integer of
          1 : (
               Bits            : bitpacked array[0..31] of T1BITS;
              );
          2 : (
               Raw             : DWord;
              );
  end;

  SERCOSCOMMAND_STATUS = bitpacked record
      case integer of
          1 : (  Data : record
                   CommandSetInDrive                  : T1BITS;
                   ExecutionOfCommandInDriveEnabled   : T1BITS;
                   CommandNotYetExecuted              : T1BITS;
                   ExecutionOfCommandIsNotPossible    : T1BITS;
                   Reserved1                          : T4BITS;
                   OperatingDataInvalid               : T1BITS;
                   Reserved2                          : T7BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..15] of T1BITS;
              );
          3 : (
               Raw             : Word;
              );
  end;

  ATTRIBUTEDWORD = bitpacked record
      case integer of
          1 : (  Data : record
                   /// Bit 0-15 of Reception Telegram's payload: Conversion factor: The conversion factor is an unsigned integer used to convert numeric Bytes to
                   /// display format. The conversion factor shall be set to a Value of 1, if a conversion is not required (e.g. for
                   /// binary numbers, character strings or floating - point numbers).
                   ConversionFactor                   : T16BITS;
                   /// Bit 16-18 of Reception Telegram's payload: The Bytes length is required so that the Master is able to complete Service Channel Bytes transfers correctly.
                   DataLength                         : T2BITS;
                   List                               : T1BITS;
                   /// Bit 19 of Reception Telegram's payload: Indicates whether this Bytes calls a procedure in a drive:
                   /// * 0 Operation Bytes or parameter
                   /// * 1 Procedure command.
                   Command                            : T1BITS;
                   /// Bit 20-22 of Reception Telegram's payload: Format used to convert the operation Bytes, and min/max input values to the correct display format.
                   DataDisplay                        : T3BITS;
                   Reserved2                          : T1BITS;
                   /// Bit 24-27 of Reception Telegram's payload: Decimal point: Places after the decimal point indicates the position of the decimal point of
                   /// appropriate operation Bytes. Decimal point is used to define fixed point decimal numbers. For all other display
                   /// formats the decimal point shall be = 0.
                   DecimalPoints                      : T4BITS;
                   WriteOnlyPhase2                    : T1BITS;
                   WriteOnlyPhase3                    : T1BITS;
                   WriteOnlyPhase4                    : T1BITS;
                   Reserved3                          : T1BITS;
                 end
              );
          2 : (
               Bits            : bitpacked array[0..31] of T1BITS;
              );
          3 : (
               Raw             : DWord;
              );
  end;

  function  IsParameterClass(aClass:TVMCOMMANDCLASS):boolean;

  function  GetAttributeDefault:dword;
  function  GetAttribute(const MAP:TMySortedMap; const CD:TCOMMANDDATA):dword;

  function  ParameterIsReadOnly(const pw:dword; const phase:word):boolean;
  function  ParameterIsCommand(const pw:dword):boolean;
  function  ParameterIsTime(const pw:dword):boolean;
  function  ParameterIsIDN(const pw:dword):boolean;
  function  ParameterIsChar(const pw:dword):boolean;
  function  ParameterIsUInt(const pw:dword):boolean;
  function  ParameterIsInt(const pw:dword):boolean;
  function  ParameterIsFloat(const pw:dword):boolean;
  function  ParameterIsBinary(const pw:dword):boolean;
  function  ParameterIsHex(const pw:dword):boolean;
  function  ParameterIsList(const pw:dword):boolean;
  function  ParameterIsByteList(const pw:dword):boolean;
  function  ParameterIsWordList(const pw:dword):boolean;
  function  ParameterIsDWordList(const pw:dword):boolean;
  function  ParameterIsFloatList(const pw:dword):boolean;
  function  ParameterConversionFactor(const pw:dword):word;
  function  ParameterSizeOf(const pw:dword):byte;

  function  SaveRegisterData(const CD:TCOMMANDDATA; MAP:TMySortedMap):boolean;
  function  SaveRegisterDataRaw(const RR:TRegisterRecord; MAP:TMySortedMap):boolean;overload;
  function  SaveRegisterDataRaw(aKey:TIDN; aValue:PRegisterRecord; MAP:TMySortedMap):boolean;overload;
  function  SaveRegisterDataRaw(const CD:TCOMMANDDATA; aValue:PRegisterRecord; MAP:TMySortedMap):boolean;overload;

  function  LoadRegisterData(const CD:TCOMMANDDATA; MAP:TMySortedMap):TCOMMANDDATA;
  function  LoadRegisterDataRaw(const CD:TCOMMANDDATA; MAP:TMySortedMap):PRegisterRecord;overload;
  function  LoadRegisterDataRaw(const index:word; MAP:TMySortedMap):PRegisterRecord;overload;
  function  LoadRegisterDataRaw(const aKey:TIDN; MAP:TMySortedMap):PRegisterRecord;overload;

  procedure DeleteRegisterData(const CD:TCOMMANDDATA; MAP:TMySortedMap);
  procedure ClearRegisterData(MAP:TMySortedMap);
  procedure CreateRegisterData(var MAP:TMySortedMap);
  function  RegisterDataCount(var MAP:TMySortedMap):integer;

  function  IDN2CD(const IDN:string; const DriveNumber:byte):TCOMMANDDATA;
  function  COMMAND2CD(const C:TCOMMAND; const DriveNumber:byte):TCOMMANDDATA;
  function  GetIDN(const CD:TCOMMANDDATA):string; overload;
  function  GetIDN(const RR:TRegisterRecord):string; overload;
  function  GetIDN(const C:TCOMMAND):string; overload;

  function StringToIntSafe(const sv:string):Longint;

  function HexStringToDecimal(const hexstring:string):DWord;
  function DecimalToHexString(b:byte; const dd:boolean):string;
  function DecimalToHexString(w:word; const dd:boolean):string;
  function DecimalToHexString(dw:dword; const dd:boolean):string;

  function BinaryStringToDecimal(const binstring:string):DWord;
  function DecimalToBinaryString(const b:byte; const dd:boolean = false):string;overload;
  function DecimalToBinaryString(const w:word; const dd:boolean = false):string;overload;
  function DecimalToBinaryString(const dw:DWord; const dd:boolean = false):string;overload;

implementation

uses
  Tools;

const
  //--------------------------------------------------------------------------
  // Attribute    Bits 22-20:     Data type and display format
  //--------------------------------------------------------------------------
  CSMD_ATTRIBUTE_FORMAT_DataBinaryDisplayBinary         = %000;
  CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayUdec             = %001;
  CSMD_ATTRIBUTE_FORMAT_DataIntDisplayDec               = %010;
  CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayHex              = %011;
  CSMD_ATTRIBUTE_FORMAT_DataCharDisplayUTF8             = %100;
  CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayIDN              = %101;
  CSMD_ATTRIBUTE_FORMAT_DataFloatDisplaySignedDecExp    = %110;
  CSMD_ATTRIBUTE_FORMAT_DataSercosTimeDisplaySercosTime = %111;

  //--------------------------------------------------------------------------
  // Attribute    Bits 18-16:     Data length
  //--------------------------------------------------------------------------
  CSMD_SERC_BYTE_LEN            = %00;   // Bit-Mask length byte
  CSMD_SERC_WORD_LEN            = %01;   // Bit-Mask length word
  CSMD_SERC_LONG_LEN            = %10;   // Bit-Mask length long
  CSMD_SERC_DOUBLE_LEN          = %11;   // Bit-Mask length double

function StringToIntSafe(const sv:string):Longint;
begin
  {$ifdef ALLOWCONVERRORS}
  result:=StrToInt(sv);
  {$else}
  result:=StrToIntDef(sv,0);
  {$endif}
end;

function DecimalToBinaryStringBase(const b:int64; const Size: byte; const dd:boolean):string;
begin
  result:=BinStr(b,size*8);
  if dd then result:=result+'b';
end;

function DecimalToBinaryString(const b:byte; const dd:boolean):string;
begin
  result:=DecimalToBinaryStringBase(b,1,dd);
end;

function DecimalToBinaryString(const w:word; const dd:boolean):string;
begin
  result:=DecimalToBinaryStringBase(w,2,dd);
end;

function DecimalToBinaryString(const dw:DWord; const dd:boolean):string;
begin
  result:=DecimalToBinaryStringBase(dw,4,dd);
end;

function BinaryStringToDecimal(const binstring:string):DWord;
var
  s:string;
begin
  //s:=binstring;
  s:=ExtractWhileConforming(binstring,['0','1']);
  if (Length(s)>0) then
  begin
    //if s[Length(s)]='b' then Delete(s,Length(s),1);
    {$ifdef ALLOWCONVERRORS}
    result:=StrToInt('%'+s);
    {$else}
    result:=StrToIntDef('%'+s,0);
    {$endif}
  end else result:=0;
end;

function HexStringToDecimal(const hexstring:string):DWord;
var
  s:string;
begin
  s:=hexstring;
  if (Length(s)>0) then
  begin
    if s[Length(s)]='h' then Delete(s,Length(s),1);
    if (Length(s)>1) then if s[2]='x' then Delete(s,1,2);
    {$ifdef ALLOWCONVERRORS}
    result:=StrToInt('$'+s);
    {$else}
    result:=StrToIntDef('$'+s,0);
    {$endif}
  end else result:=0;
end;

function DecimalToHexStringBase(const b:int64; const Size: byte; const dd:boolean):string;
begin
  result:=hexstr(b,Size);
  if dd then result:='0x'+result;
  //if dd then result:=result+'h';
end;

function DecimalToHexString(b:byte; const dd:boolean):string;
begin
  result:=DecimalToHexStringBase(b,2,dd);
end;

function DecimalToHexString(w:word; const dd:boolean):string;
begin
  result:=DecimalToHexStringBase(w,4,dd);
end;

function DecimalToHexString(dw:dword; const dd:boolean):string;
begin
  result:=DecimalToHexStringBase(dw,8,dd);
end;

function IDN2CD(const IDN:string; const DriveNumber:byte):TCOMMANDDATA;
begin
  Result:=Default(TCOMMANDDATA);
  if (Length(IDN)>7) then
  begin
    if IDN[1]='S' then Result.CCLASS:=ccDrive;
    if IDN[1]='P' then Result.CCLASS:=ccDriveSpecific;
    if IDN[1]='T' then Result.CCLASS:=ccTask;
    if IDN[1]='C' then Result.CCLASS:=ccControl;
    if IDN[1]='A' then Result.CCLASS:=ccAxis;
    Result.MEMORY:=(Pos('-7-',IDN)=2);
    Result.NUMID:=StrToInt(Copy(IDN,5,4));
    Result.SETID:=DriveNumber;
  end;
end;

function COMMAND2CD(const C:TCOMMAND; const DriveNumber:byte):TCOMMANDDATA;
begin
  Result:=Default(TCOMMANDDATA);
  Result.CCLASS:=C.CCLASS;
  Result.CSUBCLASS:=C.CSUBCLASS;
  Result.NUMID:=C.NUMID;
  Result.SETID:=DriveNumber;
end;

function IsParameterClass(aClass:TVMCOMMANDCLASS):boolean;
begin
  result:=(aClass in [TVMCOMMANDCLASS.ccAxis..TVMCOMMANDCLASS.ccTask]);
end;

function GetIDN(const CD:TCOMMANDDATA):string;
var
  bs       : byte;
  bt       : char;
begin
  if ((CD.CCLASS=ccNone) OR (CD.NUMID=0)) then result:='-' else
  begin
    bt:=VMCOMMANDCLASS[CD.CCLASS];
    case CD.CCLASS of
      ccDrive          : bt:='S';
      ccDriveSpecific  : bt:='P';
    else
    end;
    case CD.MEMORY of
      false            : bs:=0;
      true             : bs:=7;
    end;
    result:=Format('%s-%d-%.4d',[bt,bs,CD.NUMID])
  end;
end;

function GetIDN(const RR:TRegisterRecord):string;
var
  bt       : char;
begin
  if ((RR.CCLASS=ccNone) OR (RR.IDN.Data.Num=0)) then result:='-' else
  begin
    bt:=VMCOMMANDCLASS[RR.CClass];
    case RR.CCLASS of
      ccDrive          : bt:='S';
      ccDriveSpecific  : bt:='P';
    else
    end;
    if RR.IDN.Data.Typ=1 then bt:='P';
    result:=Format('%s-%d-%.4d',[bt,RR.IDN.Data.Blk,RR.IDN.Data.Num])
  end;
end;

function GetIDN(const C:TCOMMAND):string; overload;
var
  CD:TCOMMANDDATA;
begin
  CD:=Default(TCOMMANDDATA);
  CD.CCLASS:=C.CCLASS;
  CD.CSUBCLASS:=C.CSUBCLASS;
  CD.NUMID:=C.NUMID;
  Result:=GetIDN(CD);
end;

function IndexOfRegisterData(const CD:TCOMMANDDATA; MAP:TMySortedMap):integer;
var
  aKey : TIDN;
begin
  aKey:=GetIDN(CD);
  {$ifdef USEHASHLIST}
  result:=MAP.FindIndexOf(aKey);
  {$else}
  result:=MAP.IndexOf(aKey);
  {$endif}
end;

function  IndexOfRegisterData(const Key:TIDN; MAP:TMySortedMap):integer;
begin
  {$ifdef USEHASHLIST}
  result:=MAP.FindIndexOf(Key);
  {$else}
  result:=MAP.IndexOf(Key);
  {$endif}
end;

function SaveRegisterData(const CD:TCOMMANDDATA; MAP:TMySortedMap):boolean;
var
  i,j      : integer;
  P        : PRegisterRecord;
  Found    : boolean;
  DataList : TStringList;
  s        : string;
  aKey     : TIDN;
begin
  P:=nil;
  i:=IndexOfRegisterData(CD,MAP);
  Found:=(i<>-1);
  result:=Found;
  {$ifdef USEHASHLIST}
  if Found then P:=PRegisterRecord(MAP.Items[i]);
  {$else}
  if Found then P:=MAP.Data[i];
  {$endif}

  if ((NOT Found) OR (Not Assigned(P))) then
  begin
    new(P);
    P^:=Default(TRegisterRecord);
    P^.CClass:=CD.CCLASS;
    P^.IDN.Data.Num:=CD.NUMID;
    if (CD.CCLASS=ccDriveSpecific) then P^.IDN.Data.Typ:=1;
    if CD.MEMORY then P^.IDN.Data.Blk:=7;
  end;

  if (CD.CSUBCLASS=mscList) then
  begin
    DataList:=TStringList.Create;
    try
      if ((CD.STEPID=STEPLISTSTART) OR (CD.STEPID=0)) then
      begin
        P^.Value:=CD.DATA;
      end
      else
      begin
        j:=CD.STEPID;
        DataList.CommaText:=P^.Value;
        SetCountStringList(DataList,j);
        DataList.Strings[CD.STEPID-1]:=CD.DATA;
        P^.Value:=DataList.CommaText;
      end;
    finally
      DataList.Free;
    end;
  end
  else
  begin
    if (CD.CSUBCLASS=mscParameterData) then P^.Value:=CD.DATA;
    if (CD.CSUBCLASS=mscName) then P^.Name:=CD.DATA;
    if (CD.CSUBCLASS=mscUpperLimit) then P^.Max:=CD.DATA;
    if (CD.CSUBCLASS=mscLowerLimit) then P^.Min:=CD.DATA;
    if (CD.CSUBCLASS=mscUnits) then P^.Measure:=CD.DATA;
    if (CD.CSUBCLASS=mscAttributes) then P^.Attribute:=BinaryStringToDecimal(CD.DATA);
  end;
  if (NOT Found) then
  begin
    aKey:=GetIDN(CD);
    {$ifdef USEHASHLIST}
    i:=MAP.Add(aKey,nil);
    {$else}
    i:=MAP.Add(aKey);
    {$endif}
  end;
  {$ifdef USEHASHLIST}
  MAP.Items[i]:=TObject(P);
  {$else}
  MAP.Data[i]:=P;
  {$endif}
end;

function SaveRegisterDataRaw(const RR:TRegisterRecord; MAP:TMySortedMap):boolean;
var
  P        : PRegisterRecord;
  aKey     : TIDN;
  Found    : boolean;
  i        : integer;
begin
  aKey:=GetIDN(RR);
  result:=SaveRegisterDataRaw(aKey,@RR,MAP);
  (*





  i:=IndexOfRegisterData(aKey,MAP);
  Found:=(i<>-1);
  {$ifdef USEHASHLIST}
  if Found then P:=PRegisterRecord(MAP.Items[i]);
  {$else}
  if Found then P:=MAP.Data[i];
  {$endif}
  if ((NOT Found) OR (Not Assigned(P))) then
  begin
    new(P);
    P^:=Default(TRegisterRecord);
  end;
  P^:=RR;
  if (NOT Found) then
  begin
    {$ifdef USEHASHLIST}
    i:=MAP.Add(aKey,nil);
    {$else}
    i:=MAP.Add(aKey);
    {$endif}
  end;
  {$ifdef USEHASHLIST}
  MAP.Items[i]:=TObject(P);
  {$else}
  MAP.Data[i]:=P;
  {$endif}
  *)
end;

function SaveRegisterDataRaw(aKey:TIDN; aValue:PRegisterRecord; MAP:TMySortedMap):boolean;
var
  P        : PRegisterRecord;
  Found    : boolean;
  i        : integer;
begin
  P:=nil;
  i:=IndexOfRegisterData(aKey,MAP);
  Found:=(i<>-1);
  result:=Found;
  {$ifdef USEHASHLIST}
  if Found then P:=PRegisterRecord(MAP.Items[i]);
  {$else}
  if Found then P:=MAP.Data[i];
  {$endif}
  if ((NOT Found) OR (Not Assigned(P))) then
  begin
    new(P);
    P^:=Default(TRegisterRecord);
  end;
  P^:=aValue^;
  if (NOT Found) then
  begin
    {$ifdef USEHASHLIST}
    i:=MAP.Add(aKey,nil);
    {$else}
    i:=MAP.Add(aKey);
    {$endif}
  end;
  {$ifdef USEHASHLIST}
  MAP.Items[i]:=TObject(P);
  {$else}
  MAP.Data[i]:=P;
  {$endif}
end;

function SaveRegisterDataRaw(const CD:TCOMMANDDATA; aValue:PRegisterRecord; MAP:TMySortedMap):boolean;overload;
var
  aKey : TIDN;
begin
  aKey:=GetIDN(CD);
  result:=SaveRegisterDataRaw(aKey,aValue,MAP);
end;

function LoadRegisterData(const CD:TCOMMANDDATA; MAP:TMySortedMap):TCOMMANDDATA;
var
  P : PRegisterRecord;
  i : integer;
begin
  Result:=CD;
  P:=nil;
  i:=IndexOfRegisterData(CD,MAP);
  {$ifdef USEHASHLIST}
  if (i<>-1) then P:=PRegisterRecord(MAP.Items[i]);
  {$else}
  if (i<>-1) then P:=MAP.Data[i];
  {$endif}
  if Assigned(P) then
  begin
    Result.CCLASS         := P^.CClass;
    Result.MEMORY         := (P^.IDN.Data.Blk=7);
    Result.NUMID          := P^.IDN.Data.Num;
    case CD.CSUBCLASS of
      mscAttributes     : Result.DATA := DecimalToBinaryString(P^.Attribute);
      mscUpperLimit     : Result.DATA := P^.Max;
      mscLowerLimit     : Result.DATA := P^.Min;
      mscList,
      //mscBlock ,
      mscParameterData  : Result.DATA := P^.Value;
      mscName           : Result.DATA := P^.Name;
      mscUnits          : Result.DATA := P^.Measure;
    else
      // we should never be here !!!
      raise EArgumentException.Create ('Wrong subclass used to get data from datastore !');
    end;
  end
  else Result.DATA :='';
end;

function LoadRegisterDataRaw(const CD:TCOMMANDDATA; MAP:TMySortedMap):PRegisterRecord;
var
  P : PRegisterRecord;
  i : integer;
begin
  P:=nil;
  i:=IndexOfRegisterData(CD,MAP);
  {$ifdef USEHASHLIST}
  if (i<>-1) then P:=PRegisterRecord(MAP.Items[i]);
  {$else}
  if (i<>-1) then P:=MAP.Data[i];
  {$endif}
  result:=P;
end;

function LoadRegisterDataRaw(const index:word; MAP:TMySortedMap):PRegisterRecord;
var
  P : PRegisterRecord;
begin
  {$ifdef USEHASHLIST}
  P:=PRegisterRecord(MAP.Items[index]);
  {$else}
  P:=MAP.Data[index];
  {$endif}
  result:=P;
end;

function LoadRegisterDataRaw(const aKey:TIDN; MAP:TMySortedMap):PRegisterRecord;
var
  P : PRegisterRecord;
  i : integer;
begin
  P:=nil;
  i:=IndexOfRegisterData(aKey,MAP);
  {$ifdef USEHASHLIST}
  if (i<>-1) then P:=PRegisterRecord(MAP.Items[i]);
  {$else}
  if (i<>-1) then P:=MAP.Data[i];
  {$endif}
  result:=P;
end;

procedure DeleteRegisterData(const CD:TCOMMANDDATA; MAP:TMySortedMap);
var
  P : PRegisterRecord;
  i : integer;
begin
  i:=IndexOfRegisterData(CD,MAP);
  if (i<>-1) then
  begin
    {$ifdef USEHASHLIST}
    P:=PRegisterRecord(MAP.Items[i]);
    {$else}
    P:=MAP.Data[i];
    {$endif}
    if Assigned(P) then Dispose(P);
    MAP.Delete(i);
  end;
  P:=nil;
end;

procedure ClearRegisterData(MAP:TMySortedMap);
var
  i    : integer;
  P    : PRegisterRecord;
  s    : boolean;
begin
  {$ifndef USEHASHLIST}
  s:=MAP.Sorted;
  MAP.Sorted:=False;
  {$endif}
  for i:=Pred(MAP.Count) downto 0 do
  begin
    {$ifdef USEHASHLIST}
    P:=PRegisterRecord(MAP.Items[i]);
    {$else}
    P:=MAP.Data[i];
    {$endif}
    if Assigned(P) then Dispose(P);
    P:=nil;
    //MAP.Delete(i);
  end;
  MAP.Clear;
  {$ifndef USEHASHLIST}
  if s then MAP.Sorted:=True;
  {$endif}
end;

procedure CreateRegisterData(var MAP:TMySortedMap);
begin
  MAP:=TMySortedMap.Create;
  {$ifndef USEHASHLIST}
  MAP.Sorted:=True;
  {$endif}
  {$ifdef USEHASHLIST}
  MAP.OwnsObjects:=False;
  {$endif}
end;

function  RegisterDataCount(var MAP:TMySortedMap):integer;
begin
  result:=MAP.Count;
end;

function GetAttributeDefault:dword;
var
  ATT : ATTRIBUTEDWORD;
begin
  ATT.Raw:=0;
  ATT.Data.ConversionFactor:=1;
  ATT.Data.WriteOnlyPhase3:=1;
  ATT.Data.WriteOnlyPhase4:=1;
  ATT.Data.DataLength:=CSMD_SERC_WORD_LEN;
  ATT.Data.DataDisplay:=CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayUdec;
  result:=ATT.Raw;
end;

function GetAttribute(const MAP:TMySortedMap; const CD:TCOMMANDDATA):dword;
var
  LocalCD:TCOMMANDDATA;
  StoreCD:TCOMMANDDATA;
begin
  try
    LocalCD:=CD;
    LocalCD.CSUBCLASS:=mscAttributes;
    StoreCD:=LoadRegisterData(LocalCD,MAP);
    result:=BinaryStringToDecimal(StoreCD.DATA);
  except
    raise EArgumentException.Create ('Wrong format of attribute from datastore.');
  end;
end;

function ParameterIsReadOnly(const pw:dword; const phase:word):boolean;
var
  ATT:ATTRIBUTEDWORD;
  EditDisabledInPhase2:boolean;
  EditDisabledInPhase3:boolean;
  EditDisabledInPhase4:boolean;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    EditDisabledInPhase2:=(ATT.Data.WriteOnlyPhase2=1);
    EditDisabledInPhase3:=(ATT.Data.WriteOnlyPhase3=1);
    EditDisabledInPhase4:=(ATT.Data.WriteOnlyPhase4=1);

    if (phase=0) then
    begin
      result:=(EditDisabledInPhase2 AND EditDisabledInPhase3 AND EditDisabledInPhase4);
    end
    else
    begin
      if (phase=2) then result:=EditDisabledInPhase2;
      if (phase=3) then result:=EditDisabledInPhase3;
      if (phase=4) then result:=EditDisabledInPhase4;
    end;
  end;
end;

function ParameterIsCommand(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.Command=1);
  end;
end;

function ParameterIsTime(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.DataDisplay=CSMD_ATTRIBUTE_FORMAT_DataSercosTimeDisplaySercosTime);
  end;
end;


function ParameterIsIDN(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.DataDisplay=CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayIDN);
  end;
end;


function ParameterIsChar(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.DataDisplay=CSMD_ATTRIBUTE_FORMAT_DataCharDisplayUTF8);
  end;
end;

function ParameterIsUInt(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.DataDisplay=CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayUdec);
  end;
end;

function ParameterIsInt(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.DataDisplay=CSMD_ATTRIBUTE_FORMAT_DataIntDisplayDec);
  end;
end;

function ParameterIsFloat(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.DataDisplay=CSMD_ATTRIBUTE_FORMAT_DataFloatDisplaySignedDecExp);
  end;
end;

function ParameterIsBinary(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.DataDisplay=CSMD_ATTRIBUTE_FORMAT_DataBinaryDisplayBinary);
  end;
end;

function ParameterIsHex(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.DataDisplay=CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayHex);
  end;
end;

function ParameterIsList(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.List=1);
  end;
end;

function  ParameterIsByteList(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.List=1);
    if result then result:=(ATT.Data.DataLength=CSMD_SERC_BYTE_LEN);
  end;
end;

function  ParameterIsWordList(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.List=1);
    if result then result:=(ATT.Data.DataLength=CSMD_SERC_WORD_LEN);
  end;
end;

function  ParameterIsDWordList(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.List=1);
    if result then result:=(ATT.Data.DataLength=CSMD_SERC_LONG_LEN);
  end;
end;

function ParameterIsFloatList(const pw:dword):boolean;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=false;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.List=1);
    if result then result:=(ATT.Data.DataLength=CSMD_SERC_DOUBLE_LEN);
  end;
end;

function ParameterConversionFactor(const pw:dword):word;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=0;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    result:=(ATT.Data.ConversionFactor);
  end;
end;

function ParameterSizeOf(const pw:dword):byte;
var
  ATT:ATTRIBUTEDWORD;
begin
  result:=0;
  ATT.Raw:=pw;
  if (ATT.Raw<>0) then
  begin
    if ATT.Data.DataLength=CSMD_SERC_BYTE_LEN then result:=1;
    if ATT.Data.DataLength=CSMD_SERC_WORD_LEN then result:=2;
    if ATT.Data.DataLength=CSMD_SERC_LONG_LEN then result:=4;
    if ATT.Data.DataLength=CSMD_SERC_DOUBLE_LEN then result:=8;
  end;
end;

end.

