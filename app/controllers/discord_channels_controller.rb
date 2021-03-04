class DiscordChannelsController < ApplicationController
  def show
    @discord_channel = DiscordChannel
      .includes(:players)
      .find_by(channel_id: params[:id])
  end
end
