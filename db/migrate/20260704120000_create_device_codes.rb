class CreateDeviceCodes < ActiveRecord::Migration[7.2]
  def change
    create_table :device_codes do |t|
      t.string :code, null: false
      t.references :player, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :device_codes, :code, unique: true
  end
end
