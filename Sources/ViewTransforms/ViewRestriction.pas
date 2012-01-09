unit ViewRestriction;

interface

uses
  SysUtils, Classes, Graphics, ScUtils, GR32, FunLabyUtils, Generics, Dialogs;

const
  attrViewRestrictionRadius = 'ViewRestrictionRadius';
  idViewRestrictionPlugin = 'ViewRestrictionPlugin';

var
  attrtypeViewRestrictionRadius: Integer;

type
  TViewRestrictionPluginPlayerData = class(TPlayerData)
  private
    FMaskBitmap: TBitmap32;
    FViewRestrictionRadius: Integer;

    procedure UpdateMaskBitmap(ViewWidth, ViewHeight: Integer);
  public
    constructor Create(AComponent: TFunLabyComponent;
      APlayer: TPlayer); override;
    destructor Destroy; override;

    procedure UpdateMaskBitmapIfNeeded(ViewWidth, ViewHeight: Integer);

    property MaskBitmap: TBitmap32 read FMaskBitmap;
  end;

  TViewRestrictionPlugin = class(TPlugin)
  protected
    class function GetPlayerDataClass: TPlayerDataClass; override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID);

    procedure DrawView(Context: TDrawViewContext); override;
  end;

var { FunDelphi codegen }
  compViewRestrictionPlugin: TViewRestrictionPlugin;

implementation

procedure InitializeUnit(Master: TMaster);
begin
  TViewRestrictionPlugin.Create(Master, idViewRestrictionPlugin);
end;

function DistanceSquare(const Point1, Point2: TPoint): Integer;
var
  DiffX, DiffY: Integer;
begin
  DiffX := Point1.X - Point2.X;
  DiffY := Point1.Y - Point2.Y;
  Result := DiffX*DiffX + DiffY*DiffY;
end;

{ TViewRestrictionPluginPlayerData }

constructor TViewRestrictionPluginPlayerData.Create(
  AComponent: TFunLabyComponent; APlayer: TPlayer);
begin
  inherited;

  FMaskBitmap := TBitmap32.Create;
  FMaskBitmap.DrawMode := dmBlend;
end;

destructor TViewRestrictionPluginPlayerData.Destroy;
begin
  FMaskBitmap.Free;

  inherited;
end;

procedure TViewRestrictionPluginPlayerData.UpdateMaskBitmap(
  ViewWidth, ViewHeight: Integer);
var
  Center: TPoint;
  MaxRadius, MaxRadiusSq, RadiusSq, X, Y: Integer;
  UsefulRect: TRect;
begin
  FViewRestrictionRadius :=
    Integer(Player.Attributes[attrViewRestrictionRadius]^);

  MaskBitmap.SetSize(2*ViewWidth, 2*ViewHeight);
  MaskBitmap.Clear(clBlack32);
  Center := Point(ViewWidth, ViewHeight);

  // Fetch maximum radius
  MaxRadius := FViewRestrictionRadius;
  if MaxRadius <= 0 then
    Exit;

  // Square radius
  MaxRadiusSq := MaxRadius * MaxRadius;

  // Compute useful rect
  UsefulRect := Rect(Center.X-MaxRadius, Center.Y-MaxRadius,
    Center.X+MaxRadius, Center.Y+MaxRadius);
  if not IntersectRect(UsefulRect, UsefulRect, MaskBitmap.ClipRect) then
    Exit;

  // Draw the useful rect
  for X := UsefulRect.Left to UsefulRect.Right-1 do
  begin
    for Y := UsefulRect.Top to UsefulRect.Bottom-1 do
    begin
      RadiusSq := DistanceSquare(Center, Point(X, Y));

      if RadiusSq <= MaxRadiusSq then
        MaskBitmap.Pixel[X, Y] := SetAlpha(clBlack32,
          $FF * RadiusSq div MaxRadiusSq);
    end;
  end;
end;

procedure TViewRestrictionPluginPlayerData.UpdateMaskBitmapIfNeeded(
  ViewWidth, ViewHeight: Integer);
var
  MaskBitmapBounds: TRect;
begin
  MaskBitmapBounds := MaskBitmap.BoundsRect;

  if (MaskBitmapBounds.Right <> 2*ViewWidth) or
    (MaskBitmapBounds.Bottom <> 2*ViewHeight) or
    (FViewRestrictionRadius <>
      Integer(Player.Attributes[attrViewRestrictionRadius]^)) then
  begin
    UpdateMaskBitmap(ViewWidth, ViewHeight);
  end;
end;

{ TViewRestrictionPlugin }

constructor TViewRestrictionPlugin.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;

  FZIndex := 512;
end;

class function TViewRestrictionPlugin.GetPlayerDataClass: TPlayerDataClass;
begin
  Result := TViewRestrictionPluginPlayerData;
end;

procedure TViewRestrictionPlugin.DrawView(Context: TDrawViewContext);
var
  Player: TPlayer;
  Zone: TRect;
  ViewWidth, ViewHeight: Integer;
  PlayerData: TViewRestrictionPluginPlayerData;
  Center, TopLeft: TPoint;
begin
  Player := Context.Player;
  Zone := Context.Zone;
  ViewWidth := Player.Mode.Width;
  ViewHeight := Player.Mode.Height;

  PlayerData := TViewRestrictionPluginPlayerData(GetPlayerData(Player));

  PlayerData.UpdateMaskBitmapIfNeeded(ViewWidth, ViewHeight);

  // Build Center
  Center.X := (Player.Position.X-Zone.Left) * SquareSize + HalfSquareSize;
  Center.Y := (Player.Position.Y-Zone.Top)  * SquareSize + HalfSquareSize;

  // Build TopLeft
  TopLeft.X := Center.X - ViewWidth;
  TopLeft.Y := Center.Y - ViewHeight;

  // Draw mask bitmap
  Context.Bitmap.Draw(TopLeft.X, TopLeft.Y, PlayerData.MaskBitmap);
end;

end.
