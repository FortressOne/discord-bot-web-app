require "test_helper"

class Stats::PlayerLinkerTest < ActiveSupport::TestCase
  test "links exact names case-insensitively" do
    player = Player.create!(name: "Haze")

    assert_equal player.id, Stats::PlayerLinker.new.player_id_for("haze")
  end

  test "links sanitized login usernames" do
    player = Player.create!(name: "dr no")

    # login-era event logs carry TflToken.sanitize_username(player.name)
    assert_equal player.id, Stats::PlayerLinker.new.player_id_for("dr_no")
  end

  test "never links ambiguous names" do
    Player.create!(name: "sam jones")
    Player.create!(name: "sam_jones")

    assert_nil Stats::PlayerLinker.new.player_id_for("sam_jones")
  end

  test "returns nil for unknown names" do
    assert_nil Stats::PlayerLinker.new.player_id_for("stranger")
  end
end
