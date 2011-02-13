unit GraphicsToolsEx;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools;

procedure CleanRectAlpha(Bitmap: TBitmap32; const Rect: TRect;
  Alpha: Integer = $FF); deprecated 'Use GraphicsTools.CleanRectAlpha instead';

implementation

{*
  Voir GraphicsTools.CleanRectAlpha
*}
procedure CleanRectAlpha(Bitmap: TBitmap32; const Rect: TRect;
  Alpha: Integer = $FF);
begin
  GraphicsTools.CleanRectAlpha(Bitmap, Rect, Alpha);
end;

end.
