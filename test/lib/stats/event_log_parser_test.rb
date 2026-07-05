require "test_helper"

module Stats
  class EventLogParserTest < ActiveSupport::TestCase
    # A hand-computable match: alice (team 1, Soldier) vs bob (team 2, Scout).
    EVENTS = [
      { type: "gameStart", map: "2fort5r", numPlayers: 2, numTeams: 2, time: 0,
        demo: "2022-01-01_00-00-00_[2fort5r]_blue_vs_red.mvd", gameTimeStamp: "2022-01-01T00:00:00.000Z" },
      { type: "playerStart", player: "alice", classtime: 0, time: 0 },
      { type: "playerStart", player: "bob", classtime: 0, time: 0 },
      { type: "attack", player: "alice", playerClass: "3", inflictor: "rocketlauncher", time: 10 },
      { type: "attack", player: "alice", playerClass: "3", inflictor: "rocketlauncher", time: 12 },
      { type: "damageDone", kind: "enemy", player: "alice", playerClass: 3, playerTeam: 1,
        target: "bob", targetClass: 1, targetTeam: 2, inflictor: "proj_rocket", damage: 90, time: 12 },
      { type: "kill", kind: "enemy", player: "alice", playerClass: 3, playerTeam: 1,
        target: "bob", targetClass: 1, targetTeam: 2, inflictor: "proj_rocket", time: 12 },
      { type: "death", kind: "enemy", attacker: "alice", attackerClass: 3, attackerTeam: 1,
        player: "bob", playerClass: 1, playerTeam: 2, inflictor: "proj_rocket", time: 12 },
      # bob grabs the flag, carries 30s, is killed by alice: a flag stop
      { type: "pickup", team: 2, player: "bob", playerClass: "1", time: 100 },
      { type: "death", kind: "enemy", attacker: "alice", attackerClass: 3, attackerTeam: 1,
        player: "bob", playerClass: 1, playerTeam: 2, inflictor: "proj_rocket", time: 130 },
      { type: "fumble", team: 2, player: "bob", playerClass: "1", timeCarried: 30, time: 130 },
      # alice grabs the flag at 200 and caps at 245: 45s carry
      { type: "pickup", team: 1, player: "alice", playerClass: "3", time: 200 },
      { type: "goal", team: 1, player: "alice", playerClass: "3", time: 245 },
      # bob deliberately throws the flag
      { type: "pickup", team: 2, player: "bob", playerClass: "1", time: 300 },
      { type: "fumble", team: 2, player: "bob", playerClass: "1", timeCarried: 5, time: 305 },
      # alice teamkills, then suicides; environmental death for bob
      { type: "kill", kind: "team", player: "alice", playerClass: 3, playerTeam: 1,
        target: "carol", targetClass: 5, targetTeam: 1, inflictor: "proj_rocket", time: 400 },
      { type: "kill", kind: "self", player: "alice", playerClass: 3, playerTeam: 1,
        target: "alice", targetClass: 3, targetTeam: 1, inflictor: "proj_rocket", time: 410 },
      { type: "death", kind: "self", attacker: "alice", attackerClass: 3, attackerTeam: 1,
        player: "alice", playerClass: 3, playerTeam: 1, inflictor: "proj_rocket", time: 410 },
      { type: "kill", kind: "enemy", player: "world", playerClass: 8, playerTeam: 1,
        target: "bob", targetClass: 1, targetTeam: 2, inflictor: "worldspawn", time: 500 },
      { type: "death", kind: "enemy", attacker: "world", attackerClass: 8, attackerTeam: 1,
        player: "bob", playerClass: 1, playerTeam: 2, inflictor: "worldspawn", time: 500 },
      # alice destroys bob's sentry: not a kill
      { type: "kill", kind: "enemy", player: "alice", playerClass: 3, playerTeam: 1,
        target: "bob", targetClass: 10, targetTeam: 2, inflictor: "proj_rocket", time: 550 },
      # class switch: alice played Soldier 0-600, Demoman 600-1200
      { type: "changeClass", player: "alice", playerClass: 3, nextClass: 4, team: 1, timePlayed: 600, time: 600 },
      { type: "changeClass", player: "alice", playerClass: 4, nextClass: 0, team: 1, timePlayed: 600, time: 1200 },
      { type: "changeClass", player: "bob", playerClass: 1, nextClass: 0, team: 2, timePlayed: 1200, time: 1200 },
      { type: "teamScores", team1Score: 10, team2Score: 0, team1Name: "blue", team2Name: "red",
        winningTeam: 1, time: 1200 },
      { type: "gameEnd", time: 1200 }
    ].freeze

    def raw_log
      # As uploaded by the game server: one object per line, comma-terminated,
      # no enclosing brackets.
      EVENTS.map { |event| "#{event.to_json}," }.join("\n")
    end

    test "parses match metadata" do
      result = EventLogParser.parse(raw_log)

      assert_equal "parsed", result.status
      assert_equal "2fort5r", result.map_name
      assert_equal "2022-01-01_00-00-00_[2fort5r]_blue_vs_red.mvd", result.demo_filename
      assert_equal Time.utc(2022, 1, 1), result.played_at
      assert_equal 1200, result.duration_seconds
      assert_equal 10, result.team1_score
      assert_equal 0, result.team2_score
      assert_equal 1, result.winning_team
      assert_equal %w[alice bob].sort, result.players.keys.sort
    end

    test "aggregates kills, deaths, teamkills, suicides and sentry kills" do
      players = EventLogParser.parse(raw_log).players

      # bob at 12 plus his sentry at 550: sentry destruction counts as a kill
      assert_equal 2, players["alice"][:kills]
      assert_equal 1, players["alice"][:teamkills]
      assert_equal 1, players["alice"][:suicides]
      assert_equal 1, players["alice"][:sentries_destroyed]
      assert_equal 1, players["alice"][:deaths]
      # bob: rocket at 12, flag stop at 130, environmental at 500
      assert_equal 3, players["bob"][:deaths]
      assert_equal 0, players["bob"][:kills]
    end

    test "aggregates damage by kind" do
      players = EventLogParser.parse(raw_log).players

      assert_equal 90, players["alice"][:damage_given]
      assert_equal 90, players["bob"][:damage_taken]
      assert_equal 0, players["alice"][:team_damage]
    end

    test "canonicalises weapon names across attack and damage events" do
      alice = EventLogParser.parse(raw_log).players["alice"]

      assert_equal({ "shots" => 2, "hits" => 1, "damage" => 90, "kills" => 2 }, alice[:weapon_stats]["rl"])
      assert_nil alice[:weapon_stats]["rocketlauncher"]
      assert_nil alice[:weapon_stats]["proj_rocket"]
    end

    test "tracks flag events, stops, throws and carry time" do
      players = EventLogParser.parse(raw_log).players

      assert_equal 1, players["alice"][:flag_caps]
      assert_equal 45, players["alice"][:flag_carry_seconds]
      assert_equal 1, players["alice"][:flag_stops]
      assert_equal 2, players["bob"][:flag_touches]
      assert_equal 2, players["bob"][:flag_drops]
      assert_equal 1, players["bob"][:flag_throws]
      assert_equal 35, players["bob"][:flag_carry_seconds]
    end

    test "tracks class time from changeClass events" do
      players = EventLogParser.parse(raw_log).players

      assert_equal({ "Sold" => 600, "Demo" => 600 }, players["alice"][:class_seconds])
      assert_equal({ "Sco" => 1200 }, players["bob"][:class_seconds])
    end

    test "excludes the world pseudo-player" do
      result = EventLogParser.parse(raw_log)

      assert_not_includes result.players.keys, "world"
    end

    test "accepts logs already wrapped in brackets" do
      result = EventLogParser.parse("[#{EVENTS.map(&:to_json).join(',')}]")

      assert_equal "parsed", result.status
      assert_equal 2, result.players.size
    end

    test "survives a corrupt line" do
      corrupt = raw_log.lines.insert(3, "{\"type\": \"attack\", BROKEN\n").join

      result = EventLogParser.parse(corrupt)

      assert_equal "parsed", result.status
      assert_equal 2, result.players.size
    end

    test "flags trivial games as empty" do
      events = [
        { type: "gameStart", map: "2fort5r", numPlayers: 1, numTeams: 2, time: 0, gameTimeStamp: "2022-01-01T00:00:00.000Z" },
        { type: "gameEnd", time: 5 }
      ]
      result = EventLogParser.parse(events.map { |event| "#{event.to_json}," }.join("\n"))

      assert_equal "empty", result.status
    end

    test "reports unparseable input as error" do
      assert_equal "error", EventLogParser.parse("").status
    end

    test "splits stats into halves at the midpoint" do
      result = EventLogParser.parse(raw_log)

      alice = result.players["alice"][:half_stats]
      assert_equal({ "Sold" => 600 }, alice["1"]["class_seconds"])
      assert_equal({ "Demo" => 600 }, alice["2"]["class_seconds"])
      assert_equal 2, alice["1"]["kills"]
      assert_equal 1, alice["1"]["flag_caps"]
      assert_equal 45, alice["1"]["flag_carry_seconds"]
      assert_equal 1, alice["1"]["suicides"]
      assert_equal 0, alice["2"]["kills"]

      bob = result.players["bob"][:half_stats]
      assert_equal 3, bob["1"]["deaths"]
      assert_equal 2, bob["1"]["flag_touches"]
      assert_equal 1, bob["1"]["flag_throws"]
    end

    test "builds a kill matrix between real players only" do
      result = EventLogParser.parse(raw_log)

      assert_equal({ "alice" => { "bob" => { "kills" => 1, "damage" => 90 } } }, result.kill_matrix)
    end

    test "does not flag a symmetric match as attack defence" do
      assert_not EventLogParser.parse(raw_log).attack_defence
    end

    test "detects attack defence from the flag touch pattern" do
      events = [
        { type: "gameStart", map: "rs_zzr", numPlayers: 2, numTeams: 2, time: 0, gameTimeStamp: "2022-01-01T00:00:00.000Z" },
        { type: "playerStart", player: "alice", classtime: 0, time: 0 },
        { type: "playerStart", player: "bob", classtime: 0, time: 0 },
        # team 1 does all the flag work in half 1, team 2 in half 2
        { type: "pickup", team: 1, player: "alice", playerClass: "3", time: 100 },
        { type: "goal", team: 1, player: "alice", playerClass: "3", time: 150 },
        { type: "pickup", team: 1, player: "alice", playerClass: "3", time: 300 },
        { type: "goal", team: 1, player: "alice", playerClass: "3", time: 350 },
        { type: "pickup", team: 2, player: "bob", playerClass: "1", time: 700 },
        { type: "goal", team: 2, player: "bob", playerClass: "1", time: 750 },
        { type: "pickup", team: 2, player: "bob", playerClass: "1", time: 900 },
        { type: "goal", team: 2, player: "bob", playerClass: "1", time: 950 },
        { type: "changeClass", player: "alice", playerClass: 3, nextClass: 0, team: 1, timePlayed: 1200, time: 1200 },
        { type: "changeClass", player: "bob", playerClass: 1, nextClass: 0, team: 2, timePlayed: 1200, time: 1200 },
        { type: "teamScores", team1Score: 20, team2Score: 20, team1Name: "blue", team2Name: "red", winningTeam: 0, time: 1200 },
        { type: "gameEnd", time: 1200 }
      ]

      result = EventLogParser.parse(events.map { |event| "#{event.to_json}," }.join("\n"))

      assert result.attack_defence
    end

    test "keeps the round-length boundary when team 2 ends the match early" do
      events = [
        { type: "gameStart", map: "rs_zzr", numPlayers: 2, numTeams: 2, time: 0, gameTimeStamp: "2022-01-01T00:00:00.000Z" },
        { type: "playerStart", player: "alice", classtime: 0, time: 0 },
        { type: "playerStart", player: "bob", classtime: 0, time: 0 },
        # team 1 attacks the full first half...
        { type: "pickup", team: 1, player: "alice", playerClass: "3", time: 100 },
        { type: "goal", team: 1, player: "alice", playerClass: "3", time: 150 },
        { type: "pickup", team: 1, player: "alice", playerClass: "3", time: 300 },
        # ...including right at the end of it
        { type: "pickup", team: 1, player: "alice", playerClass: "3", time: 500 },
        # team 2 passes their score at 4:49 into the second half: game over
        { type: "pickup", team: 2, player: "bob", playerClass: "1", time: 700 },
        { type: "goal", team: 2, player: "bob", playerClass: "1", time: 750 },
        { type: "pickup", team: 2, player: "bob", playerClass: "1", time: 850 },
        { type: "goal", team: 2, player: "bob", playerClass: "1", time: 889 },
        { type: "changeClass", player: "alice", playerClass: 3, nextClass: 0, team: 1, timePlayed: 889, time: 889 },
        { type: "changeClass", player: "bob", playerClass: 1, nextClass: 0, team: 2, timePlayed: 889, time: 889 },
        { type: "teamScores", team1Score: 10, team2Score: 20, team1Name: "blue", team2Name: "red", winningTeam: 2, time: 889 },
        { type: "gameEnd", time: 889 }
      ]

      result = EventLogParser.parse(events.map { |event| "#{event.to_json}," }.join("\n"))

      assert result.attack_defence
      assert_equal 600, result.half_boundary
      # alice's 500s pickup belongs to the first half, not duration/2 halves
      assert_equal 3, result.players["alice"][:half_stats]["1"]["flag_touches"]
    end

    test "a roundStart event sets the boundary directly" do
      events = [
        { type: "gameStart", map: "rs_zzr", numPlayers: 2, numTeams: 2, time: 0, gameTimeStamp: "2022-01-01T00:00:00.000Z" },
        { type: "roundStart", time: 0 },
        { type: "kill", kind: "enemy", player: "alice", playerClass: 3, playerTeam: 1,
          target: "bob", targetClass: 1, targetTeam: 2, inflictor: "proj_rocket", time: 100 },
        { type: "death", kind: "enemy", attacker: "alice", attackerClass: 3, attackerTeam: 1,
          player: "bob", playerClass: 1, playerTeam: 2, inflictor: "proj_rocket", time: 100 },
        { type: "roundStart", time: 480 },
        { type: "teamScores", team1Score: 10, team2Score: 0, team1Name: "blue", team2Name: "red", winningTeam: 1, time: 960 },
        { type: "gameEnd", time: 960 }
      ]

      result = EventLogParser.parse(events.map { |event| "#{event.to_json}," }.join("\n"))

      assert_equal 480, result.half_boundary
    end

    test "a changeClass burst confirms the round boundary" do
      # No flag activity at all, but five players change class at 600.
      events = [
        { type: "gameStart", map: "frozen1", numPlayers: 2, numTeams: 2, time: 0, gameTimeStamp: "2022-01-01T00:00:00.000Z" },
        { type: "kill", kind: "enemy", player: "alice", playerClass: 3, playerTeam: 1,
          target: "bob", targetClass: 1, targetTeam: 2, inflictor: "proj_rocket", time: 100 },
        { type: "death", kind: "enemy", attacker: "alice", attackerClass: 3, attackerTeam: 1,
          player: "bob", playerClass: 1, playerTeam: 2, inflictor: "proj_rocket", time: 100 }
      ] + 5.times.map { |i|
        { type: "changeClass", player: "p#{i}", playerClass: 3, nextClass: 4, team: (i % 2) + 1, timePlayed: 600, time: 600 }
      } + [
        { type: "teamScores", team1Score: 10, team2Score: 0, team1Name: "blue", team2Name: "red", winningTeam: 1, time: 1160 },
        { type: "gameEnd", time: 1160 }
      ]

      result = EventLogParser.parse(events.map { |event| "#{event.to_json}," }.join("\n"))

      assert_equal 600, result.half_boundary
      assert_not result.attack_defence
    end

    test "skips halves for short matches" do
      events = [
        { type: "gameStart", map: "1on1r", numPlayers: 2, numTeams: 2, time: 0, gameTimeStamp: "2022-01-01T00:00:00.000Z" },
        { type: "kill", kind: "enemy", player: "alice", playerClass: 3, playerTeam: 1,
          target: "bob", targetClass: 1, targetTeam: 2, inflictor: "proj_rocket", time: 60 },
        { type: "death", kind: "enemy", attacker: "alice", attackerClass: 3, attackerTeam: 1,
          player: "bob", playerClass: 1, playerTeam: 2, inflictor: "proj_rocket", time: 60 },
        { type: "teamScores", team1Score: 1, team2Score: 0, team1Name: "blue", team2Name: "red", winningTeam: 1, time: 300 },
        { type: "gameEnd", time: 300 }
      ]

      result = EventLogParser.parse(events.map { |event| "#{event.to_json}," }.join("\n"))

      assert_empty result.players["alice"][:half_stats]
      assert_not result.attack_defence
    end

    test "map entities with class 0 are not players" do
      events = [
        { type: "gameStart", map: "rs_zzr", numPlayers: 2, numTeams: 2, time: 0, gameTimeStamp: "2022-01-01T00:00:00.000Z" },
        { type: "kill", kind: "enemy", player: "alice", playerClass: 3, playerTeam: 1,
          target: "bob", targetClass: 1, targetTeam: 2, inflictor: "proj_rocket", time: 10 },
        { type: "death", kind: "enemy", attacker: "alice", attackerClass: 3, attackerTeam: 1,
          player: "bob", playerClass: 1, playerTeam: 2, inflictor: "proj_rocket", time: 10 },
        # alice destroys a building under construction: a sentry kill, and
        # build_timer is not a participant
        { type: "kill", kind: "enemy", player: "alice", playerClass: 3, playerTeam: 1,
          target: "build_timer", targetClass: 0, targetTeam: 2, inflictor: "proj_rocket", time: 20 },
        { type: "damageDone", kind: "enemy", player: "alice", playerClass: 3, playerTeam: 1,
          target: "build_timer", targetClass: 0, targetTeam: 2, inflictor: "proj_rocket", damage: 96, time: 20 },
        # bob blows up his own build timer: not a teamkill
        { type: "kill", kind: "team", player: "bob", playerClass: 1, playerTeam: 2,
          target: "build_timer", targetClass: 0, targetTeam: 2, inflictor: "grenade", time: 30 },
        # a map kill trigger teamkills someone: not a participant either
        { type: "kill", kind: "team", player: "kill", playerClass: 0, playerTeam: 2,
          target: "bob", targetClass: 1, targetTeam: 2, inflictor: "info_tfgoal", time: 40 },
        { type: "death", kind: "team", attacker: "kill", attackerClass: 0, attackerTeam: 2,
          player: "bob", playerClass: 1, playerTeam: 2, inflictor: "info_tfgoal", time: 40 },
        { type: "teamScores", team1Score: 10, team2Score: 0, team1Name: "blue", team2Name: "red", winningTeam: 1, time: 700 },
        { type: "gameEnd", time: 700 }
      ]

      result = EventLogParser.parse(events.map { |event| "#{event.to_json}," }.join("\n"))

      assert_equal %w[alice bob], result.players.keys.sort
      alice = result.players["alice"]
      assert_equal 2, alice[:kills]
      assert_equal 1, alice[:sentries_destroyed]
      assert_equal 0, result.players["bob"][:teamkills]
      # bob still died to the kill trigger
      assert_equal 2, result.players["bob"][:deaths]
      assert_equal({ "alice" => { "bob" => { "kills" => 1, "damage" => 0 } } }, result.kill_matrix)
    end

    test "scrubs invalid UTF-8 bytes from player names" do
      # Old logs carry raw Quake-charset bytes ("fun chars") in names.
      funky = raw_log.gsub("alice", "al\xEDce".b).force_encoding(Encoding::UTF_8)

      result = EventLogParser.parse(funky)

      assert_equal "parsed", result.status
      assert_includes result.players.keys, "al?ce"
    end

    test "tolerates a corrupt gameStart timestamp" do
      corrupt = raw_log.sub(/"gameTimeStamp":"[^"]*"/, '"gameTimeStamp":"2021-10-01Tcabo:59:44.053Z"')

      result = EventLogParser.parse(corrupt)

      assert_equal "parsed", result.status
      assert_nil result.played_at
    end
  end
end
