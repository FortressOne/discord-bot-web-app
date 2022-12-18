class RemoveDiscordChannelPlayerIdFromTrueskillRatings < ActiveRecord::Migration[7.0]
  def change
    remove_column :trueskill_ratings, :discord_channel_player_id, :int
  end
end
