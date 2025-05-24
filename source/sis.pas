unit sis;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

implementation

uses
  common,
  Bits;

const
  STX           = $02;
  PARAM_WRITE   = $8F;
  PARAM_READ    = $80;
  LOCAL_ADDR    = $01;

type
  ByteArray = array[1..32] of Byte;

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
  if service = PARAM_WRITE then
    len := 15 // send word = 2 bytes
  else
    len := 13;

  Ctrl.Raw:=0;

  // SIS Header
  telegram[1] := STX;          // Start symbol: STX (0x02)
  // telegram[2] :=            // Checksum
  telegram[3] := len - 7;      // DatL
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

  if service = PARAM_WRITE then
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
  IDN        : ansistring;
  IDNWORD    : TIDNWORD;
  DataCtrl   : TSISDataControl;
  service    : Byte;
begin
  if ((CD.CCLASS=ccNone) OR (CD.NUMID=0)) then Exit;

  IDN:=GetIDN(CD);

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

  DataCtrl.Raw:=0;
  DataCtrl.Data.Element:=GetElementNumber(CD.CSUBCLASS);
  DataCtrl.Data.LastTransmission:=1;

  if (Length(CD.DATA)=0) then
    service:=PARAM_READ
  else
    service:=PARAM_WRITE;


end;


procedure SendSISParameterWrite(const destAddr: Byte; const sParam: string; value: Word);
var
  telegram   : ByteArray;
  len        : Integer;
begin
  BuildSISTelegram(destAddr, 'S-0-0258', value, PARAM_WRITE, telegram, len);
  SendTelegram(telegram, len);
end;

function ReadSISParameter(const destAddr: Byte; const idn: string; out value: Word): Boolean;
var
  telegram   : ByteArray;
  len, i     : Integer;
  b          : Byte;
  response   : ByteArray;
begin
  BuildSISTelegram(destAddr, idn, 0, PARAM_READ, telegram, len);
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

