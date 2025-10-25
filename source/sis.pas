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

procedure BuildSISStartTelegram(SlaveAddress: Byte; out telegram: SISByteArray; out len: Integer);
procedure BuildSISTelegram(const CD: TPARAMETERDATA; out telegram: SISByteArray; out len: Integer);overload;
function  ParseSISTelegram(const SourceCD: TPARAMETERDATA; const telegram: SISByteArray; const len: Integer):TPARAMETERDATA; overload;
function  ParseSISTelegram(const SourceCD: TPARAMETERDATA; const s: RawByteString):TPARAMETERDATA; overload;

implementation

uses
  drive,
  Bits;

const
  MASTER_ADDR   = $00;

type
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

// Cmd := BuildSISCommand($80, driveaddress, ParamType, ParamIDN, []); // Read example

procedure BuildSISCommand(Service: Byte; AdrE: Byte; ParamType: Byte; ParamIDN: Word; UserData: array of Byte; out Data: array of Byte);
var
  Telegram: array of Byte;
  DatL: Byte;
  UserHead: array[0..4] of Byte;
begin
  UserHead[0] := $00; // Control (last transmission)
  UserHead[1] := AdrE; // Device address
  UserHead[2] := ParamType; // 0=S, 1=P
  UserHead[3] := Lo(ParamIDN);
  UserHead[4] := Hi(ParamIDN);

  DatL := 5 + Length(UserData); // User head + data

  SetLength({%H-}Telegram, 8 + DatL); // Header + user

  Telegram[0] := $02; // STX
  Telegram[2] := DatL; // DatL
  Telegram[3] := DatL; // DatLW
  Telegram[4] := $00; // Cntrl (no subaddr, no packet)
  Telegram[5] := Service; // 0x80 read, 0x8F write
  Telegram[6] := $00; // AdrS (master=0)
  Telegram[7] := AdrE; // AdrE

  Move(UserHead[0], Telegram[8], 5);
  if Length(UserData) > 0 then Move(UserData[0], Telegram[13], Length(UserData));

  Telegram[1] := CalculateCS(Telegram); // CS

  //Result := Telegram;
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

procedure BuildSISStartTelegram(SlaveAddress: Byte; out telegram: SISByteArray; out len: Integer);
var
  sum, i     : Integer;
begin
  if (SlaveAddress=0) then
    raise EArgumentException.CreateFmt ('Wrong slave address : %d !',[SlaveAddress]);

  len := 11;
  // SIS Header
  telegram[1]  := STX;          // Start symbol: STX (0x02)
  // telegram[2] :=             // Checksum
  telegram[3]  := len-8;        // DatL
  telegram[4]  := telegram[3];  // DatLW
  telegram[5]  := 0;            // Cntrl
  telegram[6]  := SISServiceInitSISCommunications;
  telegram[7]  := MASTER_ADDR;  // Address of the sender: station number (0 - 126)
  telegram[8]  := SlaveAddress; // Address of the receiver: 0 - 126 ==> specifies a single station, 128 ==> "point-to-point" connection; 129 - 253 ==> addresses logical groups, 254 - 255 ==> fixes a broadcast

  // Address might also be 0
  // To be investigated
  telegram[9]  := SlaveAddress;
  //telegram[9]  := 0;

  telegram[10] := SISSubServiceSettingBaud;
  // 9600 baud
  telegram[11] := 0;

  sum := STX;
  for i := 3 to len do
    sum := sum + telegram[i];
  telegram[2] := (0 - sum) and $FF;
end;

// This is the real one !!
procedure BuildSISTelegram(const CD:TPARAMETERDATA; out telegram: SISByteArray; out len: Integer);
var
  UserHeader     : TSISUserDataHeader;
  Ctrl           : TSISHeaderControl;
  SISService     : byte;
  DataSize       : byte;
  DA             : dword;
  sum,i          : integer;
  DW             : DATAWORD;
  DDW            : DATADWORD;
  LocalCD        : TPARAMETERDATA;
begin
  len:=0;

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

    // SIS Header
    telegram[1] := STX;          // Start symbol: STX (0x02)
    //telegram[2] := checksum    // Checksum
    //telegram[3] := length;     // DatL
    //telegram[4] := length;     // DatLW
    Ctrl.Raw:=0;
    Ctrl.Data.TelegramType:=0;   // Create command telegram
    telegram[5] := Ctrl.Raw;     // Cntrl
    telegram[6] := SISService;      // 0x80 ... 0x8F special services for ECODRIVE
    telegram[7] := MASTER_ADDR;  // Address of the sender: station number (0 - 126)
    telegram[8] := CD.SETID;     // Address of the receiver: 0 - 126 ==> specifies a single station, 128 ==> "point-to-point" connection; 129 - 253 ==> addresses logical groups, 254 - 255 ==> fixes a broadcast

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

    // Send userdata header
    telegram[9]  := UserHeader.Bytes[0];
    telegram[10] := UserHeader.Bytes[1];
    telegram[11] := UserHeader.Bytes[2];
    telegram[12] := UserHeader.Bytes[3];
    telegram[13] := UserHeader.Bytes[4];

    // Send userdats, if any
    if ((SISService=SISServiceListRead) OR (SISService=SISServiceListWrite)) then
    begin
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
        len:=8+5+2+2                    // SIS header + user data header + DataSize of list data
      else
        len:=8+5+2+2+DW.Raw;            // SIS header + user data header + DataSize of list data + DataSize of user data
    end;

    if ((SISService=SISServiceParamRead) OR (SISService=SISServiceParamWrite)) then
    begin
      if (SISService=SISServiceParamRead) then len:=8+5;                  // SIS header + user data header
      if (SISService=SISServiceParamWrite) then len:=8+5+DataSize;            // SIS header + user data header + DataSize of user data
    end;

    // Add data, if any
    if (SISService=SISServiceParamWrite) then
    begin
      DDW.Raw:=StrToIntDef(CD.DATA,0);
      if DataSize>=1 then telegram[14] := DDW.Bytes[0];
      if DataSize>=2 then telegram[15] := DDW.Bytes[1];
      if DataSize>=4 then telegram[16] := DDW.Bytes[2];
      if DataSize>=4 then telegram[17] := DDW.Bytes[3];
    end;


    if (SISService=SISServiceListWrite) then
    begin
      //telegram[18] := 0;
    end;


    // Set datalength
    telegram[3] := len - 8;             // DatL
    telegram[4] := telegram[3];         // DatLW

    // SIS checksum
    sum := STX;
    for i := 3 to len do
      sum := sum + telegram[i];
    telegram[2] := (0 - sum) and $FF;
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

