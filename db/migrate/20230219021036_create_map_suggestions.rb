class CreateMapSuggestions < ActiveRecord::Migration[7.0]
  def change
    create_table :map_suggestions do |t|
      t.references :game_map, null: false, foreign_key: true
      t.references :discord_channel, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true

      t.timestamps
    end
  end
end
