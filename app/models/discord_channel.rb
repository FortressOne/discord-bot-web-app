class DiscordChannel < ApplicationRecord
  has_many :matches
  has_many :trueskill_ratings
  has_many :players, through: :discord_channel_players
end
