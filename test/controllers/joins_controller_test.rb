require "test_helper"

class JoinsControllerTest < ActionDispatch::IntegrationTest
  test "join page renders with address" do
    get "/join/sheldon-t470:27511"
    assert_response :success
    assert_includes response.body, "sheldon-t470:27511"
    assert_includes response.body, "fo://sheldon-t470:27511/join"
  end

  test "spectate variant" do
    get "/spectate/192.168.1.50:27511"
    assert_includes response.body, "fo://192.168.1.50:27511/spectate"
  end

  test "garbage address rejected" do
    get "/join/%3Cscript%3E"
    assert_response :bad_request
    assert_empty response.body
  end
end
