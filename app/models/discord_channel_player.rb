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

  # returns cse less form_period/cse of cse per in-a-row loss (ignoring draws).
  # I.e with form_period 5, lost last match, returns 80% of cse, lost two last
  # matches, returns 60% of cse. Won't set you below 0. Resets with a win.
  def form_weighted_cse
    if teams.empty? || conservative_skill_estimate <= 0
      return conservative_skill_estimate
    end

    per_consecutive_loss_handicap = conservative_skill_estimate / FORM_PERIOD
    form_period_teams = teams.last(FORM_PERIOD).reverse

    form_period_teams.inject(conservative_skill_estimate) do |fwcse, team|
      break fwcse if team.result == 1

      fwcse -= per_consecutive_loss_handicap
    end
  end

  def leaderboard_sort_order
    if discord_channel.rated?
      trueskill_rating.conservative_skill_estimate * -1
    else
      Time.zone.now - last_match_date
    end
  end

  def last_match_date
    teams.last { |team| team.created_at }.created_at
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

  def trueskill_ratings_graph(int)
    recent_teams = teams.where.not(result: nil).order(:created_at).last(30)

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
