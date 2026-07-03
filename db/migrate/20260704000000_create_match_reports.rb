class CreateMatchReports < ActiveRecord::Migration[7.2]
  def change
    create_table :match_reports do |t|
      t.string :game_token, null: false
      t.string :report_type, null: false
      t.string :map
      t.string :server_name
      t.string :server_address
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :match_reports, :game_token
    add_index :match_reports, :report_type
  end
end
