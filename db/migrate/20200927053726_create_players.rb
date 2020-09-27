class CreatePlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :players do |t|
      t.decimal :discord_id
      t.string :email
      t.string :username

      t.timestamps
    end
    add_index :players, :discord_id, unique: true
  end
end
