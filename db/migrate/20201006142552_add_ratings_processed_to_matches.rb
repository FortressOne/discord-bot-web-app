class AddRatingsProcessedToMatches < ActiveRecord::Migration[6.0]
  def change
    add_column :matches, :ratings_processed, :bool
  end
end
