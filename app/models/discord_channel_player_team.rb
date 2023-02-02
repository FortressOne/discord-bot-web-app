class DiscordChannelPlayerTeam < ApplicationRecord
  has_one :trueskill_rating, as: :trueskill_rateable, dependent: :destroy
  belongs_to :team
  belongs_to :discord_channel_player
  has_many :discord_channel_player_team_rounds, dependent: :destroy
  has_many :rounds, through: :discord_channel_player_team_round

  after_create :create_trueskill_rating

  delegate :name, to: :discord_channel_player
  delegate :match, to: :team

  def emojis
    discord_channel_player_team_rounds.map(&:emoji).join("")
  end
end
