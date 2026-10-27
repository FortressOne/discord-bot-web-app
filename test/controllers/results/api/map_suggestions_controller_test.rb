require "test_helper"

class Results::Api::V1::MapSuggestionsControllerTest < ActionDispatch::IntegrationTest
  AUTH = { "Authorization" => "Bearer bot-secret" }.freeze

  setup do
    ENV["BOT_API_TOKEN"] = "bot-secret"
    @channel_id = discord_channels(:one).channel_id
  end

  teardown do
    ENV.delete("BOT_API_TOKEN")
  end

  def vote(size, headers: AUTH)
    post "/results/api/v1/map_suggestions/vote", as: :json, headers: headers,
         params: { map_suggestion: { channel_id: @channel_id, for_teamsize: 4 }, size: size, except: ["2fort5r"] }
  end

  test "all actions require the bot token" do
    assert_no_difference "MapSuggestion.count" do
      vote(3, headers: {})
      assert_response :unauthorized

      post "/results/api/v1/map_suggestions", as: :json,
           params: { map_suggestion: { channel_id: @channel_id, discord_player_id: "5", for_teamsize: 4 } }
      assert_response :unauthorized
    end

    get "/results/api/v1/map_suggestions", params: { map_suggestion: { discord_channel_id: @channel_id } }
    assert_response :unauthorized
  end

  test "vote creates the requested number of suggestions" do
    assert_difference "MapSuggestion.count", 2 do
      vote(2)
    end

    assert_response :success
    assert_equal 2, JSON.parse(response.body).size
  end

  test "vote size is clamped" do
    assert_difference "MapSuggestion.count", Results::Api::V1::MapSuggestionsController::MAX_VOTE_SIZE do
      vote(1_000_000)
    end
    assert_response :success

    assert_difference "MapSuggestion.count", 1 do
      vote(-5)
    end
    assert_response :success
  end

  test "index for an unknown channel is empty, not a 500" do
    get "/results/api/v1/map_suggestions", headers: AUTH,
        params: { map_suggestion: { discord_channel_id: "123456789" } }

    assert_response :success
    assert JSON.parse(response.body).values.all?(&:empty?)
  end
end
