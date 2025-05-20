unit CommBase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  ICommInterface = interface
    ['{D1D547B8-E241-43ED-96F6-D21E37772D6E}']
    function  GetData:string;
    function  GetAsync: boolean;
    procedure SetAsync(value:boolean);
    //function  GetRTSToggle: boolean;
    //procedure SetRTSToggle(value:boolean);
    function  GetActive: boolean;
    procedure SetActive(state: boolean);
    function  GetOnRxData: TNotifyEvent;
    procedure SetOnRxData(event:TNotifyEvent);
    procedure WriteString(const cmd: string; var dat: string);
    procedure WriteStringPrio(const cmd: string; var dat: string);
    procedure WriteStringBlocking(const cmd: string; var dat: string);
    property  Data: string read GetData;
    property  Active: boolean read GetActive write SetActive;
    property  Async: boolean read GetAsync write SetAsync;
    //property  RTSToggle: boolean read GetRTSToggle write SetRTSToggle;
    property  OnRxData: TNotifyEvent read GetOnRxData write SetOnRxData;
  end;

implementation

end.

