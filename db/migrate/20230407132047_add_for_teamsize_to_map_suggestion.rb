class AddForTeamsizeToMapSuggestion < ActiveRecord::Migration[7.0]
  def change
    add_column :map_suggestions, :for_teamsize, :integer
  end
end
