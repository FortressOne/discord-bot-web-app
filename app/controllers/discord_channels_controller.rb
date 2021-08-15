class DiscordChannelsController < ApplicationController
  def index
    @discord_channels = DiscordChannel.all
  end

  def show
    discord_channel = DiscordChannel.find_by(channel_id: params[:id])

    @discord_channel_players = discord_channel
      .discord_channel_players
      .order_by_last_match

    @matches = discord_channel.matches.history
  end
end
