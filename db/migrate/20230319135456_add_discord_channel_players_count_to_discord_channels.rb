class AddDiscordChannelPlayersCountToDiscordChannels < ActiveRecord::Migration[7.0]
  def self.up
    add_column :discord_channels, :discord_channel_players_count, :integer, null: false, default: 0
  end

  def self.down
    remove_column :discord_channels, :discord_channel_players_count
  end
end
