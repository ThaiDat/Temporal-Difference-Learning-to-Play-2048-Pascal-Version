unit Agent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GameEnv, Board;

const
  DEFAULT_LR: Single = 0.1;
  MAX_NTUPLES = 20;

type

  { TPattern }
  TPattern = record
    Pattern: array [0..15] of Integer;
    Size: Integer;
  end;

  { TNtuple }

  TNtuple = class
  private
    FPattern: TPattern;
    FTable: array of Single;
    FLen: Integer;
    function Index(constref AState: TState): UInt64;
  public
    constructor Create(constref APattern: TPattern); overload;
    destructor Destroy; override;
    function LookUp(constref AState: TState): Single;
    procedure Update(constref AState: TState; constref AValue: Single);
    procedure Save(var AFile: TFileStream);
  end;

  { TWeightlessNetwork }

  TWeightlessNetwork = class
  private
    FNtuples: array [0..MAX_NTUPLES-1] of TNtuple;
    FN: Integer;
    FLearningRate: Single;
  public
    constructor Create; overload;
    constructor Create(constref ALr: Single); overload;
    destructor Destroy; override;

    procedure Push(constref APattern: TPattern);
    procedure Pop;
    procedure Fit(constref AState: TState; constref AValue: Single);
    function Predict(constref AState: TState): Single;
    procedure Save(var AFile: TFileStream);
  end;

function CreatePattern(ATiles: array of const): TPattern;

implementation

function CreatePattern(ATiles: array of const): TPattern;
var
  i: Integer;
begin
  for i := 0 to High(ATiles) do Result.Pattern[i] := ATiles[i].VInteger;
  Result.Size:= Length(ATiles);
end;

{ TWeightlessNetwork }

constructor TWeightlessNetwork.Create;
begin
  Self.FLearningRate:=DEFAULT_LR;
  Self.FN := 0;
end;

constructor TWeightlessNetwork.Create(constref ALr: Single);
begin
  Self.FLearningRate:=ALr;
  Self.FN := 0;
end;

procedure TWeightlessNetwork.Push(constref APattern: TPattern);
begin
  if Self.FN = Length(Self.FNtuples) then raise EOutOfMemory.Create('Reach maximum number of ntuples');
  Self.FNtuples[Self.FN] := TNtuple.Create(APattern);
  Inc(Self.FN);
end;

procedure TWeightlessNetwork.Pop;
begin
  if Self.FN = 0 then Exit;
  Dec(Self.FN);
  FreeAndNil(Self.FNtuples[Self.FN]);
end;

procedure TWeightlessNetwork.Fit(constref AState: TState; constref AValue: Single);
var
  currentValue, update: Single;
  i: Integer;
begin
  currentValue := Self.Predict(AState);
  update := (AValue - currentValue) * Self.FLearningRate / Self.FN;
  for i := 0 to Self.FN - 1 do
  begin
    Self.FNtuples[i].Update(AState, update);
  end;
end;

function TWeightlessNetwork.Predict(constref AState: TState): Single;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to self.FN - 1 do
    Result += Self.FNtuples[i].LookUp(AState);
end;

procedure TWeightlessNetwork.Save(var AFile: TFileStream);
var
  i: Integer;
begin
  for i := 0 to Self.FN - 1 do Self.FNtuples[i].Save(AFile);
end;

destructor TWeightlessNetwork.Destroy;
var
  i: Integer;
begin
  for i := 0 to Self.FN-1 do Self.FNtuples[i].Free;
  inherited Destroy;
end;

{ TNtuple }

function TNtuple.Index(constref AState: TState): UInt64;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Self.FPattern.Size - 1 do
  begin
    Result := (Result shl 4) or UInt64(AState.Get(Self.FPattern.Pattern[i]));
  end;
end;

constructor TNtuple.Create(constref APattern: TPattern);
begin
  Self.FPattern := APattern;
  Self.FLen := 1 shl (APattern.Size shl 2);
  SetLength(Self.FTable, Self.FLen);
end;

destructor TNtuple.Destroy;
begin
  SetLength(Self.FTable, 0);
  inherited;
end;

function TNtuple.LookUp(constref AState: TState): Single;
var
  flipped: TState;
begin
  flipped := AState.FlipHorizontal;
  Result := 0;
  Result += Self.FTable[Self.Index(AState)];
  Result += Self.FTable[Self.Index(AState.Rotate90Left)];
  Result += Self.FTable[Self.Index(AState.Rotate90Right)];
  Result += Self.FTable[Self.Index(AState.Rotate180)];
  Result += Self.FTable[Self.Index(flipped)];
  Result += Self.FTable[Self.Index(flipped.Rotate90Left)];
  Result += Self.FTable[Self.Index(flipped.Rotate90Right)];
  Result += Self.FTable[Self.Index(flipped.Rotate180)];
end;

procedure TNtuple.Update(constref AState: TState; constref AValue: Single);
var
  flipped: TState;
  updateValue: Single;
begin
  updateValue := AValue / 8;
  flipped := AState.FlipHorizontal;
  Self.FTable[Self.Index(AState)] += updateValue;
  Self.FTable[Self.Index(AState.Rotate90Left)] += updateValue;
  Self.FTable[Self.Index(AState.Rotate90Right)] += updateValue;
  Self.FTable[Self.Index(AState.Rotate180)] += updateValue;
  Self.FTable[Self.Index(flipped)] += updateValue;
  Self.FTable[Self.Index(flipped.Rotate90Left)] += updateValue;
  Self.FTable[Self.Index(flipped.Rotate90Right)] += updateValue;
  Self.FTable[Self.Index(flipped.Rotate180)] += updateValue;
end;

procedure TNtuple.Save(var AFile: TFileStream);
begin
  AFile.WriteBuffer(Pointer(Self.FTable)^, Self.FLen * SizeOf(Single));
end;

end.

