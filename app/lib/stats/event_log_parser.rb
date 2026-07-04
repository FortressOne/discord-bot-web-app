# Parses a FortressOne per-match JSON event log (as uploaded to the
# fortressone-stats S3 bucket by the game server) into match metadata and
# per-player aggregate stats.
#
# The log format is one JSON object per line, comma-terminated, usually
# without the enclosing array brackets. Event semantics follow
# fo-stats/FO_stats_v1f.ps1 (haze's HTML generator).
module Stats
  class EventLogParser
    CLASS_NAMES = %w[World Sco Snp Sold Demo Med HwG Pyro Spy Eng SG].freeze
    SENTRY_CLASS = 10
    MIN_DURATION = 60
    MIN_PLAYERS = 2

    # The engine attributes environmental and gas-grenade effects to a
    # pseudo-player named "world"; it is not a participant.
    WORLD = "world".freeze

    # attack events carry weapon names, damageDone/kill events carry
    # projectile/entity names. Both map onto one canonical short name so a
    # weapon's shots, hits, damage and kills land in the same bucket.
    # Short names follow fo-stats/FO_stats_v1f.ps1's weapSN().
    WEAPON_NAMES = {
      "shotgun" => "sg", "supershotgun" => "ssg",
      "nailgun" => "ng", "spike" => "ng",
      "supernailgun" => "sng", "superspike" => "sng",
      "rocketlauncher" => "rl", "proj_rocket" => "rl",
      "grenadelauncher" => "gl", "grenade" => "gl",
      "pipebomblauncher" => "pipe", "pipebomb" => "pipe",
      "assaultcannon" => "cann", "proj_bullet" => "cann",
      "flamethrower" => "flame", "flamerflame" => "flame",
      "incendiary" => "incen", "pyro_rocket" => "incen",
      "sniperrifle" => "sniper", "autorifle" => "auto",
      "railgun" => "rail", "railslug" => "rail",
      "normalgrenade" => "hgren", "grentimer" => "hgren",
      "mirvgrenade" => "mirv", "mirvsinglegrenade" => "mirv",
      "flashgrenade" => "flash", "shockgrenade" => "shock",
      "empgrenade" => "emp", "napalmgrenade" => "napalm",
      "gasgrenade" => "gas", "caltrop" => "calt",
      "medikit" => "bio", "spanner" => "spann",
      "proj_tranq" => "tranq", "tranquiliser" => "tranq",
      "detpack" => "detp",
      "sentrygun" => "sent", "building_sentrygun" => "sent", "build_timer" => "sent",
      "building_dispenser" => "disp",
      "info_tfgoal" => "laser"
    }.freeze

    Result = Struct.new(
      :map_name, :played_at, :demo_filename, :duration_seconds,
      :team1_name, :team2_name, :team1_score, :team2_score, :winning_team,
      :player_count, :players, :status, :error_message,
      keyword_init: true
    )

    def self.parse(raw)
      new(raw).parse
    end

    def initialize(raw)
      @raw = raw
      @players = Hash.new { |hash, name| hash[name] = blank_player }
      @teams_seen = Hash.new { |hash, name| hash[name] = Hash.new(0) }
      @flag_took_at = {}
      @last_class_change = {}
      @previous_death = nil
      @result = Result.new(players: {}, status: "parsed")
    end

    def parse
      events = decode_events
      return error_result("no events") if events.empty?

      events.each { |event| process(event) }
      finalise(events)
      @result
    rescue JSON::ParserError => e
      error_result("unparseable JSON: #{e.message.truncate(200)}")
    end

    private

    def decode_events
      content = @raw.strip
      return [] if content.empty?

      wrapped = content.start_with?("[") ? content : "[#{content.sub(/,\s*\z/, '')}]"
      JSON.parse(wrapped)
    rescue JSON::ParserError
      # Fall back to line-by-line parsing so one corrupt line doesn't
      # invalidate the whole match.
      @raw.each_line.filter_map do |line|
        line = line.strip.delete_prefix("[").delete_suffix("]").sub(/,\z/, "")
        next if line.empty?

        begin
          JSON.parse(line)
        rescue JSON::ParserError
          nil
        end
      end
    end

    def process(event)
      case event["type"]
      when "gameStart" then process_game_start(event)
      when "playerStart" then @last_class_change[event["player"]] = event["time"].to_i
      when "changeClass" then process_change_class(event)
      when "attack" then process_attack(event)
      when "damageDone" then process_damage(event)
      when "kill" then process_kill(event)
      when "death" then process_death(event)
      when "pickup" then process_pickup(event)
      when "fumble" then process_fumble(event)
      when "goal" then process_goal(event)
      when "teamScores" then process_team_scores(event)
      when "gameEnd" then @result.duration_seconds = event["time"].to_i
      end
      @previous_death = nil unless event["type"] == "death"
    end

    def process_game_start(event)
      @result.map_name = event["map"]
      @result.demo_filename = event["demo"]
      @result.player_count = event["numPlayers"].to_i
      timestamp = event["gameTimeStamp"]
      @result.played_at = Time.zone.parse(timestamp) if timestamp
    end

    def process_change_class(event)
      name = event["player"]
      return if name.blank?

      note_team(name, event["team"])
      time = event["time"].to_i
      from_class = event["playerClass"].to_i
      last_change = @last_class_change[name] || 0
      duration = time - last_change
      if from_class.positive? && from_class < SENTRY_CLASS && duration.positive?
        @players[name][:class_seconds][CLASS_NAMES[from_class]] += duration
      end
      @last_class_change[name] = time
    end

    def process_attack(event)
      name = event["player"]
      return if name.blank? || name == WORLD

      weapon_stat(name, event["inflictor"])["shots"] += 1
    end

    def process_damage(event)
      name = event["player"]
      damage = event["damage"].to_i
      return if name.blank? || damage.zero?

      case event["kind"]
      when "enemy"
        target = event["target"]
        @players[target][:damage_taken] += damage if target.present? && target != WORLD
        return if name == WORLD

        note_team(name, event["playerTeam"])
        @players[name][:damage_given] += damage
        weapon = weapon_stat(name, event["inflictor"])
        weapon["hits"] += 1
        weapon["damage"] += damage
      when "team"
        return if name == WORLD

        note_team(name, event["playerTeam"])
        @players[name][:team_damage] += damage
      end
    end

    def process_kill(event)
      name = event["player"]
      return if name.blank? || name == WORLD

      note_team(name, event["playerTeam"])
      case event["kind"]
      when "self"
        @players[name][:suicides] += 1
      when "team"
        @players[name][:teamkills] += 1
      when "enemy"
        if event["targetClass"].to_i == SENTRY_CLASS
          @players[name][:sentries_destroyed] += 1
        else
          @players[name][:kills] += 1
          weapon_stat(name, event["inflictor"])["kills"] += 1
        end
      end
    end

    def process_death(event)
      name = event["player"]
      return if name.blank? || name == WORLD || event["playerClass"].to_i == SENTRY_CLASS

      note_team(name, event["playerTeam"])
      @players[name][:deaths] += 1
      @previous_death = event
    end

    def process_pickup(event)
      name = event["player"]
      return if name.blank?

      note_team(name, event["team"])
      @players[name][:flag_touches] += 1
      @flag_took_at[name] = event["time"].to_i
    end

    def process_fumble(event)
      name = event["player"]
      return if name.blank?

      @players[name][:flag_drops] += 1
      carried = event["timeCarried"] || carry_duration(name, event["time"])
      @players[name][:flag_carry_seconds] += carried.to_i
      @flag_took_at.delete(name)

      # A fumble in the same instant as the carrier's death is a flag stop,
      # credited to the killer. Any other fumble (except a self-kill) is a
      # deliberate throw. Mirrors FO_stats_v1f.ps1.
      death = @previous_death
      if death && death["player"] == name && death["time"] == event["time"] && death["kind"] != "self"
        killer = death["attacker"]
        @players[killer][:flag_stops] += 1 if killer.present? && killer != WORLD
      elsif death.nil? || death["kind"] != "self"
        @players[name][:flag_throws] += 1
      end
    end

    def process_goal(event)
      name = event["player"]
      return if name.blank?

      note_team(name, event["team"])
      @players[name][:flag_caps] += 1
      @players[name][:flag_carry_seconds] += carry_duration(name, event["time"]).to_i
      @flag_took_at.delete(name)
    end

    def process_team_scores(event)
      @result.team1_name = event["team1Name"]
      @result.team2_name = event["team2Name"]
      @result.team1_score = event["team1Score"].to_i
      @result.team2_score = event["team2Score"].to_i
      @result.winning_team = event["winningTeam"].to_i
    end

    def carry_duration(name, time)
      took_at = @flag_took_at[name]
      took_at ? time.to_i - took_at : 0
    end

    def note_team(name, team)
      team = team.to_i
      @teams_seen[name][team] += 1 if team.positive?
    end

    def weapon_stat(name, inflictor)
      inflictor = inflictor.presence || "unknown"
      weapon = WEAPON_NAMES[inflictor] || inflictor.tr("_", "-")
      @players[name][:weapon_stats][weapon] ||= { "shots" => 0, "hits" => 0, "damage" => 0, "kills" => 0 }
    end

    def blank_player
      {
        kills: 0, deaths: 0, teamkills: 0, suicides: 0, sentries_destroyed: 0,
        damage_given: 0, damage_taken: 0, team_damage: 0,
        flag_touches: 0, flag_caps: 0, flag_drops: 0, flag_throws: 0,
        flag_stops: 0, flag_carry_seconds: 0,
        class_seconds: Hash.new(0), weapon_stats: {}
      }
    end

    def finalise(events)
      @result.duration_seconds ||= events.last&.dig("time").to_i

      # Only players with a known team count; spectator/world noise does not.
      @result.players = @teams_seen.keys.index_with do |name|
        player = @players[name]
        player[:team] = @teams_seen[name].max_by { |_, count| count }.first
        player[:class_seconds] = player[:class_seconds].to_h
        player
      end

      if @result.map_name.blank?
        @result.status = "error"
        @result.error_message = "no gameStart event"
      elsif @result.players.size < MIN_PLAYERS || @result.duration_seconds.to_i < MIN_DURATION || @result.team1_score.nil?
        @result.status = "empty"
      end
    end

    def error_result(message)
      @result.status = "error"
      @result.error_message = message
      @result
    end
  end
end
