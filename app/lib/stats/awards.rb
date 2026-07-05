# Per-match awards in the qwtf.live tradition, computed from a match's
# PlayerMatchStat rows (wrapped in WeightedTotals so counting stats compare
# weighted; rates opt out with weighted: false). Ties share the award.
# Awards with a zero-valued winner are omitted.
module Stats
  class Awards
    Award = Struct.new(:title, :emoji, :description, :player, :players, :value, keyword_init: true)

    DEFINITIONS = [
      { title: "Slaughterhouse", emoji: "🔪", description: "most kills", stat: ->(p) { p.kills }, unit: "kills" },
      { title: "Juggernaut", emoji: "💥", description: "most damage", stat: ->(p) { p.damage_given }, unit: "damage" },
      { title: "Golden Hands", emoji: "🚩", description: "most captures", stat: ->(p) { p.flag_caps }, unit: "caps" },
      { title: "No-no-no Motumbo", emoji: "🙅", description: "most flag stops", stat: ->(p) { p.flag_stops }, unit: "stops" },
      { title: "Running Man", emoji: "🏃", description: "longest flag time", stat: ->(p) { p.flag_carry_seconds }, number: ->(v) { Time.at(v).utc.strftime("%-M:%S") }, unit: "" },
      { title: "Terminator", emoji: "🤖", description: "best K/(D+TK)", stat: ->(p) { (p.deaths + p.teamkills).zero? ? p.kills.to_f : p.kills.fdiv(p.deaths + p.teamkills) }, number: ->(v) { format("%.2f", v) }, unit: "K/(D+TK)" },
      { title: "Hulk Smash", emoji: "💪", description: "most sentries destroyed", stat: ->(p) { p.sentries_destroyed }, unit: "sentries" },
      { title: "Lemming", emoji: "🪦", description: "most deaths", stat: ->(p) { p.deaths }, unit: "deaths" },
      { title: "Kamikaze", emoji: "💣", description: "most suicides", stat: ->(p) { p.suicides }, unit: "suicides" },
      { title: "Mr Magoo", emoji: "👓", description: "most teamkills", stat: ->(p) { p.teamkills }, unit: "teamkills" },
      { title: "Attention Whore", emoji: "📢", description: "most damage given + taken", stat: ->(p) { p.damage_given + p.damage_taken }, unit: "damage" }
    ].freeze

    def self.for(players, breakdown: nil, kill_matrix: {})
      return [] if players.size < 2

      awards = DEFINITIONS.filter_map { |definition| build(definition, players) }
      awards += role_awards(breakdown, kill_matrix) if breakdown&.attack_defence?
      awards
    end

    def self.build(definition, players)
      candidates = players
      candidates = players.map { |player| player.respond_to?(:actual) ? player.actual : player } if definition[:weighted] == false
      scored = candidates.map { |player| [player, definition[:stat].call(player)] }
      best = scored.map(&:last).max
      return nil if best.to_f <= 0

      winners = scored.select { |_, value| value == best }.map(&:first)
      actual = winners.size == 1 && winners.first.respond_to?(:actual) ? definition[:stat].call(winners.first.actual) : nil
      display = value_display(best, actual, unit: definition[:unit], number: definition[:number])
      named(definition[:title], definition[:emoji], definition[:description], winners.map(&:name), display)
    end

    # Attack/defence awards over the half-breakdown rows; weighted like the
    # role tables, with the actual in parentheses.
    def self.role_awards(breakdown, kill_matrix)
      attack = breakdown.tables[:attack]
      defence = breakdown.tables[:defence]
      awards = [
        rows_award("Commando", "🪖", "most kills on attack", attack, "kills") { |row| row.kills },
        rows_award("Rambo", "🔫", "most damage on attack", attack, "damage") { |row| row.damage_given },
        rows_award("Shy Guy", "🙈", "lowest damage taken on defence", defence, "damage", minimum: true) { |row| row.damage_taken }
      ]
      awards << spec_ops(defence, kill_matrix)
      awards.compact
    end

    def self.rows_award(title, emoji, description, rows, unit, minimum: false, &stat)
      return nil if rows.blank?

      scored = rows.map { |row| raw = stat.call(row); [row, raw, (raw * row.weight).round] }
      best = minimum ? scored.map(&:last).min : scored.map(&:last).max
      return nil if best.nil? || (!minimum && best <= 0)

      winners = scored.select { |_, _, weighted| weighted == best }
      actual = winners.size == 1 ? winners.first[1] : nil
      display = value_display(best, actual, unit: unit)
      named(title, emoji, description, winners.map { |row, _, _| row.name }, display)
    end

    def self.spec_ops(defence, kill_matrix)
      demo_defenders = defence.select { |row| row.dominant_class == "Demo" }.map(&:name)
      return nil if demo_defenders.empty? || kill_matrix.blank?

      scored = kill_matrix.map do |attacker, victims|
        [attacker, demo_defenders.sum { |demo| victims.dig(demo, "kills").to_i }]
      end
      best = scored.map(&:last).max
      return nil if best.to_i <= 0

      names = scored.select { |_, value| value == best }.map(&:first)
      named("Spec Ops", "🥷", "most kills on the enemy demoman", names, "#{best} kills")
    end

    # "19 (17) teamkills" — weighted first, actual in parentheses, unit last.
    def self.value_display(value, actual, unit:, number: nil)
      number ||= ->(v) { v.to_s }
      text = number.call(value)
      text += " (#{number.call(actual)})" if actual && actual != value
      [text, unit].reject { |part| part.to_s.empty? }.join(" ")
    end

    def self.named(title, emoji, description, names, value)
      Award.new(title: title, emoji: emoji, description: description,
                player: names.join(", "), players: names, value: value)
    end
  end
end
