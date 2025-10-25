unit sis;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  common;

const
  STX                                    = $02;  // SIS header pre-amble

  SISServiceUserIdentification           = $00;  // Needs address and subservice in userdata
  SISServiceTerminationDataTransmission  = $01;  // Enter the service to be cancelled in the useful data.
  SISServiceFlashOperation               = $02;
  SISServiceInitSISCommunications        = $03;  // Needs address and subservice in userdata
  SISServiceExecutingListSISServices     = $04;

  SISServiceParamRead                    = $80;
  SISServiceListRead                     = $81;
  SISServicePhaseRead                    = $82;

  SISServicePhaseWrite                   = $8D;
  SISServiceListWrite                    = $8E;
  SISServiceParamWrite                   = $8F;

  SISSubServiceReadOutSISVersion         = $01; // Only for UserIdentification  ; subservice is implemented but not active
  SISSubServiceReadOutFWANumber          = $02; // Only for UserIdentification  ; supplies content of S-0-0030
  SISSubServiceReadOutUnitTypecode       = $03; // Only for UserIdentification  ; supplies content of S-0-0140
  SISSubServiceReadOutSupportedBaudRates = $04; // Only for UserIdentification  ; read baud for serial comms

  SISSubServiceSettingTrS                = $01; // Only SISCommunications ; Sets the slave response period
  SISSubServiceSettingTzA                = $02; // Only SISCommunications ; Specifies the separation period between characters
  SISSubServiceSettingTmas               = $03; // Only SISCommunications ; Sets the cycle period for the master control word (MSW)
  SISSubServiceSettingBaud               = $07; // Only SISCommunications ; Determining the baud rate initializes the baud rate of the serial transmission
  SISSubServiceSettingBaudTest           = $08; // Only SISCommunications ; Time-controlled baud rate test allows temporary change of the baud rate
  SISSubServiceSettingAccept             = $FF; // Only SISCommunications ; Accepting the determined values activates the values initialized with the subservices 0x01, 0x02 and 0x07

  (*
  $00 Error-free transmission without error
  $01 During the execution of the requested service an error occured. The service-specific error code is contained in the useful data of the reaction telegram
  $F0 The requested service is not supported by the addressed slave
  $F8 In the sequential telegram, data in the useful data header, the transmitter address or the service have changed
  $F9 The command telegram contains subaddresses.The routing of telegrams is not supported by the slave
  $FA Useful data are missing in the command telegram. The telegram cannot be executed
  $FB The requested subservice is not supported by the addressed slave
  $FC The requested component is not available in the addressed slave. The component address is invalid
  *)

type
  SISByteArray = array[1..256] of Byte;

procedure BuildSISCommand(SISService,SISSubService,Address:byte; Data:dword; out telegram: SISByteArray; out len: Integer);
procedure BuildSISTelegram(const CD: TPARAMETERDATA; out telegram: SISByteArray; out len: Integer);overload;
function  ParseSISTelegram(const SourceCD: TPARAMETERDATA; const telegram: SISByteArray; const len: Integer):TPARAMETERDATA; overload;
function  ParseSISTelegram(const SourceCD: TPARAMETERDATA; const s: RawByteString):TPARAMETERDATA; overload;

implementation

uses
  drive,
  Bits;

const
  MASTER_ADDR   = $10;

type
  TSISTelegramHeader = bitpacked record
    case integer of
       1 : (
         Data : packed record
           StartChar   : Byte;   // always $02
           CheckSum    : Byte;   // negated sum of all bytes
           DataLen     : Byte;   // DatL
           DataLenRep  : Byte;   // DatLW
           Control     : Byte;   // see SIS spec, bit 4 = 0 cmd / 1 response
           Service     : Byte;   // SIS service code
           AddrSender  : Byte;   // Address of the sender: station number (0 - 127)
           AddrRecv    : Byte;   // Address of the receiver: 0 - 126 ==> specifies a single station, 128 ==> "point-to-point" connection; 129 - 253 ==> addresses logical groups, 254 - 255 ==> fixes a broadcast
         end
          );
       2 : (
         Bytes            : packed array[0..7] of byte;
           );
  end;

  TSISHeaderControl = bitpacked record
    case integer of
        1 : (
          Data : record
             NumberOfSubaddress          : T3BITS;
             ContainsPackageNumber       : T1BITS;
             TelegramType                : T1BITS; // command=0 ; reaction = 1;
             Status                      : T3BITS;
          end
           );
        2 : (
          Bits            : bitpacked array[0..7] of T1BITS;
            );
        3 : (
          Raw             : byte;
            );

  end;
  TSISDataControl = bitpacked record
    case integer of
        1 : (
          Data : record
             Reserved1          : T2BITS;
             LastTransmission   : T1BITS; // In case of a normal (non-list) parameter: always 1.
             Element            : T3BITS;
             Reserved2          : T2BITS;
          end
           );
        2 : (
          Bits            : bitpacked array[0..7] of T1BITS;
            );
        3 : (
          Raw             : byte;
            );
  end;

  TSISUserDataHeader = packed record
    case integer of
        1 : (
          Data : packed record
             Control            : TSISDataControl;
             UnitAdddress       : byte;
             ParamExtended      : byte; //  000 Drive (S/P) ; 001 A - Parameter (CLC command card) ; 010 C - Parameter (CLC command card) ; 100 Y - Parameter (SERCANS)
             ParamData          : TIDNWORD;
          end
           );
        2 : (
          Bytes            : packed array[0..4] of byte;
            );
  end;


function CalculateCS(Telegram: array of Byte): Byte;
var
  Sum, i: Integer;
begin
  Sum := 0;
  for i := 0 to High(Telegram) do
    if i <> 1 then Sum := Sum + Telegram[i];
  Result := Byte(not Sum);
end;

procedure SendByte(b: Byte);
begin
end;

function ReceiveByte(var b: Byte): Boolean;
begin
end;

procedure SendTelegram(const telegram: SISByteArray; const len: Integer);
var
  i: Integer;
begin
  for i := 1 to len do
    SendByte(telegram[i]);
end;

function ParseIDN(const IDN: ansistring; out paramType: Byte; out paramNum: Word): Boolean;
var
  CD   : TPARAMETERDATA;
begin
  CD:=IDN2CD(IDN,0);
  case CD.CCLASS of
    ccDrive: paramType            := $00;
    ccDriveSpecific: paramType    := $01;
  else
    Exit(False);
  end;
  paramNum:=CD.NUMID;
  result:=True;
end;

procedure BuildSISCommand(SISService,SISSubService,Address:byte; Data:dword; out telegram: SISByteArray; out len: Integer);
const
  HEADEROFFSET = 1;
  USERDATAOFFSET = HEADEROFFSET+8;
var
  Header         : TSISTelegramHeader;
  Ctrl           : TSISHeaderControl;
  i              : integer;
  sum            : byte;
  DDW            : DATADWORD;
begin
  len:=10;

  Ctrl.Raw:=0;
  Ctrl.Data.TelegramType:=0;

  with Header.Data do
  begin
    StartChar  := STX;
    CheckSum   := 0;
    DataLen    := 0;
    DataLenRep := 0;
    Control    := Ctrl.Raw;
    Service    := SISService;
    AddrSender := MASTER_ADDR;
    AddrRecv   := Address;
  end;

  //101 .. 116 data block number
  //1 .. 40 drive addresses
  //1 .. 2 master axis addresses
  //0 SERCOS master (PPC)
  // Unitaddress = 0 for the drive itself !
  // Might be wrong !!
  telegram[USERDATAOFFSET]  := 0;
  telegram[USERDATAOFFSET+1] := SISSubService;
  i:=0;
  case SISSubService of
    SISSubServiceSettingTrS      : i:=2;
    SISSubServiceSettingTzA      : i:=2;
    SISSubServiceSettingTmas     : i:=2;
    SISSubServiceSettingBaud     : i:=1;
    SISSubServiceSettingBaudTest : i:=3;
    SISSubServiceSettingAccept   : i:=0;
  end;
  Inc(len,i);

  DDW.Raw:=Data;
  if i>=1 then telegram[USERDATAOFFSET+2] := DDW.Bytes[0];
  if i>=2 then telegram[USERDATAOFFSET+3] := DDW.Bytes[1];
  if i>=3 then telegram[USERDATAOFFSET+4] := DDW.Bytes[2];
  if i>=4 then telegram[USERDATAOFFSET+5] := DDW.Bytes[3];

  // Set datalength
  Header.Data.DataLen:=len - 8;
  Header.Data.DataLenRep:=Header.Data.DataLen;

  // Fill telegram with header data
  for i:=0 to 7 do telegram[HEADEROFFSET+i] := Header.Bytes[i];

  // SIS checksum
  sum := STX;
  for i := 3 to len do
    sum := (sum + telegram[i]) and $FF;
  telegram[2] := (0 - sum) and $FF;

  // Check the checksum
  sum:=0;
  for i := 1 to len do
    sum := (sum + telegram[i]) and $FF;

  if (sum<>0) then
    raise EArgumentException.CreateFmt ('CDC checksum error : %d !',[sum]);
end;

// This is the real one !!
procedure BuildSISTelegram(const CD:TPARAMETERDATA; out telegram: SISByteArray; out len: Integer);
const
  HEADEROFFSET = 1;
  USERHEADEROFFSET = HEADEROFFSET+8;
  USERDATAOFFSET = USERHEADEROFFSET+5;
var
  Header         : TSISTelegramHeader;
  Ctrl           : TSISHeaderControl;
  UserHeader     : TSISUserDataHeader;
  SISService     : byte;
  DataSize       : byte;
  DA             : dword;
  i              : integer;
  sum            : byte;
  DW             : DATAWORD;
  DDW            : DATADWORD;
  LocalCD        : TPARAMETERDATA;
begin
  len:=8+5; // MainHeader+UserHeader

  if ((CD.CCLASS=ccNone) OR (CD.NUMID=0)) then Exit;

  //if (CD.SETID=0) then
  //  raise EArgumentException.CreateFmt ('Wrong slave address : %d !',[CD.SETID]);

  SISService:=0;

  if IsParameterClass(CD.CCLASS) then
  begin
    DA:=GetDriveAttribute(CD);
    if DA=0 then
    begin
      // We have no atribute data [yet]
      // Get the data from the default values [drive #0]!
      LocalCD:=CD;
      LocalCD.SETID:=0;
      DA:=GetDriveAttribute(LocalCD);
    end;
    DataSize:=ParameterSizeOf(DA);

    // Set SISService type
    if ParameterIsList(DA) then
    begin
      if (Length(CD.DATA)=0) then
        SISService:=SISServiceListRead
      else
        SISService:=SISServiceListWrite;
    end
    else
    begin
      if (Length(CD.DATA)=0) then
        SISService:=SISServiceParamRead
      else
        SISService:=SISServiceParamWrite;
    end;

    if ParameterIsReadOnly(DA,{phase=}4) then
    begin
      if ((SISService=SISServiceParamWrite) OR (SISService=SISServiceListWrite)) then
        raise EArgumentException.CreateFmt ('Read only parameter : %s !',[GetIDN(CD)]);
    end;

    Ctrl.Raw:=0;
    Ctrl.Data.TelegramType:=0;   // Create command telegram
    with Header.Data do
    begin
      StartChar  := STX;
      CheckSum   := 0;
      DataLen    := 0;
      DataLenRep := 0;
      Control    := Ctrl.Raw;
      Service    := SISService;
      AddrSender := MASTER_ADDR;
      AddrRecv   := CD.SETID;
    end;

    // SIS user data header
    // Control
    UserHeader.Data.Control.Raw:=0;
    UserHeader.Data.Control.Data.Element:=GetElementNumber(CD.CSUBCLASS);
    UserHeader.Data.Control.Data.LastTransmission:=1;
    // Unitaddress = 0 for the drive itself !
    // Might be wrong !!
    UserHeader.Data.UnitAdddress := 0;
    // Parameter type extended = 0 for S and P arameters
    UserHeader.Data.ParamExtended := 0;
    // Parameter type and number
    UserHeader.Data.ParamData:=GetIDNWord(CD);

    // Send userdats, if any
    if ((SISService=SISServiceListRead) OR (SISService=SISServiceListWrite)) then
    begin
      // ToDo
      DW.Raw:=1*DataSize;                   // List offset ... e.g. read second item
      //telegram[14] := DW.Bytes[0];      // List offset LSB
      //telegram[15] := DW.Bytes[1];      // List offset MSB
      telegram[14] := DW.Lo;            // List offset LSB
      telegram[15] := DW.Hi;            // List offset MSB
      DW.Raw:=5*DataSize;                   // List length ... e.g. read 5 items
      //telegram[16] := DW.Bytes[0];      // List length LSB
      //telegram[17] := DW.Bytes[1];      // List length MSB
      telegram[16] := DW.Lo;            // List length LSB
      telegram[17] := DW.Hi;            // List length MSB

      if (Length(CD.DATA)=0) then
        len:=len+2+2                    // SIS header + user data header + DataSize of list data
      else
        len:=len+2+2+DW.Raw;            // SIS header + user data header + DataSize of list data + DataSize of user data

      if (SISService=SISServiceListWrite) then
      begin
        // ToDo
        //telegram[18] := 0;
      end;
    end;

    // Fill telegram with userdata header
    for i:=0 to 4 do telegram[USERHEADEROFFSET+i] := UserHeader.Bytes[i];

    // Fill telegram with userdata itself, if any
    if (SISService=SISServiceParamWrite) then
    begin
      len:=len+DataSize;
      DDW.Raw:=StrToIntDef(CD.DATA,0);
      i:=0;
      while i<DataSize do
      begin
        telegram[USERDATAOFFSET+i] := DDW.Bytes[i];
        Inc(i);
      end;
    end;

    // Set datalength
    Header.Data.DataLen:=len - 8;
    Header.Data.DataLenRep:=Header.Data.DataLen;

    // Fill telegram with header data
    for i:=0 to 7 do telegram[HEADEROFFSET+i] := Header.Bytes[i];

    // SIS checksum
    sum := STX;
    for i := 3 to len do
      sum := (sum + telegram[i]) and $FF;
    telegram[2] := (0 - sum) and $FF;

    // Check the checksum
    sum:=0;
    for i := 1 to len do
      sum := (sum + telegram[i]) and $FF;

    if (sum<>0) then
      raise EArgumentException.CreateFmt ('CDC checksum error : %d !',[sum]);

  end;
end;

(*
procedure SendSISParameterWrite(const destAddr: Byte; const sParam: string; value: Word);
var
  telegram   : SISByteArray;
  len        : Integer;
begin
  BuildSISTelegram(destAddr, sParam, value, SISServiceParamWrite, telegram, len);
  SendTelegram(telegram, len);
end;

function ReadSISParameter(const destAddr: Byte; const idn: string; out value: Word): Boolean;
var
  telegram   : SISByteArray;
  len, i     : Integer;
  b          : Byte;
  response   : SISByteArray;
begin
  BuildSISTelegram(destAddr, idn, 0, SISServiceParamRead, telegram, len);
  SendTelegram(telegram, len);

  for i := 1 to 13 do
  begin
    if not ReceiveByte(b) then
    begin
      ReadSISParameter := False;
      Exit;
    end;
    response[i] := b;
  end;

  if response[1] <> STX then
  begin
    ReadSISParameter := False;
    Exit;
  end;

  value := response[12] + (response[13] shl 8);
  ReadSISParameter := True;
end;
*)

function ParseSISTelegram(const SourceCD: TPARAMETERDATA; const telegram: SISByteArray; const len: Integer):TPARAMETERDATA;
begin
  result:=SourceCD;
end;

function ParseSISTelegram(const SourceCD: TPARAMETERDATA; const s: RawByteString):TPARAMETERDATA;
var
  datas:ansistring;
  Success:boolean;
  i:integer;
begin
  datas:=s;
  result:=SourceCD;
  // Look at the SIS header
  if Length(datas)>=8 then
  begin
    Success:=(Ord(datas[1])=STX);
    Delete(datas,1,8);
  end;
  // Look at the user header
  if Length(datas)>=3 then
  begin
    Delete(datas,1,3);
  end;
  // Look at the user data
  if Length(datas)>=1 then
  begin
    for i:=1 to Length(datas) do
    begin

    end;
  end;

end;


end.

