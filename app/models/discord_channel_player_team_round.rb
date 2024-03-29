class DiscordChannelPlayerTeamRound < ApplicationRecord
  belongs_to :discord_channel_player_team
  belongs_to :round

  delegate :team, to: :discord_channel_player_team
  delegate :name, to: :discord_channel_player_team

  def image
    Playerclass.new(playerclass).image(team.colour.to_sym)
  end

  def emoji
    Rails.application.config.playerclass_emojis[team.colour.to_sym][playerclass]
  end
end
