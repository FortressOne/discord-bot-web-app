class CreateTrueskillRatings < ActiveRecord::Migration[6.0]
  def change
    create_table :trueskill_ratings do |t|
      t.float :skill, default: 25.0
      t.float :deviation, default: 8.333333333333334
      t.references :player, null: false, foreign_key: true

      t.timestamps
    end
  end
end
