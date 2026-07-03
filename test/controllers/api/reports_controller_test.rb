require "test_helper"

class Api::ReportsControllerTest < ActionDispatch::IntegrationTest
  # Shaped like ReportMatchResult in server-qwprogs ssqc/json.qc.
  REPORT = {
    server_name: "Zel's FortressOne QWTF-Live Test",
    server_address: "home.sheldonjohnson.net:27515",
    region: "oceania",
    shard: "test",
    game_token: "20260704_test_2fort5r",
    report_type: "end",
    map: "2fort5r",
    teams: [
      { score: 5, players: [{ username: "zel", fo_token: "abc", pc: 4 }] },
      { score: 3, players: [{ username: "newby", fo_token: "def", pc: 9 }] }
    ],
    mvd: "2fort5r_20260704.mvd",
    round_start: 100,
    round_end: 1300
  }.freeze

  test "persists a match report and returns ok" do
    assert_difference "MatchReport.count", 1 do
      post api_report_url, params: REPORT, as: :json
    end

    assert_response :success

    report = MatchReport.last
    assert_equal "20260704_test_2fort5r", report.game_token
    assert_equal "end", report.report_type
    assert_equal "2fort5r", report.map
    assert_equal 5, report.payload["teams"][0]["score"]
    assert_equal "zel", report.payload["teams"][0]["players"][0]["username"]
  end

  test "rejects a report with no game_token" do
    assert_no_difference "MatchReport.count" do
      post api_report_url, params: REPORT.except(:game_token), as: :json
    end

    assert_response :unprocessable_entity
  end
end
