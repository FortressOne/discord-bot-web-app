class HomeController < ApplicationController
  # Servers whose recorded demos count as matches; other prefixes in the
  # demos bucket belong to other communities (hue, legacy-huetf, clan).
  DEMO_COUNT_SERVERS = %w[staging pug quad scrim tourney duel].freeze

  def index
    @matches = Match.completed.limit(1)
    @metrics = Rails.cache.fetch("site-metrics", expires_in: 1.hour) do
      kills, caps = PlayerMatchStat.pick(Arel.sql("SUM(kills), SUM(flag_caps)"))
      {
        matches: match_count,
        players: Player.count,
        frags: kills.to_i,
        caps: caps.to_i
      }
    end
  end

  private

  def match_count
    demos = recorded_demo_count
    return MatchStat.parsed.count unless demos

    # Stats with no game_mode predate the region/mode key layout
    # (americas/fo/uploaded/...); their demos aren't under any server dir in
    # the tally, so they count on top.
    demos + MatchStat.parsed.where(game_mode: [nil, ""]).count
  end

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
