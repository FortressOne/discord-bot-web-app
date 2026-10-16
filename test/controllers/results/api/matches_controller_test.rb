require "test_helper"

class Results::Api::V1::MatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["BOT_API_TOKEN"] = "bot-secret"
    @uneven_match = {
      match: {
        server: { address: "test.example:27500", name: "test" },
        teams: { "1" => { players: [{ id: 1 }] }, "2" => { players: [] } }
      }
    }
  end

  test "create rejects requests without the bot token" do
    assert_no_difference "Server.count" do
      post "/results/api/v1/matches", params: @uneven_match, as: :json
    end

    assert_response :unauthorized
  end

  test "create rejects a wrong bot token" do
    assert_no_difference "Server.count" do
      post "/results/api/v1/matches", params: @uneven_match, as: :json,
           headers: { "Authorization" => "Bearer wrong" }
    end

    assert_response :unauthorized
  end

  test "create rejects requests when no bot token is configured" do
    ENV.delete("BOT_API_TOKEN")
    post "/results/api/v1/matches", params: @uneven_match, as: :json,
         headers: { "Authorization" => "Bearer " }

    assert_response :unauthorized
  end

  test "create accepts the bot token" do
    post "/results/api/v1/matches", params: @uneven_match, as: :json,
         headers: { "Authorization" => "Bearer bot-secret" }

    # Past auth: the uneven teams are then rejected by validation.
    assert_response :unprocessable_entity
  end

  test "update rejects requests without the bot token" do
    match = matches(:one)

    post "/results/api/v1/matches/#{match.id}",
         params: { match: { id: match.id, winner: 1, teams: {} } }, as: :json

    assert_response :unauthorized
  end
end
