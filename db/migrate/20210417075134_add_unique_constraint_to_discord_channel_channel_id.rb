class AddUniqueConstraintToDiscordChannelChannelId < ActiveRecord::Migration[6.0]
  def change
    add_index :discord_channels, :channel_id, unique: true
  end
end
