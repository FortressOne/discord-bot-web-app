require "test_helper"

class LinksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "shows the approve form" do
    get link_url(code: "ABCD-1234")

    assert_response :success
  end

  test "approving requires sign in" do
    code = DeviceCode.mint

    post link_url, params: { code: code.code }

    assert_redirected_to link_path(code: code.code)
    assert_equal "pending", code.reload.status
  end

  test "signed-in player approves a code" do
    code = DeviceCode.mint
    sign_in players(:one)

    post link_url, params: { code: code.code }

    assert_response :success
    code.reload
    assert_equal "approved", code.status
    assert_equal players(:one), code.player
  end

  test "cannot re-approve someone else's code" do
    code = DeviceCode.mint
    code.approve(players(:one))
    sign_in players(:two)

    post link_url, params: { code: code.code }

    assert_redirected_to link_path(code: code.code)
    assert_equal players(:one), code.reload.player
  end
end
