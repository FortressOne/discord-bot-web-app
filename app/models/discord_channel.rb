class DiscordChannel < ApplicationRecord
  has_many :matches
  has_many :discord_channel_players, dependent: :destroy
  has_many :trueskill_ratings, through: :discord_channel_players
  has_many :players, through: :discord_channel_players

  def percentile(discord_channel_player)
    100.0 * rank(discord_channel_player) / discord_channel_players.count
  end

  def rank(discord_channel_player)
    trueskill_ratings
      .where("mean > ?", discord_channel_player.rating_mean)
      .count + 1
  end

  def to_param
    channel_id
  end
end
