# Resolves an in-game name from a match event log to a Player record.
#
# On login-required servers the logged name IS the login username —
# Player#name passed through TflToken.sanitize_username — so that mapping is
# exact. Older archive logs carry freeform nicknames, which link only when
# they happen to equal a player's name. Ambiguous names (two players who
# sanitize to the same string) are never linked: a missing link is better
# than a wrong one.
module Stats
  class PlayerLinker
    def initialize
      candidates = Hash.new { |hash, key| hash[key] = Set.new }
      Player.pluck(:id, :name).each do |id, name|
        next if name.blank?

        candidates[name.downcase] << id
        candidates[TflToken.sanitize_username(name).downcase] << id
      end
      @by_name = candidates.filter_map { |name, ids| [name, ids.first] if ids.size == 1 }.to_h
    end

    def player_id_for(name)
      @by_name[name.to_s.downcase]
    end
  end
end
