class AddTimestampsToDiscordChannelPlayerTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :discord_channel_player_teams, :created_at, :datetime
    add_column :discord_channel_player_teams, :updated_at, :datetime
  end
end
