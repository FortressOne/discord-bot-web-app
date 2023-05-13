class FixDuplicatedDcps < ActiveRecord::Migration[7.0]
  def change
    # Find the duplicates
    duplicates = DiscordChannelPlayer
      .select('player_id, discord_channel_id, COUNT(*) AS count')
      .group(:player_id, :discord_channel_id)
      .having('COUNT(*) > 1')

    duplicates.each do |duplicate|
      # Get all the records for this group
      records = DiscordChannelPlayer
        .where(player_id: duplicate.player_id, 
               discord_channel_id: duplicate.discord_channel_id)

      # Choose the first record to keep
      record_to_keep = records.first

      # Get the IDs of the records to delete
      ids_to_delete = records
        .where.not(id: record_to_keep.id)
        .pluck(:id)

      # Update all references to the deleted records 
      #    to refer to the kept record
      # Update references in DiscordChannelPlayerTeam
      DiscordChannelPlayerTeam
        .where(discord_channel_player_id: ids_to_delete)
        .update_all(discord_channel_player_id: record_to_keep.id)

      # Update references in DiscordChannelPlayerRound
      DiscordChannelPlayerRound
        .where(discord_channel_player_id: ids_to_delete)
        .update_all(discord_channel_player_id: record_to_keep.id)

      # Delete the duplicates
      DiscordChannelPlayer.where(id: ids_to_delete).destroy_all
    end
  end
end
