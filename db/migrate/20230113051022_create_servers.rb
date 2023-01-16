class CreateServers < ActiveRecord::Migration[7.0]
  def change
    create_table :servers do |t|
      t.string :name
      t.string :address

      t.timestamps
    end

    add_reference :matches, :server, foreign_key: true
  end
end
