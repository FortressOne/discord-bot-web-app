namespace :data_migration do
  desc 'migration for per-channel ratings'
  task per_channel_ratings: :environment do

    TrueskillRating.destroy_all
    DiscordChannelPlayer.destroy_all

    oce = DiscordChannel.create(
      channel_id: "542237808895459338",
      name: "FortressOne #oceania"
    )

    na = DiscordChannel.create(
      channel_id: "731615877732106268",
      name: "QuakeWorld Team Fortress #🔫pick-up-games"
    )

    Match.all.each do |match|
      if match.discord_channel.channel_id == oce.channel_id
        match.discord_channel_id = oce.id
      end

      if match.discord_channel.channel_id == na.channel_id
        match.discord_channel_id = na.id
      end
      match.save
    end

    DiscordChannel.where.not(id: oce.id).where.not(id: na.id).destroy_all

    Team.all.each do |team|
      discord_channel_id = team.match.discord_channel_id

      team.players.each do |player|
        dcp = DiscordChannelPlayer.find_or_create_by(
          discord_channel_id: discord_channel_id,
          player_id: player.id
        )

        dcp.teams << team
        dcp.save
      end
    end
  end
end
