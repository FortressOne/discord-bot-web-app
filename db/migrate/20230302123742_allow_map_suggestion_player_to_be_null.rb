class AllowMapSuggestionPlayerToBeNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null(:map_suggestions, :player_id, true)
  end
end
