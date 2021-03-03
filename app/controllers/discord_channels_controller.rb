class DiscordChannelsController < ApplicationController
  def show
    @discord_channel = DiscordChannel.find_by(channel_id: params[:id])
  end
end
