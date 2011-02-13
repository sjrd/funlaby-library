unit ImageOnView;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools;

resourcestring
  SDefaultImageOnViewPlugin = 'Plugin d''image sur la vue par défaut';

const
  idDefaultImageOnViewPlugin = 'DefaultImageOnViewPlugin';

type
  /// Origine d'une position
  TImagePosOrigin = (poAbsolute, poCentered, poAbsoluteFromEnd, poPercentage);

  {*
    Position sur une image
  *}
  TImagePos = class(TFunLabyPersistent)
  private
    FOriginX: TImagePosOrigin;
    FOriginY: TImagePosOrigin;
    FPosX: Integer;
    FPosY: Integer;

    FDefaultOriginX: TImagePosOrigin;
    FDefaultOriginY: TImagePosOrigin;
    FDefaultPosX: Integer;
    FDefaultPosY: Integer;

    function IsOriginXStored: Boolean;
    function IsOriginYStored: Boolean;
    function IsPosXStored: Boolean;
    function IsPosYStored: Boolean;

    function GetCoord(Origin: TImagePosOrigin; Pos, Min, Max: Integer): Integer;
  protected
    procedure StoreDefaults; override;
  public
    function GetPoint(const Size: TPoint): TPoint; overload;
    function GetPoint(const Rect: TRect): TPoint; overload;
  published
    property OriginX: TImagePosOrigin read FOriginX write FOriginX
      stored IsOriginXStored;
    property PosX: Integer read FPosX write FPosX stored IsPosXStored;

    property OriginY: TImagePosOrigin read FOriginY write FOriginY
      stored IsOriginYStored;
    property PosY: Integer read FPosY write FPosY stored IsPosYStored;
  end;

  {*
    Plugin qui affiche une image (un peintre) sur la vue du joueur
  *}
  TImageOnViewPlugin = class(TPlugin)
  private
    FPainter: TPainter;

    FPosOnView: TImagePos;
    FPosOnImage: TImagePos;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
    destructor Destroy; override;

    procedure AfterConstruction; override;

    procedure DrawView(Context: TDrawViewContext); override;
  published
    property Painter: TPainter read FPainter;

    property PosOnView: TImagePos read FPosOnView;
    property PosOnImage: TImagePos read FPosOnImage;
  end;

var { FunDelphi codegen }
  compDefaultImageOnViewPlugin: TImageOnViewPlugin;

implementation

procedure InitializeUnit(Master: TMaster);
begin
  TImageOnViewPlugin.Create(Master, idDefaultImageOnViewPlugin);
end;

{ TImagePos }

function TImagePos.IsOriginXStored: Boolean;
begin
  Result := FOriginX <> FDefaultOriginX;
end;

function TImagePos.IsOriginYStored: Boolean;
begin
  Result := FOriginY <> FDefaultOriginY;
end;

function TImagePos.IsPosXStored: Boolean;
begin
  Result := FPosX <> FDefaultPosX;
end;

function TImagePos.IsPosYStored: Boolean;
begin
  Result := FPosY <> FDefaultPosY;
end;

procedure TImagePos.StoreDefaults;
begin
  inherited;

  FDefaultOriginX := FOriginX;
  FDefaultOriginY := FOriginY;
  FDefaultPosX := FPosX;
  FDefaultPosY := FPosY;
end;

function TImagePos.GetCoord(Origin: TImagePosOrigin;
  Pos, Min, Max: Integer): Integer;
begin
  case Origin of
    poAbsolute:
      Result := Min+Pos;
    poCentered:
      Result := (Min+Max) div 2 + Pos;
    poAbsoluteFromEnd:
      Result := Max + Pos;
  else
    Result := Min + (Max-Min) * Pos div 100;
  end;
end;

function TImagePos.GetPoint(const Size: TPoint): TPoint;
var
  Rect: TRect;
begin
  Rect.Left := 0;
  Rect.Top := 0;
  Rect.Right := Size.X;
  Rect.Bottom := Size.Y;
  Result := GetPoint(Rect);
end;

function TImagePos.GetPoint(const Rect: TRect): TPoint;
begin
  Result.X := GetCoord(OriginX, PosX, Rect.Left, Rect.Right);
  Result.Y := GetCoord(OriginY, PosY, Rect.Top, Rect.Bottom);
end;

{ TImageOnViewPlugin }

{*
  Crée une instance de TImageOnViewPlugin
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du plugin
*}
constructor TImageOnViewPlugin.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;

  FPainter := TPainter.Create(Master.ImagesMaster);
  FPainter.BeginUpdate;

  FPosOnView := TImagePos.Create;
  FPosOnImage := TImagePos.Create;
end;

{*
  [@inheritDoc]
*}
destructor TImageOnViewPlugin.Destroy;
begin
  FPosOnImage.Free;
  FPosOnView.Free;

  FPainter.Free;

  inherited;
end;

{*
  [@inheritDoc]
*}
procedure TImageOnViewPlugin.AfterConstruction;
begin
  inherited;

  FPainter.EndUpdate;
end;

{*
  [@inheritDoc]
*}
procedure TImageOnViewPlugin.DrawView(Context: TDrawViewContext);
var
  ViewPoint, ImagePoint: TPoint;
begin
  ViewPoint := PosOnView.GetPoint(Context.ViewRect);
  ImagePoint := PosOnImage.GetPoint(Painter.Size);

  Painter.DrawAtTimeTo(Context.TickCount, Context.Bitmap,
    ViewPoint.X - ImagePoint.X, ViewPoint.Y - ImagePoint.Y);
end;

end.
