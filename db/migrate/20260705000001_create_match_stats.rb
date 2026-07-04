class CreateMatchStats < ActiveRecord::Migration[7.2]
  def change
    create_table :match_stats do |t|
      t.string :s3_key, null: false
      t.string :region
      t.string :game_mode
      t.string :map_name
      t.datetime :played_at
      t.integer :duration_seconds
      t.string :team1_name
      t.string :team2_name
      t.integer :team1_score
      t.integer :team2_score
      t.integer :winning_team
      t.integer :player_count
      t.string :demo_filename
      t.string :status, null: false, default: "pending"
      t.string :error_message
      t.references :match, foreign_key: true, index: true
      t.timestamps

      t.index :s3_key, unique: true
      t.index :map_name
      t.index :played_at
      t.index [:region, :game_mode]
    end

    create_table :player_match_stats do |t|
      t.references :match_stat, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :team
      t.integer :kills, null: false, default: 0
      t.integer :deaths, null: false, default: 0
      t.integer :teamkills, null: false, default: 0
      t.integer :suicides, null: false, default: 0
      t.integer :sentries_destroyed, null: false, default: 0
      t.integer :damage_given, null: false, default: 0
      t.integer :damage_taken, null: false, default: 0
      t.integer :team_damage, null: false, default: 0
      t.integer :flag_touches, null: false, default: 0
      t.integer :flag_caps, null: false, default: 0
      t.integer :flag_drops, null: false, default: 0
      t.integer :flag_throws, null: false, default: 0
      t.integer :flag_stops, null: false, default: 0
      t.integer :flag_carry_seconds, null: false, default: 0
      t.jsonb :class_seconds, null: false, default: {}
      t.jsonb :weapon_stats, null: false, default: {}
      t.timestamps

      t.index :name
    end
  end
end
