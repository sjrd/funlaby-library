unit FloorLevelledGrounds;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, SdDialogs, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools, FLBFields,
  FLBCommon, ViewRestriction;

resourcestring
  SCategoryLevelledGrounds = 'Terrains à niveau';
  SCategoryTunnels = 'Tunnels';
  SCategoryBridges = 'Ponts';

  SFullField = 'Mur';
  SEmptyField = 'Vide';
  STunnel = 'Tunnel';
  SBridge = 'Pont';

  SFloorLevelledGroundCreatorHint = 'Créer un nouveau terrain à niveau';
  STunnelCreatorHint = 'Créer un nouveau tunnel';
  SBridgeCreatorHint = 'Créer un nouveau pont';

const {don't localize}
  idFullField = 'FullField';
  idEmptyField = 'EmptyField';

  idFloorLevelledGroundCreator = 'FloorLevelledGroundCreator';
  idTunnelCreator = 'TunnelCreator';
  idBridgeCreator = 'BridgeCreator';
  
  fFloorLevelledGroundCreator = 'Creators/LevelledGroundCreator';
  fTunnelCreator = 'Gates/Tunnel';
  
  actClimbLevelUp = 'ClimbLevelUp';
  actFallLevelDown = 'FallLevelDown';

type
  /// Ensemble de directions
  TDirections = set of TDirection;
  
  /// Noms de fichiers par direction
  TByDirFileNames = array[diNorth..diWest] of string;
  
const
  diAllDirections = [diNorth..diWest];
  TunnelBorderSize = 5;
  
  TunnelCenterRect: TRect = (
    Left: TunnelBorderSize; Top: TunnelBorderSize;
    Right: SquareSize - TunnelBorderSize; Bottom: SquareSize - TunnelBorderSize
  );
  
  TunnelOpeningRect: array[diNorth..diWest] of TRect = (
    (
      Left: TunnelBorderSize; Top: 0;
      Right: SquareSize-TunnelBorderSize; Bottom: TunnelBorderSize+1
    ),

    (
      Left: SquareSize-TunnelBorderSize-1; Top: TunnelBorderSize;
      Right: SquareSize; Bottom: SquareSize-TunnelBorderSize
    ),

    (
      Left: TunnelBorderSize; Top: SquareSize-TunnelBorderSize-1;
      Right: SquareSize-TunnelBorderSize; Bottom: SquareSize
    ),

    (
      Left: 0; Top: TunnelBorderSize;
      Right: TunnelBorderSize+1; Bottom: SquareSize-TunnelBorderSize
    )
  );
  
  fTunnelGateByDir: TByDirFileNames = (
    'Gates/TunnelNorth', 'Gates/TunnelEast', 'Gates/TunnelSouth',
    'Gates/TunnelWest'
  );
  
  fBridgeCenter = 'Bridges/BridgeCenter';
  fBridgeByDir: TByDirFileNames = (
    'Bridges/BridgeNorth', 'Bridges/BridgeEast', 'Bridges/BridgeSouth',
    'Bridges/BridgeWest'
  );

type
  {*
    Sol avec un niveau
    @author sjrd
    @version 5.0
  *}
  TFloorLevelledGround = class(TGround)
  private
    FLevel: Integer; /// Niveau

    procedure EditMapSquare(var Msg: TEditMapSquareMessage);
      message msgEditMapSquare;
  protected
    function GetCategory: string; override;
    
    procedure DoDrawCeiling(Context: TDrawSquareContext); override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
  published
    property Level: Integer read FLevel write FLevel default 0;
  end;
  
  {*
    Classe de base pour TFullField et TEmptyField
    @author sjrd
    @version 5.0
  *}
  TFullOrEmptyField = class(TField)
  private
    FAction: TPlayerAction; /// Action à tester pour changer d'étage

    procedure EditMapSquare(var Msg: TEditMapSquareMessage);
      message msgEditMapSquare;

    function FindDestSquare(Map: TMap; var Pos: T3DPoint): Boolean;
  protected
    function GetCategory: string; override;
    function GetIsDesignable: Boolean; override;

    procedure DoDraw(Context: TDrawSquareContext); override;
    procedure DoDrawCeiling(Context: TDrawSquareContext); override;

    procedure DoFindDestSquare(Map: TMap; var Pos: T3DPoint); virtual;
    procedure DrawDestSquare(Context, DestContext: TDrawSquareContext); virtual;
    procedure DoFailedAction(Context: TMoveContext); virtual;
    
    property Action: TPlayerAction read FAction write FAction;
  public
    procedure Entering(Context: TMoveContext); override;
  end;

  {*
    Terrain plein, qui montre le premier terrain au-dessus
    @author sjrd
    @version 5.0
  *}
  TFullField = class(TFullOrEmptyField)
  protected
    procedure DoFindDestSquare(Map: TMap; var Pos: T3DPoint); override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
  end;
  
  {*
    Terrain vide, à travers lequel on peut voir en-dessous et tomber
    @author sjrd
    @version 5.0
  *}
  TEmptyField = class(TFullOrEmptyField)
  private
    procedure PlankMessage(var Msg: TPlankMessage); message msgPlank;
  protected
    procedure DoFindDestSquare(Map: TMap; var Pos: T3DPoint); override;
    procedure DoFailedAction(Context: TMoveContext); override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
  end;
  
  {*
    Tunnel
    @author sjrd
    @version 5.0
  *}
  TTunnel = class(TFullField)
  private
    FOpenings: TDirections; /// Côtés où il y a une ouverture

    procedure EditMapSquare(var Msg: TEditMapSquareMessage);
      message msgEditMapSquare;

    function GetIsOpened(Dir: TDirection): Boolean;
    procedure SetIsOpened(Dir: TDirection; Value: Boolean);
  protected
    function GetCategory: string; override;
    function GetIsDesignable: Boolean; override;

    procedure DrawDestSquare(
      Context, DestContext: TDrawSquareContext); override;

    procedure GetDrawMode(Context: TDrawSquareContext;
      out DrawOpen, DrawGates: Boolean);

    procedure DoDraw(Context: TDrawSquareContext); override;
    procedure DoDrawCeiling(Context: TDrawSquareContext); override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;

    function IsActuallyOpened(const FromPos: TQualifiedPos;
      Dir: TDirection): Boolean;
    function IsGate(const FromPos: TQualifiedPos; Dir: TDirection): Boolean;

    procedure Entering(Context: TMoveContext); override;
    procedure Exiting(Context: TMoveContext); override;

    procedure Entered(Context: TMoveContext); override;
    procedure Exited(Context: TMoveContext); override;

    property IsOpened[Dir: TDirection]: Boolean
      read GetIsOpened write SetIsOpened;
  published
    property Openings: TDirections read FOpenings write FOpenings
      default diAllDirections;
  end;

  {*
    Pont
    @author sjrd
    @version 5.0
  *}
  TBridge = class(TField)
  private
    FOpenings: TDirections; /// Côtés où il y a une ouverture

    procedure EditMapSquare(var Msg: TEditMapSquareMessage);
      message msgEditMapSquare;

    function GetIsOpened(Dir: TDirection): Boolean;
    procedure SetIsOpened(Dir: TDirection; Value: Boolean);
  protected
    function GetCategory: string; override;

    procedure DoDraw(Context: TDrawSquareContext); override;

    procedure DoDrawBridge(Context: TDrawSquareContext); virtual;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;

    function IsActuallyOpened(const FromPos: TQualifiedPos;
      Dir: TDirection): Boolean;
      
    class procedure DrawBridgesAbove(Context: TDrawSquareContext);

    procedure Entering(Context: TMoveContext); override;
    procedure Exiting(Context: TMoveContext); override;

    property IsOpened[Dir: TDirection]: Boolean
      read GetIsOpened write SetIsOpened;
  published
    property Openings: TDirections read FOpenings write FOpenings
      default diAllDirections;
  end;

  {*
    Créateur de terrain avec un niveau
    @author sjrd
    @version 5.0
  *}
  TFloorLevelledGroundCreator = class(TComponentCreator)
  protected
    function GetCategory: string; override;
    function GetHint: string; override;

    function GetComponentClass: TFunLabyComponentClass; override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
  end;

  {*
    Créateur de tunnels
    @author sjrd
    @version 5.0
  *}
  TTunnelCreator = class(TComponentCreator)
  protected
    function GetCategory: string; override;
    function GetHint: string; override;

    function GetComponentClass: TFunLabyComponentClass; override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
  end;

  {*
    Créateur de ponts
    @author sjrd
    @version 5.0
  *}
  TBridgeCreator = class(TComponentCreator)
  protected
    function GetCategory: string; override;
    function GetHint: string; override;

    function GetComponentClass: TFunLabyComponentClass; override;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
  end;

var { FunDelphi codegen }
  compFullField: TFullField;
  compEmptyField: TEmptyField;
  
  compFloorLevelledGroundCreator: TFloorLevelledGroundCreator;
  compTunnelCreator: TTunnelCreator;
  compBridgeCreator: TBridgeCreator;

implementation

procedure InitializeUnit(Master: TMaster; Params: TStrings);
begin
  TFullField.Create(Master, idFullField);
  TEmptyField.Create(Master, idEmptyField);

  TFloorLevelledGroundCreator.Create(Master, idFloorLevelledGroundCreator);
  TTunnelCreator.Create(Master, idTunnelCreator);
  TBridgeCreator.Create(Master, idBridgeCreator);
end;

{----------------------------}
{ TFloorLevelledGround class }
{----------------------------}

constructor TFloorLevelledGround.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;
  
  Name := SGrass;
  Painter.AddImage(fGrass);

  FLevel := 0;
end;

{*
  Déclenché en édition lorsqu'une case est modifiée avec un terrain à niveau
  @param Msg   Message
*}
procedure TFloorLevelledGround.EditMapSquare(var Msg: TEditMapSquareMessage);
var
  Map: TMap;
  Pos: T3DPoint;
  IsInside: Boolean;
begin
  if Msg.Phase = espAdd then
  begin
    // Check outside
    Map := Msg.QPos.Map;
    Pos := Msg.QPos.Position;
    IsInside := Map.InMap(Pos);
    
    // Check for floor count
    if not Map.InFloors(Level) then
    begin
      ShowDialog('Erreur',
        'Cette carte ne comporte pas suffisamment d''étages pour ce terrain',
        dtError, dbOK, 1, 0);
      Msg.Flags := Msg.Flags + [esfCancel];
      Exit;
    end;

    // Place this field at the floor specified by Level
    Pos.Z := Level;
    Msg.QPos.Position.Z := Level;
    if IsInside then
      Map[Pos] := Master.SquareByComps(ID, '', '', '')
    else
      Map.Outside[Pos.Z] := Master.SquareByComps(ID, '', '', '');
    
    // Place full fields below
    Pos.Z := Level-1;
    while Map.InFloors(Pos) do
    begin
      if not (Map[Pos].Field is TFullField) then
      begin
        if IsInside then
          Map[Pos] := Master.SquareByComps(idFullField, '', '', '')
        else
          Map.Outside[Pos.Z] := Master.SquareByComps(idFullField, '', '', '');
      end;
      
      Pos.Z := Pos.Z-1;
    end;
    
    // Place empty fields above
    Pos.Z := Level+1;
    while Map.InFloors(Pos) do
    begin
      if not (Map[Pos].Field is TEmptyField) then
      begin
        if IsInside then
          Map[Pos] := Master.SquareByComps(idEmptyField, '', '', '')
        else
          Map.Outside[Pos.Z] := Master.SquareByComps(idEmptyField, '', '', '');
      end;

      Pos.Z := Pos.Z+1;
    end;
    
    // Mark message as handled
    Msg.Flags := Msg.Flags + [esfHandled];
  end;
end;

{*
  [@inheritDoc]
*}
function TFloorLevelledGround.GetCategory: string;
begin
  Result := SCategoryLevelledGrounds;
end;

{*
  [@inheritDoc]
*}
procedure TFloorLevelledGround.DoDrawCeiling(Context: TDrawSquareContext);
begin
  TBridge.DrawBridgesAbove(Context);
end;

{-------------------------}
{ TFullOrEmptyField class }
{-------------------------}

{*
  Déclenché en édition lorsqu'une case est modifiée avec un terrain à niveau
  @param Msg   Message
*}
procedure TFullOrEmptyField.EditMapSquare(var Msg: TEditMapSquareMessage);
var
  Other: T3DPoint;
begin
  if Msg.Phase in [espAdding, espRemoving] then
  begin
    Other := Msg.QPos.Position;

    if FindDestSquare(Msg.QPos.Map, Other) then
      Msg.QPos.Position := Other;
  end;
end;

{*
  Trouve la case de destination
  @param Map   Carte
  @param Pos   Position à modifier pour aller à la case de destination
  @return True en cas de succès, False si aucune case n'a pu être trouvée
*}
function TFullOrEmptyField.FindDestSquare(Map: TMap;
  var Pos: T3DPoint): Boolean;
var
  OrigPos: T3DPoint;
begin
  if Map = nil then
    Result := False
  else
  begin
    OrigPos := Pos;
    DoFindDestSquare(Map, Pos);
    Result := Map.InFloors(Pos) and (not Same3DPoint(Pos, OrigPos));
  end;
end;

{*
  [@inheritDoc]
*}
function TFullOrEmptyField.GetCategory: string;
begin
  Result := SCategoryLevelledGrounds;
end;

{*
  [@inheritDoc]
*}
function TFullOrEmptyField.GetIsDesignable: Boolean;
begin
  Result := False;
end;

{*
  [@inheritDoc]
*}
procedure TFullOrEmptyField.DoDraw(Context: TDrawSquareContext);
var
  OtherQPos: TQualifiedPos;
  OtherContext: TDrawSquareContext;
begin
  OtherQPos.Map := Context.Map;
  OtherQPos.Position := Context.Pos;

  if not FindDestSquare(OtherQPos.Map, OtherQPos.Position) then
  begin
    Context.Bitmap.FillRectS(Context.SquareRect, clBlack32);
    Exit;
  end;

  OtherContext := TDrawSquareContext.Create(Context, OtherQPos);
  try
    DrawDestSquare(Context, OtherContext);
  finally
    OtherContext.Free;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TFullOrEmptyField.DoDrawCeiling(Context: TDrawSquareContext);
begin
  TBridge.DrawBridgesAbove(Context);
end;

{*
  Trouve la case de destination
  @param Map   Carte
  @param Pos   Position à modifier pour aller à la case de destination
*}
procedure TFullOrEmptyField.DoFindDestSquare(Map: TMap; var Pos: T3DPoint);
begin
end;

{*
  Dessine la case destination
  @param   Context       Contexte de dessin du terrain vide ou plein
  @param   DestContext   Contexte de dessin de la case desination
*}
procedure TFullOrEmptyField.DrawDestSquare(
  Context, DestContext: TDrawSquareContext);
begin
  DestContext.Map[DestContext.Pos].Draw(DestContext);
end;

{*
  Déclenche le message d'erreur approprié suite à l'échec de l'action
*}
procedure TFullOrEmptyField.DoFailedAction(Context: TMoveContext);
begin
end;

{*
  [@inheritDoc]
*}
procedure TFullOrEmptyField.Entering(Context: TMoveContext);
var
  Map: TMap;
  Other, PlayerPos: T3DPoint;
  Height: Integer;
  Player: TPlayer;
  OtherContext: TMoveContext;
begin
  Map := Context.Map;
  Other := Context.Pos;
  Player := Context.Player;
  PlayerPos := Player.Position;

  if not FindDestSquare(Map, Other) then
  begin
    Context.Cancel;
    Exit;
  end;
  
  Height := Other.Z - Context.Pos.Z;
  if Height < 0 then
    Height := -Height;
    
  if not Player.DoAction(Action, Height) then
  begin
    DoFailedAction(Context);
    Context.Cancel;
    Exit;
  end;
  
  OtherContext := TMoveContext.Create(Player, Other, Context.Key,
    Context.Shift);
  try
    if not Player.IsMoveAllowed(OtherContext) then
    begin
      Context.Cancel;
      Exit;
    end;
    
    if Same3DPoint(Player.Position, PlayerPos) then
      Player.MoveTo(OtherContext, True);
      
    Context.GoOnMoving := OtherContext.GoOnMoving;
  finally
    OtherContext.Free;
  end;
end;

{------------------}
{ TFullField class }
{------------------}

{*
  Crée un terrain plein
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du terrain
  @param AName     Nom du terrain
*}
constructor TFullField.Create(AMaster: TMaster; const AID: TComponentID);
begin
  inherited;

  Name := SFullField;
  Action := actClimbLevelUp;
end;

{*
  [@inheritDoc]
*}
procedure TFullField.DoFindDestSquare(Map: TMap; var Pos: T3DPoint);
begin
  while Map.InFloors(Pos) and (Map[Pos].Field is TFullField) do
    Pos.Z := Pos.Z + 1;
end;

{-------------------}
{ TEmptyField class }
{-------------------}

{*
  Crée un terrain vide
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du terrain
  @param AName     Nom du terrain
*}
constructor TEmptyField.Create(AMaster: TMaster; const AID: TComponentID);
begin
  inherited;

  Name := SEmptyField;
  Action := actFallLevelDown;
end;

{*
  Gestionnaire de message msgPlank
  TLevelledGround permet d'y poser la planche pour autant que de l'autre côté,
  il y ait également un TLevelledGround de même niveau.
  Il permet de passer au-dessus si on part d'un TLevelledGround de niveau plus
  élevé.
  @param Msg   Message
*}
procedure TEmptyField.PlankMessage(var Msg: TPlankMessage);
var
  Map: TMap;
  Pos: T3DPoint;
begin
  if Msg.Kind <> pmkPassOver then
    Exit;

  Map := Msg.Player.Map;
  Pos := Msg.Pos;
  
  if Map[Pos].Obstacle <> nil then
    Exit;
  
  Pos.Z := Pos.Z - 1;
  
  if Map.InMap(Pos) and (Map[Pos].Obstacle <> nil) then
    Exit;
    
  Msg.Result := True;
end;

{*
  [@inheritDoc]
*}
procedure TEmptyField.DoFindDestSquare(Map: TMap; var Pos: T3DPoint);
begin
  while Map.InFloors(Pos) and (Map[Pos].Field is TEmptyField) do
    Pos.Z := Pos.Z - 1;
end;

{*
  [@inheritDoc]
*}
procedure TEmptyField.DoFailedAction(Context: TMoveContext);
begin
  if Context.KeyPressed then
    Context.Player.ShowMessage(
      'T''es pas fou ?! Tu ne voulais quand même pas sauter d''aussi haut !');
end;

{---------------}
{ TTunnel class }
{---------------}

{*
  Crée un tunnel
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du tunnel
  @param AName     Nom du tunnel
*}
constructor TTunnel.Create(AMaster: TMaster; const AID: TComponentID);
begin
  inherited;

  FOpenings := diAllDirections;
  
  Name := STunnel;
  Painter.AddImage(fGrass);
end;

{*
  Déclenché en édition lorsqu'une case est modifiée avec un terrain à niveau
  @param Msg   Message
*}
procedure TTunnel.EditMapSquare(var Msg: TEditMapSquareMessage);
var
  Map: TMap;
  Pos: T3DPoint;
begin
  case Msg.Phase of
    espAdd:
    begin
      // Get position
      Map := Msg.QPos.Map;
      Pos := Msg.QPos.Position;

      if not Map.InMap(Pos) then
      begin
        ShowDialog('Erreur',
          'Ce type de terrain ne peut être placé hors de la carte',
          dtError, dbOK, 1, 0);
        Msg.Flags := Msg.Flags + [esfCancel];
        Exit;
      end;
    
      // Need to be a TFullField
      if not (Map[Pos].Field is TFullField) then
      begin
        ShowDialog('Erreur',
          'Vous devez placer les tunnels sur des terrains pleins',
          dtError, dbOK, 1, 0);
        Msg.Flags := Msg.Flags + [esfCancel];
        Exit;
      end;
    end;
    
    espAdding, espRemoving: { disable behavior of TFullField };
  else
    inherited;
  end;
end;

{*
  Indique si une direction est ouverted
  @param Dir   Direction
  @return True si cette direction est ouverte, False sinon
*}
function TTunnel.GetIsOpened(Dir: TDirection): Boolean;
begin
  Result := Dir in Openings;
end;

{*
  Ouvre ou ferme une direction
  @param Dir     Direction
  @param Value   True ouvre la direction, False la ferme
*}
procedure TTunnel.SetIsOpened(Dir: TDirection; Value: Boolean);
begin
  if Value then
    Openings := Openings + [Dir]
  else
    Openings := Openings - [Dir];
end;

{*
  [@inheritDoc]
*}
function TTunnel.GetCategory: string;
begin
  Result := SCategoryTunnels;
end;

{*
  [@inheritDoc]
*}
function TTunnel.GetIsDesignable: Boolean;
begin
  Result := True;
end;

{*
  [@inheritDoc]
*}
procedure TTunnel.DrawDestSquare(Context, DestContext: TDrawSquareContext);
var
  DrawOpen, DrawGates: Boolean;
begin
  GetDrawMode(Context, DrawOpen, DrawGates);
  
  if DrawOpen then
    DestContext.Map[DestContext.Pos].Field.Draw(DestContext)
  else
    inherited;
end;

{*
  Obtient le mode de dessin du tunnel dans un contexte donné
*}
procedure TTunnel.GetDrawMode(Context: TDrawSquareContext;
  out DrawOpen, DrawGates: Boolean);
var
  PlayerPos: T3DPoint;
begin
  DrawOpen := False;
  DrawGates := False;

  if Context.DrawViewContext = nil then
    DrawOpen := True
  else if Context.DrawViewContext.Floor = Context.Pos.Z then
  begin
    PlayerPos := Context.DrawViewContext.Player.Position;
    if Context.Map[PlayerPos].Field is TTunnel then
      DrawOpen := True
    else
      DrawGates := True;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TTunnel.DoDraw(Context: TDrawSquareContext);
var
  DrawOpen, DrawGates: Boolean;
begin
  GetDrawMode(Context, DrawOpen, DrawGates);

  if DrawOpen then
    Painter.Draw(Context);
end;

{*
  [@inheritDoc]
*}
procedure TTunnel.DoDrawCeiling(Context: TDrawSquareContext);
var
  Map: TMap;
  DrawOpen, DrawGates: Boolean;
  AboveBmp: TBitmap32;
  OtherContext: TDrawSquareContext;
  Dir: TDirection;
begin
  Map := Context.Map;
  GetDrawMode(Context, DrawOpen, DrawGates);

  if DrawOpen then
  begin
    AboveBmp := CreateEmptySquareBitmap;
    try
      // inherited DoDraw on AboveBmp
      OtherContext := TDrawSquareContext.Create(AboveBmp, 0, 0, Context.QPos);
      try
        OtherContext.Assign(Context);
        inherited DoDraw(OtherContext);
      finally
        OtherContext.Free;
      end;

      // Make some parts of AboveBmp transparent (center and openings)
      AboveBmp.FillRectS(TunnelCenterRect, clTransparent32);
      for Dir := diNorth to diWest do
        if IsActuallyOpened(Context.QPos, Dir) then
          AboveBmp.FillRectS(TunnelOpeningRect[Dir], clTransparent32);

      // Draw AboveBmp on the final context
      Context.Bitmap.Draw(Context.X, Context.Y, AboveBmp);
    finally
      AboveBmp.Free;
    end;
  end else
  begin
    inherited DoDraw(Context);
  end;

  if DrawGates then
  begin
    for Dir := diNorth to diWest do
      if IsGate(Context.QPos, Dir) then
        Master.ImagesMaster.Draw(fTunnelGateByDir[Dir], Context);
  end;
  
  if not DrawOpen then
    inherited;
end;

{*
  [@inheritDoc]
*}
procedure TTunnel.Entering(Context: TMoveContext);
var
  Dir: TDirection;
begin
  Dir := Context.Player.Direction;

  if (Context.DestMap <> Context.SrcMap) or
    (not Same3DPoint(PointBehind(Context.Src, Dir), Context.Dest)) then
    Exit;

  if not IsOpened[NegDir[Dir]] then
    inherited;
end;

{*
  [@inheritDoc]
*}
procedure TTunnel.Exiting(Context: TMoveContext);
var
  Dir: TDirection;
begin
  Dir := Context.Player.Direction;

  if (Context.DestMap <> Context.SrcMap) or
    (not Same3DPoint(PointBehind(Context.Src, Dir), Context.Dest)) then
    Exit;

  if not IsOpened[Dir] then
    Context.Cancel;
end;

{*
  [@inheritDoc]
*}
procedure TTunnel.Entered(Context: TMoveContext);
begin
  Context.Player.AddPlugin(Master.Plugin[idViewRestrictionPlugin]);
end;

{*
  [@inheritDoc]
*}
procedure TTunnel.Exited(Context: TMoveContext);
begin
  if not (Context.DestSquare.Field is TTunnel) then
    Context.Player.RemovePlugin(Master.Plugin[idViewRestrictionPlugin]);
end;

{*
  Teste si ce tunnel est effectivement ouvert à un endroit donné du jeu
  @param FromPos   Position du tunnel
  @param Dir       Direction dans laquelle tester
*}
function TTunnel.IsActuallyOpened(const FromPos: TQualifiedPos;
  Dir: TDirection): Boolean;
var
  Map: TMap;
  Pos: T3DPoint;
  OtherField: TField;
begin
  if not IsOpened[Dir] then
    Result := False
  else if IsNoQPos(FromPos) then
    Result := True
  else
  begin
    Map := FromPos.Map;
    Pos := PointBehind(FromPos.Position, Dir);
    OtherField := Map[Pos].Field;

    if (OtherField is TTunnel) and
      TTunnel(OtherField).IsOpened[NegDir[Dir]] then
      Result := True
    else if OtherField is TFullField then
      Result := False
    else
      Result := True;
  end;
end;

{*
  Teste si ce tunnel a une entrée à un endroit donné du jeu
  @param FromPos   Position du tunnel
  @param Dir       Direction dans laquelle tester
*}
function TTunnel.IsGate(const FromPos: TQualifiedPos;
  Dir: TDirection): Boolean;
var
  Map: TMap;
  Pos: T3DPoint;
  OtherField: TField;
begin
  if (not IsOpened[Dir]) or IsNoQPos(FromPos) then
    Result := False
  else
  begin
    Map := FromPos.Map;
    Pos := PointBehind(FromPos.Position, Dir);
    OtherField := Map[Pos].Field;
    
    Result := not (OtherField is TFullField);
  end;
end;

{---------------}
{ TBridge class }
{---------------}

{*
  Crée un nouveau pont
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du pont
  @param AName     Nom du pont
*}
constructor TBridge.Create(AMaster: TMaster; const AID: TComponentID);
begin
  inherited;

  Name := SBridge;

  FOpenings := diAllDirections;
end;

{*
  Déclenché en édition lorsqu'une case est modifiée avec un terrain à niveau
  @param Msg   Message
*}
procedure TBridge.EditMapSquare(var Msg: TEditMapSquareMessage);
begin
end;

{*
  Indique si une direction est ouverted
  @param Dir   Direction
  @return True si cette direction est ouverte, False sinon
*}
function TBridge.GetIsOpened(Dir: TDirection): Boolean;
begin
  Result := Dir in Openings;
end;

{*
  Ouvre ou ferme une direction
  @param Dir     Direction
  @param Value   True ouvre la direction, False la ferme
*}
procedure TBridge.SetIsOpened(Dir: TDirection; Value: Boolean);
begin
  if Value then
    Openings := Openings + [Dir]
  else
    Openings := Openings - [Dir];
end;

{*
  [@inheritDoc]
*}
function TBridge.GetCategory: string;
begin
  Result := SCategoryBridges;
end;

{*
  [@inheritDoc]
*}
procedure TBridge.DoDraw(Context: TDrawSquareContext);
var
  BelowQPos: TQualifiedPos;
  BelowContext: TDrawSquareContext;
begin
  if not Context.IsNowhere then
  begin
    BelowQPos := Context.QPos;
    BelowQPos.Position.Z := BelowQPos.Position.Z - 1;
    
    if BelowQPos.Map.InMap(BelowQPos.Position) then
    begin
      BelowContext := TDrawSquareContext.Create(Context, BelowQPos);
      try
        BelowQPos.Map[BelowQPos.Position].Draw(BelowContext);
      finally
        BelowContext.Free;
      end;
    end;
  end;
  
  DoDrawBridge(Context);
end;

{*
  Dessine le pont en lui-même
  @param Context   Contexte de dessin du pont
*}
procedure TBridge.DoDrawBridge(Context: TDrawSquareContext);
var
  Dir: TDirection;
begin
  Master.ImagesMaster.Draw(fBridgeCenter, Context);
  
  for Dir := diNorth to diWest do
    if IsActuallyOpened(Context.QPos, Dir) then
      Master.ImagesMaster.Draw(fBridgeByDir[Dir], Context);
end;

{*
  Teste si ce pont est effectivement ouvert à un endroit donné du jeu
  @param FromPos   Position du pont
  @param Dir       Direction dans laquelle tester
*}
function TBridge.IsActuallyOpened(const FromPos: TQualifiedPos;
  Dir: TDirection): Boolean;
var
  Map: TMap;
  Pos: T3DPoint;
  OtherField: TField;
begin
  if not IsOpened[Dir] then
    Result := False
  else if IsNoQPos(FromPos) then
    Result := True
  else
  begin
    Map := FromPos.Map;
    Pos := PointBehind(FromPos.Position, Dir);
    OtherField := Map[Pos].Field;

    if (OtherField is TBridge) and
      TBridge(OtherField).IsOpened[NegDir[Dir]] then
      Result := True
    else if (OtherField is TTunnel) and
      TTunnel(OtherField).IsOpened[NegDir[Dir]] then
      Result := True
    else if OtherField is TGround then
      Result := True
    else
      Result := False;
  end;
end;

{*
  Dessine les ponts qui sont au-dessus d'une case donnée
  @param Context   Contexte de dessin de la case
*}
class procedure TBridge.DrawBridgesAbove(Context: TDrawSquareContext);
var
  QPos: TQualifiedPos;
  Square: TSquare;
  BridgeContext: TDrawSquareContext;
begin
  if Context.IsNowhere then
    Exit;

  QPos := Context.QPos;
  
  while QPos.Map.InMap(QPos.Position) do
  begin
    Square := QPos.Map[QPos.Position];
    
    if Square.Field is TBridge then
    begin
      BridgeContext := TDrawSquareContext.Create(Context, QPos);
      try
        TBridge(Square.Field).DoDrawBridge(BridgeContext);
        if Square.Effect <> nil then
          Square.Effect.Draw(BridgeContext);
        if Square.Tool <> nil then
          Square.Tool.Draw(BridgeContext);
        if Square.Obstacle <> nil then
          Square.Obstacle.Draw(BridgeContext);
      finally
        BridgeContext.Free;
      end;
    end;
    
    QPos.Position.Z := QPos.Position.Z + 1;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TBridge.Entering(Context: TMoveContext);
var
  Dir: TDirection;
  QPos: TQualifiedPos;
begin
  Dir := Context.Player.Direction;

  if (Context.DestMap <> Context.SrcMap) or
    (not Same3DPoint(PointBehind(Context.Src, Dir), Context.Dest)) then
    Exit;
    
  QPos.Map := Context.Map;
  QPos.Position := Context.Pos;

  if not IsActuallyOpened(QPos, NegDir[Dir]) then
    inherited;
end;

{*
  [@inheritDoc]
*}
procedure TBridge.Exiting(Context: TMoveContext);
var
  Dir: TDirection;
  QPos: TQualifiedPos;
begin
  Dir := Context.Player.Direction;

  if (Context.DestMap <> Context.SrcMap) or
    (not Same3DPoint(PointBehind(Context.Src, Dir), Context.Dest)) then
    Exit;

  QPos.Map := Context.Map;
  QPos.Position := Context.Pos;

  if not IsActuallyOpened(QPos, Dir) then
    Context.Cancel;
end;

{-----------------------------------}
{ TFloorLevelledGroundCreator class }
{-----------------------------------}

{*
  Crée un nouveau créateur de terrains à niveau
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du créateur de téléporteurs
*}
constructor TFloorLevelledGroundCreator.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited Create(AMaster, AID);

  IconPainter.AddImage(fFloorLevelledGroundCreator);
end;

{*
  [@inheritDoc]
*}
function TFloorLevelledGroundCreator.GetCategory: string;
begin
  Result := SCategoryLevelledGrounds;
end;

{*
  [@inheritDoc]
*}
function TFloorLevelledGroundCreator.GetHint: string;
begin
  Result := SFloorLevelledGroundCreatorHint;
end;

{*
  [@inheritDoc]
*}
function TFloorLevelledGroundCreator.GetComponentClass: TFunLabyComponentClass;
begin
  Result := TFloorLevelledGround;
end;

{----------------------}
{ TTunnelCreator class }
{----------------------}

{*
  Crée un nouveau créateur de tunnels
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du créateur de téléporteurs
*}
constructor TTunnelCreator.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited Create(AMaster, AID);

  IconPainter.AddImage(fTunnelCreator);
end;

{*
  [@inheritDoc]
*}
function TTunnelCreator.GetCategory: string;
begin
  Result := SCategoryTunnels;
end;

{*
  [@inheritDoc]
*}
function TTunnelCreator.GetHint: string;
begin
  Result := STunnelCreatorHint;
end;

{*
  [@inheritDoc]
*}
function TTunnelCreator.GetComponentClass: TFunLabyComponentClass;
begin
  Result := TTunnel;
end;

{----------------------}
{ TBridgeCreator class }
{----------------------}

{*
  Crée un nouveau créateur de ponts
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du créateur de téléporteurs
*}
constructor TBridgeCreator.Create(AMaster: TMaster;
  const AID: TComponentID);
var
  Dir: TDirection;
begin
  inherited Create(AMaster, AID);

  IconPainter.AddImage(fBridgeCenter);
  for Dir := diNorth to diWest do
    IconPainter.AddImage(fBridgeByDir[Dir]);
end;

{*
  [@inheritDoc]
*}
function TBridgeCreator.GetCategory: string;
begin
  Result := SCategoryBridges;
end;

{*
  [@inheritDoc]
*}
function TBridgeCreator.GetHint: string;
begin
  Result := SBridgeCreatorHint;
end;

{*
  [@inheritDoc]
*}
function TBridgeCreator.GetComponentClass: TFunLabyComponentClass;
begin
  Result := TBridge;
end;

end.
