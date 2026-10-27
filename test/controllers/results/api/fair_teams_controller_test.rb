require "test_helper"

class Results::Api::V1::FairTeamsControllerTest < ActionDispatch::IntegrationTest
  AUTH = { "Authorization" => "Bearer bot-secret" }.freeze

  setup do
    ENV["BOT_API_TOKEN"] = "bot-secret"
    @channel = discord_channels(:one)
  end

  teardown do
    ENV.delete("BOT_API_TOKEN")
  end

  def rate(discord_id, skill)
    player = Player.create!(discord_id: discord_id, name: "p#{discord_id}")
    dcp = DiscordChannelPlayer.create!(player: player, discord_channel: @channel)
    dcpt = DiscordChannelPlayerTeam.create!(discord_channel_player: dcp, team: teams(:one))
    TrueskillRating.create!(trueskill_rateable: dcpt, mean: skill, deviation: 0)
  end

  def fair_teams(players, headers: AUTH, channel_id: @channel.channel_id)
    get "/results/api/v1/fair_teams/new", params: { channel_id: channel_id, players: players }, headers: headers
  end

  test "requires the bot token" do
    fair_teams(%w[1 2], headers: {})
    assert_response :unauthorized

    fair_teams(%w[1 2], headers: { "Authorization" => "Bearer wrong" })
    assert_response :unauthorized
  end

  test "returns splits fairest first" do
    rate("11", 30)
    rate("22", 10)
    rate("33", 20)
    # 44 has never played: skill 0.

    fair_teams(%w[11 22 33 44])

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 3, body.size
    assert_equal({ "1" => %w[44 11], "2" => %w[22 33] }, body.first)
    assert_equal({ "1" => %w[33 11], "2" => %w[22 44] }, body.last)
  end

  test "creates no records" do
    assert_no_difference ["Player.count", "DiscordChannel.count", "DiscordChannelPlayer.count"] do
      fair_teams(%w[901 902 903 904], channel_id: "999999999999")
    end

    assert_response :success
    assert_equal 3, JSON.parse(response.body).size
  end

  test "caps the number of players" do
    fair_teams((1..17).map(&:to_s))
    assert_response :unprocessable_entity

    fair_teams((1..16).map(&:to_s))
    assert_response :success
    assert_equal 6435, JSON.parse(response.body).size
  end

  test "rejects junk players" do
    fair_teams(%w[11 11])
    assert_response :unprocessable_entity

    fair_teams(%w[11 abc])
    assert_response :unprocessable_entity

    fair_teams(%w[11])
    assert_response :unprocessable_entity

    get "/results/api/v1/fair_teams/new", params: { channel_id: @channel.channel_id, players: "11" }, headers: AUTH
    assert_response :unprocessable_entity
  end
end
