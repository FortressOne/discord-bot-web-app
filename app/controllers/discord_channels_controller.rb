class DiscordChannelsController < ApplicationController
  def show
    @discord_channel = DiscordChannel
      .includes(players: { matches: :discord_channel })
      .find_by(channel_id: params[:id])
  end
end
