class Results::DiscordChannelsController < ApplicationController
  add_breadcrumb "Home", :root_path

  def index
    @discord_channels = DiscordChannel.all
    add_breadcrumb "Discord channels"
  end

  def show
    @discord_channel = DiscordChannel.find_by(channel_id: params[:id])

    @discord_channel_players = DiscordChannelPlayer
      .where(discord_channel_id: @discord_channel.id)
      .joins(:teams)
      .includes(:teams, :player, :trueskill_rating)
      .sort_by(&:last_match_date)
      .reverse

    @matches = Match
      .where(discord_channel_id: @discord_channel.id)
      .history

    add_breadcrumb "Discord channels", results_root_path
    add_breadcrumb @discord_channel.name
  end
end
