unit ImgPlayerMessages;

interface

uses
  Types, SysUtils, Classes, TypInfo, Graphics, Contnrs, Controls,
  Dialogs, ScUtils, GR32, FunLabyUtils, FunLabyCoreConsts,
  FunLabyToolsConsts, Generics, GraphicsTools, MapTools,
  FLBShowMessage, GraphicsToolsEx;

const
  msgShowImageMsg = $43;

  idShowImageMessagePlugin = 'ShowImageMessagePlugin';

type
  TPlayerShowImageMsgMessage = record
    SimpleMsg: TPlayerShowMsgMessage;
    PainterImages: TStringDynArray;
  end;

  {*
    Données liées au joueur pour un TShowImageMessagePlugin
    @author sjrd
    @version 1.0
  *}
  TShowImageMessagePluginPlayerData = class(TDefaultShowMessagePluginPlayerData)
  private
    FImgPainter: TPainter; /// Peintre pour l'image associée au message
  public
    constructor Create(AComponent: TFunLabyComponent;
      APlayer: TPlayer); override;
    destructor Destroy; override;

    property ImgPainter: TPainter read FImgPainter;
  end;

  {*
    Plugin supportant l'affichage de messages avec une image à gauche
    @author sjrd
    @version 5.0
  *}
  TShowImageMessagePlugin = class(TDefaultShowMessagePlugin)
  private
    procedure MsgShowImageMsgHandler(
      var Msg: TPlayerShowImageMsgMessage); message msgShowImageMsg;
  protected
    class function GetPlayerDataClass: TPlayerDataClass; override;

    procedure PrepareLines(
      PlayerData: TDefaultShowMessagePluginPlayerData;
      const Text: string); override;
    procedure PrepareAnswers(
      PlayerData: TDefaultShowMessagePluginPlayerData;
      const Answers: TStringDynArray); override;

    procedure DrawText(Context: TDrawViewContext;
      PlayerData: TDefaultShowMessagePluginPlayerData); override;
    procedure DrawAnswers(Context: TDrawViewContext;
      PlayerData: TDefaultShowMessagePluginPlayerData); override;

    procedure ShowImageMsg(var Context: TPlayerShowImageMsgMessage); virtual;
  public
    procedure DrawView(Context: TDrawViewContext); override;
  end;

var { FunDelphi codegen }
  compShowImageMessagePlugin: TShowImageMessagePlugin;

procedure ShowImageMsg(Player: TPlayer; const Text, Image: string); overload;
procedure ShowImageMsg(Player: TPlayer; const Text: string;
  const Images: array of string); overload;

implementation

procedure InitializeUnit(Master: TMaster; Params: TStrings);
begin
  TShowImageMessagePlugin.Create(Master, idShowImageMessagePlugin);
end;

procedure ShowImageMsg(Player: TPlayer; const Text, Image: string);
begin
  ShowImageMsg(Player, Text, [Image]);
end;

procedure ShowImageMsg(Player: TPlayer; const Text: string;
  const Images: array of string);
var
  Msg: TPlayerShowImageMsgMessage;
  I: Integer;
begin
  Msg.SimpleMsg.MsgID := msgShowImageMsg;
  Msg.SimpleMsg.Text := Text;

  SetLength(Msg.PainterImages, Length(Images));
  for I := Low(Images) to High(Images) do
    Msg.PainterImages[I] := Images[I];

  Player.Dispatch(Msg);
end;

{-----------------------------------------}
{ TShowImageMessagePluginPlayerData class }
{-----------------------------------------}

{*
  Crée les données du joueur
  @param AComponent   Composant propriétaire
  @param APlayer      Joueur
*}
constructor TShowImageMessagePluginPlayerData.Create(
  AComponent: TFunLabyComponent; APlayer: TPlayer);
begin
  inherited;

  FImgPainter := TPainter.Create(Player.Master.ImagesMaster);
end;

{*
  [@inheritDoc]
*}
destructor TShowImageMessagePluginPlayerData.Destroy;
begin
  FImgPainter.Free;

  inherited;
end;

{-------------------------------}
{ TShowImageMessagePlugin class }
{-------------------------------}

{*
  Gestionnaire du message Afficher un message avec une image
  @param Msg   Message
*}
procedure TShowImageMessagePlugin.MsgShowImageMsgHandler(
  var Msg: TPlayerShowImageMsgMessage);
begin
  Msg.SimpleMsg.Handled := True;

  if (Msg.SimpleMsg.Text <> '') or (Length(Msg.SimpleMsg.Answers) > 0) then
    ShowImageMsg(Msg);
end;

{*
  [@inheritDoc]
*}
class function TShowImageMessagePlugin.GetPlayerDataClass: TPlayerDataClass;
begin
  Result := TShowImageMessagePluginPlayerData;
end;

{*
  [@inheritDoc]
*}
procedure TShowImageMessagePlugin.PrepareLines(
  PlayerData: TDefaultShowMessagePluginPlayerData; const Text: string);
var
  OldPadding: TPoint;
begin
  with TShowImageMessagePluginPlayerData(PlayerData) do
  begin
    if ImgPainter.IsEmpty then
      inherited
    else
    begin
      OldPadding := Padding;
      try
        Padding := Point(Padding.X + (ImgPainter.Size.X+Padding.X) div 2,
          Padding.Y);
        inherited;
      finally
        Padding := OldPadding;
      end;
    end;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TShowImageMessagePlugin.PrepareAnswers(
  PlayerData: TDefaultShowMessagePluginPlayerData;
  const Answers: TStringDynArray);
var
  OldPadding: TPoint;
begin
  with TShowImageMessagePluginPlayerData(PlayerData) do
  begin
    if ImgPainter.IsEmpty then
      inherited
    else
    begin
      OldPadding := Padding;
      try
        Padding := Point(Padding.X + (ImgPainter.Size.X+Padding.X) div 2,
          Padding.Y);
        inherited;
      finally
        Padding := OldPadding;
      end;
    end;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TShowImageMessagePlugin.DrawText(Context: TDrawViewContext;
  PlayerData: TDefaultShowMessagePluginPlayerData);
var
  OldPadding: TPoint;
begin
  with TShowImageMessagePluginPlayerData(PlayerData) do
  begin
    if ImgPainter.IsEmpty then
      inherited
    else
    begin
      OldPadding := Padding;
      try
        Padding := Point(Padding.X + (ImgPainter.Size.X+Padding.X),
          Padding.Y);
        inherited;
      finally
        Padding := OldPadding;
      end;
    end;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TShowImageMessagePlugin.DrawAnswers(Context: TDrawViewContext;
  PlayerData: TDefaultShowMessagePluginPlayerData);
var
  OldPadding: TPoint;
begin
  with TShowImageMessagePluginPlayerData(PlayerData) do
  begin
    if ImgPainter.IsEmpty then
      inherited
    else
    begin
      OldPadding := Padding;
      try
        Padding := Point(Padding.X + (ImgPainter.Size.X+Padding.X),
          Padding.Y);
        inherited;
      finally
        Padding := OldPadding;
      end;
    end;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TShowImageMessagePlugin.ShowImageMsg(
  var Context: TPlayerShowImageMsgMessage);
var
  I: Integer;
begin
  with Context,
    TShowImageMessagePluginPlayerData(GetPlayerData(SimpleMsg.Player)) do
  begin
    try
      for I := Low(PainterImages) to High(PainterImages) do
        ImgPainter.AddImage(PainterImages[I]);

      ShowMessage(SimpleMsg);
    finally
      ImgPainter.Clear;
    end;
  end;
end;

{*
  [@inheritDoc]
*}
procedure TShowImageMessagePlugin.DrawView(Context: TDrawViewContext);
begin
  inherited;

  with Context, TShowImageMessagePluginPlayerData(GetPlayerData(Player)) do
  begin
    if not Activated then
      Exit;

    ImgPainter.DrawAtTimeTo(TickCount, Bitmap, MessageRect.Left + Padding.X,
      MessageRect.Top + Padding.Y);
  end;
end;

end.
