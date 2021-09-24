class Results::DiscordChannelsController < ApplicationController
  add_breadcrumb "Home", :root_path

  def index
    @discord_channels = DiscordChannel.all
    add_breadcrumb "Discord Channels"
  end

  def show
    @discord_channel = DiscordChannel.find_by(channel_id: params[:id])

    @discord_channel_players = @discord_channel
      .discord_channel_players
      .leaderboard

    @matches = @discord_channel.matches.history

    add_breadcrumb "Discord channels", results_root_path
    add_breadcrumb @discord_channel.name
  end
end
