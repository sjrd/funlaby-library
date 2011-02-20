unit MovableBlocks;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools;

resourcestring
  SCategoryMovableBlocks = 'Blocs qui bougent';

type
  TMovableBlock = class(TSquareModifier)
  private
    FCanCrossZones: Boolean; /// Indique si le bloc peut traverser les zones

    FDefaultCanCrossZones: Boolean; /// CanCrossZones par défaut

    function IsCanCrossZonesStored: Boolean;
  protected
    procedure StoreDefaults; override;

    function GetCategory: string; override;

    function IsDestSquareValid(Context: TMoveContext;
      Square: TSquare): Boolean; virtual;
    function IsMoveAllowed(Context: TMoveContext;
      const Behind: T3DPoint): Boolean; virtual;
    procedure ApplyMove(Context: TMoveContext; const Behind: T3DPoint); virtual;
  public
    procedure Pushing(Context: TMoveContext); override;
  published
    property CanCrossZones: Boolean read FCanCrossZones write FCanCrossZones
      stored IsCanCrossZonesStored;
  end;

  TAnchoredMovableBlock = class(TMovableBlock)
  private
    FOrigQPos: TQualifiedPos; /// Position d'origine
  protected
    procedure DefineProperties(Filer: TFunLabyFiler); override;
  public
    procedure Reset; virtual;
    procedure FixThere; virtual;

    class procedure ResetAll(Master: TMaster);
  end;

  TConstrainedMovableBlock = class(TAnchoredMovableBlock)
  private
    FAllowedDirs: TDirections;  /// Directions autorisées
    FMaximumMoveCount: Integer; /// Nombre maximal de déplacements

    FRemainingMoveCount: Integer; /// Nombre de déplacements restant

    FDefaultAllowedDirs: TDirections;  /// AllowedDirs par défaut
    FDefaultMaximumMoveCount: Integer; /// MaximumMoveCount par défaut

    function IsAllowedDirsStored: Boolean;
    function IsMaximumMoveCountStored: Boolean;
  protected
    procedure DefineProperties(Filer: TFunLabyFiler); override;

    procedure StoreDefaults; override;

    function IsMoveAllowed(Context: TMoveContext;
      const Behind: T3DPoint): Boolean; override;
    procedure ApplyMove(Context: TMoveContext;
      const Behind: T3DPoint); override;

    property RemainingMoveCount: Integer
      read FRemainingMoveCount write FRemainingMoveCount;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;

    procedure Reset; override;
    procedure FixThere; override;
  published
    property AllowedDirs: TDirections read FAllowedDirs write FAllowedDirs
      stored IsAllowedDirsStored;
    property MaximumMoveCount: Integer
      read FMaximumMoveCount write FMaximumMoveCount
      stored IsMaximumMoveCountStored;
  end;

function IsSameZone(Map: TMap; const Left, Right: T3DPoint): Boolean;

implementation

function IsSameZone(Map: TMap; const Left, Right: T3DPoint): Boolean;
begin
  Result := False;

  if (Left.X div Map.ZoneWidth) <> (Right.X div Map.ZoneWidth) then
    Exit;

  if (Left.Y div Map.ZoneHeight) <> (Right.Y div Map.ZoneHeight) then
    Exit;

  if Left.Z <> Right.Z then
    Exit;

  Result := True;
end;

{---------------------}
{ TMovableBlock class }
{---------------------}

function TMovableBlock.IsCanCrossZonesStored: Boolean;
begin
  Result := FCanCrossZones <> FDefaultCanCrossZones;
end;

procedure TMovableBlock.StoreDefaults;
begin
  inherited;

  FDefaultCanCrossZones := FCanCrossZones;
end;

function TMovableBlock.GetCategory: string;
begin
  Result := SCategoryMovableBlocks;
end;

function TMovableBlock.IsDestSquareValid(Context: TMoveContext;
  Square: TSquare): Boolean;
begin
  Result := (Square.Field is TGround) and (Square.Effect = nil) and
    (Square.Tool = nil) and (Square.Obstacle = nil);
end;

function TMovableBlock.IsMoveAllowed(Context: TMoveContext;
  const Behind: T3DPoint): Boolean;
var
  BehindQPos: TQualifiedPos;
begin
  BehindQPos.Map := Context.Map;
  BehindQPos.Position := Behind;

  Result := IsDestSquareValid(Context, Context.Map[Behind]) and
    (not IsAnySquareModifier(BehindQPos)) and
    (CanCrossZones or IsSameZone(Context.Map, Context.Pos, Behind));
end;

procedure TMovableBlock.ApplyMove(Context: TMoveContext;
  const Behind: T3DPoint);
begin
  ChangePosition(Behind);
end;

procedure TMovableBlock.Pushing(Context: TMoveContext);
var
  Behind: T3DPoint;
begin
  Behind := PointBehind(Context.Pos, Context.Player.Direction);

  if IsMoveAllowed(Context, Behind) then
    ApplyMove(Context, Behind)
  else
    Context.Cancel;
end;

{-----------------------------}
{ TAnchoredMovableBlock class }
{-----------------------------}

procedure TAnchoredMovableBlock.DefineProperties(Filer: TFunLabyFiler);
var
  HasData: Boolean;
begin
  inherited;

  if psReading in PersistentState then
  begin
    FOrigQPos := QPos;
    HasData := False;
  end else
  begin
    HasData := (not Master.Editing) and (not SameQPos(FOrigQPos, QPos));
  end;

  Filer.DefineFieldProperty('OrigQPos.Map', TypeInfo(TMap),
    @FOrigQPos.Map, HasData);

  Filer.DefineFieldProperty('OrigQPos.Position.X', TypeInfo(Integer),
    @FOrigQPos.Position.X, HasData);
  Filer.DefineFieldProperty('OrigQPos.Position.Y', TypeInfo(Integer),
    @FOrigQPos.Position.Y, HasData);
  Filer.DefineFieldProperty('OrigQPos.Position.Z', TypeInfo(Integer),
    @FOrigQPos.Position.Z, HasData);
end;

procedure TAnchoredMovableBlock.Reset;
begin
  ChangePosition(FOrigQPos);
end;

procedure TAnchoredMovableBlock.FixThere;
begin
  FOrigQPos := QPos;
end;

class procedure TAnchoredMovableBlock.ResetAll(Master: TMaster);
var
  I: Integer;
begin
  for I := 0 to Master.PosComponentCount-1 do
  begin
    if Master.PosComponents[I] is Self then
      TAnchoredMovableBlock(Master.PosComponents[I]).Reset;
  end;
end;

{--------------------------------}
{ TConstrainedMovableBlock class }
{--------------------------------}

constructor TConstrainedMovableBlock.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;

  FAllowedDirs := [diNorth, diEast, diSouth, diWest];
  FMaximumMoveCount := 1;
end;

function TConstrainedMovableBlock.IsAllowedDirsStored: Boolean;
begin
  Result := FAllowedDirs <> FDefaultAllowedDirs;
end;

function TConstrainedMovableBlock.IsMaximumMoveCountStored: Boolean;
begin
  Result := FMaximumMoveCount <> FDefaultMaximumMoveCount;
end;

procedure TConstrainedMovableBlock.DefineProperties(Filer: TFunLabyFiler);
begin
  inherited;

  if psReading in PersistentState then
    FRemainingMoveCount := FMaximumMoveCount;

  Filer.DefineFieldProperty('RemainingMoveCount', TypeInfo(Integer),
    @FRemainingMoveCount,
    (not Master.Editing) and (FRemainingMoveCount <> FMaximumMoveCount));
end;

procedure TConstrainedMovableBlock.StoreDefaults;
begin
  inherited;

  FDefaultAllowedDirs := FAllowedDirs;
  FDefaultMaximumMoveCount := FMaximumMoveCount;
end;

function TConstrainedMovableBlock.IsMoveAllowed(Context: TMoveContext;
  const Behind: T3DPoint): Boolean;
begin
  Result := inherited IsMoveAllowed(Context, Behind);

  Result := Result and (Context.Player.Direction in AllowedDirs) and
    (RemainingMoveCount > 0);
end;

procedure TConstrainedMovableBlock.ApplyMove(Context: TMoveContext;
  const Behind: T3DPoint);
begin
  RemainingMoveCount := RemainingMoveCount - 1;
  inherited;
end;

procedure TConstrainedMovableBlock.Reset;
begin
  inherited;

  FRemainingMoveCount := FMaximumMoveCount;
end;

procedure TConstrainedMovableBlock.FixThere;
begin
  inherited;

  FMaximumMoveCount := 0;
  FRemainingMoveCount := 0;
end;

end.
