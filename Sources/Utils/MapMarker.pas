unit MapMarker;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools;

resourcestring
  SCategoryMapMarkers = 'Marqueurs';

  SDefaultMapMarkerName = 'Marqueur';
  SMapMarkerCreatorHint = 'Créer un nouveau marqueur';

const
  idMapMarkerCreator = 'MarkerCreator';
  fMapMarker = 'Markers/YellowFlag';
  fCreator = 'Creators/Creator';

type
  {*
    Marqueur à mettre sur une carte pour identifier une position
    @author sjrd
    @version 5.0
  *}
  TMapMarker = class(TPosComponent)
  private
    function GetSquare: TSquare;
    function GetField: TField;
    function GetEffect: TEffect;
    function GetTool: TTool;
    function GetObstacle: TObstacle;

    procedure SetSquare(Value: TSquare);
    procedure SetField(Value: TField);
    procedure SetEffect(Value: TEffect);
    procedure SetTool(Value: TTool);
    procedure SetObstacle(Value: TObstacle);
  protected
    function GetCategory: string; override;

    procedure DoDraw(Context: TDrawSquareContext); override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;

    property Square: TSquare read GetSquare write SetSquare;
    property Field: TField read GetField write SetField;
    property Effect: TEffect read GetEffect write SetEffect;
    property Tool: TTool read GetTool write SetTool;
    property Obstacle: TObstacle read GetObstacle write SetObstacle;
  end;

  {*
    Créateur de téléporteurs invisibles
    @author sjrd
    @version 5.0
  *}
  TMapMarkerCreator = class(TComponentCreator)
  protected
    function GetCategory: string; override;
    function GetHint: string; override;

    function GetComponentClass: TFunLabyComponentClass; override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
  end;

var { FunDelphi codegen }
  compMapMarkerCreator: TMapMarkerCreator;

implementation

procedure InitializeUnit(Master: TMaster; Params: TStrings);
begin
  TMapMarkerCreator.Create(Master, idMapMarkerCreator);
end;

{ TMapMarker }

constructor TMapMarker.Create(AMaster: TMaster; const AID: TComponentID);
begin
  inherited;

  Name := SDefaultMapMarkerName;

  Painter.AddImage(fMapMarker);
end;

function TMapMarker.GetSquare: TSquare;
begin
  Result := Map[Position];
end;

function TMapMarker.GetField: TField;
begin
  Result := Map[Position].Field;
end;

function TMapMarker.GetEffect: TEffect;
begin
  Result := Map[Position].Effect;
end;

function TMapMarker.GetTool: TTool;
begin
  Result := Map[Position].Tool;
end;

function TMapMarker.GetObstacle: TObstacle;
begin
  Result := Map[Position].Obstacle;
end;

procedure TMapMarker.SetSquare(Value: TSquare);
begin
  Map[Position] := Value;
end;

procedure TMapMarker.SetField(Value: TField);
begin
  Square := ChangeField(Square, Value);
end;

procedure TMapMarker.SetEffect(Value: TEffect);
begin
  Square := ChangeEffect(Square, Value);
end;

procedure TMapMarker.SetTool(Value: TTool);
begin
  Square := ChangeTool(Square, Value);
end;

procedure TMapMarker.SetObstacle(Value: TObstacle);
begin
  Square := ChangeObstacle(Square, Value);
end;

{*
  [@inheritDoc]
*}
function TMapMarker.GetCategory: string;
begin
  Result := SCategoryMapMarkers;
end;

{*
  [@inheritDoc]
*}
procedure TMapMarker.DoDraw(Context: TDrawSquareContext);
begin
  if Master.Editing then
    inherited;
end;

{ TMapMarkerCreator }

constructor TMapMarkerCreator.Create(AMaster: TMaster; const AID: TComponentID);
begin
  inherited;

  IconPainter.AddImage(fMapMarker);
  IconPainter.AddImage(fCreator);
end;

{*
  [@inheritDoc]
*}
function TMapMarkerCreator.GetCategory: string;
begin
  Result := SCategoryMapMarkers;
end;

{*
  [@inheritDoc]
*}
function TMapMarkerCreator.GetHint: string;
begin
  Result := SMapMarkerCreatorHint;
end;

{*
  [@inheritDoc]
*}
function TMapMarkerCreator.GetComponentClass: TFunLabyComponentClass;
begin
  Result := TMapMarker;
end;

end.
