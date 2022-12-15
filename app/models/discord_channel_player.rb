class DiscordChannelPlayer < ApplicationRecord
  include ResultConstants

  has_one :trueskill_rating, dependent: :destroy
  belongs_to :discord_channel
  belongs_to :player
  has_many :discord_channel_players_teams
  has_many :teams, through: :discord_channel_players_teams

  scope :leaderboard, -> do
    joins(:player)
      .joins(:teams)
      .merge(Player.visible)
      .includes(:player, :trueskill_rating)
      .sort_by(&:leaderboard_sort_order)
  end

  before_create :build_trueskill_rating

  def tier
    return "🔑" if percentile < 25.0
    return "🥄" if percentile < 50.0
    return "🔱" if percentile < 75.0
    return "⚔️"  if percentile < 85.0
    return "💎" if percentile < 93.0
    "👑"
  end

  def percentile
    discord_channel.percentile(self)
  end

  def rank
    discord_channel.rank(self)
  end

  def conservative_skill_estimate
    trueskill_rating.conservative_skill_estimate
  end

  def leaderboard_sort_order
    if discord_channel.rated?
      trueskill_rating.conservative_skill_estimate * -1
    else
      Time.zone.now - last_match_date
    end
  end

  def last_match_date
    teams.last && teams.last.match.created_at
  end

  def match_count
    teams.count
  end

  def win_count
    teams.where(result: WIN).count
  end

  def loss_count
    teams.where(result: LOSS).count
  end

  def draw_count
    teams.where(result: DRAW).count
  end
end
