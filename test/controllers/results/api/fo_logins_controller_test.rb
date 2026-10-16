require "test_helper"

class Results::Api::FoLoginsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @player = players(:one)
    @player.regenerate_auth_token
  end

  %w[v1 v2].each do |version|
    test "#{version} logs in with a valid auth_token" do
      post "/results/api/#{version}/fo_login",
           params: { fo_login: { auth_token: @player.auth_token } }, as: :json

      assert_response :success
    end

    test "#{version} rejects a wrong auth_token" do
      post "/results/api/#{version}/fo_login",
           params: { fo_login: { auth_token: "not-a-real-token" } }, as: :json

      assert_response :forbidden
    end

    test "#{version} rejects a missing auth_token" do
      post "/results/api/#{version}/fo_login", params: { fo_login: { x: 1 } }, as: :json

      assert_response :forbidden
      assert_not_includes response.body, @player.auth_token
    end

    test "#{version} rejects a blank auth_token" do
      post "/results/api/#{version}/fo_login", params: { fo_login: { auth_token: "" } }, as: :json

      assert_response :forbidden
    end
  end

  test "v2 returns the player's own token only for that token" do
    post "/results/api/v2/fo_login",
         params: { fo_login: { auth_token: @player.auth_token } }, as: :json

    assert_equal @player.id, response.parsed_body.dig("player", "id")
  end
end
