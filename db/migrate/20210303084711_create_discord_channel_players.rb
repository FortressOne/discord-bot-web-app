class CreateDiscordChannelPlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :discord_channel_players do |t|
      t.references :discord_channel, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true

      t.timestamps
    end
  end
end
