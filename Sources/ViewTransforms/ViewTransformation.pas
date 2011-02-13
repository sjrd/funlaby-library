unit ViewTransformation;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools,
  GR32_Transforms;

type
  {*
    Classe de base pour les plugins appliquant une transformation à la vue
    @author sjrd
    @version 5.0
  *}
  TCustomViewTransformationPlugin = class(TPlugin)
  private
    FTransformation: TTransformation; /// Transformation à appliquer

    procedure SetTransformation(ATransformation: TTransformation);
  protected
    property Transformation: TTransformation
      read FTransformation write SetTransformation;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
    destructor Destroy; override;

    procedure DrawView(Context: TDrawViewContext); override;
  end;

  {*
    Plugin appliquant une transformation à la vue
    @author sjrd
    @version 5.0
  *}
  TViewTransformationPlugin = class(TCustomViewTransformationPlugin)
  public
    property Transformation;
  end;

implementation

{ TCustomViewTransformationPlugin class }

constructor TCustomViewTransformationPlugin.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;

  FZIndex := 768;
end;

destructor TCustomViewTransformationPlugin.Destroy;
begin
  FTransformation.Free;

  inherited;
end;

procedure TCustomViewTransformationPlugin.SetTransformation(
  ATransformation: TTransformation);
begin
  if ATransformation <> FTransformation then
  begin
    FreeAndNil(FTransformation);
    FTransformation := ATransformation;
  end;
end;

procedure TCustomViewTransformationPlugin.DrawView(Context: TDrawViewContext);
var
  TempBitmap: TBitmap32;
begin
  if Transformation = nil then
    Exit;

  TempBitmap := TBitmap32.Create;
  try
    TempBitmap.Assign(Context.Bitmap);
    Context.Bitmap.Clear;
    Transformation.SrcRect := FloatRect(Context.ViewRect);
    Transform(Context.Bitmap, TempBitmap, Transformation);
  finally
    TempBitmap.Free;
  end;
end;

end.
