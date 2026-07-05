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

    # In FO pug convention a match is two mirrored halves: team 1 attacks
    # the first half, team 2 the second (fo-stats FO_stats_v1f.ps1). A match
    # counts as attack/defence when flag touches actually follow that
    # pattern; symmetric maps (both teams capping all game) do not.
    MIN_HALF_SECONDS = 300
    AD_PURITY = 0.8
    MIN_AD_TOUCHES = 4

    # Standard round lengths (2x10 and 2x15 formats). A match can end
    # before the second half runs its course — team 2 wins the moment
    # they pass team 1's score — so the boundary is NOT always duration/2.
    ROUND_LENGTHS = [600, 900].freeze

    Result = Struct.new(
      :map_name, :played_at, :demo_filename, :duration_seconds,
      :team1_name, :team2_name, :team1_score, :team2_score, :winning_team,
      :player_count, :players, :status, :error_message,
      :kill_matrix, :attack_defence, :half_boundary,
      keyword_init: true
    )

    def self.parse(raw)
      new(raw).parse
    end

    def initialize(raw)
      # Old logs contain raw Quake-charset bytes in player names ("fun
      # chars"), which are not valid UTF-8 and blow up String#strip/JSON.
      @raw = raw.to_s.force_encoding(Encoding::UTF_8).scrub("?")
      @players = Hash.new { |hash, name| hash[name] = blank_player }
      @teams_seen = Hash.new { |hash, name| hash[name] = Hash.new(0) }
      @half_players = {}
      @half_teams = Hash.new { |hash, key| hash[key] = Hash.new(0) }
      @kill_matrix = {}
      @flag_took_at = {}
      @last_class_change = {}
      @previous_death = nil
      @result = Result.new(players: {}, status: "parsed", kill_matrix: {}, attack_defence: false)
    end

    def parse
      events = decode_events
      return error_result("no events") if events.empty?

      @half_boundary, @attack_defence = detect_halves(events)
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
    rescue ArgumentError
      # Some logs have corrupt timestamps ("2021-10-01Tcabo:59:44.053Z");
      # the importer falls back to the timestamp in the S3 key.
      @result.played_at = nil
    end

    def process_change_class(event)
      name = event["player"]
      return if name.blank?

      time = event["time"].to_i
      note_team(name, event["team"], time)
      from_class = event["playerClass"].to_i
      last_change = @last_class_change[name] || 0
      duration = time - last_change
      if from_class.positive? && from_class < SENTRY_CLASS && duration.positive?
        class_name = CLASS_NAMES[from_class]
        @players[name][:class_seconds][class_name] += duration
        add_half_class_time(name, class_name, last_change, time)
      end
      @last_class_change[name] = time
    end

    # A class segment can span the half boundary; split it so each half
    # gets its share.
    def add_half_class_time(name, class_name, from, to)
      return unless @half_boundary

      first = [to, @half_boundary].min - from
      half_stat(name, 1)["class_seconds"][class_name] += first if first.positive?
      second = to - [from, @half_boundary].max
      half_stat(name, 2)["class_seconds"][class_name] += second if second.positive?
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

      time = event["time"]
      case event["kind"]
      when "enemy"
        target = event["target"]
        if target.present? && target != WORLD
          @players[target][:damage_taken] += damage
          bump_half(target, time, "damage_taken", damage)
        end
        return if name == WORLD

        note_team(name, event["playerTeam"], time)
        @players[name][:damage_given] += damage
        bump_half(name, time, "damage_given", damage)
        duel_stat(name, target)["damage"] += damage if target.present? && target != WORLD
        weapon = weapon_stat(name, event["inflictor"])
        weapon["hits"] += 1
        weapon["damage"] += damage
      when "team"
        return if name == WORLD

        note_team(name, event["playerTeam"], time)
        @players[name][:team_damage] += damage
        bump_half(name, time, "team_damage", damage)
      end
    end

    def process_kill(event)
      name = event["player"]
      return if name.blank? || name == WORLD

      time = event["time"]
      note_team(name, event["playerTeam"], time)
      case event["kind"]
      when "self"
        @players[name][:suicides] += 1
        bump_half(name, time, "suicides")
      when "team"
        @players[name][:teamkills] += 1
        bump_half(name, time, "teamkills")
      when "enemy"
        # Sentry destruction counts as a kill too; the separate tally
        # remains for career stats, but only player-vs-player kills feed
        # the duel matrix.
        @players[name][:kills] += 1
        bump_half(name, time, "kills")
        weapon_stat(name, event["inflictor"])["kills"] += 1
        if event["targetClass"].to_i == SENTRY_CLASS
          @players[name][:sentries_destroyed] += 1
          bump_half(name, time, "sentries_destroyed")
        else
          target = event["target"]
          duel_stat(name, target)["kills"] += 1 if target.present? && target != WORLD
        end
      end
    end

    def process_death(event)
      name = event["player"]
      return if name.blank? || name == WORLD || event["playerClass"].to_i == SENTRY_CLASS

      note_team(name, event["playerTeam"], event["time"])
      @players[name][:deaths] += 1
      bump_half(name, event["time"], "deaths")
      @previous_death = event
    end

    def process_pickup(event)
      name = event["player"]
      return if name.blank?

      note_team(name, event["team"], event["time"])
      @players[name][:flag_touches] += 1
      bump_half(name, event["time"], "flag_touches")
      @flag_took_at[name] = event["time"].to_i
    end

    def process_fumble(event)
      name = event["player"]
      return if name.blank?

      @players[name][:flag_drops] += 1
      bump_half(name, event["time"], "flag_drops")
      carried = (event["timeCarried"] || carry_duration(name, event["time"])).to_i
      @players[name][:flag_carry_seconds] += carried
      bump_half(name, event["time"], "flag_carry_seconds", carried)
      @flag_took_at.delete(name)

      # A fumble in the same instant as the carrier's death is a flag stop,
      # credited to the killer. Any other fumble (except a self-kill) is a
      # deliberate throw. Mirrors FO_stats_v1f.ps1.
      death = @previous_death
      if death && death["player"] == name && death["time"] == event["time"] && death["kind"] != "self"
        killer = death["attacker"]
        if killer.present? && killer != WORLD
          @players[killer][:flag_stops] += 1
          bump_half(killer, event["time"], "flag_stops")
        end
      elsif death.nil? || death["kind"] != "self"
        @players[name][:flag_throws] += 1
        bump_half(name, event["time"], "flag_throws")
      end
    end

    def process_goal(event)
      name = event["player"]
      return if name.blank?

      note_team(name, event["team"], event["time"])
      @players[name][:flag_caps] += 1
      bump_half(name, event["time"], "flag_caps")
      carried = carry_duration(name, event["time"]).to_i
      @players[name][:flag_carry_seconds] += carried
      bump_half(name, event["time"], "flag_carry_seconds", carried)
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

    def note_team(name, team, time = nil)
      team = team.to_i
      return unless team.positive?

      @teams_seen[name][team] += 1
      half = half_of(time)
      @half_teams[[name, half]][team] += 1 if half
    end

    # Pick the half boundary and decide whether this is an attack/defence
    # match in one pass. Candidates are the match midpoint plus the
    # standard round lengths; the flag-touch pattern (team 1 attacks the
    # first half, team 2 the second) confirms one of them. An unconfirmed
    # match keeps the midpoint and is not attack/defence.
    def detect_halves(events)
      game_end = events.reverse_each.find { |event| event["type"] == "gameEnd" }
      duration = (game_end || events.last)&.dig("time").to_i
      fallback = duration / 2
      return [nil, false] if fallback < MIN_HALF_SECONDS

      team_counts = Hash.new { |hash, name| hash[name] = Hash.new(0) }
      touches = []
      events.each do |event|
        name = event["player"]
        next if name.blank? || name == WORLD

        team = event["playerTeam"].to_i
        team = event["team"].to_i if team.zero?
        team_counts[name][team] += 1 if team.positive?
        touches << [name, event["time"].to_i] if event["type"] == "pickup"
      end
      team_of = team_counts.transform_values { |counts| counts.max_by { |_, count| count }.first }

      candidates = ([fallback] + ROUND_LENGTHS).uniq.select do |boundary|
        boundary >= MIN_HALF_SECONDS && duration - boundary >= MIN_DURATION
      end
      scored = candidates.filter_map do |boundary|
        touch_halves = touches.filter_map do |name, time|
          team = team_of[name]
          [time <= boundary ? 1 : 2, team] if team
        end
        next if touch_halves.size < MIN_AD_TOUCHES || touch_halves.map(&:first).uniq.size < 2

        [boundary, touch_halves.count { |half, team| half == team }.fdiv(touch_halves.size)]
      end

      boundary, purity = scored.max_by { |_, best| best }
      if purity && purity >= AD_PURITY
        [boundary, true]
      else
        [fallback, false]
      end
    end

    def half_of(time)
      return nil unless @half_boundary && time

      time.to_i <= @half_boundary ? 1 : 2
    end

    def half_stat(name, half)
      @half_players[[name, half]] ||= blank_half
    end

    def bump_half(name, time, key, amount = 1)
      half = half_of(time)
      half_stat(name, half)[key] += amount if half
    end

    def duel_stat(attacker, victim)
      (@kill_matrix[attacker] ||= {})[victim] ||= { "kills" => 0, "damage" => 0 }
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

    def blank_half
      {
        "team" => nil,
        "kills" => 0, "deaths" => 0, "teamkills" => 0, "suicides" => 0,
        "sentries_destroyed" => 0,
        "damage_given" => 0, "damage_taken" => 0, "team_damage" => 0,
        "flag_touches" => 0, "flag_caps" => 0, "flag_drops" => 0,
        "flag_throws" => 0, "flag_stops" => 0, "flag_carry_seconds" => 0,
        "class_seconds" => Hash.new(0)
      }
    end

    def finalise(events)
      @result.duration_seconds ||= events.last&.dig("time").to_i

      # Only players with a known team count; spectator/world noise does not.
      @result.players = @teams_seen.keys.index_with do |name|
        player = @players[name]
        player[:team] = @teams_seen[name].max_by { |_, count| count }.first
        player[:class_seconds] = player[:class_seconds].to_h
        player[:half_stats] = half_stats_for(name, player[:team])
        player
      end

      @result.kill_matrix = @kill_matrix.slice(*@teams_seen.keys)
                                        .transform_values { |victims| victims.slice(*@teams_seen.keys) }
                                        .reject { |_, victims| victims.empty? }
      @result.attack_defence = @attack_defence
      @result.half_boundary = @half_boundary

      if @result.map_name.blank?
        @result.status = "error"
        @result.error_message = "no gameStart event"
      elsif @result.players.size < MIN_PLAYERS || @result.duration_seconds.to_i < MIN_DURATION || @result.team1_score.nil?
        @result.status = "empty"
      end
    end

    def half_stats_for(name, overall_team)
      [1, 2].filter_map { |half|
        stats = @half_players[[name, half]]
        next unless stats

        team_counts = @half_teams[[name, half]]
        stats["team"] = team_counts.any? ? team_counts.max_by { |_, count| count }.first : overall_team
        stats["class_seconds"] = stats["class_seconds"].to_h
        [half.to_s, stats]
      }.to_h
    end

    def error_result(message)
      @result.status = "error"
      @result.error_message = message
      @result
    end
  end
end
