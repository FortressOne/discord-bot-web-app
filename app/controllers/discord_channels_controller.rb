class DiscordChannelsController < ApplicationController
  def show
    @discord_channel = DiscordChannel.find_by(channel_id: params[:id])
    @players = Player.leaderboard(@discord_channel.id)
  end
end
