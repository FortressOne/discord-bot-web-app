class AddDiscordChannelPlayerTeamsCountToTeams < ActiveRecord::Migration[7.0]
  def self.up
    add_column :teams, :discord_channel_player_teams_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :teams, :discord_channel_player_teams_count
  end
end
