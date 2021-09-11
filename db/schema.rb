# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_09_11_145347) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "discord_channel_players", force: :cascade do |t|
    t.bigint "discord_channel_id", null: false
    t.bigint "player_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["discord_channel_id"], name: "index_discord_channel_players_on_discord_channel_id"
    t.index ["player_id"], name: "index_discord_channel_players_on_player_id"
  end

  create_table "discord_channel_players_teams", id: false, force: :cascade do |t|
    t.bigint "discord_channel_player_id", null: false
    t.bigint "team_id", null: false
  end

  create_table "discord_channels", force: :cascade do |t|
    t.string "channel_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "rated", default: false, null: false
    t.index ["channel_id"], name: "index_discord_channels_on_channel_id", unique: true
  end

  create_table "game_maps", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "game_map_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "ratings_processed"
    t.bigint "discord_channel_id"
    t.index ["discord_channel_id"], name: "index_matches_on_discord_channel_id"
    t.index ["game_map_id"], name: "index_matches_on_game_map_id"
  end

  create_table "players", force: :cascade do |t|
    t.decimal "discord_id"
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "invisible", default: false, null: false
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "result"
    t.bigint "match_id", null: false
    t.string "name"
    t.index ["match_id"], name: "index_teams_on_match_id"
  end

  create_table "trueskill_ratings", force: :cascade do |t|
    t.float "mean", default: 25.0
    t.float "deviation", default: 8.333333333333334
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "discord_channel_player_id"
    t.index ["discord_channel_player_id"], name: "index_trueskill_ratings_on_discord_channel_player_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "discord_channel_players", "discord_channels"
  add_foreign_key "discord_channel_players", "players"
  add_foreign_key "matches", "discord_channels"
  add_foreign_key "matches", "game_maps"
  add_foreign_key "teams", "matches"
  add_foreign_key "trueskill_ratings", "discord_channel_players"
end
