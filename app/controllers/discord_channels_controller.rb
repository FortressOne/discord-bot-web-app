class DiscordChannelsController < ApplicationController
  def show
    @discord_channel_id = DiscordChannel.find_by(channel_id: params[:id]).id
    @players = Player.discord_channel_leaderboard(@discord_channel_id)
  end
end
