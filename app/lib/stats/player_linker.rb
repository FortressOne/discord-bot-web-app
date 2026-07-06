# Resolves an in-game name from a match event log to a Player record.
#
# On login-required servers the logged name is the login username with the
# Player id appended ("bent#35" is Player 35), so that mapping is exact.
# Older archive logs carry freeform nicknames, which link only when they
# happen to equal a player's name. Ambiguous names (two players who
# sanitize to the same string) are never linked: a missing link is better
# than a wrong one.
module Stats
  class PlayerLinker
    ID_SUFFIX = /#(\d+)\z/

    def initialize
      candidates = Hash.new { |hash, key| hash[key] = Set.new }
      @ids = Set.new
      Player.pluck(:id, :name).each do |id, name|
        @ids << id
        next if name.blank?

        candidates[name.downcase] << id
        candidates[TflToken.sanitize_username(name).downcase] << id
      end
      @by_name = candidates.filter_map { |name, ids| [name, ids.first] if ids.size == 1 }.to_h
    end

    def player_id_for(name, hint: nil)
      return hint if hint && @ids.include?(hint)

      name = name.to_s
      if (id = name[ID_SUFFIX, 1])
        return id.to_i if @ids.include?(id.to_i)

        name = name.sub(ID_SUFFIX, "")
      end
      @by_name[name.downcase]
    end
  end
end
