class AddReferenceToDiscordChannelPlayerInTrueskillRating < ActiveRecord::Migration[6.0]
  def change
    add_reference :trueskill_ratings, :discord_channel_player, foreign_key: true
  end
end
