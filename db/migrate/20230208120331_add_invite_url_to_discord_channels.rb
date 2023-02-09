class AddInviteUrlToDiscordChannels < ActiveRecord::Migration[7.0]
  def change
    add_column :discord_channels, :invite_url, :string
  end
end
