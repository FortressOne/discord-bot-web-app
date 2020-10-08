class AddDiscordChannelReferenceToMatch < ActiveRecord::Migration[6.0]
  def change
    add_reference :matches, :discord_channel, foreign_key: true
  end
end
