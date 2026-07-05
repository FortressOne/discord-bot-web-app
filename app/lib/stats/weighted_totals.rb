# Wraps a PlayerMatchStat so counting stats come back weighted: each
# half's contribution scales by that half's weight (see
# HalfBreakdown#half_weight), so a shortened half counts fairly in
# whole-match numbers. Rates (K/D) and identity pass through untouched;
# the raw record stays reachable via #actual.
module Stats
  class WeightedTotals < SimpleDelegator
    WEIGHTED_STATS = %w[
      kills deaths teamkills suicides sentries_destroyed
      damage_given damage_taken team_damage
      flag_touches flag_caps flag_drops flag_throws flag_stops
      flag_carry_seconds
    ].freeze

    def initialize(player, weights)
      super(player)
      @weights = weights
    end

    WEIGHTED_STATS.each do |stat|
      define_method(stat) do
        halves = __getobj__.half_stats
        return __getobj__.public_send(stat) if halves.blank? || @weights.values.all? { |weight| weight.to_f <= 1.01 }

        halves.sum { |half, stats| stats[stat].to_i * @weights[half.to_i].to_f }.round
      end
    end

    def actual
      __getobj__
    end
  end
end
