class AddTimestampsToDiscordChannelPlayerTeams < ActiveRecord::Migration[7.0]
  def change
    add_timestamps :discord_channel_player_teams, null: true
  end
end
