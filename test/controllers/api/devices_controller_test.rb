require "test_helper"

class Api::DevicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["TFL_LOGIN_SALT"] = "test-salt"
  end

  test "mints a pairing code" do
    post api_device_url

    assert_response :success
    assert_match(/\A[A-Z2-9]{4}-[A-Z2-9]{4}\z/, response.body)
    assert DeviceCode.exists?(code: response.body)
  end

  test "polling a pending code" do
    code = DeviceCode.mint

    get "/api/device/#{code.code}"

    assert_response :success
    assert_equal "pending", response.body
  end

  test "polling an approved code releases the token exactly once" do
    code = DeviceCode.mint
    code.approve(players(:one))

    get "/api/device/#{code.code}"
    assert_equal "token #{TflToken.mint(players(:one))}", response.body

    get "/api/device/#{code.code}"
    assert_equal "expired", response.body
  end

  test "polling normalizes user-mangled codes" do
    code = DeviceCode.mint

    get "/api/device/#{code.code.delete('-').downcase}"

    assert_equal "pending", response.body
  end

  test "polling an unknown or expired code" do
    get "/api/device/ZZZZ-9999"
    assert_equal "expired", response.body

    code = DeviceCode.mint
    code.update!(expires_at: 1.minute.ago)
    get "/api/device/#{code.code}"
    assert_equal "expired", response.body
  end
end
