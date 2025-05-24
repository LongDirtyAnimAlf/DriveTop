unit sis2;

interface

procedure WriteSercosParamIDN(const idn: string; const data: array of Byte; dataLength: Byte);
procedure ReadSercosParamIDN(const idn: string);

implementation

procedure SendByte(b: Byte);
begin
end;

function ParseIDN(const idn: string; out paramType: Byte; out paramNum: Word): Boolean;
var
  t: Char;
  s: string;
  Code :integer;
begin
  if Length(idn) < 7 then Exit(False);
  t := UpCase(idn[1]);
  case t of
    'S': paramType := $00;
    'P': paramType := $01;
    'D': paramType := $02;
  else
    Exit(False);
  end;
  s := Copy(idn, Pos('-', idn, 4) + 1, 4);
  if Length(s) <> 4 then Exit(False);
  Val('$' + s, paramNum, Code);
  Result := (Code = 0);
end;

procedure WriteSercosParamIDN(const idn: string; const data: array of Byte; dataLength: Byte);
var
  telegram: array[0..63] of Byte;
  response: array[0..31] of Byte;
  i, cs, paramType: Byte;
  paramNum: Word;
  received, timeout: Integer;
  statusByte: Byte;
begin
  if not ParseIDN(idn, paramType, paramNum) then begin
    Writeln('Invalid IDN format: ', idn);
    Exit;
  end;
  telegram[0] := $02;
  telegram[1] := 0;
  telegram[2] := 9 + dataLength - 4;
  telegram[3] := telegram[2];
  telegram[4] := $00;
  telegram[5] := $1F;
  telegram[6] := $01;
  telegram[7] := $02;
  telegram[8] := $30;
  telegram[9] := $01;
  telegram[10] := paramType;
  telegram[11] := Lo(paramNum);
  telegram[12] := Hi(paramNum);
  for i := 0 to dataLength - 1 do
    telegram[13 + i] := data[i];
  cs := 0;
  for i := 0 to 12 + dataLength do
    cs := (cs + telegram[i]) and $FF;
  telegram[1] := (not cs) and $FF;
  for i := 0 to 12 + dataLength do
    SendByte(telegram[i]);
  received := 0;
  timeout := 0;
  repeat
    Inc(received);
    Inc(timeout);
  until (received >= 13) or (timeout > 500);
  if received < 13 then
  begin
    Writeln('No valid response received.');
    Exit;
  end;
  statusByte := response[8];
  if statusByte = 0 then
    Writeln('Write to ', idn, ' succeeded.')
  else
    Writeln('Write failed. Status byte: $', HexStr(statusByte, 2));
end;

procedure ReadSercosParamIDN(const idn: string);
var
  telegram: array[0..31] of Byte;
  response: array[0..31] of Byte;
  paramType: Byte;
  paramNum: Word;
  cs, i, timeout, received: Integer;
  statusByte: Byte;
begin
  if not ParseIDN(idn, paramType, paramNum) then begin
    Writeln('Invalid IDN format: ', idn);
    Exit;
  end;
  telegram[0] := $02;
  telegram[1] := 0;
  telegram[2] := 5;
  telegram[3] := 5;
  telegram[4] := $00;
  telegram[5] := $10;
  telegram[6] := $01;
  telegram[7] := $02;
  telegram[8] := $30;
  telegram[9] := $01;
  telegram[10] := paramType;
  telegram[11] := Lo(paramNum);
  telegram[12] := Hi(paramNum);
  cs := 0;
  for i := 0 to 12 do
    cs := (cs + telegram[i]) and $FF;
  telegram[1] := (not cs) and $FF;
  for i := 0 to 12 do
    SendByte(telegram[i]);
  received := 0;
  timeout := 0;
  repeat
    Inc(received);
    Inc(timeout);
  until (received >= 13) or (timeout > 500);
  if received < 13 then
  begin
    Writeln('No response received.');
    Exit;
  end;
  statusByte := response[8];
  if statusByte = 0 then
  begin
    Write('Read from ', idn, ' = ');
    for i := 9 to received - 1 do
      Write(HexStr(response[i], 2), ' ');
    Writeln;
  end
  else
    Writeln('Read failed. Status byte: $', HexStr(statusByte, 2));
end;

end.
