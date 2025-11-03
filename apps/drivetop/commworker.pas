unit commworker;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs,
  serialcomm, common;

type
  TWorkManager = class;

  // Worker thread with queue
  TWorkerThread = class(TThread)
  private
    FSISQueue: TList;
    FASCIIQueue: TList;
    FLock: TCriticalSection;
    FEvent: TEvent;
    FOnWorkComplete: TNotifyEvent;
    FCurrentWorkData: PPARAMETERDATA;
    FIsProcessing: Boolean;
    FOwner: TWorkManager;
    procedure ProcessSISWork(AData: PPARAMETERDATA);
    procedure ProcessASCIIWork(AData: PPARAMETERDATA);
  protected
    procedure Execute; override;
    procedure NotifyComplete;
  public
    constructor Create(Owner:TWorkManager);
    destructor Destroy; override;
    procedure AddSISWork(AData: PPARAMETERDATA);
    procedure AddSISWorkPrio(AData: PPARAMETERDATA);
    procedure AddSISWorkBlocking(AData: PPARAMETERDATA);
    procedure AddASCIIWork(AData: PPARAMETERDATA);
    procedure AddASCIIWorkPrio(AData: PPARAMETERDATA);
    procedure AddASCIIWorkBlocking(AData: PPARAMETERDATA);
    function IsAllFinished: Boolean;
    property CurrentWorkData: PPARAMETERDATA read FCurrentWorkData;
    property OnWorkComplete: TNotifyEvent read FOnWorkComplete write FOnWorkComplete;
  end;

  TWorkManager = class
  private
    FComms:TLazSerial;
    FWorkComplete: TNotifyEvent;
    FThread: TWorkerThread;
    procedure SetWorkComplete(aValue:TNotifyEvent);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddWork(var NewWorkData: TPARAMETERDATA; SISData:boolean; prio:boolean=false;blocking:boolean=false);
    function IsAllFinished: Boolean;
    property WorkComplete: TNotifyEvent read FWorkComplete write SetWorkComplete;
    property Comms:TLazSerial write FComms;
  end;

implementation

uses
  drive,sis;


const
  MAXWORD = $FFFF;

constructor TWorkerThread.Create(Owner:TWorkManager);
begin
  inherited Create(True);
  Self.FOwner:=Owner;
  FreeOnTerminate := False;
  FSISQueue := TList.Create;
  FASCIIQueue := TList.Create;
  FLock := TCriticalSection.Create;
  FEvent := TEvent.Create(nil, False, False, '');
  FIsProcessing := False;
end;

destructor TWorkerThread.Destroy;
var
  i: Integer;
begin
  Terminate;
  FEvent.SetEvent;
  WaitFor;

  // Clean up any remaining items
  FLock.Acquire;
  try
    for i := 0 to FSISQueue.Count - 1 do
      Dispose(PPARAMETERDATA(FSISQueue[i]));
    FSISQueue.Free;
    for i := 0 to FASCIIQueue.Count - 1 do
      Dispose(PPARAMETERDATA(FASCIIQueue[i]));
    FASCIIQueue.Free;
  finally
    FLock.Release;
  end;

  FLock.Free;
  FEvent.Free;
  inherited;
end;

procedure TWorkerThread.AddSISWork(AData: PPARAMETERDATA);
begin
  FLock.Acquire;
  try
    FSISQueue.Add(AData);
    FEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TWorkerThread.AddSISWorkPrio(AData: PPARAMETERDATA);
begin
  FLock.Acquire;
  try
    FSISQueue.Insert(0,AData);
    FEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TWorkerThread.AddSISWorkBlocking(AData: PPARAMETERDATA);
begin
  FLock.Acquire;
  try
    ProcessSISWork(AData);
  finally
    FLock.Release;
  end;
end;

procedure TWorkerThread.AddASCIIWork(AData: PPARAMETERDATA);
begin
  FLock.Acquire;
  try
    FASCIIQueue.Add(AData);
    FEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TWorkerThread.AddASCIIWorkPrio(AData: PPARAMETERDATA);
begin
  FLock.Acquire;
  try
    FASCIIQueue.Insert(0,AData);
    FEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TWorkerThread.AddASCIIWorkBlocking(AData: PPARAMETERDATA);
begin
  FLock.Acquire;
  try
    ProcessASCIIWork(AData);
  finally
    FLock.Release;
  end;
end;

procedure TWorkerThread.ProcessSISWork(AData: PPARAMETERDATA);
var
  SISSendData            : SISTelegram;
  SISRetrieveHeader      : SISTelegram;
  SISRetrieveUserData    : SISTelegram;
  DataReady              : boolean;
  SlaveDataLength        : Integer;
  MasterDataLength       : Integer;
  crc,i,dataindex        : Integer;
  Header                 : TSISTelegramHeader;
  UserHeader             : TSISUserDataResponseHeader;
  success                : boolean;
begin

  if Assigned(FOwner.FComms) AND Assigned(FOwner.FComms.SynSer) then
  begin
    success:=(FOwner.FComms.SynSer.LastError=0);
    FillChar({%H-}SISSendData,SizeOf(SISSendData),0);
    BuildSISTelegram(AData^,SISSendData,MasterDataLength);
    AData^.DATA:='';
    repeat
      DataReady:=true;
      FOwner.FComms.SynSer.Purge;
      // Send the master header and master data
      success:=(FOwner.FComms.SynSer.SendBuffer(@SISSendData,MasterDataLength)=MasterDataLength);
      FOwner.FComms.SynSer.Flush;
      if success then success:=(FOwner.FComms.SynSer.LastError=0);
      if success then
      begin
        FillChar({%H-}SISRetrieveHeader,SizeOf(SISRetrieveHeader),0);
        success:=(FOwner.FComms.SynSer.RecvBufferEx(@SISRetrieveHeader,8,10000)=8);
        if success then success:=(FOwner.FComms.SynSer.LastError=0);
        if success then
        begin
          for i:=1 to 8 do Header.Bytes[i-1]:=SISRetrieveHeader[i];
          SlaveDataLength:=Header.Data.DataLen;
          if (SlaveDataLength>0) then
          begin
            FillChar({%H-}SISRetrieveUserData,SizeOf(SISRetrieveUserData),0);
            success:=(FOwner.FComms.SynSer.RecvBufferEx(@SISRetrieveUserData,SlaveDataLength,10000)=SlaveDataLength);
            if success then success:=(FOwner.FComms.SynSer.LastError=0);
            if success then
            begin
              // Check the CRC
              crc:=0;
              for i:=1 to 8 do crc := ((crc + SISRetrieveHeader[i]) AND $FF);
              for i:=1 to SlaveDataLength do crc := ((crc + SISRetrieveUserData[i]) AND $FF);
              success:=(crc=0);// crc should now be zero again !!
              if success then
              begin
                // Check for normal user data
                if (SlaveDataLength>=3) then
                begin
                  //Process first three bytes of user data
                  for i:=1 to 3 do UserHeader.Bytes[i-1]:=SISRetrieveUserData[i];
                  DataReady:=(UserHeader.Data.Control.Data.LastTransmission=1);
                  // Skip userdata header and process rest of data
                  if (SlaveDataLength>3) then
                  begin
                    Dec(SlaveDataLength,3);
                    dataindex:=Length(AData^.DATA)+1;
                    // Extend DATA to store the received bytes
                    SetLength(AData^.DATA,Length(AData^.DATA)+SlaveDataLength);
                    // Add remaining userdata if any
                    for i:=1 to SlaveDataLength do
                    begin
                      AData^.DATA[dataindex]:=Chr(SISRetrieveUserData[i+3]);
                      Inc(dataindex);
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    until DataReady;
    NewerParseSISResponse(AData);
  end
  else
  begin
    //Sleep(1500); // Simulate processing time
    AData^.DATA := 'No connection available';
    AData^.ERROR := 'No connection available';
  end;
end;

procedure TWorkerThread.ProcessASCIIWork(AData: PPARAMETERDATA);
var
  c         : RawByteString;
  ro        : boolean;
  rcvd      : ansistring;
  re        : boolean;
  datas     : ansistring;
  i,j       : integer;
  success   : boolean;
begin
  if Assigned(FOwner.FComms) AND Assigned(FOwner.FComms.SynSer) then
  begin
    ro:=(Length(AData^.DATA)=0);

    c:=GetDirectDriveCommand(AData^);

    AData^.DATA:='';

    FOwner.FComms.SynSer.Purge;
    FOwner.FComms.SynSer.SendString(c+#13);
    FOwner.FComms.SynSer.Flush;

    if (AData^.CSUBCLASS=mscList) then
      rcvd:=FOwner.FComms.SynSer.RecvTerminated(1500,TERDT) // List might take long to receive
    else
      rcvd:=FOwner.FComms.SynSer.RecvTerminated(100,TERDT);

    if ((FOwner.FComms.SynSer.LastError=0) AND (Length(rcvd)>0)) then
    begin
      // Response should always start with the command itself
      success:=(Pos(c,rcvd)=1);
      if success then
      begin
        // Remove header
        //i:=Pos(#13,rcvd);
        //Delete(rcvd,1,i);
      end;
      // remove [unneeded and unwanted and unexpected] CRLF from result
      SetLength({%H-}datas,MAXWORD);
      j:=1;
      for i:=1 to Length(rcvd) do
      begin
        if (rcvd[i]=#10) then continue;
        if ((i<Length(rcvd)) AND (rcvd[i]=#13) AND (rcvd[i+1]=#10)) then continue;
        datas[j]:=rcvd[i];
        Inc(j);
        if (j>MAXWORD) then break; // prevent memory errors
      end;
      SetLength(datas,j-1);
      // Add the terminator to the result
      AData^.DATA:=datas+TERDT;
    end;
    NewProcessNormalResponse(AData);
  end
  else
  begin
    //Sleep(1500); // Simulate processing time
    AData^.DATA := 'No connection available';
    AData^.ERROR := 'No connection available';
  end;
end;

procedure TWorkerThread.NotifyComplete;
var
  WorkData: PPARAMETERDATA;
begin
  if Assigned(FOnWorkComplete) then
    FOnWorkComplete(Self)
  else
  begin
    WorkData := CurrentWorkData;
    if Assigned(WorkData) then Dispose(WorkData);
  end;
end;

procedure TWorkerThread.Execute;
var
  WorkItem: PPARAMETERDATA;
  WaitResult:TWaitResult;
  SISWork:boolean;
begin
  while (NOT Terminated) do
  begin
    WaitResult:=FEvent.WaitFor(INFINITE);

    if ((WaitResult=wrSignaled) AND (NOT Terminated)) then
    begin
      FLock.Acquire;
      try
        if FSISQueue.Count > 0 then
        begin
          SISWork:=True;
          WorkItem := PPARAMETERDATA(FSISQueue[0]);
          FSISQueue.Delete(0);
          FIsProcessing := True;
        end
        else
        if FASCIIQueue.Count > 0 then
        begin
          SISWork:=False;
          WorkItem := PPARAMETERDATA(FASCIIQueue[0]);
          FASCIIQueue.Delete(0);
          FIsProcessing := True;
        end
        else
        begin
          WorkItem := nil;
          FIsProcessing := False;
        end;
      finally
        FLock.Release;
      end;

      if Assigned(WorkItem) then
      begin
        if SISWork then
          ProcessSISWork(WorkItem)
        else
          ProcessASCIIWork(WorkItem);
        FCurrentWorkData := WorkItem;
        Synchronize(@NotifyComplete);
        FCurrentWorkData := nil;
        FLock.Acquire;
        try
          if ((FSISQueue.Count>0) OR (FASCIIQueue.Count>0)) then
          begin
            Sleep(10); // don't flood
            FEvent.SetEvent;
          end
          else
            FIsProcessing := False;
        finally
          FLock.Release;
        end;
      end;
    end;

  end;
end;

function TWorkerThread.IsAllFinished: Boolean;
begin
  FLock.Acquire;
  try
    Result := (FSISQueue.Count = 0) AND (FASCIIQueue.Count = 0) and (not FIsProcessing);
  finally
    FLock.Release;
  end;
end;

constructor TWorkManager.Create;
begin
  FComms:=nil;
  FThread := TWorkerThread.Create(Self);
  FThread.Start;
end;

destructor TWorkManager.Destroy;
begin
  FThread.Free;
  inherited;
end;

procedure TWorkManager.AddWork(var NewWorkData: TPARAMETERDATA; SISData:boolean;prio:boolean;blocking:boolean);
var
  WorkData: PPARAMETERDATA;
begin
  if SISData then
  begin
    if blocking then
    begin
      FThread.AddSISWorkBlocking(@NewWorkData);
    end
    else
    begin
      New(WorkData);
      WorkData^:=NewWorkData;
      if prio then
        FThread.AddSISWorkPrio(WorkData)
      else
        FThread.AddSISWork(WorkData);
    end;
  end
  else
  begin
    if blocking then
    begin
      FThread.AddASCIIWorkBlocking(@NewWorkData);
    end
    else
    begin
      New(WorkData);
      WorkData^:=NewWorkData;
      if prio then
        FThread.AddASCIIWorkPrio(WorkData)
      else
        FThread.AddASCIIWork(WorkData);
    end;
  end;
end;

procedure TWorkManager.SetWorkComplete(aValue:TNotifyEvent);
begin
  if (FWorkComplete<>aValue) then
  begin
    FWorkComplete:=aValue;
    FThread.OnWorkComplete := FWorkComplete;
  end;
end;

function TWorkManager.IsAllFinished: Boolean;
begin
  Result := FThread.IsAllFinished;
end;

end.

