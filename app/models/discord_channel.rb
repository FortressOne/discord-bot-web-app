class DiscordChannel < ApplicationRecord
  has_many :matches
  has_many :discord_channel_players
  has_many :players, through: :discord_channel_players

  scope :leaderboard, -> do
    includes(players: { matches: :discord_channel })
      .where.not(players: { name: nil })
  end
end
