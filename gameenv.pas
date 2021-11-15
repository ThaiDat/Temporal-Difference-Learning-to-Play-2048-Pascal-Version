unit GameEnv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, GameDriver, Board;

const
  REWARD_SCALE: Single = 1;

type

  { TState }
  TState = TBoard;

  { TNextState }
  TNextState = record
    NextState: TState;
    Reward: Single;
    Done: Boolean;
  end;

  { TGameEnvironment }

  TGameEnvironment = class
  private
    FDriver: SilentGameDriver;
  public
    constructor Create;
    destructor Destroy; override;
    function Reset: TState;
    function Step(constref AAction: Integer): TNextState;
  end;

implementation

{ TGameEnvironment }

constructor TGameEnvironment.Create;
begin
  Self.FDriver := SilentGameDriver.Create;
  Self.FDriver.Connect;
end;

destructor TGameEnvironment.Destroy;
begin
  Self.FDriver.Free;
  inherited;
end;

function TGameEnvironment.Reset: TState;
begin
  Self.FDriver.Restart;
  Result := Self.FDriver.Board;
end;

function TGameEnvironment.Step(constref AAction: Integer): TNextState;
var
  oldScore: Integer;
begin
  oldScore := Self.FDriver.Score;
  Self.FDriver.MakeMove(AAction);
  Result.NextState := Self.FDriver.Board;
  Result.Reward := (Self.FDriver.Score - oldScore) * REWARD_SCALE;
  Result.Done := Self.FDriver.IsEnd;
end;

end.

