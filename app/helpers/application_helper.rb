module ApplicationHelper
  include Pagy::Frontend

  def result(int)
    { 1 => "Win", 0 => "Draw", -1 => "Lose" }[int]
  end

  def percentile(percentile)
    "#{percentile.to_i}<sup>#{percentile.to_i.ordinal}</sup>"
  end
  # Data for shared/_result_card from a pug Match.
  def result_card_for_match(match)
    teams = [match.team(1), match.team(2)].compact.map do |team|
      {
        flag: team.flag, name: team.description,
        players: team.discord_channel_player_teams.map do |dcpt|
          icons = safe_join(dcpt.images.map { |pc| image_tag(pc[:url], alt: pc[:alt], style: "height: 44px;") })
          { icons: icons, name: dcpt.name, url: dcpt.player, medals: [] }
        end
      }
    end
    meta = []
    meta << ["Server", match.server.name, "qw://#{match.server.address}"] if match.server
    meta << ["Discord", match.discord_channel.name, match.discord_channel] if match.discord_channel
    {
      id: match.id, timestamp: match.created_at, meta: meta,
      summary: match_summary(match),
      progress: { colour: match.result_colour, value: match.progress_value, max: 1200 },
      teams: teams, score: match.score,
      links: [["Stats", match.match_stat ? stat_path(match.match_stat) : match.stats_uri],
              ["Demo", match.demo_uri]]
    }
  end

  # Data for shared/_result_card from a parsed MatchStat.
  def result_card_for_match_stat(match_stat, players:, awards:)
    teams = [1, 2].map do |team|
      {
        flag: Team::FLAGS.fetch(team, Team::DEFAULT_FLAG),
        name: "#{((team == 1 ? match_stat.team1_name : match_stat.team2_name).presence || Team::COLOUR[team]).capitalize} Team",
        players: players.select { |player| player.team == team && !player.unteamed? }.map do |player|
          url = player.player_id ? player_path(player.player_id) : stats_path(player: player.name)
          medals = awards.select { |award| award.players.include?(player.name) }
                         .map { |award| { emoji: award.emoji, title: "#{award.title} (#{award.description})" } }
          { icons: stats_main_class_icons(player, height: 44),
            name: stats_display_name(player.name), url: url, medals: medals }
        end
      }
    end
    meta = []
    if match_stat.match
      meta << ["Server", match_stat.match.server.name, "qw://#{match_stat.match.server.address}"] if match_stat.match.server
      meta << ["Discord", match_stat.match.discord_channel.name, match_stat.match.discord_channel] if match_stat.match.discord_channel
    else
      meta << ["Region", match_stat.region, stats_path(region: match_stat.region)]
      meta << ["Mode", match_stat.game_mode, stats_path(mode: match_stat.game_mode)]
    end
    links = [["Raw event log", match_stat.json_url]]
    links << ["PUG result", url_for(match_stat.match)] if match_stat.match
    if match_stat.demo_filename.present? && match_stat.match&.demo_uri.present?
      links << ["Demo", match_stat.match.demo_uri]
    end
    all_time = players.select(&:unteamed?).map do |player|
      halves = player.respond_to?(:half_stats) ? (player.half_stats || {}) : {}
      first_icon, second_icon = %w[1 2].map do |half|
        stats = halves[half] || {}
        main = (stats["class_seconds"] || {}).max_by { |_, seconds| seconds }&.first
        colour = StatsHelper::TEAM_COLOURS[stats["team"].to_i] || :blue
        main ? stats_class_icon(main, colour, height: 32) : "".html_safe
      end
      url = player.player_id ? player_path(player.player_id) : stats_path(player: player.name)
      { name: stats_display_name(player.name), url: url,
        first_icon: first_icon, second_icon: second_icon }
    end
    {
      id: match_stat.id, timestamp: match_stat.played_at, fit: true, all_time: all_time,
      meta: meta, summary: stats_match_summary(match_stat, players),
      progress: { colour: match_stat.result_colour, value: match_stat.progress_value, max: match_stat.progress_max },
      teams: teams, score: "#{match_stat.team1_score} — #{match_stat.team2_score}",
      links: links
    }
  end
end
