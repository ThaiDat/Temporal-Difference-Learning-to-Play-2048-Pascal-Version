program RL2048;

uses DateUtils, SysUtils, Classes, Board, GameDriver, GameEnv, Agent, GamePlanner;

const
  TRAIN_STEPS: UInt64 = 1000000000;
  EVAL_STEPS: UInt64 = 1000000;
  BACKUP_STEPS: UInt64 = 10000000;
  BACKUP_LOCATION = 'bin/model.pasrl';


function FindMaxTile(constref ABoard: TBoard): Integer;
var
  i, tile: Integer;
begin
  Result := 0;
  for i := 0 to 15 do
  begin
    tile := ABoard.Get(i);
    if tile > Result then Result := tile;
  end;
end;

var
  env: TGameEnvironment;
  model: TWeightlessNetwork;
  state: TState;
  checkpoint, nextCheckpoint: TDateTime;
  av: TPlan;
  reaction: TNextState;
  alltimeMax, boardMax, gamePlayed, i: Integer;
  step: UInt64;
  maxCounter: array [1..15] of Integer = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  totalScore, episodeScore: Single;
  elapsed: Double;
  backupFileStream: TFileStream;

begin
  env := TGameEnvironment.Create;
  model := TWeightlessNetwork.Create;
  model.Push(CreatePattern([0, 1, 2, 3, 4, 5]));
  model.Push(CreatePattern([4, 5, 6, 7, 8, 9]));
  model.Push(CreatePattern([0, 1, 2, 4, 5, 6]));
  model.Push(CreatePattern([4, 5, 6, 8, 9, 10]));
  state := env.Reset;

  alltimeMax := 0;
  gamePlayed := 0;
  totalScore := 0;
  episodeScore:=0;
  checkpoint := Now;
  for step := 1 to TRAIN_STEPS do
  begin
    av := Plan(state, model);
    reaction := env.Step(av.Action);
    model.Fit(state, av.Value);

    episodeScore += reaction.Reward;
    if reaction.Done then
    begin
      state := env.Reset;
      boardMax := FindMaxTile(reaction.NextState);
      Inc(maxCounter[boardMax]);
      if boardMax > alltimeMax then alltimeMax := boardMax;
      totalScore += episodeScore;
      episodeScore := 0;
      Inc(gamePlayed);
    end
    else
      state := reaction.NextState;

    if step mod EVAL_STEPS = 0 then
    begin
      nextCheckpoint := Now;
      elapsed:= MilliSecondsBetween(checkpoint, nextCheckpoint) / 1000;
      WriteLn('Trained ', step, ' steps in ', elapsed:9:2 , ' seconds');
      WriteLn('    Maximum tile reached: ', 1 shl alltimeMax);
      Write('    Played ', gamePlayed, ' games with mean score: ');
      if gamePlayed > 0 then WriteLn((totalScore/REWARD_SCALE/gamePlayed):12:3) else WriteLn('NaN');
      Write('    Max tiles: ');
      for i := 1 to 15 do if maxCounter[i] > 0 then
      begin
        Write(1 shl i, ':', maxCounter[i], ' , ');
        maxCounter[i] := 0;
      end;
      WriteLn;
      gamePlayed := 0;
      totalScore := 0;
      checkpoint := Now;
    end;

    if step mod BACKUP_STEPS = 0 then
    begin
      backupFileStream := TFileStream.Create(BACKUP_LOCATION, fmCreate);
      model.Save(backupFileStream);
      FreeAndNil(backupFileStream);
    end;
  end;
end.
