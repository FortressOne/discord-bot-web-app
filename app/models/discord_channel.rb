class DiscordChannel < ApplicationRecord
  has_many :matches, dependent: :destroy
  has_many :discord_channel_players, dependent: :destroy
  has_many :discord_channel_player_teams, through: :discord_channel_players
  has_many :players, through: :discord_channel_players

  def percentile(discord_channel_player)
    100 - 100.0 * (rank(discord_channel_player)-1) / discord_channel_players_count
  end

  def rank(discord_channel_player)
    1 + trueskill_ratings.count do |tr|
      tr.conservative_skill_estimate > discord_channel_player.conservative_skill_estimate
    end
  end

  def players_with_at_least_one_match_played_count
    discord_channel_players.joins(:teams).distinct.count
  end

  def to_param
    channel_id
  end

  private

  def trueskill_ratings
    discord_channel_players.map(&:trueskill_rating).compact
  end
end
