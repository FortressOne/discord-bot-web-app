# Matches in Coachs:
# 2293


desc "fix data"
task fix_data: :environment do 
  Match.find(2293).update(discord_channel_id: 911)

  bad_dcpts = DiscordChannelPlayerTeam.all.select do |dcpt|
    dcpt.discord_channel_player.discord_channel_id != dcpt.team.match.discord_channel_id
  end

  bad_dcpts.each do |dcpt|
    old_dcp = dcpt.discord_channel_player

    new_dcp = DiscordChannelPlayer.find_or_create_by(
      discord_channel_id: dcpt.team.match.discord_channel_id,
      player_id: dcpt.discord_channel_player.player_id
    )

    dcpt.update(discord_channel_player_id: new_dcp.id)
  end
end
