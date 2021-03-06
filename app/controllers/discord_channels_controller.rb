class DiscordChannelsController < ApplicationController
  def show
    @discord_channel_players = DiscordChannel
      .includes(discord_channel_players: [:trueskill_rating, :player])
      .find_by(channel_id: params[:id])
      .discord_channel_players
      .sort_by do |dcp|
        dcp.trueskill_rating.conservative_skill_estimate * -1
      end
  end
end
