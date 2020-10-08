class CreateDiscordChannels < ActiveRecord::Migration[6.0]
  def change
    create_table :discord_channels do |t|
      t.string :channel_id
      t.string :name

      t.timestamps
    end
  end
end
