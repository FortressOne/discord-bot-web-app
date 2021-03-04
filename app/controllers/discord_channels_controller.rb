class DiscordChannelsController < ApplicationController
  def show
    @discord_channel = DiscordChannel
      .includes(players: :matches)
      .find_by(channel_id: params[:id])
  end
end
