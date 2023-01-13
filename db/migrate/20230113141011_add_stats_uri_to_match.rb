class AddStatsUriToMatch < ActiveRecord::Migration[7.0]
  def change
    add_column :matches, :stats_uri, :string
  end
end
