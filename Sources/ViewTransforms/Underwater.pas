unit Underwater;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, Math, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools,
  GR32_Transforms, GR32_Math, GR32_LowLevel, ViewTransformation,
  GExtUnderwaterTransform;

const
  idUnderwaterPlugin = 'UnderwaterPlugin';

type
  {*
    Plugin qui rend une vue du style sous eau
    @author sjrd
  *}
  TUnderwaterPlugin = class(TCustomViewTransformationPlugin)
  private
    FTransformation: TUnderwaterTransformation; /// Transformation
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;

    procedure DrawView(Context: TDrawViewContext); override;
  end;

var { FunDelphi codegen }
  compUnderwaterPlugin: TUnderwaterPlugin;

const
  clUnderwater32 = TColor32($800050D0);

implementation

procedure InitializeUnit(Master: TMaster);
begin
  TUnderwaterPlugin.Create(Master, idUnderwaterPlugin);
end;

{ TUnderwaterPlugin class }

constructor TUnderwaterPlugin.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;

  FTransformation := TUnderwaterTransformation.Create;
  Transformation := FTransformation;
end;

procedure TUnderwaterPlugin.DrawView(Context: TDrawViewContext);
begin
  with Context.Bitmap do
    FillRectTS(ClipRect, clUnderwater32);

  FTransformation.TickCount := Context.TickCount;

  inherited;
end;

end.
