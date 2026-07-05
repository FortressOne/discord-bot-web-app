require "test_helper"

class MatchStatTest < ActiveSupport::TestCase
  def build_stat(**attributes)
    MatchStat.new(
      s3_key: "sydney/pub/x.json", status: "parsed",
      team1_name: "blue", team2_name: "red",
      duration_seconds: 1200, half_boundary_seconds: 600,
      **attributes
    )
  end

  test "blue wins by points" do
    stat = build_stat(winning_team: 1, team1_score: 50, team2_score: 30)

    assert_equal "Blue wins by 20 points", stat.result_description
  end

  test "red wins with time remaining when the match ended early" do
    stat = build_stat(winning_team: 2, team1_score: 50, team2_score: 60, duration_seconds: 1027)

    assert_equal "Red wins with 2m 53s remaining", stat.result_description
  end

  test "red full-time win falls back to points" do
    stat = build_stat(winning_team: 2, team1_score: 30, team2_score: 40)

    assert_equal "Red wins by 10 points", stat.result_description
  end

  test "draw" do
    stat = build_stat(winning_team: 0, team1_score: 30, team2_score: 30)

    assert_equal "Draw!", stat.result_description
  end
end
