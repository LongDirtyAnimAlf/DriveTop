unit commworker;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs,
  serialcomm,
  common, drive, sis;

type
  // Worker thread with queue
  TWorkerThread = class(TThread)
  private
    FQueue: TList;
    FLock: TCriticalSection;
    FEvent: TEvent;
    FOnWorkComplete: TNotifyEvent;
    FCurrentWorkData: PPARAMETERDATA;
    FIsProcessing: Boolean;
    procedure ProcessWork(AData: PPARAMETERDATA);
  protected
    procedure Execute; override;
    procedure NotifyComplete;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddWork(AData: PPARAMETERDATA);
    procedure AddWorkPrio(AData: PPARAMETERDATA);
    procedure AddWorkBlocking(AData: PPARAMETERDATA);
    function IsAllFinished: Boolean;
    property CurrentWorkData: PPARAMETERDATA read FCurrentWorkData;
    property OnWorkComplete: TNotifyEvent read FOnWorkComplete write FOnWorkComplete;
  end;

  TWorkManager = class
  private
    FWorkComplete: TNotifyEvent;
    FThread: TWorkerThread;
    procedure SetWorkComplete(aValue:TNotifyEvent);
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddWork(var NewWorkData: TPARAMETERDATA; prio:boolean=false;blocking:boolean=false);
    function IsAllFinished: Boolean;
    property WorkComplete: TNotifyEvent read FWorkComplete write SetWorkComplete;
  end;

implementation

constructor TWorkerThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FQueue := TList.Create;
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
    for i := 0 to FQueue.Count - 1 do
      Dispose(PPARAMETERDATA(FQueue[i]));
    FQueue.Free;
  finally
    FLock.Release;
  end;

  FLock.Free;
  FEvent.Free;
  inherited;
end;

procedure TWorkerThread.AddWork(AData: PPARAMETERDATA);
begin
  FLock.Acquire;
  try
    FQueue.Add(AData);
    FEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TWorkerThread.AddWorkPrio(AData: PPARAMETERDATA);
begin
  FLock.Acquire;
  try
    FQueue.Insert(0,AData);
    FEvent.SetEvent;
  finally
    FLock.Release;
  end;
end;

procedure TWorkerThread.AddWorkBlocking(AData: PPARAMETERDATA);
begin
  FLock.Acquire;
  try
    ProcessWork(AData);
  finally
    FLock.Release;
  end;
end;

procedure TWorkerThread.ProcessWork(AData: PPARAMETERDATA);
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
begin
  while (NOT Terminated) do
  begin
    WaitResult:=FEvent.WaitFor(INFINITE);

    if ((WaitResult=wrSignaled) AND (NOT Terminated)) then
    begin
      FLock.Acquire;
      try
        if FQueue.Count > 0 then
        begin
          WorkItem := PPARAMETERDATA(FQueue[0]);
          FQueue.Delete(0);
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
        ProcessWork(WorkItem);
        FCurrentWorkData := WorkItem;
        Synchronize(@NotifyComplete);
        FCurrentWorkData := nil;
        FLock.Acquire;
        try
          if (FQueue.Count>0) then
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
    Result := (FQueue.Count = 0) and not FIsProcessing;
  finally
    FLock.Release;
  end;
end;

constructor TWorkManager.Create;
begin
  FThread := TWorkerThread.Create;
  FThread.Start;
end;

destructor TWorkManager.Destroy;
begin
  FThread.Free;
  inherited;
end;

procedure TWorkManager.AddWork(var NewWorkData: TPARAMETERDATA; prio:boolean;blocking:boolean);
var
  WorkData: PPARAMETERDATA;
begin
  if blocking then
  begin
    FThread.AddWorkBlocking(@NewWorkData);
  end
  else
  begin
    New(WorkData);
    WorkData^:=NewWorkData;
    if prio then
      FThread.AddWorkPrio(WorkData)
    else
      FThread.AddWork(WorkData);
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

