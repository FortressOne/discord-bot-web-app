class DiscordChannel < ApplicationRecord
  has_many :matches
  has_many :trueskill_ratings
end
