require "csv"

namespace :snoozerlan do
  desc "enter snoozerlan results"
  task build: :environment do
    discord_channel = DiscordChannel.find_by!(channel_id: 521616424549089280)
    discord_channel.matches.destroy_all

    time = Time.parse("2021-12-11 14:30:00").in_time_zone("Sydney")

    CSV.foreach('tr.csv') do |row|
      m = discord_channel.matches.create
      m.update(created_at: time)
      time += 30.minutes

      t1 = m.teams.new

      t1.discord_channel_players = ["wm", "hydr0buds", "Snoozer", "haze"].map do |name|
        player_id = Player.find_by!(name: name).id
        DiscordChannelPlayer.find_by!(player_id: player_id, discord_channel_id: discord_channel.id)
      end

      t1.save

      t2 = m.teams.new

      t2.discord_channel_players = ["blindcant", "driz", "Wolv", "zel"].map do |name|
        player_id = Player.find_by!(name: name).id
        DiscordChannelPlayer.find_by!(player_id: player_id, discord_channel_id: discord_channel.id)
      end

      t2.save

      m.game_map = GameMap.find_or_create_by(name: row.first)

      case row.last
      when "a"
        t1.update(result: 1)
        t2.update(result: -1)
      when "n"
        t1.update(result: -1)
        t2.update(result: 1)
      when "d"
        t1.update(result: 0)
        t2.update(result: 0)
      end

      m.save
    end
  end
end
