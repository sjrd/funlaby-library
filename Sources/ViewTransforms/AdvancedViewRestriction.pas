unit AdvancedViewRestriction;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyGraphics, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools, BitmapCache;

const
  msgEmitLight = $46;

  idAdvViewRestrictionPlugin = 'AdvViewRestrictionPlugin';

type
  TEmitLightMessage = record
    SimpleMsg: TPlayerMessage;
    Context: TDrawViewContext;
    ViewMask: TBitmap32;
    LightPos: TPoint;
  end;

  TAdvViewRestrictionPluginPlayerData = class(TPlayerData)
  private
    FViewMask: TBitmap32;
  public
    constructor Create(AComponent: TFunLabyComponent;
      APlayer: TPlayer); override;
    destructor Destroy; override;

    property ViewMask: TBitmap32 read FViewMask;
  end;

  TAdvViewRestrictionPlugin = class(TPlugin)
  protected
    class function GetPlayerDataClass: TPlayerDataClass; override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID);

    procedure DrawView(Context: TDrawViewContext); override;
  end;

var { FunDelphi codegen }
  compAdvViewRestrictionPlugin: TAdvViewRestrictionPlugin;

var
  LightCombine: TPixelCombineEvent;
  CircleLightCache: TCustomBitmapCache;

implementation

procedure LightCombineProc(Self: TObject; F: TColor32; var B: TColor32;
  M: TColor32);
begin
  B := MultiplyComponents(F, B);
end;

procedure InitializeUnit(Master: TMaster);
var
  Proc: procedure(Self: TObject; F: TColor32; var B: TColor32; M: TColor32);
begin
  Proc := LightCombineProc;
  LightCombine := TPixelCombineEvent(MakeMethod(Pointer(Proc)));

  TAdvViewRestrictionPlugin.Create(Master, idAdvViewRestrictionPlugin);
end;

{ TAdvViewRestrictionPluginPlayerData }

constructor TAdvViewRestrictionPluginPlayerData.Create(
  AComponent: TFunLabyComponent; APlayer: TPlayer);
begin
  inherited;

  FViewMask := TBitmap32.Create;
  FViewMask.DrawMode := dmBlend;
end;

destructor TAdvViewRestrictionPluginPlayerData.Destroy;
begin
  FViewMask.Free;

  inherited;
end;

{ TAdvViewRestrictionPlugin }

constructor TAdvViewRestrictionPlugin.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;

  FZIndex := 512;
end;

class function TAdvViewRestrictionPlugin.GetPlayerDataClass: TPlayerDataClass;
begin
  Result := TAdvViewRestrictionPluginPlayerData;
end;

procedure TAdvViewRestrictionPlugin.DrawView(Context: TDrawViewContext);
var
  Player: TPlayer;
  Zone: TRect;
  ViewWidth, ViewHeight: Integer;
  PlayerData: TAdvViewRestrictionPluginPlayerData;
  ViewMask: TBitmap32;
  EmitLightMsg: TEmitLightMessage;
  I: Integer;
  PosComp: TPosComponent;
begin
  Player := Context.Player;
  Zone := Context.Zone;
  ViewWidth := Player.Mode.Width;
  ViewHeight := Player.Mode.Height;

  PlayerData := TAdvViewRestrictionPluginPlayerData(GetPlayerData(Player));
  ViewMask := PlayerData.ViewMask;

  ViewMask.SetSize(ViewWidth, ViewHeight);
  ViewMask.Clear(clBlack32);

  EmitLightMsg.SimpleMsg.MsgID := msgEmitLight;
  EmitLightMsg.Context := Context;
  EmitLightMsg.ViewMask := ViewMask;

  for I := 0 to Master.PosComponentCount-1 do
  begin
    PosComp := Master.PosComponents[I];
    if PosComp.Map = Context.Map then
    begin
      EmitLightMsg.LightPos.X :=
        (PosComp.Position.X-Zone.Left) * SquareSize + HalfSquareSize;
      EmitLightMsg.LightPos.Y :=
        (PosComp.Position.Y-Zone.Top) * SquareSize + HalfSquareSize;

      PosComp.Dispatch(EmitLightMsg);
    end;
  end;

  Context.Bitmap.Draw(0, 0, ViewMask);
end;

end.
