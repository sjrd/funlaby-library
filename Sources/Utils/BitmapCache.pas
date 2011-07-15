unit BitmapCache;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools;

type
  TCustomBitmapCache = class(TObject)
  private
    FCache: TBucketList;
    FLock: TMultiReadExclusiveWriteSynchronizer;

    function GetBitmaps(Data: Pointer): TBitmap32;
  protected
    procedure InitializeBitmap(Bitmap: TBitmap32;
      Data: Pointer); virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;

    property Bitmaps[Data: Pointer]: TBitmap32 read GetBitmaps; default;
  end;

implementation

constructor TCustomBitmapCache.Create;
begin
  inherited;

  FCache := TBucketList.Create;
  FLock := TMultiReadExclusiveWriteSynchronizer.Create;
end;

destructor TCustomBitmapCache.Destroy;
begin
  FLock.Free;
  FCache.Free;

  inherited;
end;

function TCustomBitmapCache.GetBitmaps(Data: Pointer): TBitmap32;
var
  Modified: Boolean;
begin
  FLock.BeginRead;
  try
    if not FCache.Find(Data, Pointer(Result)) then
    begin
      Modified := FLock.BeginWrite;
      try
        if not (Modified and FCache.Find(Data, Pointer(Result))) then
        begin
          Result := TBitmap32.Create;
          try
            InitializeBitmap(Result, Data);
            FCache.Add(Data, Pointer(Result));
          except
            Result.Free;
            raise;
          end;
        end;
      finally
        FLock.EndWrite;
      end;
    end;
  finally
    FLock.EndRead;
  end;
end;

end.
