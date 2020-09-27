class CreateTeams < ActiveRecord::Migration[6.0]
  def change
    create_table :teams do |t|
      t.timestamps
      t.integer :result

      t.references :match, null: false, foreign_key: true
    end
  end
end
