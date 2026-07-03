require "test_helper"

class Api::TokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["TFL_LOGIN_SALT"] = "test-salt"
    ENV["BOT_API_TOKEN"] = "bot-secret"
    @headers = { "Authorization" => "Bearer bot-secret" }
    @player = players(:one)
  end

  test "mints a token for an existing player by discord_id" do
    post api_token_url, params: { discord_id: @player.discord_id.to_i.to_s },
                        headers: @headers, as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal TflToken.mint(@player), body["token"]
    assert_equal @player.name, body["name"]
  end

  test "creates a player for an unknown discord_id" do
    assert_difference "Player.count", 1 do
      post api_token_url, params: { discord_id: "300000000000000003", name: "fresh" },
                          headers: @headers, as: :json
    end

    assert_response :success
    player = Player.find_by(discord_id: "300000000000000003")
    assert_equal "fresh", player.name
    assert_equal TflToken.mint(player), response.parsed_body["token"]
  end

  test "unknown discord_id without a name is unprocessable" do
    assert_no_difference "Player.count" do
      post api_token_url, params: { discord_id: "300000000000000004" },
                          headers: @headers, as: :json
    end

    assert_response :unprocessable_entity
  end

  test "rejects a missing bearer token" do
    post api_token_url, params: { discord_id: @player.discord_id.to_i.to_s }, as: :json

    assert_response :unauthorized
  end

  test "rejects a wrong bearer token" do
    post api_token_url, params: { discord_id: @player.discord_id.to_i.to_s },
                        headers: { "Authorization" => "Bearer nope" }, as: :json

    assert_response :unauthorized
  end

  test "missing discord_id is a bad request" do
    post api_token_url, params: { name: "x" }, headers: @headers, as: :json

    assert_response :bad_request
  end
end
