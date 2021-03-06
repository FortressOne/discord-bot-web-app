class DiscordChannelsController < ApplicationController
  def show
    @discord_channel_players = DiscordChannel
      .find_by(channel_id: params[:id])
      .discord_channel_players
      .leaderboard
  end
end
