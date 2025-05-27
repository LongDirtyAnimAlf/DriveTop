unit CommBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  ICommInterface = interface
    ['{D1D547B8-E241-43ED-96F6-D21E37772D6E}']
    function  GetData:RawByteString;
    function  GetAsync: boolean;
    procedure SetAsync(value:boolean);
    function  GetActive: boolean;
    procedure SetActive(state: boolean);
    function  GetOnRxData: TNotifyEvent;
    procedure SetOnRxData(event:TNotifyEvent);
    procedure WriteString(const cmd: RawByteString; var dat: RawByteString);
    procedure WriteStringPrio(const cmd: RawByteString; var dat: RawByteString);
    procedure WriteStringBlocking(const cmd: RawByteString; var dat: RawByteString);
    property  Data: RawByteString read GetData;
    property  Active: boolean read GetActive write SetActive;
    property  Async: boolean read GetAsync write SetAsync;
    property  OnRxData: TNotifyEvent read GetOnRxData write SetOnRxData;
  end;

implementation

end.

