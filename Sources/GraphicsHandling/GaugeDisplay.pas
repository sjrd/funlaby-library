unit GaugeDisplay;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools;

const
  idGaugeDisplayPlugin = 'GaugeDisplayPlugin';

  DefaultMaxValue = 100;

  DefaultPadding = 8;
  DefaultGaugeWidth = 100;
  DefaultGaugeHeight = 6;
  DefaultGaugeSep = 4;

  msgGetGaugeProperties = $51;

type
  {*
    Propriétés d'une gauge
  *}
  TGaugeProperties = record
    Visible: Boolean;  /// Indique si cette gauge est visible
    Value: Integer;    /// Valeur actuelle de la gauge
    MaxValue: Integer; /// Valeur maximale de la gauge
  end;

  {*
    Type du message GetGaugeProperties
  *}
  TGetGaugePropertiesMessage = record
    MsgID: Word;     /// ID du message
    Handled: Boolean; /// Indique si le message a été géré
    Reserved: Byte;   /// Réservé
    Player: TPlayer;  /// Joueur concerné

    Properties: TGaugeProperties; /// Propriétés de la gauge
  end;

  {*
    Description d'une gauge
    @author sjrd
  *}
  TGaugeDescription = class(TFunLabyPersistent)
  private
    FEnabled: Boolean; /// Indique si cette gauge est active

    FLeftColor: TColor32;       /// Couleur à gauche du dégradé
    FRightColor: TColor32;      /// Couleur à droite du dégradé
    FBorderColor: TColor32;     /// Couleur de la bordure
    FBackgroundColor: TColor32; /// Couleur de background

    FRelatedComponent: TFunLabyComponent; /// Composant associé
  public
    constructor Create; virtual;

    function GetProperties(Player: TPlayer): TGaugeProperties;
  published
    property Enabled: Boolean read FEnabled write FEnabled default True;

    property LeftColor: TColor32 read FLeftColor write FLeftColor
      default clWhite32;
    property RightColor: TColor32 read FRightColor write FRightColor
      default clWhite32;
    property BorderColor: TColor32 read FBorderColor write FBorderColor
      default clBlack32;
    property BackgroundColor: TColor32
      read FBackgroundColor write FBackgroundColor default clTransparent32;

    property RelatedComponent: TFunLabyComponent
      read FRelatedComponent write FRelatedComponent;
  end;

  TGaugeDescriptionClass = class of TGaugeDescription;

  {*
    Collection de gauges
    @author sjrd
    @version 5.0
  *}
  TGaugeDescriptionCollection = class(TFunLabyCollection)
  private
    function GetItems(Index: Integer): TGaugeDescription;
  protected
    function CreateItem(ItemClass: TFunLabyPersistentClass):
      TFunLabyPersistent; override;

    function GetDefaultItemClass: TFunLabyPersistentClass; override;
  public
    property Items[Index: Integer]: TGaugeDescription read GetItems; default;
  end;

  {*
    Plugin dessinant des gauges sur la vue du joueur
    @author sjrd
    @version 5.0
  *}
  TGaugeDisplayPlugin = class(TPlugin)
  private
    FGauges: TGaugeDescriptionCollection; /// Gauges

    FPadding: Integer;     /// Padding dans le coin supérieur gauche de la vue
    FGaugeWidth: Integer; /// Largeur d'une gauge
    FGaugeHeight: Integer; /// Hauteur d'une gauge
    FGaugeSep: Integer;    /// Séparation entre deux gauges
  protected
    procedure DrawGauge(Bitmap: TBitmap32; Gauge: TGaugeDescription;
      const Properties: TGaugeProperties; X, Y: Integer);
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
    destructor Destroy; override;

    procedure DrawView(Context: TDrawViewContext); override;

    function FindGauge(
      RelatedComponent: TFunLabyComponent): TGaugeDescription;
  published
    property Gauges: TGaugeDescriptionCollection read FGauges;

    property Padding: Integer read FPadding write FPadding
      default DefaultPadding;
    property GaugeWidth: Integer read FGaugeWidth write FGaugeWidth
      default DefaultGaugeWidth;
    property GaugeHeight: Integer read FGaugeHeight write FGaugeHeight
      default DefaultGaugeHeight;
    property GaugeSep: Integer read FGaugeSep write FGaugeSep
      default DefaultGaugeSep;
  end;

var { FunDelphi codegen }
  compGaugeDisplayPlugin: TGaugeDisplayPlugin;

implementation

procedure InitializeUnit(Master: TMaster);
begin
  FunLabyRegisterClass(TGaugeDescription);

  TGaugeDisplayPlugin.Create(Master, idGaugeDisplayPlugin);
end;

procedure Unloading(Master: TMaster);
begin
  FunLabyUnregisterClass(TGaugeDescription);
end;

{ TGaugeDescription class }

constructor TGaugeDescription.Create;
begin
  inherited Create;

  FEnabled := True;

  FLeftColor := clWhite32;
  FRightColor := clWhite32;
  FBorderColor := clBlack32;
  FBackgroundColor := clTransparent32;
end;

function TGaugeDescription.GetProperties(Player: TPlayer): TGaugeProperties;
const
  InitialMsg: TGetGaugePropertiesMessage = (
    MsgID: msgGetGaugeProperties;
    Handled: False;
    Reserved: 0;
    Player: nil;
    Properties: (
      Visible: True;
      Value: 0;
      MaxValue: DefaultMaxValue
    )
  );
var
  Msg: TGetGaugePropertiesMessage;
begin
  if RelatedComponent = nil then
  begin
    Result.Visible := False;
    Exit;
  end;

  Msg := InitialMsg;
  Msg.Player := Player;

  RelatedComponent.Dispatch(Msg);

  Result := Msg.Properties;
end;

{ TGaugeDescriptionCollection class }

function TGaugeDescriptionCollection.GetItems(
  Index: Integer): TGaugeDescription;
begin
  Result := TGaugeDescription(TFunLabyCollection(Self).Items[Index]);
end;

{*
  [@inheritDoc]
*}
function TGaugeDescriptionCollection.CreateItem(
  ItemClass: TFunLabyPersistentClass): TFunLabyPersistent;
begin
  Result := TGaugeDescriptionClass(ItemClass).Create;
end;

{*
  [@inheritDoc]
*}
function TGaugeDescriptionCollection.GetDefaultItemClass:
  TFunLabyPersistentClass;
begin
  Result := TGaugeDescription;
end;

{ TGaugeDisplayPlugin class }

{*
  Crée une instance de TGaugeDisplayPlugin
  @param AMaster   Maître FunLabyrinthe
  @param AID       ID du plugin
*}
constructor TGaugeDisplayPlugin.Create(AMaster: TMaster;
  const AID: TComponentID);
begin
  inherited;

  FZIndex := 1024;

  FGauges := TGaugeDescriptionCollection.Create;

  FPadding := DefaultPadding;
  FGaugeWidth := DefaultGaugeWidth;
  FGaugeHeight := DefaultGaugeHeight;
  FGaugeSep := DefaultGaugeSep;
end;

{*
  [@inheritDoc]
*}
destructor TGaugeDisplayPlugin.Destroy;
begin
  FGauges.Free;

  inherited;
end;

{*
  Dessine une gauge sur un bitmap
  @param Bitmap   Bitmap destination
  @param Properties   Propriétés de la gauge
*}
procedure TGaugeDisplayPlugin.DrawGauge(Bitmap: TBitmap32;
  Gauge: TGaugeDescription; const Properties: TGaugeProperties; X, Y: Integer);
var
  ActiveWidth, I: Integer;
begin
  ActiveWidth := GaugeWidth * Properties.Value div Properties.MaxValue;

  // Draw the border
  Bitmap.FrameRectTS(X, Y, X+GaugeWidth+2, Y+GaugeHeight+2,
    Gauge.BorderColor);

  Inc(X);
  Inc(Y);

  // Draw the active part
  if ActiveWidth > 0 then
  begin
    if Gauge.LeftColor = Gauge.RightColor then
    begin
      // No gradient
      Bitmap.FillRectTS(X, Y, X+ActiveWidth, Y+GaugeHeight, Gauge.LeftColor);
    end else
    begin
      // With gradient
      Bitmap.SetStipple([Gauge.LeftColor, Gauge.RightColor]);
      Bitmap.StippleStep := Single(1.0) / Single(GaugeWidth);

      for I := Y to Y+GaugeHeight-1 do
      begin
        Bitmap.StippleCounter := 0.0;
        Bitmap.HorzLineTSP(X, I, X+ActiveWidth-1);
      end;
    end;
  end;

  // Draw the background part
  if (Gauge.BackgroundColor <> clTransparent32) and
    (ActiveWidth < GaugeWidth) then
  begin
    Bitmap.FillRectTS(X+ActiveWidth, Y, X+GaugeWidth, Y+GaugeHeight,
      Gauge.BackgroundColor);
  end;
end;

{*
  [@inheritDoc]
*}
procedure TGaugeDisplayPlugin.DrawView(Context: TDrawViewContext);
var
  I, X, Y: Integer;
  Gauge: TGaugeDescription;
  Properties: TGaugeProperties;
begin
  X := Padding;
  Y := Padding;

  for I := 0 to Gauges.Count-1 do
  begin
    Gauge := Gauges[I];
    if not Gauge.Enabled then
      Continue;

    Properties := Gauge.GetProperties(Context.Player);

    if Properties.Visible then
    begin
      DrawGauge(Context.Bitmap, Gauge, Properties, X, Y);
      Inc(Y, GaugeHeight + 2 + GaugeSep);
    end;
  end;
end;

{*
  Trouve une gauge d'après le composant associé
  @param RelatedComponent   Composant associé
*}
function TGaugeDisplayPlugin.FindGauge(
  RelatedComponent: TFunLabyComponent): TGaugeDescription;
var
  I: Integer;
begin
  for I := 0 to Gauges.Count-1 do
  begin
    Result := Gauges[I];
    if Result.RelatedComponent = RelatedComponent then
      Exit;
  end;

  Result := nil;
end;

end.
