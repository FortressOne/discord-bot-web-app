namespace :data_migration do
  desc 'create discord channel players'
  task create_discord_channel_players: :environment do
    TrueskillRating.destroy_all

    Match.all.each do |match|
      discord_channel_id = match.discord_channel_id

      match.players.each do |player|
        DiscordChannelPlayer.find_or_create_by(
          discord_channel_id: discord_channel_id,
          player_id: player.id
        )
      end
    end

    Team.all.each do |team|
      discord_channel_id = team.match.discord_channel_id

      team.players.each do |player|
        dcp = DiscordChannelPlayer.find_or_create_by(
          discord_channel_id: discord_channel_id,
          player_id: player.id,
        )

        dcp.teams << team
        dcp.save
      end
    end
  end
end
