require "test_helper"

class Api::WhoamiControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["TFL_LOGIN_SALT"] = "test-salt"
  end

  test "valid token returns name and avatar" do
    player = players(:one)
    player.update!(image: "https://cdn.discordapp.com/avatars/1/abc.png")

    post api_whoami_url, params: { token: TflToken.mint(player) }

    assert_response :success
    assert_equal "name #{player.name}\navatar https://cdn.discordapp.com/avatars/1/abc.png", response.body
  end

  test "non-url image is omitted" do
    player = players(:one)
    player.update!(image: "home/classes/scout.png")

    post api_whoami_url, params: { token: TflToken.mint(player) }

    assert_equal "name #{player.name}", response.body
  end

  test "bad token is unauthorized" do
    post api_whoami_url, params: { token: "zel:16:16:0000000000" }

    assert_response :unauthorized
  end
end
