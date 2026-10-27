require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "should get show" do
    get player_url(players(:one))
    assert_response :success
  end

  test "own page offers rotate token as a POST form" do
    sign_in players(:one)

    get player_url(players(:one))

    assert_response :success
    form = Nokogiri::HTML(response.body).at_css("form[action='#{rotate_token_player_path(players(:one))}']")
    assert form, "expected a rotate token form"
    assert_equal "post", form["method"]
  end

  test "rotate token by POST changes the token" do
    player = players(:one)
    player.regenerate_auth_token
    sign_in player

    assert_changes -> { player.reload.auth_token } do
      post rotate_token_player_url(player)
    end

    assert_redirected_to player_url(player)
  end

  test "rotate token is not routable by GET" do
    sign_in players(:one)

    get "/players/#{players(:one).id}/rotate_token"

    assert_response :not_found
  end

  test "cannot rotate someone else's token" do
    sign_in players(:two)

    post rotate_token_player_url(players(:one))

    assert_response :forbidden
  end
end
