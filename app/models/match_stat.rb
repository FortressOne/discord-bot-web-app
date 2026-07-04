class MatchStat < ApplicationRecord
  belongs_to :match, optional: true
  has_many :player_match_stats, dependent: :destroy

  STATUSES = %w[pending parsed empty error].freeze

  validates :s3_key, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  scope :parsed, -> { where(status: "parsed") }
  scope :browsable, -> { parsed.order(played_at: :desc) }
  scope :for_map, ->(map_name) { where(map_name: map_name) }
  scope :for_region, ->(region) { where(region: region) }
  scope :for_game_mode, ->(game_mode) { where(game_mode: game_mode) }
  scope :for_player, ->(name) { where(id: PlayerMatchStat.where(name: name).select(:match_stat_id)) }

  def drawn?
    winning_team.to_i.zero?
  end

  def score
    "#{team1_score} - #{team2_score}"
  end

  def duration_display
    return nil unless duration_seconds

    format("%d:%02d", duration_seconds / 60, duration_seconds % 60)
  end

  def json_url
    "https://fortressone-stats.s3.ap-southeast-2.amazonaws.com/#{s3_key}"
  end
end
