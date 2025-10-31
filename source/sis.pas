unit sis;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math,
  common;

const
  STX                                    = $02;  // SIS header pre-amble

  //SISServiceUserIdentification           = $00;  // Needs address and subservice in userdata
  //SISServiceTerminationDataTransmission  = $01;  // Enter the service to be cancelled in the useful data.
  SISServiceFlashOperation               = $02;
  SISServiceInitSISCommunications        = $03;  // Needs address and subservice in userdata
  SISServiceExecutingListSISServices     = $04;

  SISServiceParamRead                    = $10; // 0x10 = 0x80
  SISServiceListRead                     = $11; // segment information in byte
  SISServiceListWrite                    = $1E; // segment information in byte
  SISServiceParamWrite                   = $1F; // 0x1F = 0x8F

  SERCOSServiceParamRead                 = $80; // 0x80 = 0x10
  //SERCOSServiceParamRead                 = SISServiceParamRead;
  SERCOSServiceListRead                  = $81; // segment information in word
  //SERCOSServiceListRead                  = SISServiceListRead;

  SERCOSServicePhaseRead                 = $82;
  SERCOSServicePhaseWrite                = $8D;

  SERCOSServiceListWrite                 = $8E; // segment information in word
  //SERCOSServiceListWrite                 = SISServiceListWrite;
  SERCOSServiceParamWrite                = $8F; // 0x8F = 0x1F
  //SERCOSServiceParamWrite                = SISServiceParamWrite;

  SISSubServiceReadOutSISVersion         = $01; // Only for UserIdentification  ; subservice is implemented but not active
  SISSubServiceReadOutFWANumber          = $02; // Only for UserIdentification  ; supplies content of S-0-0030
  SISSubServiceReadOutUnitTypecode       = $03; // Only for UserIdentification  ; supplies content of S-0-0140
  SISSubServiceReadOutSupportedBaudRates = $04; // Only for UserIdentification  ; read baud for serial comms

  SISSubServiceNone                      = $00;
  SISSubServiceSettingTrS                = $01; // Only SISCommunications ; Sets the slave response period
  SISSubServiceSettingTzA                = $02; // Only SISCommunications ; Specifies the separation period between characters
  SISSubServiceSettingTmas               = $03; // Only SISCommunications ; Sets the cycle period for the master control word (MSW)
  SISSubServiceSettingBaud               = $07; // Only SISCommunications ; Determining the baud rate initializes the baud rate of the serial transmission
  SISSubServiceSettingBaudTest           = $08; // Only SISCommunications ; Time-controlled baud rate test allows temporary change of the baud rate
  SISSubServiceSettingAccept             = $FF; // Only SISCommunications ; Accepting the determined values activates the values initialized with the subservices 0x01, 0x02 and 0x07

type
  SISTelegram = array[1..256] of Byte;

procedure BuildSISCommand(SISService,SISSubService,Address:byte; Data:dword; out telegram: SISTelegram; out len: Integer);
procedure BuildSISTelegram(const CD: TPARAMETERDATA; out telegram: SISTelegram; out len: Integer);overload;
function  ParseSISHeaderUserDataLength(const telegram: SISTelegram):integer;
function  ParseSISUserDataReady(const telegram: SISTelegram):boolean;
//function  ParseSISResponse(const SourceCD: TPARAMETERDATA; const s: RawByteString):TPARAMETERDATA; overload;
//function  ParseSISResponse(const SourceCD: TPARAMETERDATA; const telegram: SISTelegram; const len: Integer):TPARAMETERDATA; overload;
//function  ParseSISResponse(const telegram: SISTelegram; const len: Integer):TPARAMETERDATA; overload;
function  NewParseSISResponse(const SourceCD: TPARAMETERDATA;  const s: RawByteString):TPARAMETERDATA;

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
             Reserved                    : T1BITS;
             SlaveSystemWarning          : T1BITS;
             SlaveSystemError            : T1BITS;
          end
           );
        2 : (
          Bits            : bitpacked array[0..7] of T1BITS;
            );
        3 : (
          Raw             : byte;
            );
  end;

  TSISTelegramHeader = bitpacked record
    case integer of
       1 : (
         Data : packed record
           StartChar   : Byte;   // always $02
           CheckSum    : Byte;   // negated sum of all bytes
           DataLen     : Byte;   // DatL
           DataLenRep  : Byte;   // DatLW
           Control     : TSISHeaderControl;   // see SIS spec, bit 4 = 0 cmd / 1 response
           Service     : Byte;   // SIS service code
           AddrSender  : Byte;   // Address of the sender: station number (0 - 127)
           AddrRecv    : Byte;   // Address of the receiver: 0 - 126 ==> specifies a single station, 128 ==> "point-to-point" connection; 129 - 253 ==> addresses logical groups, 254 - 255 ==> fixes a broadcast
         end
          );
       2 : (
         Bytes            : packed array[0..7] of byte;
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

  (*

  //101 .. 116 data block number
  //1 .. 40 drive addresses
  //1 .. 2 master axis addresses
  //0 SERCOS master (PPC)

  The unit address of a drive is read in the command telegram and copied
  into the response telegram.
  The serial interface permits
  • direct SIS communication with drives supporting SIS interface. In this
  case the unit address is the same as the SIS address of the receiver.
  • accessing drive parameters via a motion control, in case of drives not
  supporting SIS interface. The SIS address is related to the motion
  control and the unit address to the drive.
  Given SIS communication with a motion control as a SIS slave and a
  SERCOS master, then the SERCOS master must be informed as to
  which unit the request relates to. This unit can be the SERCOS master
  itself or any of the drives it controls.
  The address set at the drive controller or "0" are transmitted.
  *)

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

  TSISUserDataResponseHeader = packed record
    case integer of
        1 : (
          Data : packed record
             Status             : byte;
             Control            : TSISDataControl;
             UnitAdddress       : byte;
          end
          );
        2 : (
          SIS : packed record
             Status             : byte;
             Address            : byte;
             SubService         : byte;
          end
          );
        3 : (
          Bytes            : packed array[0..2] of byte;
            );
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

procedure BuildSISCommand(SISService,SISSubService,Address:byte; Data:dword; out telegram: SISTelegram; out len: Integer);
const
  HEADEROFFSET = 1;
  USERDATAOFFSET = HEADEROFFSET+8;
var
  Header         : TSISTelegramHeader;
  i              : integer;
  sum            : byte;
  DDW            : DATADWORD;
begin
  len:=10;

  with Header.Data do
  begin
    StartChar    := STX;
    CheckSum     := 0;
    DataLen      := 0;
    DataLenRep   := 0;
    Control.Raw  := 0;
    Control.Data.TelegramType:=0;
    Service      := SISService;
    AddrSender   := MASTER_ADDR;
    AddrRecv     := Address;
  end;

  if (false) then
  //if ((SISService=SISServiceTerminationDataTransmission) AND (SISSubService=SISSubServiceNone) AND (Address=0)) then
  begin
    // We are already finished.
    // Send header only !!
    len:=8;
  end
  else
  begin
    // Unitaddress
    telegram[USERDATAOFFSET]  := Address;
    telegram[USERDATAOFFSET+1] := SISSubService;
    i:=0;
    if (SISService=SISServiceInitSISCommunications) then
    begin
      case SISSubService of
        SISSubServiceNone            : i:=0;
        SISSubServiceSettingTrS      : i:=2;
        SISSubServiceSettingTzA      : i:=2;
        SISSubServiceSettingTmas     : i:=2;
        SISSubServiceSettingBaud     : i:=1;
        SISSubServiceSettingBaudTest : i:=3;
        SISSubServiceSettingAccept   : i:=0;
      end;
    end;
    Inc(len,i);

    DDW.Raw:=Data;
    if i>=1 then telegram[USERDATAOFFSET+2] := DDW.Bytes[0];
    if i>=2 then telegram[USERDATAOFFSET+3] := DDW.Bytes[1];
    if i>=3 then telegram[USERDATAOFFSET+4] := DDW.Bytes[2];
    if i>=4 then telegram[USERDATAOFFSET+5] := DDW.Bytes[3];
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

// This is the real one !!
procedure BuildSISTelegram(const CD:TPARAMETERDATA; out telegram: SISTelegram; out len: Integer);
const
  HEADEROFFSET = 1;
  USERHEADEROFFSET = HEADEROFFSET+8;
  USERDATAOFFSET = USERHEADEROFFSET+5;
var
  Header         : TSISTelegramHeader;
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
        SISService:=SERCOSServiceListRead
      else
        SISService:=SERCOSServiceListWrite;
    end
    else
    begin
      if (Length(CD.DATA)=0) then
        SISService:=SERCOSServiceParamRead
      else
        SISService:=SERCOSServiceParamWrite;
    end;

    if ParameterIsReadOnly(DA,{phase=}4) then
    begin
      if ((SISService=SERCOSServiceParamWrite) OR (SISService=SERCOSServiceListWrite)) then
        raise EArgumentException.CreateFmt ('Read only parameter : %s !',[GetIDN(CD)]);
    end;

    with Header.Data do
    begin
      StartChar    := STX;
      CheckSum     := 0;
      DataLen      := 0;
      DataLenRep   := 0;
      Control.Raw  := 0;
      Control.Data.TelegramType:=0;
      Service      := SISService;
      if (ParameterIsList(DA) {AND (CD.CSUBCLASS=mscParameterData)}) then
      begin
        // We have an override to ease the reception of list data !!
        if (SISService=SERCOSServiceListRead) then Service:=SERCOSServiceParamRead;
        if (SISService=SERCOSServiceListWrite) then Service:=SERCOSServiceParamWrite;
      end;
      AddrSender   := MASTER_ADDR;
      AddrRecv     := CD.SETID;
    end;

    // SIS user data header
    // Control
    UserHeader.Data.Control.Raw:=0;
    UserHeader.Data.Control.Data.Element:=GetElementNumber(CD.CSUBCLASS);
    UserHeader.Data.Control.Data.LastTransmission:=1;
    UserHeader.Data.UnitAdddress := CD.SETID;
    // Parameter type extended = 0 for S and P arameters
    UserHeader.Data.ParamExtended := 0;
    // Parameter type and number
    UserHeader.Data.ParamData:=GetIDNWord(CD);

    // Fill telegram with userdata header
    for i:=0 to 4 do telegram[USERHEADEROFFSET+i] := UserHeader.Bytes[i];

    // Send param userdata, if any
    if ((SISService=SERCOSServiceParamWrite) AND (DataSize>0)) then
    begin
      len:=len+DataSize;

      DDW.Raw:=StrToIntDef(CD.DATA,0);
      for i:=0 to Pred(DataSize) do telegram[USERDATAOFFSET+i] := DDW.Bytes[i];
    end;

    // Send/receive specific list userdata
    if ((SISService=SERCOSServiceListRead) OR (SISService=SERCOSServiceListWrite)) then
    begin
      // ToDo !!
      len:=len+4;
      DW.Raw:=0;                   // List offset ... e.g. read first item
      telegram[USERHEADEROFFSET+5] := DW.Lo;            // List offset LSB
      telegram[USERHEADEROFFSET+6] := DW.Hi;            // List offset MSB
      DW.Raw:=6*DataSize;                   // List length ... e.g. read 6 items
      telegram[USERHEADEROFFSET+7] := DW.Lo;            // List length LSB
      telegram[USERHEADEROFFSET+8] := DW.Hi;            // List length MSB

      if ((SISService=SERCOSServiceListWrite) AND (DataSize>0)) then
      begin
        // ToDo
        //len:=len+DataSize;
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
    begin
      raise EArgumentException.CreateFmt ('CDC checksum error : %d !',[sum]);
    end;

  end;
end;

(*
procedure SendSISParameterWrite(const destAddr: Byte; const sParam: string; value: Word);
var
  telegram   : SISTelegram;
  len        : Integer;
begin
  BuildSISTelegram(destAddr, sParam, value, SERCOSServiceParamWrite, telegram, len);
  SendTelegram(telegram, len);
end;

function ReadSISParameter(const destAddr: Byte; const idn: string; out value: Word): Boolean;
var
  telegram   : SISTelegram;
  len, i     : Integer;
  b          : Byte;
  response   : SISTelegram;
begin
  BuildSISTelegram(destAddr, idn, 0, SERCOSServiceParamRead, telegram, len);
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


function ParseSISHeaderUserDataLength(const telegram: SISTelegram):integer;
var
  Header           : TSISTelegramHeader;
  i:integer;
begin
  for i:=1 to 8 do Header.Bytes[i-1]:=telegram[i];
  result:=(Header.Data.DataLen);
end;

function ParseSISUserDataReady(const telegram: SISTelegram):boolean;
var
  UserHeader       : TSISUserDataResponseHeader;
  i:integer;
begin
  for i:=1 to 3 do UserHeader.Bytes[i-1]:=telegram[i];
  result:=(UserHeader.Data.Control.Data.LastTransmission=1);
end;


function ParseSISResponse(const SourceCD: TPARAMETERDATA; const s: RawByteString):TPARAMETERDATA;
var
  telegram: SISTelegram;
  i:integer;
begin
  // Init
  FillChar({%H-}telegram,SizeOf(telegram),0);
  for i:=1 to Length(s) do telegram[i]:=Ord(s[i]);
  //result:=ParseSISResponse(SourceCD,telegram,Length(s));
end;

function ParseSISResponse(const SourceCD: TPARAMETERDATA; const telegram: SISTelegram; const len: Integer):TPARAMETERDATA;
var
  Header           : TSISTelegramHeader;
  UserHeader       : TSISUserDataResponseHeader;
  Success          : boolean;
  i                : integer;
  Remaining,Index  : integer;
  sum              : byte;
  DW               : DATAWORD;
  DDW              : DATADWORD;
  DA               : dword;
  LocalCD          : TPARAMETERDATA;
  DataSize         : byte;
  DataLength       : DATAWORD;
  SomeThing        : DATAWORD;
begin
  Success:=false;

  // Init
  result:=SourceCD;

  for i:=0 to 7 do Header.Bytes[i]:=0;
  for i:=0 to 2 do UserHeader.Bytes[i]:=0;
  //FillChar({%H-}SISData,SizeOf(SISData),0);
  result.DATA:='';
  result.ERROR:='Unknown error';

  // Check the checksum
  sum:=0;
  for i := 1 to len do
    sum := (sum + telegram[i]) and $FF;

  if (sum<>0) then
    raise EArgumentException.CreateFmt ('CDC checksum error : %d !',[sum]);


  Remaining:=len;
  Index:=1;

  // Look at the SIS header
  if Remaining>=8 then
  begin
    for i:=0 to 7 do Header.Bytes[i]:=telegram[Index+i];
    Inc(Index,8);
    Dec(Remaining,8);
    Success:=(Remaining>=1);
  end;

  // Now look at the user header
  if Success then
  begin
    Success:=false;
    i:=0;
    while (i<Remaining) do
    begin
      UserHeader.Bytes[i]:=telegram[Index+i];
      Inc(i);
      Inc(Index);
      (*
      if i=3 then
      begin
        // We might receive a 4th byte, in case of a special error
        if (NOT ((UserHeader.Data.Status=$01) OR (UserHeader.Data.Status=$02))) then break;
      end;
      *)
      // Max 3 bytes in user header
      if i=3 then break;
    end;
    Dec(Remaining,i);
    Success:=(Remaining>=1);
  end;

  if UserHeader.Data.Status=0 then
  begin
    result.ERROR:=''; // All ok !!
  end
  else
  begin
    case UserHeader.Data.Status of
      // Execution errors
      //$01 : result.ERROR:='Error while executing the telegram. During the execution of the requested service an error occured. The service-specific error code is contained in the useful data of the reaction telegram.';
      $01 : result.ERROR:='Error during parameter transmission. An error occurred while reading or writing a parameter.';
      //$02 : result.ERROR:='Error in the (internal) transmission channel. An error occurred while accessing the (internal) transmission channel. The specific error code is in the user data of the response telegram.';
      $02 : result.ERROR:='Error during phase switching. The specified target phase was not achieved.';
      // Protocol/telegram errors
      $F0 : result.ERROR:='Invalid service. The requested service is not supported by the addressed slave.';
      $F1 : result.ERROR:='Invalid telegram. The telegram cannot be evaluated because, for example, a slave received a response telegram from the master or the start character was not found.';
      $F2 : result.ERROR:='Telegram length error. The two length entries in the telegram do not match.';
      $F4 : result.ERROR:='Checksum error. The transmitted checksum does not match the one calculated internally.';
      $F8 : result.ERROR:='Invalid sequential telegram. In the sequential telegram, data in the useful data header, the transmitter address or the service have changed.';
      $F9 : result.ERROR:='The command telegram contains subaddresses.The routing of telegrams is not supported by the slave.';
      $FA : result.ERROR:='Useful data are missing in the command telegram. The telegram cannot be executed.';
      $FB : result.ERROR:='The requested subservice is not supported by the addressed slave.';
      $FC : result.ERROR:='The requested component is not available in the addressed slave. The component address is invalid.';
    end;
  end;

  if ((UserHeader.Data.Status=$01) OR (UserHeader.Data.Status=$02)) then
  begin
    // Report extended error code !!
    if (Remaining>=2) then
    begin
      DW.Raw:=0;
      for i:=0 to 1 do DW.Bytes[i]:=telegram[Index+i];
      result.ERROR:=GetDriveErrorDescription(DW.Raw);
      Dec(Remaining,2);
      Inc(Index,2);
      Success:=(Remaining>=1);
    end;
  end;

  // Now look at the user data
  if Success then
  begin
    if IsParameterClass(SourceCD.CCLASS) then
    begin
      DA:=GetDriveAttribute(SourceCD);
      if DA=0 then
      begin
        // We have no atribute data [yet]
        // Get the data from the default values [drive #0]!
        LocalCD:=SourceCD;
        LocalCD.SETID:=0;
        DA:=GetDriveAttribute(LocalCD);
      end;
      if ParameterIsList(DA) then
      begin
        // Retrieve the datalength in bytes !!!!
        if Remaining>=2 then
        begin
          DataLength.Bytes[0]:=telegram[Index];
          DataLength.Bytes[1]:=telegram[Index+1];
        end;
        Dec(Remaining,2);
        Inc(Index,2);
        // Retrieve something else !!??
        if Remaining>=2 then
        begin
          SomeThing.Bytes[0]:=telegram[Index];
          SomeThing.Bytes[1]:=telegram[Index+1];
        end;
        Dec(Remaining,2);
        Inc(Index,2);
      end
      else
        DataLength.Raw:=ParameterSizeOf(DA);
      // Handle all data !!
      if (ParameterIsChar(DA) OR ParameterIsByteList(DA)) then
      begin
        SetLength(result.DATA,DataLength.Raw);
        for i:=1 to DataLength.Raw do
        begin
          result.DATA[i]:=Chr(telegram[Index]);
          ////if ParameterIsBinary(DA) then result.DATA:=result.DATA+DecimalToBinaryString(DW.Raw);
          Dec(Remaining);
          Inc(Index);
        end;
      end
      else
      if (ParameterIsUInt(DA) OR ParameterIsInt(DA) OR ParameterIsWordList(DA)) then
      begin
        // Receive words !!
        DataLength.Raw:=DataLength.Raw DIV 2;
        for i:=1 to DataLength.Raw do
        begin
          DW.Bytes[0]:=telegram[Index];
          DW.Bytes[1]:=telegram[Index+1];
          Dec(Remaining,2);
          Inc(Index,2);
          if ParameterIsHex(DA) then result.DATA:=result.DATA+DecimalToHexString(DW.Raw,true)+',';
          if (ParameterIsUInt(DA) OR ParameterIsInt(DA)) then result.DATA:=result.DATA+InttoStr(DW.Raw)+',';
          if ParameterIsBinary(DA) then result.DATA:=result.DATA+DecimalToBinaryString(DW.Raw);
        end;
        if (Length(result.DATA)>0) then Delete(result.DATA,Length(result.DATA),1);
      end
      else
      if ParameterIsDWordList(DA) then
      begin
        // Receive dwords !!
        DataLength.Raw:=DataLength.Raw DIV 4;
        for i:=1 to DataLength.Raw do
        begin
          DDW.Bytes[0]:=telegram[Index];
          DDW.Bytes[1]:=telegram[Index+1];
          DDW.Bytes[2]:=telegram[Index+2];
          DDW.Bytes[3]:=telegram[Index+3];
          Dec(Remaining,4);
          Inc(Index,4);
          if ParameterIsHex(DA) then result.DATA:=result.DATA+DecimalToHexString(DDW.Raw,true)+',';
          if (ParameterIsUInt(DA) OR ParameterIsInt(DA)) then result.DATA:=result.DATA+InttoStr(DDW.Raw)+',';
          if ParameterIsBinary(DA) then result.DATA:=result.DATA+DecimalToBinaryString(DDW.Raw);
        end;
        if (Length(result.DATA)>0) then Delete(result.DATA,Length(result.DATA),1);
      end
      (*
      else
      if ParameterIsBinary(DA) then
      begin
        if DataSize=1 then
        begin
          result.DATA:=DecimalToBinaryString(telegram[Index]);
        end
        else
        if DataSize=2 then
        begin
          DW.Raw:=0;
          for i:=0 to 1 do DW.Bytes[i]:=telegram[Index+i];
          result.DATA:=DecimalToBinaryString(DW.Raw);
        end
        else
        if DataSize=4 then
        begin
          DDW.Raw:=0;
          for i:=0 to 3 do DDW.Bytes[i]:=telegram[Index+i];
          result.DATA:=DecimalToBinaryString(DDW.Raw);
        end;
      end
      *)
      else
      if ParameterIsDWordList(DA) then
      begin
        i:=0;
      end
      else
      if ParameterIsByteList(DA) then
      begin
        i:=0;
      end
      else
      begin
        i:=0;
      end;
    end
    else
    begin
      i:=0;
    end;
  end
  else
  begin
    i:=0;
  end;
end;

function IntPowerI(Base: Int64; Exponent: Cardinal): Int64;
var
  b: Int64;
  e: Cardinal;
begin
  Result := 1;
  b := Base;
  e := Exponent;
  while e > 0 do
  begin
    if (e and 1) = 1 then
      Result := Result * b;
    e := e shr 1;
    if e > 0 then
      b := b * b;
  end;
end;

function NewParseSISResponse(const SourceCD: TPARAMETERDATA;  const s: RawByteString):TPARAMETERDATA;
var
  Success          : boolean;
  i,j              : integer;
  Remaining,Index  : integer;
  DB               : DATABYTE;
  DW               : DATAWORD;
  DDW              : DATADWORD;
  IDN              : TIDNWORD;
  DA               : dword;
  LocalCD          : TPARAMETERDATA;
  DataSize         : byte;
  Decimals         : byte;
  Number           : ansistring;
  DataLength       : DATAWORD;
  SomeThing        : DATAWORD;
  IntPart,FracPart : longint;
  Divisor          : longint;
  SignIndicator    : string[1];
begin
  Success:=true;

  // Init
  result:=SourceCD;

  Index:=1;
  Remaining:=Length(s);

  DataLength.Raw:=0;
  SomeThing.Raw:=0;

  // Now look at the user data
  if Success then
  begin
    if IsParameterClass(SourceCD.CCLASS) then
    begin
      DA:=GetDriveAttribute(SourceCD);
      if DA=0 then
      begin
        // We have no atribute data [yet]
        // Get the data from the default values [drive #0]!
        LocalCD:=SourceCD;
        LocalCD.SETID:=0;
        DA:=GetDriveAttribute(LocalCD);
      end;
      DataSize:=ParameterSizeOf(DA);
      Decimals:=ParameterDecimals(DA);
      if ParameterIsList(DA) then
      begin
        // Retrieve the datalength in bytes !!!!
        if Remaining>=2 then
        begin
          DataLength.Bytes[0]:=Ord(s[Index]);
          DataLength.Bytes[1]:=Ord(s[Index+1]);
        end;
        Dec(Remaining,2);
        Inc(Index,2);
        // Retrieve something else !!??
        if Remaining>=2 then
        begin
          SomeThing.Bytes[0]:=Ord(s[Index]);
          SomeThing.Bytes[1]:=Ord(s[Index+1]);
        end;
        Dec(Remaining,2);
        Inc(Index,2);
      end
      else
        DataLength.Raw:=DataSize;

      // Handle all data !!
      if ParameterIsIDN(DA) then
      begin
        // DataSize always 2
        DataLength.Raw:=DataLength.Raw DIV 2;
        for i:=1 to DataLength.Raw do
        begin
          IDN.Raw:=0;
          for j:=0 to 1 do IDN.Bytes[j]:=Ord(s[Index+j]);
          result.DATA:=result.DATA+GetIDN(IDN)+',';
          Dec(Remaining,2);
          Inc(Index,2);
        end;
        if (Length(result.DATA)>0) then Delete(result.DATA,Length(result.DATA),1);
      end
      else
      if ParameterIsFloat(DA) then
      begin
        // DataSize might be 8 !!
        i:=0;
      end
      else
      if ParameterIsBinary(DA) then
      begin
        DataLength.Raw:=DataLength.Raw DIV DataSize;
        for i:=1 to DataLength.Raw do
        begin
          if DataSize=1 then
          begin
            result.DATA:=result.DATA+DecimalToBinaryString(Ord(s[Index]),true);
            Dec(Remaining,1);
            Inc(Index,1);
          end
          else
          if DataSize=2 then
          begin
            DW.Raw:=0;
            for j:=0 to 1 do DW.Bytes[j]:=Ord(s[Index+j]);
            result.DATA:=result.DATA+DecimalToBinaryString(DW.Raw,true)+',';
            Dec(Remaining,2);
            Inc(Index,2);
          end
          else
          if DataSize=4 then
          begin
            DDW.Raw:=0;
            for j:=0 to 3 do DDW.Bytes[j]:=Ord(s[Index+j]);
            result.DATA:=result.DATA+DecimalToBinaryString(DDW.Raw,true)+',';
            Dec(Remaining,4);
            Inc(Index,4);
          end;
        end;
        if (Length(result.DATA)>0) then Delete(result.DATA,Length(result.DATA),1);
      end
      else
      if ParameterIsChar(DA) then
      begin
        SetLength(result.DATA,DataLength.Raw);
        for i:=1 to DataLength.Raw do
        begin
          result.DATA[i]:=s[Index];
          Dec(Remaining);
          Inc(Index);
        end;
      end
      else
      if ParameterIsByteList(DA) then
      begin
        // Receive bytes !!
        for i:=1 to DataLength.Raw do
        begin
          DB.Raw:=Ord(s[Index]);
          Dec(Remaining);
          Inc(Index);
          if ParameterIsHex(DA) then
            result.DATA:=result.DATA+DecimalToHexString(DB.Raw,true)+','
          else
            result.DATA:=result.DATA+InttoStr(DB.Raw)+',';
        end;
        if (Length(result.DATA)>0) then Delete(result.DATA,Length(result.DATA),1);
      end
      else
      if (ParameterIsUInt(DA) OR ParameterIsInt(DA) OR ParameterIsHex(DA) OR ParameterIsWordList(DA) OR ParameterIsDWordList(DA)) then
      begin
        // Receive words or dwords !!
        DataLength.Raw:=DataLength.Raw DIV DataSize;
        for i:=1 to DataLength.Raw do
        begin
          DB.Raw:=Ord(s[Index]);
          Dec(Remaining);
          Inc(Index);
          DW.Signed:=DB.Signed;
          if DataSize>=2 then
          begin
            DW.Bytes[1]:=Ord(s[Index]);
            Dec(Remaining);
            Inc(Index);
          end;
          DDW.Signed:=DW.Signed;
          if DataSize>=4 then
          begin
            DDW.Bytes[2]:=Ord(s[Index]);
            DDW.Bytes[3]:=Ord(s[Index+1]);
            Dec(Remaining,2);
            Inc(Index,2);
          end;
          if ParameterIsHex(DA) then
          begin
            if DataSize=1 then result.DATA:=result.DATA+DecimalToHexString(DB.Raw,true)+',';
            if DataSize=2 then result.DATA:=result.DATA+DecimalToHexString(DW.Raw,true)+',';
            if DataSize=4 then result.DATA:=result.DATA+DecimalToHexString(DDW.Raw,true)+',';
          end
          else
          begin
            if (Decimals=0) then
            begin
              result.DATA:=result.DATA+InttoStr(DDW.Signed)+',';
            end
            else
            begin
              SignIndicator:='';
              Divisor:=IntPowerI(10,Decimals);
              DivMod(DDW.Signed,Divisor,IntPart,FracPart);
              if ((IntPart=0) AND (FracPart<0)) then SignIndicator:='-';
              FracPart:=Abs(FracPart);
              result.DATA:=result.DATA+Format('%.1s%d.%.'+InttoStr(Decimals)+'d',[SignIndicator,IntPart,FracPart])+',';
            end;
          end;
        end;
        if (Length(result.DATA)>0) then Delete(result.DATA,Length(result.DATA),1);
      end
      else
      begin
        i:=0;
      end;
    end
    else
    begin
      i:=0;
    end;
  end
  else
  begin
    i:=0;
  end;
end;


function ParseSISResponse(const telegram: SISTelegram; const len: Integer):TPARAMETERDATA;
var
  SourceCD : TPARAMETERDATA;
begin
  SourceCD:=Default(TPARAMETERDATA);
  result:=ParseSISResponse(SourceCD,telegram,len);
end;

end.

