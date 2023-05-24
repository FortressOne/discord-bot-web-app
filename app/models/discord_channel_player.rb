class DiscordChannelPlayer < ApplicationRecord
  include ResultConstants

  FORM_PERIOD = 5

  TIERS = [
    ["🔑",25.0],
    ["🥄",50.0],
    ["🔱",75.0],
    ["⚔️",85.0],
    ["💎",93.0],
    ["👑",100.0]
  ]

  has_one :trueskill_rating, as: :trueskill_rateable, dependent: :destroy
  belongs_to :discord_channel
  counter_culture :discord_channel
  belongs_to :player
  has_many :discord_channel_player_teams
  has_many :discord_channel_player_rounds
  has_many :teams, through: :discord_channel_player_teams
  has_many :rounds, through: :discord_channel_player_rounds

  after_create :create_trueskill_rating

  scope :leaderboard, -> do
    joins(:player)
      .joins(:teams)
      .merge(Player.visible)
      .includes(:player, :trueskill_rating)
      .sort_by(&:leaderboard_sort_order)
  end

  delegate :name, to: :player

  def tier
    TIERS.each do |emoji, limit|
      return emoji if percentile <= limit
    end
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
    teams.sort_by(&:created_at).last&.created_at
  end

  def match_count
    winning_teams_count + losing_teams_count + drawing_teams_count
  end

  def win_count
    winning_teams_count
  end

  def loss_count
    losing_teams_count
  end

  def draw_count
    drawing_teams_count
  end

  def trueskill_ratings_graph(n)
    recent_teams = teams.where.not(result: nil).order(:created_at).last(n)

    dcpts = recent_teams.map do |team|
      DiscordChannelPlayerTeam.find_by(
        discord_channel_player_id: id,
        team_id: team.id
      )
    end

    dcpts.map.with_index do |dcpt, i|
      [i+1, dcpt.trueskill_rating.conservative_skill_estimate]
    end
  end
end
