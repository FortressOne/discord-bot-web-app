class Round < ApplicationRecord
  belongs_to :match
  has_many :discord_channel_player_rounds
  has_many :discord_channel_players, through: :disord_channel_player_rounds
end
