class AddDamageReceivedToPlayerMatchStats < ActiveRecord::Migration[7.2]
  def change
    add_column :player_match_stats, :damage_received, :jsonb, null: false, default: {}
  end
end
