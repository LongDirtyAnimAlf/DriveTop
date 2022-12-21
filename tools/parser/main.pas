unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Memo2: TMemo;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

uses
  StrUtils, IniFiles;

type
  TVMCOMMANDCLASS                   = (ccAxis,ccControl,ccDrive,ccDriveSpecific,ccTask,ccFloat,ccGlobalFloat,ccGlobalInteger,ccInteger,ccPID,ccAbsPointTable,ccRelPointTable,ccEventTable,ccProgram,ccELS,ccFunction,ccRegister,ccSequencerList,ccSequenceTable,ccPLS,ccZones);
  TVMPARAMETERCLASS                 = TVMCOMMANDCLASS.ccAxis..TVMCOMMANDCLASS.ccTask;
  TVMCOMMANDPARAMETERSUBCLASS       = (mscAttributes,mscBlock,mscList,mscUpperLimit,mscLowerLimit,mscParameterData,mscName,mscUnits);

  TCAPSCHAR                         = 'A'..'Z';

  TCOMMANDDATA = record
    CCLASS         : TVMPARAMETERCLASS;
    CCLASSCHAR     : TCAPSCHAR;
    CSUBCLASS      : TVMCOMMANDPARAMETERSUBCLASS;
    CSUBCLASSCHAR  : TCAPSCHAR;
    SETID          : word;
    NUMID          : word;
    STEPID         : word;
    DATA           : string;
  end;

const
  VMCOMMANDCLASS                    : array[TVMCOMMANDCLASS] of TCAPSCHAR = ('A','C','D','D','T','F','G','H','I','M','X','Y','E','P','K','S','R','L','Q','W','Z');
  VMCOMMANDPARAMETERSUBCLASS        : array[TVMCOMMANDPARAMETERSUBCLASS] of TCAPSCHAR = ('A','B','D','H','L','P','T','U');

  //--------------------------------------------------------------------------------------------
  // Data Block Elements
  //--------------------------------------------------------------------------------------------
  CSMD_SERC_ELEM0            = 0;   // Close Service Channel
  CSMD_SERC_ELEM1            = 1;   // IDN
  CSMD_SERC_ELEM2            = 2;   // Name
  CSMD_SERC_ELEM3            = 3;   // Attribute
  CSMD_SERC_ELEM4            = 4;   // Unit
  CSMD_SERC_ELEM5            = 5;   // Min. Value
  CSMD_SERC_ELEM6            = 6;   // Max. Value
  CSMD_SERC_ELEM7            = 7;   // Data


  //--------------------------------------------------------------------------
  // Attribute    Bits 22-20:     Data type and display format
  //--------------------------------------------------------------------------
  CSMD_ATTRIBUTE_FORMAT                                 = %11100000000000000000000;   // And-Mask: Get data format
  CSMD_ATTRIBUTE_FORMAT_DataBinaryDisplayBinary         = %00000000000000000000000;
  CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayUdec             = %00100000000000000000000;
  CSMD_ATTRIBUTE_FORMAT_DataIntDisplayDec               = %01000000000000000000000;
  CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayHex              = %01100000000000000000000;
  CSMD_ATTRIBUTE_FORMAT_DataCharDisplayUTF8             = %10000000000000000000000;
  CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayIDN              = %10100000000000000000000;
  CSMD_ATTRIBUTE_FORMAT_DataFloatDisplaySignedDecExp    = %11000000000000000000000;
  CSMD_ATTRIBUTE_FORMAT_DataSercosTimeDisplaySercosTime = %11100000000000000000000;

  //--------------------------------------------------------------------------
  // Attribute    Bits 18-16:     Data length
  //--------------------------------------------------------------------------
  CSMD_SERC_LEN                 = $00070000;   // And-Mask: Get data length
  CSMD_SERC_WORD_LEN            = $00010000;   // Bit-Mask length word
  CSMD_SERC_LONG_LEN            = $00020000;   // Bit-Mask length long
  CSMD_SERC_DOUBLE_LEN          = $00030000;   // Bit-Mask length double
  CSMD_SERC_VAR_LEN             = $00040000;   // Bit-Mask length variable
  CSMD_SERC_VAR_BYTE_LEN        = $00040000;   // Bit-Mask String (v.len.byte)
  CSMD_SERC_VAR_WORD_LEN        = $00050000;   // Bit-Mask variab. length word
  CSMD_SERC_VAR_LONG_LEN        = $00060000;   // Bit-Mask variab. length long
  CSMD_SERC_VAR_DOUBLE_LEN      = $00070000;   // Bit-Mask variab. length double
  CSMD_SERC_LEN_WO_LISTINFO     = $00030000;   // Bit-Mask length without variable length info

  //--------------------------------------------------------------------------------
  // Attribute    Bit 19:         Function of operation data
  //--------------------------------------------------------------------------------
  CSMD_SERC_OP_DATA_MASK        = $00080000;   // AND-Mask: Get op. data function
  CSMD_SERC_DATA_PAR            = $00000000;   // Operation data or parameter
  CSMD_SERC_PROC_CMD            = $00080000;   // Procedure command

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  aRawList:TStringList;
  aResultListP,aResultListS:TStringList;
  s,aLine,aResult:string;
  i,j:integer;
  Attribute:dword;
  Param,ParamName,ParamAttribute,ParamUnit,ParamValue,ParamMin,ParamMax:string;
  ParamNum:word;
  CD :TCOMMANDDATA;
  //Ini:TIniFile;
begin
  OpenDialog1.FileName:='C:\Indramat\DriveTop\16V14\y-as.par';
  //if OpenDialog1.Execute then
  begin
    aRawList:=TStringList.Create;
    try
      aRawList.LoadFromFile(OpenDialog1.FileName);
      aResultListP:=TStringList.Create;
      aResultListS:=TStringList.Create;
      //Ini:=TIniFile.Create('test.ini');

      i:=0;
      while (i<(aRawList.Count-7)) do
      begin
        while (i<(aRawList.Count)) AND (aRawList.Strings[i]<>'|') do Inc(i);
        Param:=aRawList.Strings[i+CSMD_SERC_ELEM1];
        ParamNum:=StrtoInt(Copy(Param,Length(Param)-3,4));
        ParamName:=Trim(aRawList.Strings[i+CSMD_SERC_ELEM2]);
        ParamName:=StringReplace(ParamName,'''','"',[rfReplaceAll]);
        ParamAttribute:=aRawList.Strings[i+CSMD_SERC_ELEM3];
        Attribute:=StrToInt('%'+Trim(ParamAttribute));
        ParamUnit:=aRawList.Strings[i+CSMD_SERC_ELEM4];
        ParamMin:=aRawList.Strings[i+CSMD_SERC_ELEM5];
        ParamMax:=aRawList.Strings[i+CSMD_SERC_ELEM6];
        ParamValue:=aRawList.Strings[i+CSMD_SERC_ELEM7];
        //aResult:=Format('Number: %.4d; Active: TRUE; Name: %s; Unit: %s; Value: %s.',[j,ParamName,ParamUnit,ParamValue]);
        //aResult:=Format('   (Number: %.4d; Active: TRUE; Name: ''%s''),',[ParamNum,ParamName]);

        aResult:=Format('   (IDN: %.4d; Active: TRUE; Attribute: %%%s; Min: ''%s''; Max: ''%s''; Measure: ''%s''; Name: ''%s''),',[ParamNum,BinStr(Attribute,32),ParamMin,ParamMax,ParamUnit,ParamName]);

        CD :=Default(TCOMMANDDATA);

        (*
        Ini.WriteString(Param,'Name',ParamName);
        Ini.WriteString(Param,'Attribute',ParamAttribute);
        Ini.WriteString(Param,'Unit',ParamUnit);
        Ini.WriteString(Param,'Min',ParamMin);
        Ini.WriteString(Param,'Max',ParamMax);
        Ini.WriteString(Param,'Value',ParamValue);
        Ini.WriteBool(Param,'Active',True);
        *)

        if (Pos('-7-',Param)=0) then
        begin
          if Param[1]='S' then CD.CCLASS:=ccDrive;
          if Param[1]='P' then CD.CCLASS:=ccDriveSpecific;
        end;

        if CD.CCLASS in [ccDrive,ccDriveSpecific] then
        begin
          if CD.CCLASS=ccDriveSpecific then ParamNum:=ParamNum+$8000;
          CD.NUMID:=ParamNum;
          CD.SETID:=2; // Axis 1

          CD.CSUBCLASS:=mscName;
          s:=VMCOMMANDCLASS[CD.CCLASS]+VMCOMMANDPARAMETERSUBCLASS[CD.CSUBCLASS]+' '+InttoStr(CD.SETID)+'.'+InttoStr(CD.NUMID);
          s:=s+'=';
          s:=s+ParamName;
          Memo1.Lines.Append(s);

          CD.CSUBCLASS:=mscUnits;
          s:=VMCOMMANDCLASS[CD.CCLASS]+VMCOMMANDPARAMETERSUBCLASS[CD.CSUBCLASS]+' '+InttoStr(CD.SETID)+'.'+InttoStr(CD.NUMID);
          s:=s+'=';
          s:=s+ParamUnit;
          Memo1.Lines.Append(s);

          CD.CSUBCLASS:=mscAttributes;
          s:=VMCOMMANDCLASS[CD.CCLASS]+VMCOMMANDPARAMETERSUBCLASS[CD.CSUBCLASS]+' '+InttoStr(CD.SETID)+'.'+InttoStr(CD.NUMID);
          s:=s+'=';
          s:=s+BinStr(Attribute,SizeOf(Attribute)*8);
          Memo1.Lines.Append(s);

          CD.CSUBCLASS:=mscParameterData;
          s:=VMCOMMANDCLASS[CD.CCLASS]+VMCOMMANDPARAMETERSUBCLASS[CD.CSUBCLASS]+' '+InttoStr(CD.SETID)+'.'+InttoStr(CD.NUMID);
          s:=s+'=';

          if ((Attribute AND dword(CSMD_SERC_LEN))<>0) then
          begin
            if ((Attribute AND dword(CSMD_SERC_LEN))<>0) AND ((Attribute AND dword(CSMD_SERC_LEN))=CSMD_SERC_VAR_BYTE_LEN) then
            begin
              s:=s+ExtractWord(3,ParamValue,[' ']);
            end
            else
            begin
              s:=s+ParamValue;
            end;
          end;

          Memo1.Lines.Append(s);
        end;

        (*
        case (Attribute AND dword(CSMD_ATTRIBUTE_FORMAT)) of
          CSMD_ATTRIBUTE_FORMAT_DataBinaryDisplayBinary         : aResult:='BinBin '+aResult;
          CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayUdec             : aResult:='UIntUDec '+aResult;
          CSMD_ATTRIBUTE_FORMAT_DataIntDisplayDec               : aResult:='IntDec '+aResult;
          CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayHex              : aResult:='UIntHex '+aResult;
          CSMD_ATTRIBUTE_FORMAT_DataCharDisplayUTF8             : aResult:='CharUTF8 '+aResult;
          CSMD_ATTRIBUTE_FORMAT_DataUIntDisplayIDN              : aResult:='UIntIDN '+aResult;
          CSMD_ATTRIBUTE_FORMAT_DataFloatDisplaySignedDecExp    : aResult:='FloatScientific '+aResult;
          CSMD_ATTRIBUTE_FORMAT_DataSercosTimeDisplaySercosTime : aResult:='Time '+aResult;
        end;

        case (Attribute AND dword(CSMD_SERC_LEN)) of
          CSMD_SERC_VAR_BYTE_LEN   : aResult:='Byte list (string): '+aResult;
          CSMD_SERC_VAR_WORD_LEN   : aResult:='Word list: '+aResult;
          CSMD_SERC_VAR_LONG_LEN   : aResult:='Long list: '+aResult;
          CSMD_SERC_VAR_DOUBLE_LEN : aResult:='Double list: '+aResult;
        end;
        *)

        (*
        if ((Attribute AND dword(CSMD_SERC_LEN))<>0) then
        begin

          if ((Attribute AND dword(CSMD_SERC_LEN))=CSMD_SERC_VAR_BYTE_LEN) then
          begin
            s:=ExtractWord(3,ParamValue,[' ']);
            aResult:=aResult+'. String: '+s;
          end;

          if (((Attribute AND dword(CSMD_SERC_LEN))=CSMD_SERC_VAR_WORD_LEN) OR ((Attribute AND dword(CSMD_SERC_LEN))=CSMD_SERC_VAR_LONG_LEN)) then
          begin
            j:=StrToInt(ParamValue);
            if ((Attribute AND dword(CSMD_SERC_LEN))=CSMD_SERC_VAR_WORD_LEN) then j:=j DIV 2;
            if ((Attribute AND dword(CSMD_SERC_LEN))=CSMD_SERC_VAR_LONG_LEN) then j:=j DIV 4;
            Inc(i,CSMD_SERC_ELEM7+2);
            while ((j>0) AND (aRawList.Strings[i]<>'|')) do
            begin
               s:=aRawList.Strings[i];
               aResult:=aResult+'. Data: '+s;
               Dec(j);
               Inc(i);
            end;
            Dec(i);
          end;

        end;
        *)

        if (Pos('-7-',Param)=0) then
        begin
          if Param[1]='P' then aResultListP.Add(aResult);
          if Param[1]='S' then aResultListS.Add(aResult);
          //(Number:   0; Active: TRUE; Name: 'Dummy-Parameter'),
          //Memo2.Lines.Append(aResult);
        end;
        Inc(i);
      end;

      aResultListP.Sort;
      aResultListS.Sort;
      Memo2.Lines.Text:=aResultListS.Text+#13+#13+aResultListP.Text;

      (*
      repeat
        Inc(i);
        s:=aRawList.Strings[i];
        if s='|' then continue;
        Inc(i);
        Param:=s;
        Inc(i);
        ParamName:=s;
        Inc(i,2);
        ParamUnit:=s;
        Inc(i,2);
        ParamValue:=s;
        aResult:=Format('Parameter %s. Name %s. Unit %s. Value %s.',[Param,ParamName,ParamUnit,ParamValue]);
        Memo2.Lines.Append(aResult);
      until (i>=aRawList.Count);
      *)
    finally
      //Ini.Free;
      aResultListP.Free;
      aResultListS.Free;
      aRawList.Free;
    end;

  end;
end;

end.

