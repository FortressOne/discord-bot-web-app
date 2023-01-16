class DiscordChannelPlayersTeam < ApplicationRecord
  has_one :trueskill_rating, as: :trueskill_rateable, dependent: :destroy
  belongs_to :team
  belongs_to :discord_channel_player

  after_create :create_trueskill_rating
end
