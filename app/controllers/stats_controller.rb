# Browsable per-match stats parsed from the fortressone-stats S3 archive.
# HTML and JSON render the same data. The JSON shape is designed for the FTE
# client's menuqc stats browser (uri_get + json_parse builtins): flat arrays
# of rows, stable keys, and pre-formatted display strings alongside raw
# values so the client does no string math.
class StatsController < ApplicationController
  PAGE_ITEMS = 50

  # The only query params the match log understands. Filter links and
  # pagination carry these and nothing else: copying the whole query string
  # let crawlers that don't decode "&amp;" in hrefs (they request
  # ?map=x&amp;player=y, i.e. a param named "amp;player") snowball junk
  # params into an endless supply of unique URLs.
  FILTER_PARAMS = %w[map region mode player player_id].freeze
  INDEX_PARAMS = (FILTER_PARAMS + %w[page]).freeze

  before_action :redirect_to_canonical_index, only: :index

  def index
    filters = self.class.filter_query(request.query_parameters)
    scope = MatchStat.browsable
    scope = scope.for_map(filters["map"]) if filters["map"]
    scope = scope.for_region(filters["region"]) if filters["region"]
    scope = scope.for_game_mode(filters["mode"]) if filters["mode"]
    scope = scope.for_player(filters["player"]) if filters["player"]
    scope = scope.for_player_id(filters["player_id"]) if filters["player_id"]

    @pagy, @match_stats = pagy(
      scope.includes(:player_match_stats),
      items: PAGE_ITEMS,
      params: ->(query) { query.slice(*INDEX_PARAMS).compact_blank }
    )

    respond_to do |format|
      format.html do
        @regions = MatchStat.parsed.distinct.order(:region).pluck(:region).compact
        @game_modes = MatchStat.parsed.distinct.order(:game_mode).pluck(:game_mode).compact
      end
      format.json do
        render json: {
          stats: @match_stats.map { |match_stat| index_row(match_stat) },
          page: @pagy.page,
          pages: @pagy.pages,
          count: @pagy.count
        }
      end
    end
  end

  def show
    @match_stat = MatchStat.includes(:player_match_stats).find(params[:id])
    # Winning team first, then alphabetical within each team; all-time
    # attackers belong to neither team and go last.
    winning_team = @match_stat.winning_team.to_i
    @players = @match_stat.player_match_stats.sort_by do |player|
      if player.unteamed?
        [2, 0, player.name.downcase]
      else
        [player.team.to_i == winning_team ? 0 : 1, player.team.to_i, player.name.downcase]
      end
    end
    @breakdown = Stats::HalfBreakdown.new(@match_stat, @players)
    weights = { 1 => @breakdown.half_weight(1), 2 => @breakdown.half_weight(2) }
    @weighted_players = @players.map { |player| Stats::WeightedTotals.new(player, weights) }
    @awards = Stats::Awards.for(@weighted_players, breakdown: @breakdown, kill_matrix: @match_stat.kill_matrix)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          **index_row(@match_stat),
          s3_key: @match_stat.s3_key,
          json_url: @match_stat.json_url,
          demo_filename: @match_stat.demo_filename,
          attack_defence: @match_stat.attack_defence,
          awards: @awards.map(&:to_h),
          players: @players.map { |player| player_row(player) },
          halves: @breakdown.tables.transform_values { |rows| rows.map { |row| half_row(row) } },
          matchups: @breakdown.matchups.map { |matchup| matchup_row(matchup) },
          kill_matrix: @match_stat.kill_matrix
        }
      end
    end
  end

  # Filters currently applied, for building links that keep them.
  def self.filter_query(query)
    query.slice(*FILTER_PARAMS).select { |_, value| value.is_a?(String) && value.present? }
  end

  private

  # 301 any HTML request carrying params we don't understand (or nested /
  # array values) to the same listing without them, so every listing has
  # exactly one URL. JSON clients just have unknown params ignored.
  def redirect_to_canonical_index
    return unless request.format.html?

    query = request.query_parameters
    canonical = query.slice(*INDEX_PARAMS).select { |_, value| value.is_a?(String) }
    return if canonical.size == query.size

    redirect_to stats_path(canonical.compact_blank), status: :moved_permanently
  end

  def index_row(match_stat)
    {
      id: match_stat.id,
      played_at: match_stat.played_at&.iso8601,
      played_at_display: match_stat.played_at&.strftime("%Y-%m-%d %H:%M"),
      map: match_stat.map_name,
      region: match_stat.region,
      mode: match_stat.game_mode,
      score: match_stat.score,
      team1_score: match_stat.team1_score,
      team2_score: match_stat.team2_score,
      winning_team: match_stat.winning_team,
      drawn: match_stat.drawn?,
      result_display: match_stat.result_description,
      duration_seconds: match_stat.duration_seconds,
      duration_display: match_stat.duration_display,
      player_count: match_stat.player_count,
      match_id: match_stat.match_id,
      player_names: match_stat.player_match_stats.map(&:name).sort
    }
  end

  def player_row(player)
    {
      name: player.name,
      name_display: helpers.stats_display_name(player.name),
      player_id: player.player_id,
      team: player.team,
      unteamed: player.unteamed?,
      all_time: player.all_time,
      kills: player.kills,
      deaths: player.deaths,
      kd_display: player.kd_ratio.to_s,
      teamkills: player.teamkills,
      suicides: player.suicides,
      sentries_destroyed: player.sentries_destroyed,
      damage_given: player.damage_given,
      damage_taken: player.damage_taken,
      team_damage: player.team_damage,
      flag_touches: player.flag_touches,
      flag_caps: player.flag_caps,
      flag_drops: player.flag_drops,
      flag_throws: player.flag_throws,
      flag_stops: player.flag_stops,
      flag_carry_seconds: player.flag_carry_seconds,
      flag_carry_display: player.flag_carry_display,
      classes_display: player.class_breakdown,
      class_seconds: player.class_seconds,
      weapons: player.weapon_stats.map { |weapon, stats| weapon_row(weapon, stats) },
      damage_received: player.damage_received
    }
  end

  def half_row(row)
    {
      name: row.name,
      name_display: helpers.stats_display_name(row.name),
      player_id: row.player_id,
      team: row.team,
      half: row.half,
      kills: row.kills,
      deaths: row.deaths,
      kd_display: row.kd_ratio.to_s,
      teamkills: row.teamkills,
      suicides: row.suicides,
      sentries_destroyed: row.sentries_destroyed,
      damage_given: row.damage_given,
      damage_taken: row.damage_taken,
      team_damage: row.team_damage,
      flag_touches: row.flag_touches,
      flag_caps: row.flag_caps,
      flag_drops: row.flag_drops,
      flag_throws: row.flag_throws,
      flag_stops: row.flag_stops,
      flag_carry_seconds: row.flag_carry_seconds,
      flag_carry_display: row.flag_carry_display,
      class_seconds: row.class_seconds,
      dominant_class: row.dominant_class,
      weapons: row.weapon_stats.map { |weapon, stats| weapon_row(weapon, stats) }
    }
  end

  def matchup_row(matchup)
    {
      role: matchup.role,
      class_name: matchup.class_name,
      left: half_row(matchup.left),
      right: half_row(matchup.right),
      duels: matchup.duels
    }
  end

  def weapon_row(weapon, stats)
    shots = stats["shots"].to_i
    hits = stats["hits"].to_i
    {
      weapon: weapon,
      shots: shots,
      hits: hits,
      accuracy_display: shots.positive? ? "#{(100.0 * hits / shots).round}%" : "",
      damage: stats["damage"].to_i,
      kills: stats["kills"].to_i
    }
  end
end
