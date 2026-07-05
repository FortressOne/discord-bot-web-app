class PlayerMatchStat < ApplicationRecord
  belongs_to :match_stat
  belongs_to :player, optional: true

  validates :name, presence: true

  # An all-time attacker swaps teams at half-time so they attack both
  # ways (usually a new player). They belong to neither team.
  def unteamed?
    half_stats.values.filter_map { |half| half["team"] }.uniq.size > 1
  end

  def dominant_class
    class_seconds.max_by { |_, seconds| seconds }&.first
  end

  # Teamkills count against you: kills / (deaths + teamkills).
  def kd_ratio
    denominator = deaths + teamkills
    return kills.to_f if denominator.zero?

    (kills / denominator.to_f).round(2)
  end

  def flag_carry_display
    format("%d:%02d", flag_carry_seconds / 60, flag_carry_seconds % 60)
  end

  # e.g. {"Sold" => 523, "Demo" => 88} => "Sold 86%, Demo 14%"
  def class_breakdown
    total = class_seconds.values.sum
    return "" if total.zero?

    class_seconds.sort_by { |_, seconds| -seconds }
                 .map { |name, seconds| "#{name} #{(100.0 * seconds / total).round}%" }
                 .join(", ")
  end
end
