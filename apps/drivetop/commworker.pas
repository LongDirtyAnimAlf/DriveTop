unit commworker;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs,
  serialcomm,
  common, drive, sis;

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
  slavelength            : Integer;
  masterlength           : Integer;
  i,index                : Integer;
begin
  if Assigned(FOwner.FComms) then
  begin
    FillChar({%H-}SISSendData,SizeOf(SISSendData),0);
    BuildSISTelegram(AData^,SISSendData,masterlength);
    AData^.DATA:='';
    repeat
      DataReady:=true;
      if (FOwner.FComms.SendSIS(@SISSendData,masterlength)=masterlength) then
      begin
        FillChar({%H-}SISRetrieveHeader,SizeOf(SISRetrieveHeader),0);
        if FOwner.FComms.RetrieveSISHeader(@SISRetrieveHeader) then
        begin
          // Only length for now
          // Might also parse errors and more !
          slavelength:=ParseSISHeaderUserDataLength(SISRetrieveHeader);
          if (slavelength>0) then
          begin
            FillChar({%H-}SISRetrieveUserData,SizeOf(SISRetrieveUserData),0);
            if (FOwner.FComms.RetrieveSISUserData(@SISRetrieveUserData,slavelength)=slavelength) then
            begin
              DataReady:=ParseSISUserDataReady(SISRetrieveUserData);
              // Skip userdata header
              if (slavelength>3) then
              begin
                Dec(slavelength,3);
                index:=Length(AData^.DATA)+1;
                SetLength(AData^.DATA,Length(AData^.DATA)+slavelength);
                // Add userdata
                for i:=1 to slavelength do
                begin
                  AData^.DATA[index]:=Chr(SISRetrieveUserData[i+3]);
                  Inc(index);
                end;
              end;
            end;
          end;
        end;
      end;
    until DataReady;
  end
  else
  begin
    // Do the actual work here
    Sleep(1500); // Simulate processing time
    AData^.DATA := 'No connection available';
    AData^.ERROR := 'No connection available';
  end;
end;

procedure TWorkerThread.ProcessASCIIWork(AData: PPARAMETERDATA);
begin
  // Do the actual work here
  Sleep(1500); // Simulate processing time

  AData^.DATA := AData^.DATA + 'done !!';
  AData^.ERROR := 'Processed: ' + InttoStr(AData^.NUMID);
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
            Sleep(1); // don't flood
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

