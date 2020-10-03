# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_03_050611) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "game_maps", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "game_map_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["game_map_id"], name: "index_matches_on_game_map_id"
  end

  create_table "players", force: :cascade do |t|
    t.decimal "discord_id"
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "players_teams", id: false, force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "player_id", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "result"
    t.bigint "match_id", null: false
    t.string "name"
    t.index ["match_id"], name: "index_teams_on_match_id"
  end

  add_foreign_key "matches", "game_maps"
  add_foreign_key "teams", "matches"
end
