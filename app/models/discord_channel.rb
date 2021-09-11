class DiscordChannel < ApplicationRecord
  has_many :matches
  has_many :discord_channel_players, dependent: :destroy
  has_many :players, through: :discord_channel_players

  def to_param
    channel_id
  end
end
