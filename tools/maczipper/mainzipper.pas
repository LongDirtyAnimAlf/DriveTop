unit MainZipper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Label1: TLabel;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

uses
  Zipper,
  FileUtil; //from Lazarus, for CopyFile

{ TForm1 }

const
  BaseDirList: array[0..0] of string = ('.\..\..\..\buildbins');
  BaseName='drivetop-';
  FileList:array[0..2] of string = (BaseName+'x86_64-darwin-cocoa',BaseName+'x86_64-darwin-cocoa-legacy',BaseName+'x86_64-darwin-qt5');

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  zipper:TZipper;
  aFile1,aFile2,aFile3,aBaseDir:string;
  aIndex0,aIndex1,aIndex2:integer;
  aZipList:TStringList;
  aZipFileEntry:TZipFileEntry;
begin
  Label1.Caption:='Processing';
  for aIndex0:=Low(BaseDirList) to High(BaseDirList) do
  begin
    for aIndex1:=Low(FileList) to High(FileList) do
    begin
      aBaseDir:=ExpandFileName(BaseDirList[aIndex0]);
      aFile1:=aBaseDir+DirectorySeparator+FileList[aIndex1];
      aFile2:=aFile1+'.app'+DirectorySeparator+'Contents'+DirectorySeparator+'MacOS'+DirectorySeparator+FileList[aIndex1];
      Memo1.Lines.Append(ExtractFileName(aFile2)+' ... please wait.');
      Application.ProcessMessages;
      if FileExists(aFile2) then
      begin
        DeleteFile(aFile2);
      end;
      aFile2:=aFile1+'.zip';
      if FileExists(aFile2) then
      begin
        DeleteFile(aFile2);
      end;
      aFile2:=aFile1+'.app'+DirectorySeparator+'Contents'+DirectorySeparator+'MacOS'+DirectorySeparator+FileList[aIndex1];
      if FileExists(aFile1) then
      begin
        FileUtil.CopyFile(aFile1,aFile2);
        aZipList:=FindAllFiles(aFile1+'.app');
        try
          if (aZipList.Count > 0) then
          begin
            zipper:=TZipper.Create;
            try
              zipper.FileName:=aFile1+'.zip';
              for aIndex2:=0 to Pred(aZipList.Count) do
              begin
                aFile3:=ExtractRelativepath(aFile1+'.app',aZipList.Strings[aIndex2]);
                aZipFileEntry:=zipper.Entries.AddFileEntry(aZipList.Strings[aIndex2],aFile3);
                aZipFileEntry.OS:=OS_UNIX;
                aZipFileEntry.Attributes:=0;
                if aZipList.Strings[aIndex2]=aFile2 then
                   aZipFileEntry.Attributes:=((UNIX_FILE or UNIX_RUSR or UNIX_WUSR or UNIX_XUSR or UNIX_RGRP or UNIX_XGRP or UNIX_ROTH or UNIX_XOTH) shl 16)
                else
                  aZipFileEntry.Attributes:=((UNIX_FILE or UNIX_RUSR or UNIX_WUSR or UNIX_RGRP or UNIX_ROTH) shl 16);
              end;
              zipper.ZipAllFiles;
              zipper.Terminate;
            finally
              zipper.Destroy;
            end;
          end
        finally
          aZipList.Free;
        end;
        DeleteFile(aFile1);
      end;
    end;
  end;
  Label1.Caption:='Ready';
end;

end.

end.

