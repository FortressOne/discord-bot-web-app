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

  # Mirrors Match#description: blue wins on points at full time; red wins
  # the moment they pass blue's score, so their margin is the time left.
  def result_description
    return "Draw!" if drawn?

    winner = winning_team.to_i == 1 ? (team1_name.presence || "blue") : (team2_name.presence || "red")
    winner = winner.capitalize
    if winning_team.to_i == 2 && time_remaining.positive?
      "#{winner} wins with #{seconds_to_str(time_remaining)} remaining"
    else
      margin = (team1_score.to_i - team2_score.to_i).abs
      margin.positive? ? "#{winner} wins by #{margin} points" : "#{winner} wins"
    end
  end

  private

  def time_remaining
    return 0 unless half_boundary_seconds

    2 * half_boundary_seconds - duration_seconds.to_i
  end

  def seconds_to_str(seconds)
    ["#{seconds / 3600}h", "#{seconds / 60 % 60}m", "#{seconds % 60}s"]
      .select { |str| str =~ /[1-9]/ }.join(" ")
  end
end
