unit MapZones;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, ScStrUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools;

const
  idZoneEventsPlugin = 'ZoneEventsPlugin';

type
  {*
    Coordonnées d'une zone dans un espace en 3 dimensions
    @author sjrd
  *}
  T3DZone = record
    Floor: Integer;
    case Integer of
      0: (ZoneRect: TRect);
      1: (Left, Top, Right, Bottom: Integer);
  end;

  {*
    Coordonnées qualifiées d'une zone dans un espace en 3 dimensions
    @author sjrd
  *}
  TQualifiedZone = record
    Map: TMap;
    case Integer of
      0: (Zone: T3DZone);
      1: (
        Floor: Integer;
        case Integer of
          0: (ZoneRect: TRect);
          1: (Left, Top, Right, Bottom: Integer);
        );
  end;

  {*
    Événements d'une zone
    Les zones peuvent réagir à différents événements qui les concernent.
    Actuellement, elles peuvent réagir à l'entrée et à la sortie d'un joueur.
    @author sjrd
  *}
  TZoneEvents = class(TFunLabyComponent)
  private
    FQZone: TQualifiedZone; /// Zone qualifiée

    FStrQZone: string; /// Pour DefineProperties

    function GetStrQZone: string;
    procedure SetStrQZone(const Value: string);
  protected
    procedure DefineProperties(Filer: TFunLabyFiler); override;

    procedure ChangePosition(const AQZone: TQualifiedZone); virtual;

    procedure SetAsMapZone(Map: TMap; const ZoneIndex: T3DPoint); overload;
    procedure SetAsMapZone(const QPos: TQualifiedPos); overload;
    procedure SetAsMapZone(PosComponent: TPosComponent); overload;

    procedure SetupZone; virtual;
  public
    procedure Entered(Context: TMoveContext); virtual;
    procedure Exited(Context: TMoveContext); virtual;

    function IsInZone(const Pos: T3DPoint): Boolean; overload;
    function IsInZone(const QPos: TQualifiedPos): Boolean; overload;

    property QZone: TQualifiedZone read FQZone;
    property Map: TMap read FQZone.Map;
    property Zone: T3DZone read FQZone.Zone;

    property Floor: Integer read FQZone.Floor;
    property ZoneRect: TRect read FQZone.ZoneRect;
  end;

  {*
    Plugin gérant les événements de zone sur les joueurs
    Ce plugin est attaché automatiquement à tous les joueurs en cas de besoin.
    @author sjrd
  *}
  TZoneEventsPlugin = class(TPlugin)
  private
    FZoneEventsList: TObjectList; /// Liste des zone-events

    procedure Initialize;
    procedure DoGameStarted;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
    destructor Destroy; override;

    procedure Moved(Context: TMoveContext); override;
  end;

const
  NoQZone: TQualifiedZone = (
    Map: nil; Floor: 0; Left: 0; Top: 0; Right: 0; Bottom: 0
  );

function IsInZone(const Pos: T3DPoint;
  const Zone: T3DZone): Boolean; overload;
function IsInZone(const QPos: TQualifiedPos;
  const QZone: TQualifiedZone): Boolean; overload;

function SameZone(const Left, Right: T3DZone): Boolean; overload;
function SameZone(const Left, Right: TQualifiedZone): Boolean; overload;

function MakeMapZone(Map: TMap; const ZoneIndex: T3DPoint): TQualifiedZone;

function PosToZoneIndex(const QPos: TQualifiedPos): T3DPoint; overload;
function PosToZoneIndex(Map: TMap; const Pos: T3DPoint): T3DPoint; overload;

function PosToMapZone(const QPos: TQualifiedPos): TQualifiedZone; overload;
function PosToMapZone(Map: TMap; const Pos: T3DPoint): T3DZone; overload;

var { FunDelphi codegen }
  compZoneEventsPlugin: TZoneEventsPlugin;

implementation

procedure InitializeUnit(Master: TMaster);
begin
  TZoneEventsPlugin.Create(Master, idZoneEventsPlugin);
end;

procedure Loaded(Master: TMaster);
begin
  TZoneEventsPlugin(Master.Plugin[idZoneEventsPlugin]).Initialize;
end;

procedure GameStarted(Master: TMaster);
begin
  TZoneEventsPlugin(Master.Plugin[idZoneEventsPlugin]).DoGameStarted;
end;

{-----------------}
{ Global routines }
{-----------------}

function IsInZone(const Pos: T3DPoint; const Zone: T3DZone): Boolean;
begin
  Result := (Pos.Z = Zone.Floor) and
    PtInRect(Zone.ZoneRect, Point(Pos.X, Pos.Y));
end;

function IsInZone(const QPos: TQualifiedPos;
  const QZone: TQualifiedZone): Boolean;
begin
  Result := (QPos.Map = QZone.Map) and IsInZone(QPos.Position, QZone.Zone);
end;

function SameZone(const Left, Right: T3DZone): Boolean;
begin
  Result := (Left.Floor = Right.Floor) and
    SameRect(Left.ZoneRect, Right.ZoneRect);
end;

function SameZone(const Left, Right: TQualifiedZone): Boolean;
begin
  Result := (Left.Map = Right.Map) and SameZone(Left.Zone, Right.Zone);
end;

function MakeMapZone(Map: TMap; const ZoneIndex: T3DPoint): TQualifiedZone;
begin
  Result.Map := Map;
  Result.Floor := ZoneIndex.Z;
  Result.Left := ZoneIndex.X * Map.ZoneWidth;
  Result.Top := ZoneIndex.Y * Map.ZoneHeight;
  Result.Right := Result.Left + Map.ZoneWidth;
  Result.Bottom := Result.Top + Map.ZoneHeight;
end;

function PosToZoneIndex(const QPos: TQualifiedPos): T3DPoint;
begin
  Result := PosToZoneIndex(QPos.Map, QPos.Position);
end;

function PosToZoneIndex(Map: TMap; const Pos: T3DPoint): T3DPoint;
begin
  Result.X := IntDiv(Pos.X, Map.ZoneWidth);
  Result.Y := IntDiv(Pos.Y, Map.ZoneHeight);
  Result.Z := Pos.Z;
end;

function PosToMapZone(const QPos: TQualifiedPos): TQualifiedZone;
begin
  Result := MakeMapZone(QPos.Map, PosToZoneIndex(QPos));
end;

function PosToMapZone(Map: TMap; const Pos: T3DPoint): T3DZone;
begin
  Result := MakeMapZone(Map, PosToZoneIndex(Map, Pos)).Zone;
end;

{-------------------}
{ TZoneEvents class }
{-------------------}

function TZoneEvents.GetStrQZone: string;
begin
  if Map = nil then
    Result := ''
  else
  begin
    with FQZone do
      Result := Format('%s;%d;%d;%d;%d;%d',
        [Map.ID, Floor, Left, Top, Right, Bottom]);
  end;
end;

procedure TZoneEvents.SetStrQZone(const Value: string);
var
  Parts: TStringDynArray;
begin
  if Value = '' then
    FQZone := NoQZone
  else
  begin
    Parts := SplitTokenAll(Value, ';');

    FQZone.Map := Master.Map[Parts[0]];
    FQZone.Floor := StrToIntDef(Parts[1], 0);
    FQZone.Left := StrToIntDef(Parts[2], 0);
    FQZone.Top := StrToIntDef(Parts[3], 0);
    FQZone.Right := StrToIntDef(Parts[4], 0);
    FQZone.Bottom := StrToIntDef(Parts[5], 0);
  end;
end;

procedure TZoneEvents.DefineProperties(Filer: TFunLabyFiler);
begin
  inherited;

  FStrQZone := GetStrQZone;
  Filer.DefineFieldProperty('QZone', TypeInfo(string),
    @FStrQZone, FStrQZone <> '');
  SetStrQZone(FStrQZone);
end;

procedure TZoneEvents.ChangePosition(const AQZone: TQualifiedZone);
begin
  FQZone := AQZone;
end;

procedure TZoneEvents.SetAsMapZone(Map: TMap; const ZoneIndex: T3DPoint);
begin
  ChangePosition(MakeMapZone(Map, ZoneIndex));
end;

procedure TZoneEvents.SetAsMapZone(const QPos: TQualifiedPos);
begin
  ChangePosition(PosToMapZone(QPos));
end;

procedure TZoneEvents.SetAsMapZone(PosComponent: TPosComponent);
begin
  SetAsMapZone(PosComponent.QPos);
end;

procedure TZoneEvents.SetupZone;
begin
end;

procedure TZoneEvents.Entered(Context: TMoveContext);
begin
end;

procedure TZoneEvents.Exited(Context: TMoveContext);
begin
end;

function TZoneEvents.IsInZone(const Pos: T3DPoint): Boolean;
begin
  Result := MapZones.IsInZone(Pos, Zone);
end;

function TZoneEvents.IsInZone(const QPos: TQualifiedPos): Boolean;
begin
  Result := MapZones.IsInZone(QPos, QZone);
end;

{-------------------------}
{ TZoneEventsPlugin class }
{-------------------------}

constructor TZoneEventsPlugin.Create(AMaster: TMaster; const AID: TComponentID);
begin
  inherited;

  FZoneEventsList := TObjectList.Create(False);
end;

destructor TZoneEventsPlugin.Destroy;
begin
  FZoneEventsList.Free;

  inherited;
end;

procedure TZoneEventsPlugin.Initialize;
var
  I: Integer;
begin
  for I := 0 to Master.ComponentCount-1 do
    if Master.Components[I] is TZoneEvents then
      FZoneEventsList.Add(Master.Components[I]);
end;

procedure TZoneEventsPlugin.DoGameStarted;
var
  I: Integer;
begin
  if FZoneEventsList.Count > 0 then
  begin
    for I := 0 to FZoneEventsList.Count-1 do
      TZoneEvents(FZoneEventsList[I]).SetupZone;

    for I := 0 to Master.PlayerCount-1 do
      Master.Players[I].AddPlugin(Self);
  end;
end;

procedure TZoneEventsPlugin.Moved(Context: TMoveContext);
var
  I: Integer;
  ZoneEvents: TZoneEvents;
begin
  // Exited
  for I := 0 to FZoneEventsList.Count-1 do
  begin
    ZoneEvents := TZoneEvents(FZoneEventsList[I]);

    if ZoneEvents.IsInZone(Context.SrcQPos) and
      (not ZoneEvents.IsInZone(Context.DestQPos)) then
    begin
      ZoneEvents.Exited(Context);
    end;
  end;

  // Entered
  for I := 0 to FZoneEventsList.Count-1 do
  begin
    ZoneEvents := TZoneEvents(FZoneEventsList[I]);

    if ZoneEvents.IsInZone(Context.DestQPos) and
      (not ZoneEvents.IsInZone(Context.SrcQPos)) then
    begin
      ZoneEvents.Entered(Context);
    end;
  end;
end;

end.
