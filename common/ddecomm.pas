unit ddecomm;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, Classes, SysUtils,
  {$ifdef LCL}
  Forms,
  LCLIntf,
  LCLType,
  LMessages,
  {$endif}
  CommBase;

type
  TDataConnection = record
    Name          : PChar;
    Handle        : HSZ;
    Data          : string;
    ErrorMessage  : string;
  end;

  TDDEConnection = record
    Ret                    : UINT;
    Inst                   : DWORD;
    ErrorNumber            : WORD;
    ErrorMessageString     : String;
    TopicCLCConnection     : TDataConnection;
    TopicSERVERConnection  : TDataConnection;
    TopicVMConnection      : TDataConnection;
    hCnvTopicCLC           : HCONV;
    hCnvTopicSERVER        : HCONV;
    hCnvTopicVM            : HCONV;
  end;
  PDDEConnection = ^TDDEConnection;

  TDDEComm = class;

  TDDECommReadThread=class(TThread)
  public
    Owner: TDDEComm;
  protected
    procedure CallEvent;
    procedure Execute; override;
  end;

  TDDEComm = class(TInterfacedObject,ICommInterface)
  strict private
    ServerStatusData     : TDataConnection;
    ServerDDEStatus      : TDataConnection;
    FConnectionAddress   : word;
    FAsync               : boolean;
    procedure StopReader;
    procedure StartReader;
  private
    FOwner:TComponent;
    FActive: boolean;
    FOnRxData: TNotifyEvent;
    ReadThread: TDDECommReadThread;
    FData:string;
    FCriticalSection: TRTLCriticalSection;
    FCommandList:TStringList;
    procedure DeviceOpen;
    procedure DeviceClose;
  protected
    DDEConnection        : PDDEConnection;
    FDDEThreadConnection : TDDEConnection;
    FDDENormalConnection : TDDEConnection;
    function  GetData:string;
    function  GetAsync: boolean;
    procedure SetAsync(value:boolean);
    function  GetOnRxData: TNotifyEvent;
    procedure SetOnRxData(event:TNotifyEvent);
    function  GetActive: boolean;
    procedure SetActive(state: boolean);
  public
    constructor Create(AOwner: TComponent);// override;
    destructor Destroy; override;

    procedure WriteString(const cmd: string; var dat: string);
    procedure WriteStringPrio(const cmd: string; var dat: string);
    procedure WriteStringBlocking(const cmd: string; var dat: string);

    function  StartDDE(aPath:string):boolean;
    function  ConnectDDE:boolean;
    function  GetTopicDataConnection(const Command:string):TDataConnection;
    procedure FreeTopic(var TopicData:TDataConnection);
    function  ProcessTopic(var TopicData:TDataConnection):boolean;
    procedure DDEServerStatus;
    procedure DDEStatus;
    procedure DDECleanUp;
  published
    property Active: boolean read FActive write SetActive;
    property Async: boolean read GetAsync write SetAsync;
    property ConnectionAddress: word read FConnectionAddress write FConnectionAddress;
    property OnRxData: TNotifyEvent read GetOnRxData write SetOnRxData;
    property Data: string read GetData;
  end;

const
  {$ifdef LCL}
  WM_DDEINFO = LM_USER + 2010;
  {$endif}

  APPCLASS_MONITOR     = $00000001;
  DMLERR_NO_ERROR      = 0;
  WM_DDE_ADVISE        = $03E2;
  WM_DDE_DATA          = $03E05;
  WM_DDE_ACK           = $03E4;
  WM_DDE_TERMINATE     = $03E1;
  DDE_FBUSY            = $4000;
  XTYP_MONITOR         = ($00F0 OR XCLASS_NOTIFICATION OR XTYPF_NOBLOCK);
  MF_POSTMSGS          = $04000000;

  DDETimeout = 1000;

  ServerStatusErrorTextName   : PChar = 'STATUS|ErrorText';
  ServerDDEStatusTextName     : PChar = 'DDE|Status';

implementation

procedure LogMessage(const aMsg: string);
var
  PInfo: PChar;
begin
  {$ifdef LCL}
  PInfo := StrAlloc(Length(aMsg)+16);
  StrPCopy(PInfo, aMsg);
  if (Assigned(Application) AND Assigned(Application.MainForm)) then
  begin
    if not PostMessage(Application.MainForm.Handle, WM_DDEINFO, 0, {%H-}LPARAM(PInfo)) then
      StrDispose(PInfo);
  end;
  {$endif}
end;

function GetDdeErrorCode(g_id: DWORD):word;
begin
  Result := DdeGetLastError(g_id);
end;

function GetDdeErrorMessage(DDEError: WORD):String;
begin
  Result:='Unknown error';
  case DDEError of
    DMLERR_ADVACKTIMEOUT: Result := 'Timeout on sync advise request';
    DMLERR_BUSY: Result := 'Server is busy';
    DMLERR_DATAACKTIMEOUT: Result := 'Timeout on sync data request';
    DMLERR_DLL_NOT_INITIALIZED: Result := 'DDEML not initialised';
    DMLERR_DLL_USAGE: Result := 'Invalid request';
    DMLERR_EXECACKTIMEOUT: Result := 'Timeout on sync exec request';
    DMLERR_INVALIDPARAMETER: Result := 'Invalid parameter in request';
    DMLERR_LOW_MEMORY: Result := 'Server ran out of buffer memory';
    DMLERR_MEMORY_ERROR: Result := 'Memory allocation error';
    DMLERR_NO_CONV_ESTABLISHED: Result := 'No conversation established';
    DMLERR_NOTPROCESSED: Result := 'Request not processed by server';
    DMLERR_POKEACKTIMEOUT: Result := 'Timeout on sync poke request';
    DMLERR_POSTMSG_FAILED: Result := 'PostMessage failed';
    DMLERR_REENTRANCY: Result := 'Sync request already in progress';
    DMLERR_SERVER_DIED: Result := 'Server died';
    DMLERR_SYS_ERROR: Result := 'DDEML Internal error';
    DMLERR_UNADVACKTIMEOUT: Result := 'Timeout on unadvise request';
    DMLERR_UNFOUND_QUEUE_ID: Result := 'Invalid transaction ID';
  end;
end;

function TDDEComm.GetTopicDataConnection(const Command:string):TDataConnection;
begin
  Result:=Default(TDataConnection);
  if ((DDEConnection^.Inst<>0){ AND (DDEConnection^.hCnvTopicVM<>0)}) then  // create DDE topic handle
  begin
    Result.Name:=StrAlloc(Length(Command) + 1);
    StrPCopy(Result.Name,Command);
    Result.Handle:=DdeCreateStringHandle(DDEConnection^.Inst, Result.Name, CP_WINANSI);
  end;
end;

procedure TDDEComm.FreeTopic(var TopicData:TDataConnection);
begin
  if ((DDEConnection^.Inst<>0) AND (TopicData.Handle<>0)) then DdeFreeStringHandle(DDEConnection^.Inst, TopicData.Handle);
  if (TopicData.Name<>nil) then
  begin
    StrDispose(TopicData.Name);
    TopicData.Name:=nil;
  end;
end;

function TDDEComm.ProcessTopic(var TopicData:TDataConnection):boolean;
var
  TransactionHandle    : HDDEDATA;
  DataHandle           : HDDEData;
  DataValue            : pchar;
  DataResult           : pbyte;
  DataSize             : dword;
  DataLength           : integer;
  Success              : boolean;
  SendData             : boolean;
begin
  result:=false;

  if ((DDEConnection^.Inst<>0) AND (DDEConnection^.hCnvTopicVM<>0) AND (TopicData.Handle<>0)) then
  begin
    Success:=True;
    SendData:=(Length(TopicData.Data)>0);

    if SendData then
    begin
      if Success then // create DDE data
      begin
        GetMem(DataValue,100);
        StrPCopy(DataValue,TopicData.Data);
        DataLength:=strlen(DataValue)+1;
        DataHandle := DdeCreateDataHandle(DDEConnection^.Inst, PBYTE(DataValue), DataLength, 0, TopicData.Handle, CP_WINANSI, 0);
        Freemem(DataValue,100);
        Success:=(DataHandle<>0);
      end;
    end;

    if Success then // send data if any
    begin
      if SendData then
        TransactionHandle := DdeClientTransaction({%H-}PBYTE(DataHandle), $FFFFFFFF, DDEConnection^.hCnvTopicVM, TopicData.Handle, CF_TEXT, XTYP_POKE, DDETimeout, nil)
      else
        TransactionHandle := DdeClientTransaction(nil, 0, DDEConnection^.hCnvTopicVM, TopicData.Handle, CF_TEXT, XTYP_REQUEST, DDETimeout, nil);
      Success:=(TransactionHandle<>0);
    end;

    if (Success AND (NOT SendData)) then // get data if any
    begin
      DataResult:=DdeAccessData(TransactionHandle,@DataSize);
      Success:=(DataResult<>nil);
      if (Success) then
      begin
        TopicData.Data:=StrPas(PChar(DataResult));
      end;
    end;

    if (NOT Success) then
    begin
      DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
      TopicData.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
    end;

    DdeUnaccessData(TransactionHandle);
    DdeFreeDataHandle(TransactionHandle);

    if (SendData AND (DataHandle<>0)) then DdeFreeDataHandle(DataHandle);
  end;

  result:=Success;
end;

function TDDEComm.StartDDE(aPath:string):boolean;
const
  DEFAULTPATH = 'C:\Indramat\VisualMotion8\clc_dde.exe';
var
  Res:HINST;
  FilePath:string;
begin
  result:=false;
  FilePath:=aPath;
  Res:=ERROR_FILE_NOT_FOUND;

  if (Length(FilePath)>0) then
  begin
    if ((Res=ERROR_FILE_NOT_FOUND) AND FileExists(FilePath)) then
    begin
      FilePath:=FilePath+#0;
      Res:=ShellExecute(0, nil, @FilePath[1], nil, nil, SW_SHOWNORMAL);
    end;
  end
  else
  begin
    Res:=ShellExecute(0, nil, PChar('clc_dde.exe'), nil, nil, SW_SHOWNORMAL);
    if ((Res=ERROR_FILE_NOT_FOUND) AND FileExists(DEFAULTPATH)) then
    begin
      Res:=ShellExecute(0, nil, PChar(DEFAULTPATH), nil, nil, SW_SHOWNORMAL);
    end;
  end;
  if (Res=ERROR_FILE_NOT_FOUND) then
  begin
    LogMessage('Error. DDE server not found (clc_dde.exe)');
  end;
  result:=(Res>32);
end;

Function DDECallback(CallType, Fmt: UINT; Conv: HConv; hsz1, hsz2: HSZ;
    Data: HDDEData; Data1, Data2: DWORD): HDDEData; stdcall;
var
  DDECallbackMessage : string;
  s1,s2              : string;
  buf                : array [0..255] of char;
  pData              : PBYTE;
  Len                : DWORD;
begin
  Result := 0;
  DDECallbackMessage:='';
  s1:='';
  s2:='';

  if (hsz1<>0) then
  begin
    //FillChar({%H-}buf,sizeof(buf),0);
    //DdeQueryString(DDEConnection.Inst, hsz1, buf, sizeof(buf), CP_WINANSI);
    //s1 := string(buf);
  end;
  if (hsz2<>0) then
  begin
    //FillChar({%H-}buf,sizeof(buf),0);
    //DdeQueryString(DDEConnection.Inst, hsz2, buf, sizeof(buf), CP_WINANSI);
    //s2 := string(buf);
  end;

  case CallType of
    xtyp_Register:
      begin
        DDECallbackMessage:='xtyp_Register';
        //DDEConnection.hCnvTopicSERVER:=DdeReconnect(DDEConnection.hCnvTopicSERVER);
        //DDEConnection.hCnvTopicVM:=DdeReconnect(DDEConnection.hCnvTopicVM);
        Result:=HDDEDATA(-1);
      end;
    xtyp_Unregister:
      begin
        DDECallbackMessage:='xtyp_Unregister';
        //DDEConnection.Inst:=0;
        //DDEConnection.hCnvTopicSERVER:=0;
        //DDEConnection.hCnvTopicVM:=0;
        Result:=HDDEDATA(-1);
      end;
    xtyp_xAct_Complete:
      begin
        DDECallbackMessage:='xtyp_xAct_Complete';
      end;
    xtyp_Request, Xtyp_AdvData:
      begin
        ////Form1.Request(Conv);
        Result := dde_FAck;
        DDECallbackMessage:='Xtyp_AdvData';
      end;
    xtyp_Disconnect:
      begin
        DDECallbackMessage:='xtyp_Disconnect';
        //DDEConnection.hCnvTopicSERVER:=DdeReconnect(DDEConnection.hCnvTopicSERVER);
        //DDEConnection.hCnvTopicVM:=DdeReconnect(DDEConnection.hCnvTopicVM);
        Result:=HDDEDATA(-1);
      end;
    XTYP_ERROR:
      begin
        DDECallbackMessage:='XTYP_ERROR';
        Result:=HDDEDATA(-1);
      end;
    XTYP_EXECUTE:
      begin
        DDECallbackMessage:='XTYP_EXECUTE';
      end;
    XTYPF_NOBLOCK:
      begin
        DDECallbackMessage:='XTYPF_NOBLOCK';
        Result:=HDDEDATA(-1);
      end;
    XTYP_CONNECT, XTYP_CONNECT_CONFIRM:
      begin
        DDECallbackMessage:='XTYP_CONNECT, XTYP_CONNECT_CONFIRM';
      end;
    XTYP_ADVREQ:
      begin
        DDECallbackMessage:='XTYP_ADVREQ';
      end;
    xtyp_Poke:
      begin
        DDECallbackMessage:='xtyp_Poke';
      end;
    xtyp_AdvStart:
      begin
        DDECallbackMessage:='xtyp_AdvStart';
      end;
    xtyp_AdvStop:
      begin
        DDECallbackMessage:='xtyp_AdvStop';
      end;
    DMLERR_SERVER_DIED:
      begin
        DDECallbackMessage:='DMLERR_SERVER_DIED';
      end;
    DMLERR_SYS_ERROR:
      begin
        DDECallbackMessage:='DMLERR_SYS_ERROR';
      end;
    DMLERR_BUSY:
      begin
        DDECallbackMessage:='DMLERR_BUSY';
      end;
    DMLERR_DATAACKTIMEOUT:
      begin
        DDECallbackMessage:='DMLERR_DATAACKTIMEOUT';
      end;
    DMLERR_ADVACKTIMEOUT:
      begin
        DDECallbackMessage:='DMLERR_ADVACKTIMEOUT';
      end;
    XTYP_MONITOR :
      begin
        DDECallbackMessage:='XTYP_MONITOR ';
        pData:=DdeAccessData(Data, @Len);
        if (pData<>nil) then
        begin
          // If data is a posted message
          if (Data2=MF_POSTMSGS) then
          begin
            try
              // Check if the message was an acknowledge message
              if (PMonMsgStruct(pData)^.wMsg=WM_DDE_ACK) then
              begin
                LogMessage('prcDDE.DDECallBack: TMonMsgStruct(pData^).wMsg = WM_DDE_ACK');
                LogMessage('prcDDE.DDECallBack: Acknowledge message');
                // Detect only the acknowledge messages with no busy flag
                if ((PMonMsgStruct(pData)^.dmhd.uilo and DDE_FACK)=DDE_FACK) and
                   ((PMonMsgStruct(pData)^.dmhd.uilo and DDE_FBUSY)=0) then
                begin
                  // The DDE command has terminated
                  LogMessage('prcDDE.DDECallback: ((TMonMsgStruct(pData^).dmhd.uilo and DDE_FACK) = DDE_FACK) and ((TMonMsgStruct(pData^).dmhd.uilo and DDE_FBUSY) = 0)');
                  LogMessage('prcDDE.DDECallback: Acknowledge with BUSY Flag = 0');
                  LogMessage('prcDDE.DDECallback: ApplData.WaitStat := False');
                end
                else
                begin
                  LogMessage('prcDDE.DDECallback: Acknowledge with BUSY Flag <> 0')
                end;
              end;
              if (PMonMsgStruct(pData)^.wMsg=WM_DDE_TERMINATE) then
              begin
                // Check if in close
                LogMessage('prcDDE.DDECallBack:TMonMsgStruct(pData^).wMsg = WM_DDE_TERMINATE');
                LogMessage('prcDDE.DDECallBack: DDE_terminate message');
              end;
            finally
              // Free the accessed data
              DdeUnaccessData(Data);
            end;
          end
          else
          begin
            LogMessage('Data is no posted message');
          end;
        end
        else
        begin
          LogMessage('No data received with DdeAccessData');
        end;
      end;

  end; // end case

  if (Length(s1)>0) then DDECallbackMessage:=DDECallbackMessage+'. '+s1;
  if (Length(s2)>0) then DDECallbackMessage:=DDECallbackMessage+'. '+s2;
  if (Length(DDECallbackMessage)>0) then
  begin
    DDECallbackMessage:=DDECallbackMessage+'.';
    LogMessage(DDECallbackMessage);
  end;

end;

function TDDEComm.ConnectDDE:boolean;
const
  MAXCOUNT=10;
var
  ConnCount:integer;
  Success:boolean;
begin
  result:=false;

  DDEConnection^:=Default(TDDEConnection);

  //CallBackPtr := MakeProcInstance(DdeCallback, HInstance);

  DDEConnection^.Ret:=DdeInitialize(@DDEConnection^.Inst, @DdeCallback, APPCLASS_MONITOR{ APPCLASS_STANDARD}, 0);

  Success:=((DDEConnection^.Ret=DMLERR_NO_ERROR) AND (DDEConnection^.Inst<>0));

  if (NOT Success) then
  begin
    DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
    DDEConnection^.ErrorMessageString := GetDdeErrorMessage(DDEConnection^.ErrorNumber);
    LogMessage('Error: DdeInitialize -' +DDEConnection^.ErrorMessageString);
  end
  else
  begin
    LogMessage('DDE initialize ok');
  end;

  if (Success) then
  begin
    DDEConnection^.TopicCLCConnection:=GetTopicDataConnection('CLC_DDE');
    Success:=(DDEConnection^.TopicCLCConnection.Handle<>0);
    if (NOT Success) then
    begin
      DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
      DDEConnection^.TopicCLCConnection.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
      LogMessage('Error: DdeCreateStringHandle TopicCLC -'+DDEConnection^.TopicCLCConnection.ErrorMessage);
    end;
  end;

  if (Success) then
  begin
    // Create SERVER string handle
    DDEConnection^.TopicSERVERConnection := GetTopicDataConnection('SERVER');
    Success:=(DDEConnection^.TopicSERVERConnection.Handle<>0);
    if (NOT Success) then
    begin
      DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
      DDEConnection^.TopicSERVERConnection.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
      LogMessage('Error: DdeCreateStringHandle TopicSERVER -'+DDEConnection^.TopicSERVERConnection.ErrorMessage);
    end;
  end;

  if (Success) then
  begin
    // Connect with SERVER topic
    for ConnCount:=0 to MAXCOUNT do
    begin
      DDEConnection^.hCnvTopicSERVER := DdeConnect(DDEConnection^.Inst, DDEConnection^.TopicCLCConnection.Handle, DDEConnection^.TopicSERVERConnection.Handle, nil);
      Success:=(DDEConnection^.hCnvTopicSERVER<>0);
      if (NOT Success) then
      begin
        DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
        DDEConnection^.TopicSERVERConnection.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
        LogMessage('Error. SERVER-topic. '+DDEConnection^.TopicSERVERConnection.ErrorMessage);
        if (DDEConnection^.ErrorNumber=DMLERR_NO_CONV_ESTABLISHED) then
        begin
          LogMessage('Dde connection error. Starting CLC DDE server.');
          StartDDE('');
          //StartDDE(editDLLFileName.Text);
          {$ifdef LCL}
          //StartDDE(Application.Location+'clc_dde.exe');
          {$endif}
          //Sleep(100);
          //Application.ProcessMessages;
        end;
      end
      else
      begin
        LogMessage('Dde connection with SERVER-topic ok');
        break;
      end;
    end;
  end;

  if (Success) then
  begin
    // Create VM string handle
    //DDEConnection^.TopicVMConnection:=GetTopicDataConnection('DEMO_'+chr(48+ConnectionAddress));
    DDEConnection^.TopicVMConnection:=GetTopicDataConnection('SERIAL_'+chr(48+ConnectionAddress));
    Success:=(DDEConnection^.TopicVMConnection.Handle<>0);
    if (NOT Success) then
    begin
      DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
      DDEConnection^.TopicVMConnection.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
      LogMessage('Error: DdeCreateStringHandle TopicVM -'+DDEConnection^.TopicVMConnection.ErrorMessage);
    end;
  end;

  if (Success) then
  begin
    // Connect with VM topic
    for ConnCount:=0 to MAXCOUNT do
    begin
      DDEConnection^.hCnvTopicVM := DdeConnect(DDEConnection^.Inst, DDEConnection^.TopicCLCConnection.Handle, DDEConnection^.TopicVMConnection.Handle, nil);
      Success:=(DDEConnection^.hCnvTopicVM<>0);
      if (NOT Success) then
      begin
        DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
        DDEConnection^.TopicVMConnection.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
        LogMessage('Error. VM-topic. '+DDEConnection^.TopicVMConnection.ErrorMessage);
        if (DDEConnection^.ErrorNumber=DMLERR_NO_CONV_ESTABLISHED) then
        begin
          Sleep(100);
        end;
      end
      else
      begin
        LogMessage('Dde connection with VM-topic ok');
        break;
      end;
    end;
  end;

  result:=Success;
end;

procedure TDDEComm.DDEServerStatus;
var
  DataHandle  : HDDEDATA;
  DataResult  : PBYTE;
  DataSize    : DWORD;
begin
  begin
    if (DDEConnection^.hCnvTopicSERVER <> 0) then
    begin
      DataHandle:=DdeClientTransaction(nil, 0, DDEConnection^.hCnvTopicSERVER, ServerStatusData.Handle, CF_TEXT, XTYP_REQUEST, DDETimeout, nil);
      if (DataHandle<>0) then
      begin
        DataResult:=DdeAccessData(DataHandle,@DataSize);
      end;
      if ((DataHandle<>0) AND (DataResult<>nil)) then
      begin
        if (DataSize>0) then LogMessage(StrPas(PChar(DataResult)));
      end
      else
      begin
        DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
        ServerStatusData.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
        LogMessage('Error: ServerStatus -'+ServerStatusData.ErrorMessage);
      end;
      DdeUnaccessData(DataHandle);
      DdeFreeDataHandle(DataHandle);
    end;
  end;
end;

procedure TDDEComm.DDEStatus;
var
  DataHandle  : HDDEDATA;
  DataResult  : PBYTE;
  DataSize    : DWORD;
begin
  begin
    if (DDEConnection^.hCnvTopicSERVER <> 0) then
    begin
      DataHandle:=DdeClientTransaction(nil, 0, DDEConnection^.hCnvTopicSERVER, ServerDDEStatus.Handle, CF_TEXT, XTYP_REQUEST, DDETimeout, nil);
      if (DataHandle<>0) then
      begin
        DataResult:=DdeAccessData(DataHandle,@DataSize);
        DdeUnaccessData(DataHandle);
      end;
      if ((DataHandle<>0) AND (DataResult<>nil)) then
      begin
        if (DataSize>0) then LogMessage(StrPas(PChar(DataResult)));
      end
      else
      begin
        DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
        ServerDDEStatus.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
        LogMessage('Error: ServerDDEStatus -'+ServerDDEStatus.ErrorMessage);
      end;
      DdeUnaccessData(DataHandle);
      DdeFreeDataHandle(DataHandle);
    end;
  end;
end;

procedure TDDEComm.DDECleanUp;
begin
  //if (@DdeCallback<>nil) then FreeProcInstance(@DdeCallback);

  if (DDEConnection^.Inst<>0) then
  begin
    FreeTopic(ServerStatusData);
    FreeTopic(ServerDDEStatus);

    if (DDEConnection^.hCnvTopicSERVER<>0) then DdeDisconnect(DDEConnection^.hCnvTopicSERVER);
    if (DDEConnection^.hCnvTopicVM<>0) then DdeDisconnect(DDEConnection^.hCnvTopicVM);

    FreeTopic(DDEConnection^.TopicSERVERConnection);
    FreeTopic(DDEConnection^.TopicVMConnection);
    FreeTopic(DDEConnection^.TopicCLCConnection);

    DdeUninitialize(DDEConnection^.Inst);
  end;
end;

procedure TDDEComm.StartReader;
begin
  // Launch Thread
  if (NOT FAsync) then exit;
  if (ReadThread=nil) then
  begin
    ReadThread := TDDECommReadThread.Create(true);
    ReadThread.Owner := Self;
    ReadThread.Start;
  end;
end;

procedure TDDEComm.StopReader;
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

constructor TDDEComm.Create(AOwner: TComponent);
begin
  FOwner:=AOwner;
  FAsync:=true;
  InitCriticalSection(FCriticalSection);
  FCommandList:=TStringList.Create;
  ReadThread:=nil;
  FConnectionAddress:=1;
end;

destructor TDDEComm.Destroy;
begin
  FCommandList.Free;
  DoneCriticalsection(FCriticalSection);
  inherited;
end;

procedure TDDEComm.DeviceOpen;
var
  Success:boolean;
begin
  DDEConnection:=@FDDENormalConnection;
  Success:=ConnectDDE;
  if (Success) then
  begin
    if (DDEConnection^.hCnvTopicSERVER<>0) then
    begin
      ServerStatusData:=GetTopicDataConnection(ServerStatusErrorTextName);
      if (ServerStatusData.Handle=0) then
      begin
        DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
        ServerStatusData.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
        LogMessage('Error: ServerStatus -'+ServerStatusData.ErrorMessage);
      end;

      ServerDDEStatus:=GetTopicDataConnection(ServerDDEStatusTextName);
      if (ServerDDEStatus.Handle=0) then
      begin
        DDEConnection^.ErrorNumber:=GetDdeErrorCode(DDEConnection^.Inst);
        ServerDDEStatus.ErrorMessage:=GetDdeErrorMessage(DDEConnection^.ErrorNumber);
        LogMessage('Error: ServerDDEStatus -'+ServerDDEStatus.ErrorMessage);
      end;
    end;
  end;
  StartReader;
end;

procedure TDDEComm.DeviceClose;
begin
  StopReader;
  DDEConnection:=@FDDENormalConnection;
  DDECleanUp;
end;

function TDDEComm.GetData:string;
begin
  result:=FData;
end;

function TDDEComm.GetAsync: boolean;
begin
  result:=FAsync;
end;

procedure TDDEComm.SetAsync(value:boolean);
begin
  if (value=FAsync) then exit;
  FAsync:=value;
end;

function TDDEComm.GetOnRxData: TNotifyEvent;
begin
  result:=FOnRxData;
end;

procedure TDDEComm.SetOnRxData(event:TNotifyEvent);
begin
  if (event=FOnRxData) then exit;
  FOnRxData:=event;
end;

function TDDEComm.GetActive: boolean;
begin
  result:=FActive;
end;

procedure TDDEComm.SetActive(state: boolean);
begin
  if (state=FActive) then exit;
  try
    if state then
      DeviceOpen
    else
      DeviceClose;
    FActive:=state;
  except
    FActive:=false;
  end;
end;

procedure TDDEComm.WriteString(const cmd: string; var dat: string);
begin
  if Assigned(ReadThread) then
  begin
    EnterCriticalSection(FCriticalSection);
    try
      FCommandList.Append(Concat(cmd, FCommandList.NameValueSeparator, dat));
    finally
      LeaveCriticalSection(FCriticalSection);
    end;
  end
  else
  begin
    WriteStringBlocking(cmd,dat);
    if Assigned(FOnRxData) then FOnRxData(FOwner);
  end;
end;

procedure TDDEComm.WriteStringPrio(const cmd: string; var dat: string);
begin
  if Assigned(ReadThread) then
  begin
    EnterCriticalSection(FCriticalSection);
    try
      FCommandList.Insert(0,Concat(cmd, FCommandList.NameValueSeparator, dat));
    finally
      LeaveCriticalSection(FCriticalSection);
    end;
  end
  else
  begin
    WriteStringBlocking(cmd,dat);
    if Assigned(FOnRxData) then FOnRxData(FOwner);
  end;
end;

procedure TDDEComm.WriteStringBlocking(const cmd: string; var dat: string);
var
  rcvd : string;
  DC:TDataConnection;
  re   : boolean;
begin
  re:=Assigned(ReadThread);
  try
    if re then
    begin
      EnterCriticalSection(FCriticalSection);
      ReadThread.Suspended:=True;
    end;
    DDEConnection:=@FDDENormalConnection;
    DC:=GetTopicDataConnection(cmd);
    if (DC.Handle<>0) then
    begin
      DC.Data:=dat;
      ProcessTopic(DC);
      // Simulate as if data is coming from RS22 by adding start character and network address
      rcvd:='>'+Chr(48+ConnectionAddress)+' '+cmd;
      if (Length(DC.Data)>0) then rcvd:=rcvd+' '+DC.Data;
      dat:=rcvd;
      FData:=rcvd;
      FreeTopic(DC);
      //if Assigned(FOnRxData) then FOnRxData(FOwner);
    end;
  finally
    if re then
    begin
      ReadThread.Suspended:=False;
      LeaveCriticalSection(FCriticalSection);
    end;
  end;
end;


procedure TDDECommReadThread.CallEvent;
begin
  if Assigned(Owner.FOnRxData) then begin
    Owner.FOnRxData(Owner);
  end;
end;

procedure TDDECommReadThread.Execute;
var
  DC:TDataConnection;
  da:boolean;
  c,s:string;
begin
  Owner.DDEConnection:=@Owner.FDDEThreadConnection;
  Owner.ConnectDDE;

  while (NOT Terminated) do
  begin
    da:=false;
    EnterCriticalSection(Owner.FCriticalSection);
    try
      Owner.DDEConnection:=@Owner.FDDEThreadConnection;
      if (Owner.FCommandList.Count>0) then
      begin
        c:=Owner.FCommandList.Names[0];
        s:=Owner.FCommandList.ValueFromIndex[0];
        DC:=Owner.GetTopicDataConnection(c);
        if (DC.Handle<>0) then
        begin
          DC.Data:=s;
          Owner.ProcessTopic(DC);
          // Simulate as if data is coming from RS22 by adding start character and network address
          s:='>'+Chr(48+Owner.ConnectionAddress)+' '+c;
          if (Length(DC.Data)>0) then s:=s+' '+DC.Data;
          Owner.FData:=s;
          Owner.FreeTopic(DC);
          da:=true;
        end;
        Owner.FCommandList.Delete(0);
      end;
    finally
      LeaveCriticalSection(Owner.FCriticalSection);
    end;

    if da then Synchronize(@CallEvent);

    TThread.Yield();
    // Sleep a bit to give other processes some time
    TThread.Sleep(1);
  end;

  Owner.DDEConnection:=@Owner.FDDEThreadConnection;
  Owner.DDECleanUp;
end;

end.

