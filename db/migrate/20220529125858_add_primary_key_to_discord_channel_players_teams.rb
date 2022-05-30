class AddPrimaryKeyToDiscordChannelPlayersTeams < ActiveRecord::Migration[7.0]
  def change
    add_column :discord_channel_players_teams, :id, :primary_key
  end
end
