unit GameDriver;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Board;

type

  { SilentGameDriver }

  SilentGameDriver = class
  private
    FBoard: TBoard;
    FConnected: Boolean;
    FScore: Integer;
    function GetIsEnd: Boolean;
    procedure PutRandomNewTile;
  public
    property Board: TBoard read FBoard;
    property Score: Integer read FScore;
    property Connected: Boolean read FConnected;
    property IsEnd: Boolean read GetIsEnd;

    constructor Create;
    destructor Destroy; override;
    procedure Connect;
    procedure MakeMove(constref AMove: Integer);
    procedure Restart;
  end;

implementation

{ SilentGameDriver }

function SilentGameDriver.GetIsEnd: Boolean;
begin
  Result := Self.FBoard.Terminal;
end;

procedure SilentGameDriver.PutRandomNewTile;
var
  posZero: array[0..15] of Integer;
  nZero, i, newTile: Integer;
begin
  nZero := 0;
  for i := 0 to 15 do
    if Self.FBoard.Get(i) = 0 then
    begin
      posZero[nZero] := i;
      Inc(nZero);
    end;
  if Random(10) = 0 then newTile := 2 else newTile := 1;
  Self.FBoard.Put(posZero[Random(nZero)], newTile);
end;

constructor SilentGameDriver.Create;
begin
  Self.FConnected:=False;
  Self.FScore := 0;
  Self.FBoard .Init;
end;

destructor SilentGameDriver.Destroy;
begin
  inherited;
end;

procedure SilentGameDriver.Connect;
begin
  Self.Restart;
  Self.FConnected:=True;
end;

procedure SilentGameDriver.MakeMove(constref AMove: Integer);
var
  nextboard: TAfterBoard;
begin
  nextboard := GetAfterBoard(Self.FBoard, AMove);
  Self.FBoard := nextboard.AfterBoard;
  Inc(Self.FScore, nextboard.Score);
  if nextboard.Modified then Self.PutRandomNewTile;
end;

procedure SilentGameDriver.Restart;
begin
  Self.FBoard.Init;
  Self.FScore:=0;
  Self.PutRandomNewTile;
  Self.PutRandomNewTile;
end;

end.

