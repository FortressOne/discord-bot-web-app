class LivePlayerController < ApplicationController
  TWITCH_FORTRESSONE_GAME_ID = 1973310673

  def show
    @twitch_active_fortressone_channel = twitch
      .streams(TWITCH_FORTRESSONE_GAME_ID)
      .first
  end

  private

  def twitch
    TwitchClient.new
  end
end
