require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get player_url(players(:one))
    assert_response :success
  end
end
