class AddPlayerToPlayerMatchStats < ActiveRecord::Migration[7.2]
  def change
    add_reference :player_match_stats, :player, foreign_key: true, index: true
  end
end
