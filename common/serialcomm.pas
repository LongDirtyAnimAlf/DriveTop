{ LazSerial
Serial Port Component for Lazarus 
by Jurassic Pork  03/2013 03/2021
This library is Free software; you can rediStribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  This program is diStributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; withOut even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a Copy of the GNU Library General Public License
  along with This library; if not, Write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. }

{ Based on }
{ SdpoSerial v0.1.4
  CopyRight (C) 2006-2010 Paulo Costa
   paco@fe.up.pt
} 
{ Synaser library  by Lukas Gebauer }
{ TcomPort component }

{ new in v0.3 version
 Add conditional macros for cpuarm rpi in lazsynaser.pas
 Hide Active property from IDE Object inspector
}

{ new in v0.4 version
  DeviceClose procedure fixed
}

{ features :
Changed :  baudrate values.
            stop bits  new value : 1.5
new event : onstatus
new property FRcvLineCRLF : if this property is true, you use RecvString
in place of RecvPacket when you read data from the port.

new procedure  ShowSetupDialog to open a port settings form :
the device combobox contain the enumerated ports.
new procedure to enumerate real serial port on linux ( in synaser).

Demo : a simulator of gps serial port + serial port receiver :
you can send NMEA frames ( GGA GLL RMC°) to the opened serial port
(start gps simulator). You can change speed and heading.
In the memo you can see what is received from  the opened serial port.
In the status bar you can see the status events.

}


unit serialcomm;

{$mode objfpc}{$H+}

interface

uses
 Classes,
 {$IFDEF MSWindows}
 Windows,
 {$ENDIF}
 SysUtils, lazsynaser,  LResources,
 CommBase;


type
{$IFDEF UNIX}
  TBaudRate=(br_____0, br____50, br____75, br___110, br___134, br___150,
             br___200, br___300, br___600, br__1200, br__1800, br__2400,
             br__4800, br__9600, br_19200, br_38400, br_57600, br115200,
             br230400
   {$IFNDEF DARWIN}   // LINUX
             , br460800, br500000, br576000, br921600, br1000000, br1152000,
             br1500000, br2000000, br2500000, br3000000, br3500000, br4000000
   {$ENDIF} );
{$ELSE}      // MSWINDOWS
   TBaudRate=(br___110,br___300, br___600, br__1200, br__2400, br__4800,
           br__9600,br_14400, br_19200, br_38400,br_56000, br_57600,
           br115200,br128000, br230400,br256000, br460800, br921600);
{$ENDIF}
  TDataBits=(db8bits,db7bits,db6bits,db5bits);
  TParity=(pNone,pOdd,pEven,pMark,pSpace);
  TFlowControl=(fcNone,fcXonXoff,fcHardware);
  TStopBits=(sbOne,sbOneAndHalf,sbTwo);

  TModemSignal = (msRI,msCD,msCTS,msDSR);
  TModemSignals = Set of TModemSignal;
  TStatusEvent = procedure(Sender: TObject; Reason: THookSerialReason; const Value: string) of object;

const
{$IFDEF UNIX}
    ConstsBaud: array[TBaudRate] of integer=
    (0, 50, 75, 110, 134, 150, 200, 300, 600, 1200, 1800, 2400, 4800, 9600,
    19200, 38400, 57600, 115200, 230400
    {$IFNDEF DARWIN}  // LINUX
       , 460800, 500000, 576000, 921600, 1000000, 1152000, 1500000, 2000000,
       2500000, 3000000, 3500000, 4000000
    {$ENDIF}  );
{$ELSE}      // MSWINDOWS
    ConstsBaud: array[TBaudRate] of integer=
    (110, 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 38400, 56000, 57600,
    115200, 128000, 230400, 256000, 460800, 921600 );
{$ENDIF}

  ConstsBits: array[TDataBits] of integer=(8, 7 , 6, 5);
  ConstsParity: array[TParity] of char=('N', 'O', 'E', 'M', 'S');
  ConstsStopBits: array[TStopBits] of integer=(SB1,SB1AndHalf,SB2);

  CR     = #13;
  LF     = #10;
  CRLF   = CR+LF;
  TERDT  = ':>';
  CSS    = '$';

type
  TLazSerial = class;

  TComPortReadThread=class(TThread)
  public
    Owner: TLazSerial;
  protected
    procedure CallEvent;
    procedure Execute; override;
  end;

  { TLazSerial }

  TLazSerial = class(TComponent,ICommInterface)
  strict private
    FTerminator:ansistring;
    FAsync:boolean;
  private
    FActive: boolean;
    FSynSer: TBlockSerial;
    FDevice: string;

    FBaudRate: TBaudRate;
    FDataBits: TDataBits;
    FParity: TParity;
    FStopBits: TStopBits;

    FSoftflow, FHardflow: boolean;
    FFlowControl: TFlowControl;

    FOnRxData: TNotifyEvent;
    FOnStatus: TStatusEvent;
    ReadThread: TComPortReadThread;

    FData:string;

    FCriticalSection: TRTLCriticalSection;
    FCommandList:TStringList;

    function  GetData:string;
    function  GetActive: boolean;
    procedure SetActive(state: boolean);
    function  GetAsync: boolean;
    procedure SetAsync(value:boolean);
    function  GetOnRxData: TNotifyEvent;
    procedure SetOnRxData(event:TNotifyEvent);

    procedure StopReader;
    procedure StartReader;

    procedure DeviceOpen;
    procedure DeviceClose;

    procedure ComException(str: string);
  protected
    procedure SetBaudRate(br: TBaudRate);
    procedure SetDataBits(db: TDataBits);
    procedure SetParity(pr: TParity);
    procedure SetFlowControl(fc: TFlowControl);
    procedure SetStopBits(sb: TStopBits);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure WriteString(const cmd: string; var dat: string);
    procedure WriteStringPrio(const cmd: string; var dat: string);
    procedure WriteStringBlocking(const cmd: string; var dat: string);

    // read pin states
    function ModemSignals: TModemSignals;
    function GetDSR: boolean;
    function GetCTS: boolean;
    function GetRing: boolean;
    function GetCarrier: boolean;

    // set pin states
//    procedure SetRTSDTR(RtsState, DtrState: boolean);
    procedure SetDTR(OnOff: boolean);
    procedure SetRTS(OnOff: boolean);
//  procedure SetBreak(OnOff: boolean);

  published
    property Active: boolean read FActive write SetActive;
    property Async: boolean read GetAsync write SetAsync;
    property OnRxData: TNotifyEvent read GetOnRxData write SetOnRxData;
    property Data: string read GetData;

    property BaudRate: TBaudRate read FBaudRate write SetBaudRate; // default br115200;
    property DataBits: TDataBits read FDataBits write SetDataBits;
    property Parity: TParity read FParity write SetParity;
    property FlowControl: TFlowControl read FFlowControl write SetFlowControl;
    property StopBits: TStopBits read FStopBits write SetStopBits;
    property SynSer: TBlockSerial read FSynSer write FSynSer;
    property Device: string read FDevice write FDevice;
    property Terminator:ansistring read FTerminator write FTerminator;
    property OnStatus: TStatusEvent read FOnStatus write FOnStatus;
  end;

implementation

{ TLazSerial }

procedure TLazSerial.StopReader;
begin
  // stop capture thread
  if (ReadThread<>nil) then
  begin
    EnterCriticalSection(FCriticalSection);
    try
      FCommandList.Clear;
    finally
      LeaveCriticalSection(FCriticalSection);
    end;
    ReadThread.FreeOnTerminate:=false;
    ReadThread.Terminate;
    while (NOT ReadThread.Terminated) do
    begin
      sleep(10);
    end;
    ReadThread.Free;
    ReadThread:=nil;
  end;
end;

procedure TLazSerial.StartReader;
begin
  // Launch Thread
  if (NOT FAsync) then exit;
  if (ReadThread=nil) then
  begin
    ReadThread := TComPortReadThread.Create(true);
    ReadThread.Owner := Self;
    ReadThread.Start;
  end;
end;


procedure TLazSerial.DeviceClose;
begin
  StopReader;

  SynSer.OnStatus := nil;

  // flush device
  if (FSynSer.Handle<>INVALID_HANDLE_VALUE) then
  begin
    FSynSer.Flush;
    FSynSer.Purge;
  end;

  // close device
  if (FSynSer.Handle<>INVALID_HANDLE_VALUE) then
  begin
    FSynSer.Flush;
    FSynSer.CloseSocket;
  end;
end;

constructor TLazSerial.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAsync:=true;
  InitCriticalSection(FCriticalSection);
  FCommandList:=TStringList.Create;
  ReadThread:=nil;

  FSynSer:=TBlockSerial.Create;
  //FSynSer.EnableRTSToggle(true);
  FSynSer.LinuxLock:=false;
  FHardflow:=false;
  FSoftflow:=false;
  FFlowControl:=fcNone;
  {$IFDEF LINUX}
  FDevice:='/dev/ttyS0';
  {$ELSE}
  FDevice:='COM1';
  {$ENDIF}
  FTerminator:=CRLF;
  FBaudRate:=br__9600;
end;

destructor TLazSerial.Destroy;
begin
  DeviceClose;
  FSynSer.Free;
  FCommandList.Free;
  DoneCriticalsection(FCriticalSection);
  inherited;
end;

procedure TLazSerial.DeviceOpen;
begin
  FSynSer.Connect(FDevice);
  if FSynSer.Handle=INVALID_HANDLE_VALUE then
    raise Exception.Create('Could not open device '+ FSynSer.Device);

  FSynSer.Config(ConstsBaud[FBaudRate],
                 ConstsBits[FDataBits],
                 ConstsParity[FParity],
                 ConstsStopBits[FStopBits],
                 FSoftflow, FHardflow);

  if Assigned(OnStatus) then SynSer.OnStatus := OnStatus;

  StartReader;
end;

function TLazSerial.GetAsync: boolean;
begin
  result:=FAsync;
end;

procedure TLazSerial.SetAsync(value:boolean);
begin
  if (value=FAsync) then exit;
  FAsync:=value;
end;

function TLazSerial.GetOnRxData: TNotifyEvent;
begin
  result:=FOnRxData;
end;

procedure TLazSerial.SetOnRxData(event:TNotifyEvent);
begin
  if (event=FOnRxData) then exit;
  FOnRxData:=event;
end;

function TLazSerial.GetData:string;
begin
  result:=FData;
end;

function TLazSerial.GetActive: boolean;
begin
  result:=FActive;
end;

procedure TLazSerial.SetActive(state: boolean);
begin
  if state=FActive then exit;
  try
    if state then
      DeviceOpen
    else
      DeviceClose;
    FActive:=state;
  except
  end;
end;

procedure TLazSerial.SetBaudRate(br: TBaudRate);
begin
  FBaudRate:=br;
  if FSynSer.Handle<>INVALID_HANDLE_VALUE then begin
    FSynSer.Config(ConstsBaud[FBaudRate], ConstsBits[FDataBits], ConstsParity[FParity],
                   ConstsStopBits[FStopBits], FSoftflow, FHardflow);
  end;
end;

procedure TLazSerial.SetDataBits(db: TDataBits);
begin
  FDataBits:=db;
  if FSynSer.Handle<>INVALID_HANDLE_VALUE then begin
    FSynSer.Config(ConstsBaud[FBaudRate], ConstsBits[FDataBits], ConstsParity[FParity],
                   ConstsStopBits[FStopBits], FSoftflow, FHardflow);
  end;
end;

procedure TLazSerial.SetFlowControl(fc: TFlowControl);
begin
  if fc=fcNone then begin
    FSoftflow:=false;
    FHardflow:=false;
  end else if fc=fcXonXoff then begin
    FSoftflow:=true;
    FHardflow:=false;
  end else if fc=fcHardware then begin
    FSoftflow:=false;
    FHardflow:=true;
  end;

  if FSynSer.Handle<>INVALID_HANDLE_VALUE then begin
    FSynSer.Config(ConstsBaud[FBaudRate], ConstsBits[FDataBits], ConstsParity[FParity],
                   ConstsStopBits[FStopBits], FSoftflow, FHardflow);
  end;
  FFlowControl:=fc;
end;

procedure TLazSerial.SetParity(pr: TParity);
begin
  FParity:=pr;
  if FSynSer.Handle<>INVALID_HANDLE_VALUE then begin
    FSynSer.Config(ConstsBaud[FBaudRate], ConstsBits[FDataBits], ConstsParity[FParity],
                   ConstsStopBits[FStopBits], FSoftflow, FHardflow);
  end;
end;

procedure TLazSerial.SetStopBits(sb: TStopBits);
begin
  FStopBits:=sb;
  if FSynSer.Handle<>INVALID_HANDLE_VALUE then begin
    FSynSer.Config(ConstsBaud[FBaudRate], ConstsBits[FDataBits], ConstsParity[FParity],
                   ConstsStopBits[FStopBits], FSoftflow, FHardflow);
  end;
end;

procedure TLazSerial.WriteString(const cmd: string; var dat: string);
begin
  if Assigned(ReadThread) then
  begin
    EnterCriticalSection(FCriticalSection);
    try
      FCommandList.Append(cmd);
    finally
      LeaveCriticalSection(FCriticalSection);
    end;
  end
  else
  begin
    WriteStringBlocking(cmd,dat);
    if Assigned(FOnRxData) then FOnRxData(Owner);
  end;
end;

procedure TLazSerial.WriteStringPrio(const cmd: string; var dat: string);
begin
  if Assigned(ReadThread) then
  begin
    EnterCriticalSection(FCriticalSection);
    try
      FCommandList.Insert(0,cmd);
    finally
      LeaveCriticalSection(FCriticalSection);
    end;
  end
  else
  begin
    WriteStringBlocking(cmd,dat);
    if Assigned(FOnRxData) then FOnRxData(Owner);
  end;
end;

procedure TLazSerial.WriteStringBlocking(const cmd: string; var dat: string);
var
  rcvd : string;
  re   : boolean;
begin
  re:=Assigned(ReadThread);
  if re then
  begin
    EnterCriticalSection(FCriticalSection);
    //ReadThread.Suspended:=True;
    StopReader;
  end;
  try
    //FSynSer.Flush;
    //FSynSer.Purge;
    FSynSer.SendString(cmd);
    FSynSer.Flush;
    rcvd:=FSynSer.RecvTerminated(1500,Terminator);
    if ((FSynSer.LastError=0) AND (Length(rcvd)>0)) then rcvd:=rcvd+Terminator;
    FData:=rcvd;
    dat:=rcvd;
    //FSynSer.Flush;
    //FSynSer.Purge;
    //if Assigned(FOnRxData) then FOnRxData(Owner);
  finally
    if re then
    begin
      StartReader;
      //ReadThread.Suspended:=False;
      LeaveCriticalSection(FCriticalSection);
    end;
  end;
end;

function TLazSerial.ModemSignals: TModemSignals;
begin
  result:=[];
  if FSynSer.CTS then result := result + [ msCTS ];
  if FSynSer.carrier then result := result + [ msCD ];
  if FSynSer.ring then result := result + [ msRI ];
  if FSynSer.DSR then result := result + [ msDSR ];
end;

function TLazSerial.GetDSR: boolean;
begin
  result := FSynSer.DSR;
end;

function TLazSerial.GetCTS: boolean;
begin
  result := FSynSer.CTS;
end;

function TLazSerial.GetRing: boolean;
begin
  result := FSynSer.ring;
end;

function TLazSerial.GetCarrier: boolean;
begin
  result := FSynSer.carrier;
end;

procedure TLazSerial.SetDTR(OnOff: boolean);
begin
  FSynSer.DTR := OnOff;
end;


procedure TLazSerial.SetRTS(OnOff: boolean);
begin
  FSynSer.RTS := OnOff;
end;


procedure TLazSerial.ComException(str: string);
begin
  raise EInOutError.Create('ComPort error: '+str);
end;

{ TComPortReadThread }

procedure TComPortReadThread.CallEvent;
begin
  if Assigned(Owner.FOnRxData) then begin
    Owner.FOnRxData(Owner);
  end;
end;

procedure TComPortReadThread.Execute;
var
  FBuffer:ansistring;
  DataString:ansistring;
  //s:ansistring;
  TerminatorPos:word;
  dr,te:boolean;
  x,y:word;
begin
  DataString:='';
  FBuffer:='';
  try
    Owner.FSynSer.Purge;
    te:=(Length(Owner.Terminator)>0);

    while (NOT Terminated) do
    begin

      EnterCriticalSection(Owner.FCriticalSection);
      try
        if ((not Terminated) AND (Owner.FCommandList.Count>0)) then
        begin
          if Owner.FSynSer.CanWrite(100) then
          begin
            //s:=Owner.FCommandList[0];
            Owner.FSynSer.SendString(Owner.FCommandList[0]);
            Owner.FCommandList.Delete(0);
            //in most cases, we expect a read after a write ... wait for it ... ;-)
            //Owner.FSynSer.CanRead(100);
          end;
        end;
      finally
        LeaveCriticalSection(Owner.FCriticalSection);
      end;

      dr:=false;
      if Owner.FSynSer.CanRead(100) then
      begin
        if te then
        begin
          DataString:=Owner.FSynSer.RecvTerminated(10000,Owner.Terminator);
          dr:=((Owner.FSynSer.LastError<>ErrTimeout) AND (Length(DataString)>0));
          if dr then Owner.FData:=DataString+Owner.Terminator;
        end
        else
        begin
          DataString:='';
          repeat
            FBuffer:=Owner.FSynSer.RecvPacket(10);
            x:=Length(FBuffer);
            if (x>0) then DataString:=DataString+FBuffer;
          until ((x=0) OR (Terminated));
          dr:=(Length(DataString)>0);
          if dr then Owner.FData:=DataString;
        end;
      end;

      if dr then Synchronize(@CallEvent);

      TThread.Yield();

    end;
  except
    //Terminate;
  end;

end;

end.
