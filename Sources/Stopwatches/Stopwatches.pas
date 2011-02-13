unit Stopwatches;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools,
  GaugeDisplay;

const
  msgStopwatchExpiration = $72;

type
  TStopwatchPlugin = class;

  TStopwatchExpirationMessage = record
    MsgID: Word;
    Handled: Boolean;
    Reserved: Byte;
    Player: TPlayer;
    Stopwatch: TStopwatchPlugin;
  end;

  TStopwatchTimerEntry = class(TNotificationMsgTimerEntry)
  private
    FStopwatch: TStopwatchPlugin; /// Chronomètre concerné
  protected
    procedure Execute; override;
  public
    constructor Create(ATickCount: Cardinal;
      ADestObject: TFunLabyComponent; AStopwatch: TStopwatchPlugin;
      AMsgID: Word = msgStopwatchExpiration);
  published
    property Stopwatch: TStopwatchPlugin read FStopwatch write FStopwatch;
  end;

  TStopwatchPluginPlayerData = class(TPlayerData)
  private
    FStopwatch: TStopwatchPlugin; /// Plugin propriétaire

    FDelay: Cardinal; /// Temps du chronomètre

    FActive: Boolean;        /// Indique si le chronomètre est actif
    FEndTickCount: Cardinal; /// Tick-count d'expiration

    function GetRemainingTime: Cardinal;
  protected
    procedure DefineProperties(Filer: TFunLabyFiler); override;
  public
    constructor Create(AComponent: TFunLabyComponent;
      APlayer: TPlayer); override;

    procedure Start;
    procedure Stop;
    procedure Expire;

    property Stopwatch: TStopwatchPlugin read FStopwatch;

    property Active: Boolean read FActive;
    property EndTickCount: Cardinal read FEndTickCount;
    property RemainingTime: Cardinal read GetRemainingTime;
  published
    property Delay: Cardinal read FDelay write FDelay default 0;
  end;

  TStopwatchPlugin = class(TPlugin)
  private
    procedure StopwatchExpirationMsg(var Msg: TStopwatchExpirationMessage);
      message msgStopwatchExpiration;

    procedure GetGaugePropertiesMsg(var Msg: TGetGaugePropertiesMessage);
      message msgGetGaugeProperties;
  protected
    class function GetPlayerDataClass: TPlayerDataClass; override;

    function GetIsDesignable: Boolean; override;

    procedure Started(Context: TStopwatchPluginPlayerData); virtual;
    procedure Stopped(Context: TStopwatchPluginPlayerData); virtual;
    procedure Expired(Context: TStopwatchPluginPlayerData); virtual;
  public
    function GetPlayerData(Player: TPlayer): TStopwatchPluginPlayerData;

    procedure Start(Player: TPlayer);
    procedure Stop(Player: TPlayer);
  end;

implementation

{-------------}
{ Unit events }
{-------------}

procedure InitializeUnit(Master: TMaster);
begin
  FunLabyRegisterClass(TStopwatchTimerEntry);
end;

procedure Unloading(Master: TMaster);
begin
  FunLabyUnregisterClass(TStopwatchTimerEntry);
end;

{----------------------------}
{ TStopwatchTimerEntry class }
{----------------------------}

constructor TStopwatchTimerEntry.Create(ATickCount: Cardinal;
  ADestObject: TFunLabyComponent; AStopwatch: TStopwatchPlugin;
  AMsgID: Word = msgStopwatchExpiration);
begin
  inherited Create(ATickCount, ADestObject, AMsgID);

  FStopwatch := AStopwatch;
end;

procedure TStopwatchTimerEntry.Execute;
var
  Msg: TStopwatchExpirationMessage;
begin
  Msg.MsgID := MsgID;
  Msg.Stopwatch := Stopwatch;
  DestObject.Dispatch(Msg);
end;

{----------------------------------}
{ TStopwatchPluginPlayerData class }
{----------------------------------}

constructor TStopwatchPluginPlayerData.Create(AComponent: TFunLabyComponent;
  APlayer: TPlayer);
begin
  inherited;

  FStopwatch := AComponent as TStopwatchPlugin;
end;

function TStopwatchPluginPlayerData.GetRemainingTime: Cardinal;
var
  TickCount: Cardinal;
begin
  TickCount := Stopwatch.Master.TickCount;

  if Active and (TickCount < EndTickCount) then
    Result := EndTickCount - TickCount
  else
    Result := 0;
end;

procedure TStopwatchPluginPlayerData.DefineProperties(Filer: TFunLabyFiler);
begin
  inherited;

  Filer.DefineFieldProperty('Active', TypeInfo(Boolean),
    @FActive, Active);
  Filer.DefineFieldProperty('EndTickCount', TypeInfo(Cardinal),
    @FEndTickCount, Active);
end;

procedure TStopwatchPluginPlayerData.Start;
begin
  Stop;

  FEndTickCount := Stopwatch.Master.TickCount + Delay;
  FActive := True;

  Stopwatch.Master.Timers.ScheduleCustom(TStopwatchTimerEntry.Create(
    EndTickCount, Player, Stopwatch));

  Stopwatch.Started(Self);
end;

procedure TStopwatchPluginPlayerData.Stop;
begin
  if Active then
  begin
    FActive := False;

    Stopwatch.Stopped(Self);
  end;
end;

procedure TStopwatchPluginPlayerData.Expire;
begin
  if Active and (RemainingTime = 0) then
  begin
    FActive := False;

    Stopwatch.Expired(Self);
  end;
end;

{------------------------}
{ TStopwatchPlugin class }
{------------------------}

procedure TStopwatchPlugin.StopwatchExpirationMsg(
  var Msg: TStopwatchExpirationMessage);
begin
  if Msg.Stopwatch = Self then
    GetPlayerData(Msg.Player).Expire;
end;

procedure TStopwatchPlugin.GetGaugePropertiesMsg(
  var Msg: TGetGaugePropertiesMessage);
begin
  with GetPlayerData(Msg.Player) do
  begin
    Msg.Properties.Visible := Active;

    if Active then
    begin
      Msg.Properties.Value := RemainingTime;
      Msg.Properties.MaxValue := Delay;
    end;
  end;
end;

class function TStopwatchPlugin.GetPlayerDataClass: TPlayerDataClass;
begin
  Result := TStopwatchPluginPlayerData;
end;

function TStopwatchPlugin.GetIsDesignable: Boolean;
begin
  Result := True;
end;

procedure TStopwatchPlugin.Started(Context: TStopwatchPluginPlayerData);
begin
end;

procedure TStopwatchPlugin.Stopped(Context: TStopwatchPluginPlayerData);
begin
end;

procedure TStopwatchPlugin.Expired(Context: TStopwatchPluginPlayerData);
begin
end;

function TStopwatchPlugin.GetPlayerData(
  Player: TPlayer): TStopwatchPluginPlayerData;
begin
  Result := TStopwatchPluginPlayerData(inherited GetPlayerData(Player));
end;

procedure TStopwatchPlugin.Start(Player: TPlayer);
begin
  GetPlayerData(Player).Start;
end;

procedure TStopwatchPlugin.Stop(Player: TPlayer);
begin
  GetPlayerData(Player).Stop;
end;

end.
