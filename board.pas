unit Board;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  { TRow }
  TRow = UInt16;

  { TBoard }
  TBoard = object
  private
    FRaw: UInt64;
    function GetTerminal: Boolean;
  public
    constructor Init; overload;
    constructor Init(constref AOther: TBoard); overload;
    constructor Init(constref ARaw: UInt64); overload;

    property Terminal: Boolean read GetTerminal;
    function Get(constref ARow: Integer; constref ACol: Integer): Integer; overload;
    function Get(constref AIndex: Integer): Integer; overload;
    procedure Put(constref ARow: Integer; constref ACol: Integer; constref AValue: Integer); overload;
    procedure Put(constref AIndex: Integer; constref AValue: Integer); overload;
    function GetRow(constref ARow: Integer): TRow;
    procedure PutRow(constref ARow: Integer; constref AValue: TRow);
    function Transpose: TBoard;
    function FlipHorizontal: TBoard;
    function FlipVertical: TBoard;
    function Rotate90Left: TBoard;
    function Rotate90Right: TBoard;
    function Rotate180: TBoard;
  end;

  { TAfterBoard }
  TAfterBoard = record
    AfterBoard: TBoard;
    Score: Integer;
    Modified: Boolean;
  end;

// Helpter functions
function GetAfterBoard(constref ABoard: TBoard; constref move: Integer): TAfterBoard;

implementation

procedure MoveLeft(var ABoard: TBoard; out AScore: Integer; out AModified: Boolean);
var
  i, j, destj, leftest: Integer;
  row: TRow;

  function GetTile(constref ARow: TRow; constref i: Integer): Integer;
  begin
    Result := (ARow shr (12 - i shl 2)) and $F;
  end;

  procedure MoveTileLeft(var ARow: TRow; constref AFrom: Integer; constref ATo: Integer);
  var
    tilemask, frommask: TRow;
  begin
    // Guarantee AFrom >= ATo, GetTile(ARow, ATo)=0
    frommask := (TRow($F000) shr (AFrom shl 2));
    tilemask := ARow and frommask;
    tilemask := tilemask shl ((AFrom - ATo) shl 2);
    ARow := (ARow and not frommask) or tilemask;
  end;

  procedure MergeTileLeft(var ARow: TRow; constref AFrom: Integer; constref ATo: Integer);
  var
    frommask: TRow;
  begin
    frommask := (TRow($F000) shr (AFrom shl 2));
    ARow := (ARow and not frommask) + (TRow($1000) shr (ATo shl 2));
  end;

begin
  AScore := 0;
  AModified := False;
  for i := 0 to 3 do
  begin
    row := ABoard.GetRow(i);
    leftest := -1;
    for j := 0 to 3 do
    begin
      if GetTile(row, j) = 0 then Continue;
      destj := j - 1;
      while (destj > leftest) and (GetTile(row, destj) = 0) do Dec(destj);
      if (destj <= leftest) or (GetTile(row, destj) <> GetTile(row, j)) then
      begin
        Inc(destj);
        if j = destj then Continue;
        MoveTileLeft(row, j, destj);
        AModified := True;
      end
      else
      begin
        MergeTileLeft(row, j, destj);
        AModified := True;
        leftest := destj;
        Inc(AScore, 1 shl GetTile(row, destj));
      end;
    end;
    ABoard.PutRow(i, row);
  end;
end;

function GetAfterBoard(constref ABoard: TBoard; constref move: Integer): TAfterBoard;
begin
  case move of
  0:
    begin
      Result.AfterBoard.Init(ABoard);
      MoveLeft(Result.AfterBoard, Result.Score, Result.Modified);
    end;
  1:
    begin
      Result.AfterBoard := ABoard.Rotate90Left;
      MoveLeft(Result.AfterBoard, Result.Score, Result.Modified);
      Result.AfterBoard := Result.AfterBoard.Rotate90Right;
    end;
  2:
    begin
      Result.AfterBoard := ABoard.FlipHorizontal;
      MoveLeft(Result.AfterBoard, Result.Score, Result.Modified);
      Result.AfterBoard := Result.AfterBoard.FlipHorizontal;
    end;
  3:
    begin
      Result.AfterBoard := ABoard.Rotate90Right;
      MoveLeft(Result.AfterBoard, Result.Score, Result.Modified);
      Result.AfterBoard := Result.AfterBoard.Rotate90Left;
    end;
  else raise EArgumentOutOfRangeException.Create('Move must be 0:L, 1:U, 2:R, or 3:D');
  end;
end;

{ TBoard }

function TBoard.GetTerminal: Boolean;
var
  hozmask, vermask: UInt64;

  function ContainFourZeros(constref ARaw: Uint64): Boolean;
  var
    temp: UInt64;
  begin
    temp := not ARaw;
    temp := temp and (temp shr 1);
    temp := temp and (temp shr 2);
    Result := (temp <> 0)
  end;

begin
  if ContainFourZeros(Self.FRaw or UInt64($0F0F0F0F0F0F0F0F)) or
     ContainFourZeros(Self.FRaw or UInt64($F0F0F0F0F0F0F0F0)) then Exit(False);
  hozmask := (Self.FRaw xor (Self.FRaw shl 4)) or UInt64($000F000F000F000F);
  if ContainFourZeros(hozmask or UInt64($0F0F0F0F0F0F0F0F)) or
     ContainFourZeros(hozmask or UInt64($F0F0F0F0F0F0F0F0)) then Exit(False);
  vermask := (Self.FRaw xor (Self.FRaw shl 16)) or UInt64($FFFF);
  If ContainFourZeros(vermask or UInt64($0F0F0F0F0F0F0F0F)) or
     ContainFourZeros(vermask or UInt64($F0F0F0F0F0F0F0F0)) then Exit(False);
  Result := True;
end;

constructor TBoard.Init;
begin
  inherited;
  Self.FRaw:=0;
end;

constructor TBoard.Init(constref AOther: TBoard);
begin
  Self.FRaw:=AOther.FRaw;
end;

constructor TBoard.Init(constref ARaw: UInt64);
begin
  Self.FRaw:=ARaw;
end;

function TBoard.Get(constref ARow: Integer; constref ACol: Integer): Integer;
var
  distance: Integer;
begin
  distance := 60 - ((ARow shl 2) + ACol) shl 2;
  Result := (Self.FRaw shr distance) and $F;
end;

function TBoard.Get(constref AIndex: Integer): Integer;
begin
  Result := (Self.FRaw shr (60 - AIndex shl 2)) and $F;
end;

procedure TBoard.Put(constref ARow: Integer; constref ACol: Integer; constref AValue: Integer);
var
  distance: Integer;
begin
  distance := 60 - ((ARow shl 2) + ACol) shl 2;
  Self.FRaw:= (Self.FRaw and not (UInt64($F) shl distance)) or (UInt64(AValue) shl distance);
end;

procedure TBoard.Put(constref AIndex: Integer; constref AValue: Integer);
var
  distance: Integer;
begin
  distance := 60 - AIndex shl 2;
  Self.FRaw:= (Self.FRaw and not (UInt64($F) shl distance)) or (UInt64(AValue) shl distance);
end;

function TBoard.GetRow(constref ARow: Integer): TRow;
begin
  Result := (Self.FRaw shr (48 - ARow shl 4)) and UInt64($FFFF);
end;

procedure TBoard.PutRow(constref ARow: Integer; constref AValue: TRow);
var
  distance: Integer;
begin
  distance := 48 - ARow shl 4;
  Self.FRaw:= (Self.FRaw and not (UInt64($FFFF) shl distance)) or (UInt64(AValue) shl distance);
end;

function TBoard.Transpose: TBoard;
begin
  Result.Init(Self);
  Result.FRaw := (Result.FRaw and $F0F00F0FF0F00F0F) or ((Result.Fraw and $0000F0F00000F0F0) shl 12) or ((Result.FRaw and $0F0F00000F0F0000) shr 12);
  Result.FRaw := (Result.FRaw and $FF00FF0000FF00FF) or ((Result.FRaw and $00000000FF00FF00) shl 24) or ((Result.FRaw and $00FF00FF00000000) shr 24);
end;

function TBoard.FlipHorizontal: TBoard;
begin
  Result.Init(Self);
  Result.FRaw := ((Result.FRaw and $000F000F000F000F) shl 12) or ((Result.FRaw and $00F000F000F000F0) shl 4) or
                 ((Result.FRaw and $0F000F000F000F00) shr 4)  or ((Result.FRaw and $F000F000F000F000) shr 12);
end;

function TBoard.FlipVertical: TBoard;
begin
  Result.Init(Self);
  Result.FRaw := ((Result.FRaw and $000000000000FFFF) shl 48) or ((Result.FRaw and $00000000FFFF0000) shl 16) or
                 ((Result.FRaw and $0000FFFF00000000) shr 16) or ((Result.FRaw and $FFFF000000000000) shr 48);
end;

function TBoard.Rotate90Left: TBoard;
begin
  Result := Self.Transpose.FlipVertical;;
end;

function TBoard.Rotate90Right: TBoard;
begin
  Result := Self.Transpose.FlipHorizontal;
end;

function TBoard.Rotate180: TBoard;
begin
  Result := Self.FlipHorizontal.FlipVertical;
end;

end.

