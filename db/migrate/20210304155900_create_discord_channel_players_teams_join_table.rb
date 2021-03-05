class CreateDiscordChannelPlayersTeamsJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_join_table :discord_channel_players, :teams
  end
end
