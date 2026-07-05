require "test_helper"

class JoinsControllerTest < ActionDispatch::IntegrationTest
  test "join page renders with address" do
    get "/join/sheldon-t470:27511"
    assert_response :success
    assert_includes response.body, "sheldon-t470:27511"
    assert_includes response.body, "fo://join/sheldon-t470:27511"
  end

  test "spectate variant" do
    get "/spectate/192.168.1.50:27511"
    assert_includes response.body, "fo://spectate/192.168.1.50:27511"
  end

  test "garbage address rejected" do
    get "/join/%3Cscript%3E"
    assert_response :bad_request
  end
end
