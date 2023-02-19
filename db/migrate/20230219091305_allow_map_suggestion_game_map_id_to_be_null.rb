class AllowMapSuggestionGameMapIdToBeNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null(:map_suggestions, :game_map_id, true)
  end
end
