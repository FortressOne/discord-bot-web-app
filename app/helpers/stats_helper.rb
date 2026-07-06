module StatsHelper
  TEAM_COLOURS = { 1 => :blue, 2 => :red }.freeze

  # Column sets for the stats tables. Suicides already count as deaths and
  # sentry kills as kills, so neither gets its own column. Defenders never
  # touch the flag in attack/defence matches and attackers never stop it,
  # so each role shows only its own flag columns.
  STATS_COLUMNS = {
    flag_caps: ["Caps", "Flag captures"],
    flag_carry: ["Carry", "Flag carry time"],
    flag_touches: ["Takes", "Flag takes"],
    flag_throws: ["Throws", "Flag throws"],
    kills: ["Kills", "Kills"],
    deaths: ["Deaths", "Deaths"],
    kd: ["K/(D+TK)", "Kills per (deaths + teamkills)"],
    dmg_per_min: ["Damage/min", "Damage per minute"],
    teamkills: ["Team Kills", "Team kills"],
    damage_given: ["Damage", "Damage given"],
    damage_taken: ["Dmg T", "Damage taken"],
    team_damage: ["Team Damage", "Damage dealt to teammates"],
    flag_stops: ["Stops", "Flag stops"]
  }.freeze

  FULL_COLUMNS = %i[kills deaths kd teamkills damage_given team_damage
                    flag_touches flag_caps flag_throws flag_stops flag_carry].freeze
  ATTACK_COLUMNS = %i[flag_caps flag_carry kills damage_given dmg_per_min flag_touches
                      flag_throws teamkills team_damage].freeze
  DEFENCE_COLUMNS = %i[kills damage_given dmg_per_min flag_stops deaths teamkills kd
                       team_damage].freeze

  ROLE_COLUMNS = {
    attack: ATTACK_COLUMNS,
    defence: DEFENCE_COLUMNS,
    first_half: FULL_COLUMNS,
    second_half: FULL_COLUMNS
  }.freeze

  def stats_cell(player, column)
    if column == :kd
      # Within one half the weight cancels out of the ratio; across a whole
      # match the weighted components shift it, so show both.
      weighted = player.kd_ratio
      raw = player.respond_to?(:actual) ? player.actual.kd_ratio : weighted
      return weighted == raw ? tag.td(raw) : tag.td("#{weighted} (#{raw})", data: { sort: weighted })
    end
    return tag.td(player.damage_per_minute) if column == :dmg_per_min

    stat = column == :flag_carry ? :flag_carry_seconds : column
    clock = column == :flag_carry
    if player.respond_to?(:actual)
      weighted = player.public_send(stat)
      raw = player.actual.public_send(stat)
    else
      raw = player.public_send(stat)
      weight = player.respond_to?(:weight) ? player.weight.to_f : 1.0
      weighted = (raw * weight).round
    end

    if weighted != raw || clock
      display = weighted == raw ? (clock ? player.flag_carry_display : raw) : weighted_pair_display(weighted, raw, clock: clock)
      tag.td(display, data: { sort: weighted })
    else
      tag.td(raw)
    end
  end

  def weighted_pair_display(weighted, raw, clock: false)
    formatter = ->(value) { clock ? format("%d:%02d", value / 60, value % 60) : value.to_s }
    "#{formatter.call(weighted)} (#{formatter.call(raw)})"
  end

  # class_seconds keys are short class names ("Sold"); Playerclass is keyed
  # by class number.
  CLASS_NUMBERS = Stats::EventLogParser::CLASS_NAMES.each_with_index.to_h.freeze

  def team_colour_code(team)
    { 1 => "#01A2E8", 2 => "#EC1D24" }[team.to_i] || "#AAAAAA"
  end

  # Classes used, most-played first, minor dabbles (<5% of playing time)
  # hidden. The share lives in the tooltip.
  def stats_class_icons(player, height: 28)
    total = player.class_seconds.values.sum
    return "" if total.zero?

    colour = TEAM_COLOURS[player.team.to_i] || :blue
    icons = player.class_seconds.sort_by { |_, seconds| -seconds }.filter_map { |name, seconds|
      share = 100.0 * seconds / total
      next if share < 5

      number = CLASS_NUMBERS[name]
      next if number.nil? || number.zero?

      image = Playerclass.new(number).image(colour)
      image_tag(image[:url], alt: image[:alt], title: "#{name} #{share.round}%", style: "height: #{height}px;")
    }
    tag.span(safe_join(icons), style: "white-space: nowrap; display: inline-flex; align-items: center; gap: 0.2rem;")
  end

  # The main class of each half (first then second), coloured by the team
  # played for — the players-table view of a whole match.
  def stats_main_class_icons(player, height: 28)
    halves = player.respond_to?(:half_stats) ? player.half_stats : {}
    icons = %w[1 2].filter_map do |half|
      stats = halves[half]
      next unless stats

      main = (stats["class_seconds"] || {}).max_by { |_, seconds| seconds }&.first
      next unless main

      colour = TEAM_COLOURS[(stats["team"] || player.team).to_i] || :blue
      icon = stats_class_icon(main, colour, height: height)
      icon.presence
    end
    return stats_class_icons(player, height: height) if icons.empty?

    tag.span(safe_join(icons), style: "white-space: nowrap; display: inline-flex; align-items: center; gap: 0.2rem;")
  end

  def stats_class_full_name(class_name)
    number = CLASS_NUMBERS[class_name]
    full_name = number&.positive? && Playerclass::PLAYERCLASSES.dig(number, :name)
    full_name.presence || class_name
  end

  # Bold the winning side of a head-to-head stat. Deaths and damage taken
  # pass lower_wins.
  def duel_pair(left, right, left_display: nil, right_display: nil, lower_wins: false)
    displays = [left_display || left, right_display || right]
    return displays if left == right

    left_wins = lower_wins ? left < right : left > right
    left_wins ? [tag.strong(displays[0]), displays[1]] : [displays[0], tag.strong(displays[1])]
  end

  # Rows for a head-to-head card. When a half was cut short (team 2 won
  # before their half ran out) its values scale up for a fair comparison,
  # displayed as "weighted (actual)". Winners and margins use the
  # weighted numbers.
  def matchup_stat_rows(breakdown, matchup)
    left_weight = breakdown.half_weight(matchup.left.half)
    right_weight = breakdown.half_weight(matchup.right.half)

    definitions =
      if matchup.role == :attack
        [["Caps", :flag_caps, {}],
         ["Carry", :flag_carry_seconds, { clock: true }],
         ["Kills", :kills, {}],
         ["Damage", :damage_given, {}],
         ["Takes", :flag_touches, {}],
         ["Throws", :flag_throws, {}],
         ["Team Kills", :teamkills, { lower_wins: true }],
         ["Team Damage", :team_damage, { lower_wins: true }]]
      else
        [["Kills", :kills, {}],
         ["Damage", :damage_given, {}],
         ["Stops", :flag_stops, {}],
         ["Deaths", :deaths, { lower_wins: true }],
         ["Team Kills", :teamkills, { lower_wins: true }],
         ["Team Damage", :team_damage, { lower_wins: true }],
         ["K/(D+TK)", :kd_ratio, { rate: true }]]
      end

    definitions.map do |label, stat, options|
      raw_left = matchup.left.public_send(stat)
      raw_right = matchup.right.public_send(stat)
      if options[:rate]
        # Within one half the weight cancels out of a ratio.
        next [label, raw_left, raw_right,
              { left_display: raw_left, right_display: raw_right, lower_wins: false, clock: false }]
      end
      weighted_left = (raw_left * left_weight).round
      weighted_right = (raw_right * right_weight).round
      clock = options[:clock] || false
      [label, weighted_left, weighted_right,
       { left_display: weighted_stat_display(weighted_left, raw_left, left_weight, clock: clock),
         right_display: weighted_stat_display(weighted_right, raw_right, right_weight, clock: clock),
         lower_wins: options.fetch(:lower_wins, false), clock: clock,
         neutral: options.fetch(:neutral, false) }]
    end
  end

  def weighted_stat_display(weighted, raw, weight, clock: false)
    formatter = ->(value) { clock ? format("%d:%02d", value / 60, value % 60) : value.to_s }
    weight > 1.01 ? "#{formatter.call(weighted)} (#{formatter.call(raw)})" : formatter.call(raw)
  end

  # The margin of victory for one head-to-head row, coloured by the
  # winning side's team. A neutral hyphen on a tie.
  def duel_margin(left, right, left_team, right_team, lower_wins: false, clock: false)
    return tag.span("&ndash;".html_safe, style: "color: #FFFFFF;") if left == right

    left_wins = lower_wins ? left < right : left > right
    margin = (left - right).abs
    margin = margin.round(2) if margin.is_a?(Float)
    # On lower-wins stats (deaths, damage taken) the winner has LESS, so
    # the margin reads negative.
    sign = lower_wins ? "-" : "+"
    display = clock ? format("#{sign}%d:%02d", margin / 60, margin % 60) : "#{sign}#{margin}"
    tag.strong(display, style: "color: #{team_colour_code(left_wins ? left_team : right_team)};")
  end

  def stats_class_icon(class_name, colour, height: 24)
    number = CLASS_NUMBERS[class_name]
    return "" unless number&.positive?

    image = Playerclass.new(number).image(colour)
    image_tag(image[:url], alt: image[:alt], title: class_name, style: "height: #{height}px;")
  end

  def stats_filter_link(label, param, value, style: nil)
    link_to label, stats_path(request.query_parameters.merge(param => value, page: nil)), style: style
  end

  # A team-total cell: weighted sum with the actual in parentheses when a
  # half was shortened.
  def stats_totals_cell(members, stat, clock: false)
    weighted = members.sum { |player| player.public_send(stat) }
    raw = members.sum { |player| (player.respond_to?(:actual) ? player.actual : player).public_send(stat) }
    display = if weighted != raw
      weighted_pair_display(weighted, raw, clock: clock)
    else
      clock ? format("%d:%02d", raw / 60, raw % 60) : raw
    end
    tag.td(display, data: { sort: weighted })
  end

  # Role blocks for a player's card: [label, half_data, team] — one per
  # half, labelled by whether they attacked or defended it.
  def stats_role_blocks(player)
    player.half_stats.sort.filter_map do |half, data|
      team = (data["team"] || player.team).to_i
      role = team == half.to_i ? "Attack" : "Defence"
      [role, data, team]
    end
  end

  # Same shape as match_summary: "Red wins with 2m 54s remaining - 4v4 - ff-schtop".
  # All-time attackers belong to neither side: "4v4 +ATA".
  def stats_match_summary(match_stat, players)
    teamed, all_time_attackers = players.partition { |player| !player.unteamed? }
    sizes = teamed.group_by { |player| player.team.to_i }
    size = [1, 2].map { |team| (sizes[team] || []).size }.join("v")
    size += " +#{all_time_attackers.size > 1 ? "#{all_time_attackers.size} " : ""}ATA" if all_time_attackers.any?
    [match_stat.result_description, size, match_stat.map_name].compact.join(DELIMITER)
  end

  # Login-era logs append the Player id to the name ("bent#35") — pure
  # noise for display; the raw name still keys filters and duels.
  def stats_display_name(name)
    name.to_s.sub(Stats::PlayerLinker::ID_SUFFIX, "")
  end

  def stats_class_breakdown(class_seconds)
    total = class_seconds.values.sum
    return "" if total.zero?

    class_seconds.sort_by { |_, seconds| -seconds }
                 .map { |name, seconds| "#{name} #{(100.0 * seconds / total).round}%" }
                 .join(", ")
  end

  # Links to the Player profile when the stat row resolved to a real player,
  # otherwise falls back to filtering the match log by name. All-time
  # attackers belong to neither team and render white.
  def stats_player_link(player)
    unteamed = player.respond_to?(:unteamed?) && player.unteamed?
    style = "color: #{unteamed ? '#FFFFFF' : team_colour_code(player.team)};"
    if player.player_id
      link_to stats_display_name(player.name), player_path(player.player_id), style: style
    else
      stats_filter_link(stats_display_name(player.name), :player, player.name, style: style)
    end
  end
end
