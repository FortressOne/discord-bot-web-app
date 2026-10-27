require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  def create_match_stat
    match_stat = MatchStat.create!(
      s3_key: "sydney/pub/2022-01-01_00-00-00_[2fort5r]_blue_vs_red.json",
      region: "sydney", game_mode: "pub", map_name: "2fort5r",
      played_at: Time.utc(2022, 1, 1), duration_seconds: 1200,
      team1_name: "blue", team2_name: "red", team1_score: 10, team2_score: 0,
      winning_team: 1, player_count: 2, status: "parsed",
      demo_filename: "2022-01-01_00-00-00_[2fort5r]_blue_vs_red.mvd"
    )
    match_stat.player_match_stats.create!(
      name: "alice", team: 1, kills: 12, deaths: 3, flag_caps: 2, flag_carry_seconds: 65,
      class_seconds: { "Sold" => 1200 },
      weapon_stats: { "rl" => { "shots" => 100, "hits" => 40, "damage" => 3000, "kills" => 10 } }
    )
    match_stat.player_match_stats.create!(name: "bob", team: 2, kills: 3, deaths: 12)
    match_stat
  end

  test "index renders html with filter links" do
    create_match_stat

    get stats_url

    assert_response :success
    assert_match "Match Stats", response.body
    assert_match "2fort5r", response.body
    assert_match "alice", response.body
  end

  test "show renders html with awards and player table" do
    match_stat = create_match_stat

    get stat_url(match_stat)

    assert_response :success
    assert_match "Slaughterhouse", response.body
    assert_match "stats-table", response.body
    assert_match "rl", response.body
  end

  test "index returns browsable stats with filters" do
    match_stat = create_match_stat

    get stats_url(format: :json, map: "2fort5r", player: "alice")

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["count"]
    row = body["stats"].first
    assert_equal match_stat.id, row["id"]
    assert_equal "10 - 0", row["score"]
    assert_equal "20:00", row["duration_display"]
    assert_equal %w[alice bob], row["player_names"]
  end

  test "index filters exclude non-matching maps" do
    create_match_stat

    get stats_url(format: :json, map: "nosuchmap")

    assert_equal 0, JSON.parse(response.body)["count"]
  end

  test "show returns per-player rows with weapon stats" do
    match_stat = create_match_stat

    get stat_url(match_stat, format: :json)

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "2fort5r", body["map"]
    assert_equal 2, body["players"].size
    alice = body["players"].first
    assert_equal "alice", alice["name"]
    assert_equal "4.0", alice["kd_display"]
    assert_equal "1:05", alice["flag_carry_display"]
    assert_equal "Sold 100%", alice["classes_display"]
    rocket = alice["weapons"].first
    assert_equal "rl", rocket["weapon"]
    assert_equal "40%", rocket["accuracy_display"]
  end

  # Crawlers that don't decode "&amp;" request ?map=x&amp;player=y, which
  # Rails parses as a param literally named "amp;player".
  test "index 301s junk params to the canonical listing" do
    get "/stats?map=2fort5r&amp;player=alice&utm_source=x&page=2"

    assert_response :moved_permanently
    assert_redirected_to "/stats?map=2fort5r&page=2"
  end

  test "index 301s junk params when the client accepts anything" do
    get "/stats?map=2fort5r&amp;player=alice", headers: { "Accept" => "*/*" }

    assert_response :moved_permanently
    assert_redirected_to "/stats?map=2fort5r"
  end

  test "index ignores junk params on JSON requests" do
    get "/stats.json?map=2fort5r&amp;player=alice"

    assert_response :success
  end

  test "index 301s nested param values" do
    get "/stats?map[]=2fort5r&region=sydney"

    assert_response :moved_permanently
    assert_redirected_to "/stats?region=sydney"
  end

  test "index does not redirect known params" do
    create_match_stat

    get "/stats?map=2fort5r&region=&mode=&player="

    assert_response :success
  end

  test "index ignores unknown params on json" do
    create_match_stat

    get "/stats.json?map=2fort5r&amp;player=nobody"

    assert_response :success
    assert_equal 1, JSON.parse(response.body)["count"]
  end

  test "index ignores nested filter values on json instead of erroring" do
    create_match_stat

    get "/stats.json?map[x]=1&player[]=alice"

    assert_response :success
    assert_equal 1, JSON.parse(response.body)["count"]
  end

  test "filter links carry only known filters and are nofollow" do
    create_match_stat

    get "/stats?mode=pub&region="

    assert_response :success
    doc = Nokogiri::HTML(response.body)
    map_link = doc.css("a[href^='/stats?']").find { |a| a.text == "2fort5r" }
    assert map_link, "expected a map filter link"
    assert_equal "nofollow", map_link["rel"]
    assert_equal({ "map" => "2fort5r", "mode" => "pub" }, Rack::Utils.parse_query(URI(map_link["href"]).query))
    doc.css("a[href^='/stats?']").each do |a|
      query = Rack::Utils.parse_query(URI(a["href"]).query)
      assert_empty query.keys - StatsController::FILTER_PARAMS, a["href"]
      assert query.values.all?(&:present?), a["href"]
    end
    # The filter form doesn't submit a "commit" param.
    assert_nil doc.at_css("form input[type=submit]")["name"]
  end

  test "pagination links carry only known params" do
    rows = Array.new(StatsController::PAGE_ITEMS + 1) do |i|
      { s3_key: "k#{i}", status: "parsed", map_name: "2fort5r", region: "sydney", game_mode: "pub",
        played_at: Time.utc(2022, 1, 1) + i.minutes, created_at: Time.current, updated_at: Time.current }
    end
    MatchStat.insert_all!(rows)

    get "/stats?map=2fort5r&mode="

    assert_response :success
    page_links = Nokogiri::HTML(response.body).css("nav.pagy-nav a").map { |a| a["href"] }
    assert_includes page_links, "/stats?map=2fort5r&page=2"
    assert page_links.all? { |href| Rack::Utils.parse_query(URI(href).query).keys.sort == %w[map page] }
  end

  test "out of range page is a 404, not a 500" do
    create_match_stat

    get "/stats?page=999"
    assert_response :not_found

    get "/stats.json?page=999"
    assert_response :not_found
  end

  test "invalid page is a 404, not a 500" do
    get "/stats?page=0"
    assert_response :not_found

    get "/stats?page=abc"
    assert_response :not_found
  end
end
