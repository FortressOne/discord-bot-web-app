# Per-match awards in the qwtf.live tradition, computed from a match's
# PlayerMatchStat rows. Awards with a zero-valued winner are omitted.
module Stats
  class Awards
    Award = Struct.new(:title, :emoji, :description, :player, :value, keyword_init: true)

    DEFINITIONS = [
      { title: "Slaughterhouse", emoji: "🔪", description: "most kills", stat: ->(p) { p.kills }, format: ->(v) { "#{v} kills" } },
      { title: "Juggernaut", emoji: "💥", description: "most damage", stat: ->(p) { p.damage_given }, format: ->(v) { "#{v} damage" } },
      { title: "Golden Hands", emoji: "🚩", description: "most captures", stat: ->(p) { p.flag_caps }, format: ->(v) { "#{v} caps" } },
      { title: "No-no-no Motumbo", emoji: "🙅", description: "most flag stops", stat: ->(p) { p.flag_stops }, format: ->(v) { "#{v} stops" } },
      { title: "Running Man", emoji: "🏃", description: "longest flag time", stat: ->(p) { p.flag_carry_seconds }, format: ->(v) { Time.at(v).utc.strftime("%-M:%S") } },
      { title: "Terminator", emoji: "🤖", description: "best kills/deaths", stat: ->(p) { p.deaths.zero? ? p.kills.to_f : p.kills.fdiv(p.deaths) }, format: ->(v) { format("%.2f K/D", v) } },
      { title: "Lemming", emoji: "🪦", description: "most deaths", stat: ->(p) { p.deaths }, format: ->(v) { "#{v} deaths" } },
      { title: "Kamikaze", emoji: "💣", description: "most suicides", stat: ->(p) { p.suicides }, format: ->(v) { "#{v} suicides" } },
      { title: "Mr Magoo", emoji: "👓", description: "most teamkills", stat: ->(p) { p.teamkills }, format: ->(v) { "#{v} teamkills" } },
      { title: "Attention Whore", emoji: "📢", description: "most damage given + taken", stat: ->(p) { p.damage_given + p.damage_taken }, format: ->(v) { "#{v} damage" } }
    ].freeze

    def self.for(players)
      return [] if players.size < 2

      DEFINITIONS.filter_map do |definition|
        winner = players.max_by { |player| definition[:stat].call(player) }
        value = definition[:stat].call(winner)
        next if value.to_f <= 0

        Award.new(
          title: definition[:title],
          emoji: definition[:emoji],
          description: definition[:description],
          player: winner.name,
          value: definition[:format].call(value)
        )
      end
    end
  end
end
