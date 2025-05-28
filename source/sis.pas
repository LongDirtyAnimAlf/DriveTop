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
procedure BuildSISTelegram(SlaveAddress: Byte; const idn: string; value: Word; service: Byte; out telegram: SISByteArray; out len: Integer);overload;
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
             Reserved1                   : T1BITS;
             SystemWarningSlave          : T1BITS;
             SystemErrorSlave            : T1BITS;
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

  len := 10;
  // SIS Header
  telegram[1]  := STX;          // Start symbol: STX (0x02)
  // telegram[2] :=             // Checksum
  telegram[3]  := len-8;        // DatL
  telegram[4]  := telegram[3];  // DatLW
  telegram[5]  := 0;            // Cntrl
  telegram[6]  := SISServiceUserIdentification;
  telegram[7]  := MASTER_ADDR;  // Address of the sender: station number (0 - 126)
  telegram[8]  := SlaveAddress; // Address of the receiver: 0 - 126 ==> specifies a single station, 128 ==> "point-to-point" connection; 129 - 253 ==> addresses logical groups, 254 - 255 ==> fixes a broadcast

  telegram[9]  := SlaveAddress;
  telegram[10] := SISSubServiceReadOutSISVersion;

  sum := STX;
  for i := 3 to len do
    sum := sum + telegram[i];
  telegram[2] := (0 - sum) and $FF;
end;


procedure BuildSISTelegram(SlaveAddress: Byte; const idn: string; value: Word; service: Byte; out telegram: SISByteArray; out len: Integer);
var
  paramType  : Byte;
  paramNum   : Word;
  sum, i     : Integer;
  Ctrl       : TSISHeaderControl;
  DataCtrl   : TSISDataControl;
  IDNWORD    : TIDNWORD;
begin
  if not ParseIDN(idn, paramType, paramNum) then
    raise EArgumentException.CreateFmt ('Wrong IDN format : %s !',[IDN]);

  // ????
  if service = SISServiceParamWrite then
    len := 15 // send word = 2 bytes
  else
    len := 13;

  Ctrl.Raw:=0;

  // SIS Header
  telegram[1] := STX;          // Start symbol: STX (0x02)
  // telegram[2] :=            // Checksum
  telegram[3] := len - 8;      // DatL
  telegram[4] := telegram[3];  // DatLW
  telegram[5] := Ctrl.Raw;     // Cntrl
  telegram[6] := service;      // 0x80 ... 0x8F special services for ECODRIVE
  telegram[7] := MASTER_ADDR;  // Address of the sender: station number (0 - 126)
  telegram[8] := SlaveAddress; // Address of the receiver: 0 - 126 ==> specifies a single station, 128 ==> "point-to-point" connection; 129 - 253 ==> addresses logical groups, 254 - 255 ==> fixes a broadcast

  // SIS data
  DataCtrl.Raw:=0;
  DataCtrl.Data.Element:=GetElementNumber(mscParameterData);
  DataCtrl.Data.LastTransmission:=1;
  telegram[9] := DataCtrl.Raw;        // Control byte

  telegram[10] := SlaveAddress;       // Deviceaddress

  telegram[11] := 0;                  // Parameter type extended

  IDNWORD.Raw:=0;
  IDNWORD.Data.ParamNum:=paramNum;
  IDNWORD.Data.ParamBlock:=0;         // Normal = 0 ; Memory = 7
  IDNWORD.Data.ParamType:=paramType;  // Parameter type : S = 0 ; P = 1
  telegram[12]:=IDNWORD.Bytes[0];     // Parameter number LSB
  telegram[13]:=IDNWORD.Bytes[1];     // Parameter number MSB

  if service = SISServiceParamWrite then
  begin
    telegram[14] := Lo(value);        // User data
    telegram[15] := Hi(value);        // User data
  end;

  sum := STX;
  for i := 3 to len do
    sum := sum + telegram[i];
  telegram[2] := (0 - sum) and $FF;
end;

procedure BuildSISTelegram(const CD:TPARAMETERDATA; out telegram: SISByteArray; out len: Integer);
var
  IDNWORD        : TIDNWORD;
  Ctrl           : TSISHeaderControl;
  DataCtrl       : TSISDataControl;
  service,size   : byte;
  aw             : dword;
  sum,i          : integer;
  DW             : DATAWORD;
begin
  if ((CD.CCLASS=ccNone) OR (CD.NUMID=0)) then Exit;

  if (CD.SETID=0) then
    raise EArgumentException.CreateFmt ('Wrong slave address : %d !',[CD.SETID]);

  service:=0;

  if IsParameterClass(CD.CCLASS) then
  begin
    aw:=GetDriveAttribute(CD);
    size:=ParameterSizeOf(aw);

    // Set service type
    if ParameterIsList(aw) then
    begin
      if (Length(CD.DATA)=0) then
        service:=SISServiceListRead
      else
        service:=SISServiceListWrite;
    end
    else
    begin
      if (Length(CD.DATA)=0) then
        service:=SISServiceParamRead
      else
        service:=SISServiceParamWrite;
    end;

    if ParameterIsReadOnly(aw,4) then
    begin
      if ((service=SISServiceParamWrite) OR (service=SISServiceListWrite)) then
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
    telegram[6] := service;      // 0x80 ... 0x8F special services for ECODRIVE
    telegram[7] := MASTER_ADDR;  // Address of the sender: station number (0 - 126)
    telegram[8] := CD.SETID;     // Address of the receiver: 0 - 126 ==> specifies a single station, 128 ==> "point-to-point" connection; 129 - 253 ==> addresses logical groups, 254 - 255 ==> fixes a broadcast

    // SIS user data header
    DataCtrl.Raw:=0;
    DataCtrl.Data.Element:=GetElementNumber(CD.CSUBCLASS);
    DataCtrl.Data.LastTransmission:=1;
    telegram[9]  := DataCtrl.Raw;       // Control byte
    telegram[10] := CD.SETID;           // Deviceaddress
    telegram[11] := 0;                  // Parameter type extended

    IDNWORD.Raw:=0;
    IDNWORD.Data.ParamNum:=CD.NUMID;
    case CD.CCLASS of
      ccDrive          : IDNWORD.Data.ParamType:=0;
      ccDriveSpecific  : IDNWORD.Data.ParamType:=1;
    end;
    case CD.MEMORY of
      false            : IDNWORD.Data.ParamBlock:=0;
      true             : IDNWORD.Data.ParamBlock:=7;
    end;
    telegram[12] := IDNWORD.Bytes[0];   // Parameter data LSB
    telegram[13] := IDNWORD.Bytes[1];   // Parameter data MSB

    if ((service=SISServiceListRead) OR (service=SISServiceListWrite)) then
    begin
      DW.Raw:=1*size;                   // List offset ... e.g. read second item
      //telegram[14] := DW.Bytes[0];      // List offset LSB
      //telegram[15] := DW.Bytes[1];      // List offset MSB
      telegram[14] := DW.Lo;            // List offset LSB
      telegram[15] := DW.Hi;            // List offset MSB
      DW.Raw:=5*size;                   // List length ... e.g. read 5 items
      //telegram[16] := DW.Bytes[0];      // List length LSB
      //telegram[17] := DW.Bytes[1];      // List length MSB
      telegram[16] := DW.Lo;            // List length LSB
      telegram[17] := DW.Hi;            // List length MSB

      if (Length(CD.DATA)=0) then
        len:=8+5+2+2                    // SIS header + user data header + size of list data
      else
        len:=8+5+2+2+DW.Raw;            // SIS header + user data header + size of list data + size of user data
    end;
    if ((service=SISServiceParamRead) OR (service=SISServiceParamWrite)) then
    begin
      if (service=SISServiceParamRead) then len:=8+5;                  // SIS header + user data header
      if (service=SISServiceParamWrite) then len:=8+5+size;            // SIS header + user data header + size of user data
    end;

    // Add data, if any
    if (service=SISServiceParamWrite) then
    begin
      if size=1 then telegram[14] := 0;
      if size=2 then telegram[15] := 0;
      if size=4 then telegram[16] := 0;
      if size=4 then telegram[17] := 0;
    end;
    if (service=SISServiceListWrite) then
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

