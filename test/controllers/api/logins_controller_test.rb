require "test_helper"

class Api::LoginsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["TFL_LOGIN_SALT"] = "test-salt"
    @player = players(:one)
    @player.regenerate_auth_token
  end

  test "migrate returns a tfl token for a valid fo_token" do
    post api_login_url, params: {
      type: "migrate", fo_login: @player.name, fo_token: @player.auth_token
    }, as: :json

    assert_response :success
    assert_equal TflToken.mint(@player), response.body
    assert TflToken.verify(response.body)
  end

  test "migrate rejects an unknown fo_token" do
    post api_login_url, params: {
      type: "migrate", fo_login: "whoever", fo_token: "not-a-real-token"
    }, as: :json

    assert_response :forbidden
  end

  test "migrate rejects a blank fo_token" do
    post api_login_url, params: { type: "migrate", fo_login: "x", fo_token: "" }, as: :json

    assert_response :forbidden
  end

  test "check re-mints a valid token" do
    token = TflToken.mint(@player)

    post api_login_url, params: { type: "check", token: token }, as: :json

    assert_response :success
    assert_equal token, response.body
  end

  test "check rejects a token with a forged digest" do
    token = "#{TflToken.sanitize_username(@player.name)}:#{@player.id}:#{@player.id}:0123456789"

    post api_login_url, params: { type: "check", token: token }, as: :json

    assert_response :forbidden
  end

  test "check rejects a valid-shaped token for a deleted player" do
    token = TflToken.mint(@player)
    @player.destroy!

    post api_login_url, params: { type: "check", token: token }, as: :json

    assert_response :forbidden
  end

  test "unknown type is a bad request" do
    post api_login_url, params: { type: "bogus" }, as: :json

    assert_response :bad_request
  end
end
