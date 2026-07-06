class AddAllTimeToPlayerMatchStats < ActiveRecord::Migration[7.2]
  def change
    add_column :player_match_stats, :all_time, :string
  end
end
