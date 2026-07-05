# Per-match awards in the qwtf.live tradition, computed from a match's
# PlayerMatchStat rows (wrapped in WeightedTotals so counting stats compare
# weighted; rates opt out with weighted: false). Ties share the award.
# Awards with a zero-valued winner are omitted.
module Stats
  class Awards
    Award = Struct.new(:title, :emoji, :description, :player, :players, :value, keyword_init: true)

    DEFINITIONS = [
      { title: "Slaughterhouse", emoji: "🔪", description: "most kills", stat: ->(p) { p.kills }, format: ->(v) { "#{v} kills" } },
      { title: "Juggernaut", emoji: "💥", description: "most damage", stat: ->(p) { p.damage_given }, format: ->(v) { "#{v} damage" } },
      { title: "Golden Hands", emoji: "🚩", description: "most captures", stat: ->(p) { p.flag_caps }, format: ->(v) { "#{v} caps" } },
      { title: "No-no-no Motumbo", emoji: "🙅", description: "most flag stops", stat: ->(p) { p.flag_stops }, format: ->(v) { "#{v} stops" } },
      { title: "Running Man", emoji: "🏃", description: "longest flag time", stat: ->(p) { p.flag_carry_seconds }, format: ->(v) { Time.at(v).utc.strftime("%-M:%S") } },
      { title: "Terminator", emoji: "🤖", description: "best kills/deaths", weighted: false, stat: ->(p) { (p.deaths + p.teamkills).zero? ? p.kills.to_f : p.kills.fdiv(p.deaths + p.teamkills) }, format: ->(v) { format("%.2f K/D", v) } },
      { title: "Hulk Smash", emoji: "💪", description: "most sentries destroyed", stat: ->(p) { p.sentries_destroyed }, format: ->(v) { "#{v} sentries" } },
      { title: "Lemming", emoji: "🪦", description: "most deaths", stat: ->(p) { p.deaths }, format: ->(v) { "#{v} deaths" } },
      { title: "Kamikaze", emoji: "💣", description: "most suicides", stat: ->(p) { p.suicides }, format: ->(v) { "#{v} suicides" } },
      { title: "Mr Magoo", emoji: "👓", description: "most teamkills", stat: ->(p) { p.teamkills }, format: ->(v) { "#{v} teamkills" } },
      { title: "Attention Whore", emoji: "📢", description: "most damage given + taken", stat: ->(p) { p.damage_given + p.damage_taken }, format: ->(v) { "#{v} damage" } }
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
      display = definition[:format].call(best)
      if winners.size == 1 && winners.first.respond_to?(:actual)
        raw = definition[:stat].call(winners.first.actual)
        display += " (#{definition[:format].call(raw)})" if raw != best
      end
      named(definition[:title], definition[:emoji], definition[:description], winners.map(&:name), display)
    end

    # Attack/defence awards over the half-breakdown rows; weighted like the
    # role tables, with the actual in parentheses.
    def self.role_awards(breakdown, kill_matrix)
      attack = breakdown.tables[:attack]
      defence = breakdown.tables[:defence]
      awards = [
        rows_award("Commando", "🪖", "most kills on attack", attack, ->(v) { "#{v} kills" }) { |row| row.kills },
        rows_award("Rambo", "🔫", "most damage on attack", attack, ->(v) { "#{v} damage" }) { |row| row.damage_given },
        rows_award("Shy Guy", "🙈", "lowest damage taken on defence", defence, ->(v) { "#{v} damage" }, minimum: true) { |row| row.damage_taken }
      ]
      awards << spec_ops(defence, kill_matrix)
      awards.compact
    end

    def self.rows_award(title, emoji, description, rows, format, minimum: false, &stat)
      return nil if rows.blank?

      scored = rows.map { |row| raw = stat.call(row); [row, raw, (raw * row.weight).round] }
      best = minimum ? scored.map(&:last).min : scored.map(&:last).max
      return nil if best.nil? || (!minimum && best <= 0)

      winners = scored.select { |_, _, weighted| weighted == best }
      display = format.call(best)
      if winners.size == 1 && winners.first[2] != winners.first[1]
        display += " (#{format.call(winners.first[1])})"
      end
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

    def self.named(title, emoji, description, names, value)
      Award.new(title: title, emoji: emoji, description: description,
                player: names.join(", "), players: names, value: value)
    end
  end
end
