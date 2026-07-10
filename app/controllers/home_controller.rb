class HomeController < ApplicationController
  def index
    @matches = Match.completed.limit(1)
    @metrics = Rails.cache.fetch("site-metrics", expires_in: 1.hour) do
      kills, caps = PlayerMatchStat.pick(Arel.sql("SUM(kills), SUM(flag_caps)"))
      {
        matches: MatchStat.parsed.count,
        players: Player.count,
        frags: kills.to_i,
        caps: caps.to_i
      }
    end
  end
end
