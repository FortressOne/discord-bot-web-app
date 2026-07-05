module StatsHelper
  TEAM_COLOURS = { 1 => :blue, 2 => :red }.freeze

  # Column sets for the stats tables. Suicides already count as deaths and
  # sentry kills as kills, so neither gets its own column. Defenders never
  # touch the flag in attack/defence matches and attackers never stop it,
  # so each role shows only its own flag columns.
  STATS_COLUMNS = {
    flag_caps: ["Caps", "Flag captures"],
    flag_carry: ["Carry", "Flag carry time"],
    flag_touches: ["Took", "Flag touches"],
    flag_throws: ["Throw", "Flag throws"],
    kills: ["K", "Kills"],
    deaths: ["D", "Deaths"],
    kd: ["K/D", "Kills per death"],
    teamkills: ["TK", "Teamkills"],
    damage_given: ["Dmg", "Damage given"],
    damage_taken: ["Dmg T", "Damage taken"],
    team_damage: ["FF", "Friendly fire damage"],
    flag_stops: ["Stop", "Flag stops"]
  }.freeze

  FULL_COLUMNS = %i[kills deaths kd teamkills damage_given damage_taken team_damage
                    flag_touches flag_caps flag_throws flag_stops flag_carry].freeze
  ATTACK_COLUMNS = %i[flag_caps flag_carry flag_touches flag_throws
                      kills deaths teamkills damage_given damage_taken team_damage].freeze
  DEFENCE_COLUMNS = %i[kills deaths kd teamkills damage_given damage_taken team_damage
                       flag_stops].freeze

  ROLE_COLUMNS = {
    attack: ATTACK_COLUMNS,
    defence: DEFENCE_COLUMNS,
    first_half: FULL_COLUMNS,
    second_half: FULL_COLUMNS
  }.freeze

  def stats_cell(player, column)
    case column
    when :kd then tag.td(player.kd_ratio)
    when :flag_carry
      tag.td(player.flag_carry_display, data: { sort: player.flag_carry_seconds })
    else
      tag.td(player.public_send(column))
    end
  end

  # class_seconds keys are short class names ("Sold"); Playerclass is keyed
  # by class number.
  CLASS_NUMBERS = Stats::EventLogParser::CLASS_NAMES.each_with_index.to_h.freeze

  def team_colour_code(team)
    { 1 => "#01A2E8", 2 => "#EC1D24" }[team.to_i] || "#AAAAAA"
  end

  def stats_class_icons(player, height: 28)
    total = player.class_seconds.values.sum
    return "" if total.zero?

    colour = TEAM_COLOURS[player.team.to_i] || :blue
    icons = player.class_seconds.sort_by { |_, seconds| -seconds }.map { |name, seconds|
      number = CLASS_NUMBERS[name]
      next if number.nil? || number.zero?

      image = Playerclass.new(number).image(colour)
      share = (100.0 * seconds / total).round
      image_tag(image[:url], alt: image[:alt], title: "#{name} #{share}%", style: "height: #{height}px;") +
        tag.small(" #{share}% ")
    }.compact.join.html_safe
    tag.span(icons, style: "white-space: nowrap; display: inline-flex; align-items: center;")
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

  # The margin of victory for one head-to-head row, coloured by the
  # winning side's team. A neutral hyphen on a tie.
  def duel_margin(left, right, left_team, right_team, lower_wins: false, clock: false)
    return tag.span("&ndash;".html_safe, style: "color: #FFFFFF;") if left == right

    left_wins = lower_wins ? left < right : left > right
    margin = (left - right).abs
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

  # Links to the Player profile when the stat row resolved to a real player,
  # otherwise falls back to filtering the match log by name.
  def stats_player_link(player)
    style = "color: #{team_colour_code(player.team)};"
    if player.player_id
      link_to player.name, player_path(player.player_id), style: style
    else
      stats_filter_link(player.name, :player, player.name, style: style)
    end
  end
end
