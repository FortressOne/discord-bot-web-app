class CreatePlayers < ActiveRecord::Migration[6.0]
  def change
    create_table :players do |t|
      t.decimal :discord_id
      t.string :name
      t.string :email

      t.timestamps
    end
  end
end
