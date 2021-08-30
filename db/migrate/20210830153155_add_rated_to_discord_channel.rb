class AddRatedToDiscordChannel < ActiveRecord::Migration[6.0]
  def change
    add_column :discord_channels, :rated, :boolean, null: false, default: false
  end
end
