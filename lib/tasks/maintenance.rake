namespace :maintenance do
  desc "Fix duplicate discord_channel_players"
  task fix_dup_dcps: [:environment] do

    # 1. Find the duplicates
    duplicates = DiscordChannelPlayer
      .select('player_id, discord_channel_id, COUNT(*) AS count')
      .group(:player_id, :discord_channel_id)
      .having('COUNT(*) > 1')

    duplicates.each do |duplicate|
      # 2. Get all the records for this group
      records = DiscordChannelPlayer
        .where(player_id: duplicate.player_id, 
               discord_channel_id: duplicate.discord_channel_id)

      # Choose the first record to keep
      record_to_keep = records.first

      # Get the IDs of the records to delete
      ids_to_delete = records
        .where.not(id: record_to_keep.id)
        .pluck(:id)

      # 3. Update all references to the deleted records 
      #    to refer to the kept record
      # Update references in DiscordChannelPlayerTeam
      DiscordChannelPlayerTeam
        .where(discord_channel_player_id: ids_to_delete)
        .update_all(discord_channel_player_id: record_to_keep.id)

      # Update references in DiscordChannelPlayerRound
      DiscordChannelPlayerRound
        .where(discord_channel_player_id: ids_to_delete)
        .update_all(discord_channel_player_id: record_to_keep.id)

      # 4. Delete the duplicates
      DiscordChannelPlayer.where(id: ids_to_delete).destroy_all
    end
  end

  desc "Cleanup, recalculate ratings, recache counts"
  task cleanup: [:environment] do
    puts "delete invalid discord channels"
    DiscordChannel.where(name: nil).each { |dc| dc.destroy }

    puts "remove incomplete matches"
    unfinished_matches = Match.select { |m| m.teams.any? { |t| t.result.nil? } }
    unfinished_matches.each { |m| m.destroy }

    puts "recalculate ratings"
    TrueskillRating.destroy_all

    DiscordChannelPlayer.all.each do |dcp|
      dcp.create_trueskill_rating
    end

    Match.order(:created_at).each do |match|
      match.update_trueskill_ratings
    end

    puts "recalculate counter_caches"
    DiscordChannelPlayer.counter_culture_fix_counts
    DiscordChannelPlayerTeam.counter_culture_fix_counts
  end
end
