unit GamePlanner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GameEnv, Agent, Board;

const
  DISCOUNTED = 0.9;
  NEGINFINITY: Single = (-1.0) / (0.0);

type
  TPlan = record
    Action: Integer;
    Value: Single;
  end;

function Plan(constref AState: TState; constref AVf: TWeightlessNetwork; constref AGamma: Single = DISCOUNTED): TPlan;

implementation

function GetNextStateValue(constref AAfterState: TState; constref AVf: TWeightlessNetwork): Single;
var
  i, nNextStates: Integer;
  nextState: TState;
begin
  Result := 0;
  nNextStates := 0;
  for i := 0 to 15 do
    if AAfterState.Get(i) = 0 then
    begin
      nextState.Init(AAfterState);
      nextState.Put(i, 1);
      if not nextState.Terminal then Result += AVf.Predict(nextState) * 0.9;
      nextState.Put(i, 2);
      if not nextState.Terminal then Result += AVf.Predict(nextState) * 0.1;
      Inc(nNextStates);
    end;
  Result /= nNextStates;
end;

function Plan(constref AState: TState; constref AVf: TWeightlessNetwork; constref AGamma: Single): TPlan;
var
  action: Integer;
  afterState: TAfterBoard;
  v: Single;
begin
  Result.Action := -1;
  Result.Value := NEGINFINITY;
  for action := 0 to 3 do
  begin
    afterState := GetAfterBoard(AState, action);
    if not afterState.Modified then Continue;
    v := afterState.Score * REWARD_SCALE + AGamma * GetNextStateValue(afterState.AfterBoard, AVf);
    if v > Result.Value then
    begin
      Result.Value := v;
      Result.Action := action;
    end;
  end;
end;


end.

