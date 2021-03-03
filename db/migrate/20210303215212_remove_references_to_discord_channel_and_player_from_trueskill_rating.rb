class RemoveReferencesToDiscordChannelAndPlayerFromTrueskillRating < ActiveRecord::Migration[6.0]
  def change
    remove_reference :trueskill_ratings, :player, index: true, foreign_key: true
    remove_reference :trueskill_ratings, :discord_channel, index: true, foreign_key: true
  end
end
