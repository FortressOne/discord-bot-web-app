class HomeController < ApplicationController
  # Pickup servers whose recorded demos count as matches; other prefixes in
  # the demos bucket belong to other communities (hue, fo, clan).
  DEMO_COUNT_SERVERS = %w[staging pug quad].freeze

  def index
    @matches = Match.completed.limit(1)
    @metrics = Rails.cache.fetch("site-metrics", expires_in: 1.hour) do
      kills, caps = PlayerMatchStat.pick(Arel.sql("SUM(kills), SUM(flag_caps)"))
      {
        matches: recorded_demo_count || MatchStat.parsed.count,
        players: Player.count,
        frags: kills.to_i,
        caps: caps.to_i
      }
    end
  end

  private

  # MVDs recorded across all regions, tallied by the server-side updater into
  # the public stats bucket. Truer than MatchStat.parsed.count, which only
  # covers matches we have stats for.
  def recorded_demo_count
    counts = JSON.parse(Stats::Archive.fetch("demo-counts.json"))
    counts.values_at(*DEMO_COUNT_SERVERS).compact.sum
  rescue StandardError
    nil
  end
end
