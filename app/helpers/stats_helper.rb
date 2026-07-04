module StatsHelper
  TEAM_COLOURS = { 1 => :blue, 2 => :red }.freeze

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
    player.class_seconds.sort_by { |_, seconds| -seconds }.map { |name, seconds|
      number = CLASS_NUMBERS[name]
      next if number.nil? || number.zero?

      image = Playerclass.new(number).image(colour)
      share = (100.0 * seconds / total).round
      image_tag(image[:url], alt: image[:alt], title: "#{name} #{share}%", style: "height: #{height}px;") +
        tag.small(" #{share}% ")
    }.compact.join.html_safe
  end

  def stats_filter_link(label, param, value, style: nil)
    link_to label, stats_path(request.query_parameters.merge(param => value, page: nil)), style: style
  end
end
