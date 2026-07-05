require "test_helper"

module Stats
  class HalfBreakdownTest < ActiveSupport::TestCase
    def build_match(attack_defence: true)
      match_stat = MatchStat.new(
        s3_key: "sydney/pub/x.json", duration_seconds: 1200, attack_defence: attack_defence,
        kill_matrix: { "alice" => { "bob" => { "kills" => 5, "damage" => 400 } },
                       "bob" => { "alice" => { "kills" => 3, "damage" => 250 } } }
      )
      # alice (team 1) attacks half 1 as Sold; bob (team 2) attacks half 2 as Sold
      match_stat.player_match_stats.build(
        name: "alice", team: 1,
        half_stats: {
          "1" => { "team" => 1, "kills" => 10, "deaths" => 4, "flag_caps" => 2, "class_seconds" => { "Sold" => 600 } },
          "2" => { "team" => 1, "kills" => 6, "deaths" => 8, "flag_stops" => 3, "class_seconds" => { "Sold" => 600 } }
        }
      )
      match_stat.player_match_stats.build(
        name: "bob", team: 2,
        half_stats: {
          "1" => { "team" => 2, "kills" => 4, "deaths" => 10, "flag_stops" => 1, "class_seconds" => { "Sold" => 600 } },
          "2" => { "team" => 2, "kills" => 9, "deaths" => 6, "flag_caps" => 1, "class_seconds" => { "Sold" => 600 } }
        }
      )
      match_stat
    end

    def breakdown(match_stat)
      HalfBreakdown.new(match_stat, match_stat.player_match_stats)
    end

    test "splits rows into attack and defence by the pug convention" do
      tables = breakdown(build_match).tables

      assert_equal [["alice", 1], ["bob", 2]], tables[:attack].map { |row| [row.name, row.half] }
      # defence sorts by team, so alice (team 1, defending half 2) leads
      assert_equal [["alice", 2], ["bob", 1]], tables[:defence].map { |row| [row.name, row.half] }
      assert_equal 10, tables[:attack].first.kills
      assert_equal 3, tables[:defence].first.flag_stops
    end

    test "falls back to plain halves for symmetric matches" do
      tables = breakdown(build_match(attack_defence: false)).tables

      assert_equal %i[first_half second_half], tables.keys
      assert_equal %w[alice bob], tables[:first_half].map(&:name)
    end

    test "excludes players barely present in a half" do
      match_stat = build_match
      match_stat.player_match_stats.first.half_stats["1"]["class_seconds"] = { "Sold" => 100 }

      tables = breakdown(match_stat).tables

      assert_equal [["bob", 2]], tables[:attack].map { |row| [row.name, row.half] }
    end

    test "pairs same-class opponents with duel stats" do
      matchups = breakdown(build_match).matchups

      attack = matchups.find { |matchup| matchup.role == :attack }
      assert_equal "Sold", attack.class_name
      assert_equal %w[alice bob], [attack.left.name, attack.right.name]
      assert_equal({ left_kills: 5, right_kills: 3, left_damage: 400, right_damage: 250 }, attack.duels)

      defence = matchups.find { |matchup| matchup.role == :defence }
      assert_equal %w[alice bob], [defence.left.name, defence.right.name]
      assert_equal 3, defence.left.flag_stops
    end

    test "no matchups without the attack defence convention" do
      assert_empty breakdown(build_match(attack_defence: false)).matchups
    end
  end
end
