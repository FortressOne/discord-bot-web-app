class AddTrueskillRateableIdAndTypeToTrueskillRating < ActiveRecord::Migration[7.0]
  def change
    add_column :trueskill_ratings, :trueskill_rateable_id, :bigint
    add_column :trueskill_ratings, :trueskill_rateable_type, :string
    add_index :trueskill_ratings, [:trueskill_rateable_type, :trueskill_rateable_id], name: 'index_tr_on_tr_type_and_tr_id'

    TrueskillRating.all.each do |tr|
      tr.trueskill_rateable_type = "DiscordChannelPlayer"
      tr.trueskill_rateable_id = tr.discord_channel_player_id
      tr.save
    end
  end
end
