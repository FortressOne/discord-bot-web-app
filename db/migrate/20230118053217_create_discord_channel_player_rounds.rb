class CreateDiscordChannelPlayerRounds < ActiveRecord::Migration[7.0]
  def change
    create_table :discord_channel_player_rounds do |t|
      t.references :discord_channel_player, null: false, foreign_key: true, index: {name: "index_dcp_rounds_on_dcp_id"}
      t.references :round, null: false, foreign_key: true
      t.integer :playerclass

      t.timestamps
    end
  end
end
