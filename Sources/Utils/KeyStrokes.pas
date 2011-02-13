unit KeyStrokes;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools;

type
  {*
    Configuration de touches au clavier
    @author sjrd
    @version 5.0
  *}
  TKeyStroke = class(TFunLabyPersistent)
  private
    FKey: Word;          /// Touche appuyée
    FShift: TShiftState; /// État des touches spéciales

    FDefaultKey: Word;          /// Touche appuyée par défaut
    FDefaultShift: TShiftState; /// État des touches spéciales par défaut

    function IsKeyStored: Boolean;
    function IsShiftStored: Boolean;
  protected
    procedure StoreDefaults; override;
  public
    function Matches(AKey: Word; AShift: TShiftState = []): Boolean;
  published
    property Key: Word read FKey write FKey stored IsKeyStored;
    property Shift: TShiftState read FShift write FShift stored IsShiftStored;
  end;

  {*
    Classe de base pour les plugins devant réagir à l'appui d'une touche
    @author sjrd
  *}
  TKeyStrokePlugin = class(TPlugin)
  private
    FKeyStroke: TKeyStroke; /// Touche à appuyer pour activer l'effet du plugin
  protected
    procedure SetupKeyStroke; virtual;

    procedure KeyStrokeTriggered(Context: TKeyEventContext); virtual;
  public
    constructor Create(AMaster: TMaster; const AID: TComponentID); override;
    destructor Destroy; override;

    procedure PressKey(Context: TKeyEventContext); override;
  published
    property KeyStroke: TKeyStroke read FKeyStroke;
  end;

implementation

{ TKeyStroke class }

function TKeyStroke.IsKeyStored: Boolean;
begin
  Result := FKey <> FDefaultKey;
end;

function TKeyStroke.IsShiftStored: Boolean;
begin
  Result := FShift <> FDefaultShift;
end;

procedure TKeyStroke.StoreDefaults;
begin
  inherited;

  FDefaultKey := FKey;
  FDefaultShift := FShift;
end;

function TKeyStroke.Matches(AKey: Word; AShift: TShiftState = []): Boolean;
begin
  Result := (AKey = FKey) and (AShift = FShift);
end;

{ TKeyStrokePlugin class }

constructor TKeyStrokePlugin.Create(AMaster: TMaster; const AID: TComponentID);
begin
  inherited;

  FKeyStroke := TKeyStroke.Create;
  SetupKeyStroke;
end;

destructor TKeyStrokePlugin.Destroy;
begin
  FKeyStroke.Free;

  inherited;
end;

procedure TKeyStrokePlugin.SetupKeyStroke;
begin
end;

procedure TKeyStrokePlugin.KeyStrokeTriggered(Context: TKeyEventContext);
begin
end;

procedure TKeyStrokePlugin.PressKey(Context: TKeyEventContext);
begin
  if KeyStroke.Matches(Context.Key, Context.Shift) then
  begin
    Context.Handled := True;
    KeyStrokeTriggered(Context);
  end;
end;

end.
