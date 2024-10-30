class DiscordChannelsController < ApplicationController
  add_breadcrumb "Home", :root_path

  def index
    @discord_channels = DiscordChannel.all
    add_breadcrumb "Discord channels"
  end

  def show
    @discord_channel = DiscordChannel
      .includes([discord_channel_players: [:team, :player, :trueskill_rating, { latest_rated_discord_channel_player_team: :trueskill_rating }]])
      .find_by(channel_id: params[:id])

    raise ActiveRecord::RecordNotFound if @discord_channel.nil?

    @discord_channel_players = @discord_channel
      .discord_channel_players
      .select { |dcp| dcp.trueskill_rating }
      .sort_by(&:last_match_date)
      .reverse

    @pagy, @matches = pagy(
      Match.where(discord_channel_id: @discord_channel.id).completed
    )

    add_breadcrumb "Discord channels", discord_channels_path
    add_breadcrumb @discord_channel.name
  end
end
