class DiscordChannelPlayerRound < ApplicationRecord
  belongs_to :discord_channel_player
  belongs_to :round

  delegate :match, to: :round

  def emoji
    Rails.application.config.playerclass_emojis[team.colour.to_sym][playerclass]
  end

  def image
    Playerclass.new(playerclass).image(team.colour.to_sym)
  end

  def team
    match.team_for(discord_channel_player)
  end
end
