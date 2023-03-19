class AddTeamsCountWinningTeamsCountLosingTeamsCountDrawingTeamsCountToDiscordChannelPlayers < ActiveRecord::Migration[7.0]
  def self.up
    add_column :discord_channel_players, :teams_count, :integer, null: false, default: 0
    add_column :discord_channel_players, :winning_teams_count, :integer, null: false, default: 0
    add_column :discord_channel_players, :losing_teams_count, :integer, null: false, default: 0
    add_column :discord_channel_players, :drawing_teams_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :discord_channel_players, :teams_count
    remove_column :discord_channel_players, :winning_teams_count
    remove_column :discord_channel_players, :losing_teams_count
    remove_column :discord_channel_players, :drawing_teams_count
  end
end
