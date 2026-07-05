class AddHalfStats < ActiveRecord::Migration[7.2]
  def change
    add_column :player_match_stats, :half_stats, :jsonb, null: false, default: {}
    add_column :match_stats, :kill_matrix, :jsonb, null: false, default: {}
    add_column :match_stats, :attack_defence, :boolean, null: false, default: false
  end
end
