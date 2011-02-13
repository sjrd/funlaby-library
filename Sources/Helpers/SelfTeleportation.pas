unit SelfTeleportation;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools, KeyStrokes;

const
  idSelfTeleportationPlugin = 'SelfTeleportationPlugin';

type
  {*
    Destination d'une auto-téléportation
    @author sjrd
    @version 5.0
  *}
  TSelfTeleportationDest = class(TFunLabyPersistent)
  private
    FKeyStroke: TKeyStroke; /// Touche qui active cette destination
    FEnabled: Boolean;      /// Indique si cette destination est active

    FDestination: TPosComponent; /// Marqueur de la destination
  public
    constructor Create; virtual;
    destructor Destroy; override;
  published
    property KeyStroke: TKeyStroke read FKeyStroke;
    property Enabled: Boolean read FEnabled write FEnabled default True;

    property Destination: TPosComponent read FDestination write FDestination;
  end;

  TSelfTeleportationDestClass = class of TSelfTeleportationDest;

  {*
    Collection de destinations d'auto-téléportation
    @author sjrd
    @version 5.0
  *}
  TSelfTeleportationDestCollection = class(TFunLabyCollection)
  protected
    function CreateItem(ItemClass: TFunLabyPersistentClass):
      TFunLabyPersistent; override;

    function GetDefaultItemClass: TFunLabyPersistentClass; override;
  end;

  {*
    Plugin permettant au joueur de s'auto-téléporter à certains endroits
    @author sjrd
    @version 5.0
  *}
  TSelfTeleportationPlugin = class(TPlugin)
  private
    FDestinations: TSelfTeleportationDestCollection; /// Destinations
  protected
    function FindDestinationFor(Context: TKeyEventContext;
      out Destination: TSelfTeleportationDest): Boolean;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
    destructor Destroy; override;

    procedure PressKey(Context: TKeyEventContext); override;
  published
    property Destinations: TSelfTeleportationDestCollection read FDestinations;
  end;

var { FunDelphi codegen }
  compSelfTeleportationPlugin: TSelfTeleportationPlugin;

implementation

procedure InitializeUnit(Master: TMaster; Params: TStrings);
begin
  FunLabyRegisterClass(TSelfTeleportationDest);

  TSelfTeleportationPlugin.Create(Master, idSelfTeleportationPlugin);
end;

procedure Unloading;
begin
  FunLabyUnregisterClass(TSelfTeleportationDest);
end;

{ TSelfTeleportationDest class }

constructor TSelfTeleportationDest.Create;
begin
  inherited Create;

  FKeyStroke := TKeyStroke.Create;
  FEnabled := True;
end;

destructor TSelfTeleportationDest.Destroy;
begin
  FKeyStroke.Free;

  inherited;
end;

{ TSelfTeleportationDestCollection class }

{*
  [@inheritDoc]
*}
function TSelfTeleportationDestCollection.CreateItem(
  ItemClass: TFunLabyPersistentClass): TFunLabyPersistent;
begin
  Result := TSelfTeleportationDestClass(ItemClass).Create;
end;

{*
  [@inheritDoc]
*}
function TSelfTeleportationDestCollection.GetDefaultItemClass:
  TFunLabyPersistentClass;
begin
  Result := TSelfTeleportationDest;
end;

{ TSelfTeleportationPlugin class }

{*
  Crée une instance de TSelfTeleportationPlugin
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du plugin
*}
constructor TSelfTeleportationPlugin.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;

  FZIndex := 128;

  FDestinations := TSelfTeleportationDestCollection.Create;
end;

{*
  [@inheritDoc]
*}
destructor TSelfTeleportationPlugin.Destroy;
begin
  FDestinations.Free;

  inherited;
end;

function TSelfTeleportationPlugin.FindDestinationFor(Context: TKeyEventContext;
  out Destination: TSelfTeleportationDest): Boolean;
var
  I: Integer;
  ADestination: TSelfTeleportationDest;
begin
  for I := 0 to Destinations.Count-1 do
  begin
    ADestination := TSelfTeleportationDest(Destinations[I]);

    Result := ADestination.Enabled and
      ADestination.KeyStroke.Matches(Context.Key, Context.Shift);

    if Result then
    begin
      Destination := ADestination;
      Exit;
    end;
  end;

  Result := False;
  Destination := nil;
end;

{*
  [@inheritDoc]
*}
procedure TSelfTeleportationPlugin.PressKey(Context: TKeyEventContext);
var
  Destination: TSelfTeleportationDest;
  DestPos: TPosComponent;
begin
  if not FindDestinationFor(Context, Destination) then
    Exit;

  DestPos := Destination.Destination;
  if (DestPos <> nil) and (DestPos.Map <> nil) then
    Context.Player.MoveTo(DestPos.QPos);

  Context.Handled := True;
end;

end.
