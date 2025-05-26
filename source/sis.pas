unit sis;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  common;

const
  SISServiceParamRead                    = $80;
  SISServiceListRead                     = $81;
  SISServicePhaseRead                    = $82;

  SISServicePhaseWrite                   = $8D;
  SISServiceListWrite                    = $8E;
  SISServiceParamWrite                   = $8F;

  SISServiceUserIdentification           = $00;  // Needs address and subservice in userdata
  SISServiceTerminationDataTransmission  = $01;
  SISServiceFlashOperation               = $02;
  SISServiceInitSISCommunications        = $03;
  SISServiceExecutingListSISServices     = $04;

  SISSubServiceReadOutSISVersion         = $01; // Only for SISServiceUserIdentification
  SISSubServiceReadOutFWANumber          = $02; // Only for SISServiceUserIdentification
  SISSubServiceReadOutUnitTypecode       = $03; // Only for SISServiceUserIdentification
  SISSubServiceReadOutSupportedBaudRates = $04; // Only for SISServiceUserIdentification

  SISSubServiceSettingTrS                = $01; // Only for SISServiceInitSISCommunications
  SISSubServiceSettingTzA                = $02; // Only for SISServiceInitSISCommunications
  SISSubServiceSettingTmas               = $03; // Only for SISServiceInitSISCommunications

type
  ByteArray = array[1..256] of Byte;


procedure BuildSISStartTelegram(destAddr: Byte; out telegram: ByteArray; out len: Integer);
procedure BuildSISTelegram(destAddr: Byte; const idn: string; value: Word; service: Byte; out telegram: ByteArray; out len: Integer);overload;
procedure BuildSISTelegram(const CD:TCOMMANDDATA; out telegram: ByteArray; out len: Integer);overload;

implementation

uses
  drive,
  Bits;

const
  STX           = $02;
  LOCAL_ADDR    = $01;

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
             LastTransmission   : T1BITS;
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

procedure SendTelegram(const telegram: ByteArray; const len: Integer);
var
  i: Integer;
begin
  for i := 1 to len do
    SendByte(telegram[i]);
end;

function ParseIDN(const IDN: ansistring; out paramType: Byte; out paramNum: Word): Boolean;
var
  CD   : TCOMMANDDATA;
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

procedure BuildSISStartTelegram(destAddr: Byte; out telegram: ByteArray; out len: Integer);
var
  sum, i     : Integer;
begin
  len := 10;
  // SIS Header
  telegram[1]  := STX;          // Start symbol: STX (0x02)
  // telegram[2] :=             // Checksum
  telegram[3]  := len-8;        // DatL
  telegram[4]  := telegram[3];  // DatLW
  telegram[5]  := 0;            // Cntrl
  telegram[6]  := SISServiceUserIdentification;
  telegram[7]  := 0;            // Address of the sender: station number (0 - 126)
  telegram[8]  := destAddr;     // Address of the receiver: 0 - 126 ==> specifies a single station, 128 ==> "point-to-point" connection; 129 - 253 ==> addresses logical groups, 254 - 255 ==> fixes a broadcast

  telegram[9]  := destAddr;
  telegram[10] := SISSubServiceReadOutSISVersion;

  sum := STX;
  for i := 3 to len do
    sum := sum + telegram[i];
  telegram[2] := (0 - sum) and $FF;
end;


procedure BuildSISTelegram(destAddr: Byte; const idn: string; value: Word; service: Byte; out telegram: ByteArray; out len: Integer);
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
  telegram[7] := LOCAL_ADDR;   // Address of the sender: station number (0 - 126)
  telegram[8] := destAddr;     // Address of the receiver: 0 - 126 ==> specifies a single station, 128 ==> "point-to-point" connection; 129 - 253 ==> addresses logical groups, 254 - 255 ==> fixes a broadcast

  // SIS data
  DataCtrl.Raw:=0;
  DataCtrl.Data.Element:=GetElementNumber(mscParameterData);
  DataCtrl.Data.LastTransmission:=1;
  telegram[9]:=DataCtrl.Raw;          // Control byte

  telegram[10] := destAddr;           // Deviceaddress

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

procedure BuildSISTelegram(const CD:TCOMMANDDATA; out telegram: ByteArray; out len: Integer);
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

    // SIS Header
    telegram[1] := STX;          // Start symbol: STX (0x02)
    //telegram[2] := checksum    // Checksum
    //telegram[3] := length;     // DatL
    //telegram[4] := length;     // DatLW
    Ctrl.Raw:=0;
    Ctrl.Data.TelegramType:=0;   // Create command telegram
    telegram[5] := Ctrl.Raw;     // Cntrl
    telegram[6] := service;      // 0x80 ... 0x8F special services for ECODRIVE
    telegram[7] := LOCAL_ADDR;   // Address of the sender: station number (0 - 126)
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
      telegram[14] := DW.Bytes[0];      // List offset LSB
      telegram[15] := DW.Bytes[1];      // List offset MSB
      DW.Raw:=5*size;                   // List length ... e.g. read 5 items
      telegram[16] := DW.Bytes[0];      // List length LSB
      telegram[17] := DW.Bytes[1];      // List length MSB
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
  telegram   : ByteArray;
  len        : Integer;
begin
  BuildSISTelegram(destAddr, 'S-0-0258', value, SISServiceParamWrite, telegram, len);
  SendTelegram(telegram, len);
end;

function ReadSISParameter(const destAddr: Byte; const idn: string; out value: Word): Boolean;
var
  telegram   : ByteArray;
  len, i     : Integer;
  b          : Byte;
  response   : ByteArray;
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


end.

