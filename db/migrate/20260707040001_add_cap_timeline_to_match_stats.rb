class AddCapTimelineToMatchStats < ActiveRecord::Migration[7.2]
  def change
    add_column :match_stats, :cap_timeline, :jsonb, null: false, default: []
  end
end
