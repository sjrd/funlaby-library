unit PlayerMapMarkers;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools, KeyStrokes;

const
  idPlayerMapMarkersPlugin = 'PlayerMapMarkersPlugin';

type
  TPlayerMapMarkersPlugin = class;

  {*
    Type d'un marqueur plaçable par le joueur
    @author sjrd
    @version 5.0
  *}
  TPlayerMapMarkerType = class(TFunLabyPersistent)
  private
    FMaster: TMaster; /// Maître FunLabyrinthe

    FPainter: TPainter;     /// Peintre pour les marqueurs de ce type
    FKeyStroke: TKeyStroke; /// Touche qui active ce type de marqueur
  public
    constructor Create(AMaster: TMaster); virtual;
    destructor Destroy; override;

    property Master: TMaster read FMaster;
  published
    property Painter: TPainter read FPainter;
    property KeyStroke: TKeyStroke read FKeyStroke;
  end;

  TPlayerMapMarkerTypeClass = class of TPlayerMapMarkerType;

  {*
    Collection de types de marqueurs plaçables par le joueur
    @author sjrd
    @version 5.0
  *}
  TPlayerMapMarkerTypeCollection = class(TFunLabyCollection)
  private
    FMaster: TMaster; /// Maître FunLabyrinthe
  protected
    function CreateItem(ItemClass: TFunLabyPersistentClass):
      TFunLabyPersistent; override;

    function GetDefaultItemClass: TFunLabyPersistentClass; override;
  public
    constructor Create(AMaster: TMaster);

    property Master: TMaster read FMaster;
  end;

  {*
    Marqueur plaçable par le joueur
    @author sjrd
    @version 5.0
  *}
  TPlayerMapMarker = class(TFunLabyPersistent)
  private
    FMarkersPlugin: TPlayerMapMarkersPlugin; /// Plugin propriétaire

    FQPos: TQualifiedPos;              /// Position qualifiée
    FMarkerType: TPlayerMapMarkerType; /// Type de marqueur

    FTypeIndex: Integer; /// Index du type de marqueur (pour DefineProps)

    function GetMarkerTypeIndex: Integer;
    procedure SetMarkerTypeIndex(Value: Integer);
  protected
    procedure DefineProperties(Filer: TFunLabyFiler); override;

    property MarkersPlugin: TPlayerMapMarkersPlugin read FMarkersPlugin;
  public
    constructor Create(AMarkersPlugin: TPlayerMapMarkersPlugin); virtual;

    procedure Draw(Context: TDrawSquareContext);

    property QPos: TQualifiedPos read FQPos write FQPos;
    property MarkerType: TPlayerMapMarkerType
      read FMarkerType write FMarkerType;
  end;

  TPlayerMapMarkerClass = class of TPlayerMapMarker;

  {*
    Collection de marqueurs plaçables par le joueur
    @author sjrd
    @version 5.0
  *}
  TPlayerMapMarkerCollection = class(TFunLabyCollection)
  private
    FMarkersPlugin: TPlayerMapMarkersPlugin; /// Plugin propriétaire
  protected
    function CreateItem(ItemClass: TFunLabyPersistentClass):
      TFunLabyPersistent; override;

    function GetDefaultItemClass: TFunLabyPersistentClass; override;

    property MarkersPlugin: TPlayerMapMarkersPlugin read FMarkersPlugin;
  public
    constructor Create(AMarkersPlugin: TPlayerMapMarkersPlugin);

    function FindMarkerAt(const QPos: TQualifiedPos): TPlayerMapMarker;
  end;

  {*
    Données par joueur pour TPlayerMapMarkersPlugin
    @author sjrd
    @version 5.0
  *}
  TPlayerMapMarkersPluginPlayerData = class(TPlayerData)
  private
    FMarkers: TPlayerMapMarkerCollection; /// Marqueurs placés par ce joueur
  protected
    procedure DefineProperties(Filer: TFunLabyFiler); override;
  public
    constructor Create(AComponent: TFunLabyComponent;
      APlayer: TPlayer); override;
    destructor Destroy; override;

    property Markers: TPlayerMapMarkerCollection read FMarkers;
  end;

  {*
    Plugin pour que le joueur puisse placer des marqueurs sur la carte
    @author sjrd
    @version 5.0
  *}
  TPlayerMapMarkersPlugin = class(TPlugin)
  private
    FMarkerTypes: TPlayerMapMarkerTypeCollection; /// Types de marqueurs

    FClearKeyStroke: TKeyStroke; /// Touche d'effacement
  protected
    class function GetPlayerDataClass: TPlayerDataClass; override;

    function GetMarkers(Player: TPlayer): TPlayerMapMarkerCollection;
    function FindMarkerTypeFor(Context: TKeyEventContext;
      out MarkerType: TPlayerMapMarkerType): Boolean;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
    destructor Destroy; override;

    procedure DrawView(Context: TDrawViewContext); override;
    procedure PressKey(Context: TKeyEventContext); override;
  published
    property MarkerTypes: TPlayerMapMarkerTypeCollection read FMarkerTypes;

    property ClearKeyStroke: TKeyStroke read FClearKeyStroke;
  end;

var { FunDelphi codegen }
  compPlayerMapMarkersPlugin: TPlayerMapMarkersPlugin;

implementation

procedure InitializeUnit(Master: TMaster; Params: TStrings);
begin
  FunLabyRegisterClass(TPlayerMapMarkerType);
  FunLabyRegisterClass(TPlayerMapMarker);

  TPlayerMapMarkersPlugin.Create(Master, idPlayerMapMarkersPlugin);
end;

procedure Unloading;
begin
  FunLabyUnregisterClass(TPlayerMapMarkerType);
  FunLabyUnregisterClass(TPlayerMapMarker);
end;

{ TPlayerMapMarkerType class }

constructor TPlayerMapMarkerType.Create(AMaster: TMaster);
begin
  inherited Create;

  FMaster := AMaster;

  FPainter := TPainter.Create(FMaster.ImagesMaster);
  FKeyStroke := TKeyStroke.Create;
end;

destructor TPlayerMapMarkerType.Destroy;
begin
  FKeyStroke.Free;
  FPainter.Free;

  inherited;
end;

{ TPlayerMapMarkerTypeCollection class }

constructor TPlayerMapMarkerTypeCollection.Create(AMaster: TMaster);
begin
  inherited Create;

  FMaster := AMaster;
end;

{*
  [@inheritDoc]
*}
function TPlayerMapMarkerTypeCollection.CreateItem(
  ItemClass: TFunLabyPersistentClass): TFunLabyPersistent;
begin
  Result := TPlayerMapMarkerTypeClass(ItemClass).Create(Master);
end;

{*
  [@inheritDoc]
*}
function TPlayerMapMarkerTypeCollection.GetDefaultItemClass:
  TFunLabyPersistentClass;
begin
  Result := TPlayerMapMarkerType;
end;

{ TPlayerMapMarker class }

constructor TPlayerMapMarker.Create(AMarkersPlugin: TPlayerMapMarkersPlugin);
begin
  inherited Create;

  FMarkersPlugin := AMarkersPlugin;
end;

function TPlayerMapMarker.GetMarkerTypeIndex: Integer;
begin
  Result := MarkersPlugin.MarkerTypes.IndexOf(FMarkerType);
end;

procedure TPlayerMapMarker.SetMarkerTypeIndex(Value: Integer);
begin
  if (Value >= 0) and (Value < MarkersPlugin.MarkerTypes.Count) then
    FMarkerType := TPlayerMapMarkerType(MarkersPlugin.MarkerTypes[Value])
  else
    FMarkerType := nil;
end;

{*
  [@inheritDoc]
*}
procedure TPlayerMapMarker.DefineProperties(Filer: TFunLabyFiler);
var
  HasData: Boolean;
  IntegerInfo: PTypeInfo;
begin
  inherited;

  HasData := not IsNoQPos(QPos);

  Filer.DefineFieldProperty('Map', TypeInfo(TMap), @FQPos.Map, HasData);

  IntegerInfo := TypeInfo(Integer);

  Filer.DefineFieldProperty('Position.X', IntegerInfo,
    @FQPos.Position.X, HasData);
  Filer.DefineFieldProperty('Position.Y', IntegerInfo,
    @FQPos.Position.Y, HasData);
  Filer.DefineFieldProperty('Position.Z', IntegerInfo,
    @FQPos.Position.Z, HasData);

  FTypeIndex := GetMarkerTypeIndex;
  Filer.DefineFieldProperty('MarkerTypeIndex', IntegerInfo,
    @FTypeIndex, FTypeIndex >= 0);
  SetMarkerTypeIndex(FTypeIndex);
end;

{*
  [@inheritDoc]
*}
procedure TPlayerMapMarker.Draw(Context: TDrawSquareContext);
begin
  if MarkerType <> nil then
    MarkerType.Painter.Draw(Context);
end;

{ TPlayerMapMarkerCollection class }

constructor TPlayerMapMarkerCollection.Create(
  AMarkersPlugin: TPlayerMapMarkersPlugin);
begin
  inherited Create;

  FMarkersPlugin := AMarkersPlugin;
end;

{*
  [@inheritDoc]
*}
function TPlayerMapMarkerCollection.CreateItem(
  ItemClass: TFunLabyPersistentClass): TFunLabyPersistent;
begin
  Result := TPlayerMapMarkerClass(ItemClass).Create(MarkersPlugin);
end;

{*
  [@inheritDoc]
*}
function TPlayerMapMarkerCollection.GetDefaultItemClass:
  TFunLabyPersistentClass;
begin
  Result := TPlayerMapMarker;
end;

function TPlayerMapMarkerCollection.FindMarkerAt(
  const QPos: TQualifiedPos): TPlayerMapMarker;
var
  I: Integer;
begin
  for I := 0 to Count-1 do
  begin
    Result := TPlayerMapMarker(Items[I]);
    if (Result.QPos.Map = QPos.Map) and
      Same3DPoint(Result.QPos.Position, QPos.Position) then
      Exit;
  end;

  Result := nil;
end;

{ TPlayerMapMarkersPluginPlayerData class }

constructor TPlayerMapMarkersPluginPlayerData.Create(
  AComponent: TFunLabyComponent; APlayer: TPlayer);
begin
  inherited;

  FMarkers := TPlayerMapMarkerCollection.Create(
    Component as TPlayerMapMarkersPlugin);
end;

destructor TPlayerMapMarkersPluginPlayerData.Destroy;
begin
  FMarkers.Free;

  inherited;
end;

{*
  [@inheritDoc]
*}
procedure TPlayerMapMarkersPluginPlayerData.DefineProperties(
  Filer: TFunLabyFiler);
begin
  inherited;

  Filer.DefinePersistent('Markers', Markers);
end;

{ TPlayerMapMarkersPlugin class }

{*
  Crée une instance de TPlayerMapMarkersPlugin
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du plugin
*}
constructor TPlayerMapMarkersPlugin.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;

  FZIndex := 128;

  FMarkerTypes := TPlayerMapMarkerTypeCollection.Create(Master);

  FClearKeyStroke := TKeyStroke.Create;
  FClearKeyStroke.Key := Ord('C');
  FClearKeyStroke.Shift := [ssCtrl];
end;

{*
  [@inheritDoc]
*}
destructor TPlayerMapMarkersPlugin.Destroy;
begin
  FClearKeyStroke.Free;

  FMarkerTypes.Free;

  inherited;
end;

{*
  [@inheritDoc]
*}
class function TPlayerMapMarkersPlugin.GetPlayerDataClass: TPlayerDataClass;
begin
  Result := TPlayerMapMarkersPluginPlayerData;
end;

{*
  Récupère la liste de marqueurs associée à un joueur
  @param Player   Joueur pour lequel récupérer les marqueurs
  @return Liste de marqueurs associée au joueur spécifié
*}
function TPlayerMapMarkersPlugin.GetMarkers(
  Player: TPlayer): TPlayerMapMarkerCollection;
begin
  Result := TPlayerMapMarkersPluginPlayerData(GetPlayerData(Player)).Markers;
end;

function TPlayerMapMarkersPlugin.FindMarkerTypeFor(Context: TKeyEventContext;
  out MarkerType: TPlayerMapMarkerType): Boolean;
var
  I: Integer;
  AMarkerType: TPlayerMapMarkerType;
begin
  MarkerType := nil;

  Result := ClearKeyStroke.Matches(Context.Key, Context.Shift);
  if Result then
    Exit;

  for I := 0 to MarkerTypes.Count-1 do
  begin
    AMarkerType := TPlayerMapMarkerType(MarkerTypes[I]);
    Result := AMarkerType.KeyStroke.Matches(Context.Key, Context.Shift);

    if Result then
    begin
      MarkerType := AMarkerType;
      Exit;
    end;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TPlayerMapMarkersPlugin.DrawView(Context: TDrawViewContext);
var
  Markers: TPlayerMapMarkerCollection;
  I: Integer;
  Marker: TPlayerMapMarker;
  Position: T3DPoint;
  MarkerContext: TDrawSquareContext;
begin
  Markers := GetMarkers(Context.Player);

  for I := 0 to Markers.Count-1 do
  begin
    Marker := TPlayerMapMarker(Markers[I]);

    if not Context.IsSquareVisible(Marker.QPos) then
      Continue;

    Position := Marker.QPos.Position;

    MarkerContext := TDrawSquareContext.Create(Context.Bitmap,
      (Position.X-Context.Zone.Left) * SquareSize,
      (Position.Y-Context.Zone.Top) * SquareSize);
    try
      MarkerContext.SetDrawViewContext(Context);
      Marker.Draw(MarkerContext);
    finally
      MarkerContext.Free;
    end;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TPlayerMapMarkersPlugin.PressKey(Context: TKeyEventContext);
var
  MarkerType: TPlayerMapMarkerType;
  Markers: TPlayerMapMarkerCollection;
  Marker: TPlayerMapMarker;
begin
  if not FindMarkerTypeFor(Context, MarkerType) then
    Exit;

  with Context do
  begin
    Markers := GetMarkers(Player);

    Marker := Markers.FindMarkerAt(Player.QPos);
    if Marker <> nil then
      Markers.Remove(Marker);

    if MarkerType <> nil then
    begin
      Marker := TPlayerMapMarker(Markers.AddDefault);
      Marker.QPos := Player.QPos;
      Marker.MarkerType := MarkerType;
    end;

    Handled := True;
  end;
end;

end.
