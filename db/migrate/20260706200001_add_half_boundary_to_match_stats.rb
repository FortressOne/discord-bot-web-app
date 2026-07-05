class AddHalfBoundaryToMatchStats < ActiveRecord::Migration[7.2]
  def change
    add_column :match_stats, :half_boundary_seconds, :integer
  end
end
