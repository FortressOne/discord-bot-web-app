class CreateDiscordChannelPlayerTeamRounds < ActiveRecord::Migration[7.0]
  def change
    rename_table :discord_channel_players_teams, :discord_channel_player_teams

    create_table :discord_channel_player_team_rounds do |t|
      t.references(
        :discord_channel_player_team,
        null: false,
        foreign_key: true,
        index: { name: "index_dcpt_rounds_on_dcpt_id" }
      )

      t.references :round, null: false, foreign_key: true
      t.integer :playerclass

      t.timestamps
    end
  end
end
