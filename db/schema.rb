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

ActiveRecord::Schema[8.1].define(version: 2026_10_31_160510) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "pg_catalog.plpgsql"

  create_table "actors", force: :cascade do |t|
    t.citext "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_actors_on_name", unique: true
  end

  create_table "filming_locations", force: :cascade do |t|
    t.citext "name", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "country"], name: "index_filming_locations_on_name_and_country", unique: true
  end

  create_table "imports", force: :cascade do |t|
    t.string "kind", null: false
    t.string "status", default: "pending", null: false
    t.string "source_path", null: false
    t.string "file_checksum", null: false
    t.integer "rows_processed", default: 0, null: false
    t.integer "rows_failed", default: 0, null: false
    t.jsonb "failures", default: [], null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_checksum"], name: "index_imports_on_active_file_checksum", unique: true, where: "((status)::text = ANY ((ARRAY['running'::character varying, 'completed'::character varying])::text[]))"
  end

  create_table "movie_actors", force: :cascade do |t|
    t.bigint "movie_id", null: false
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_movie_actors_on_actor_id"
    t.index ["movie_id", "actor_id"], name: "index_movie_actors_on_movie_id_and_actor_id", unique: true
  end

  create_table "movie_filming_locations", force: :cascade do |t|
    t.bigint "movie_id", null: false
    t.bigint "filming_location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["filming_location_id"], name: "index_movie_filming_locations_on_filming_location_id"
    t.index ["movie_id", "filming_location_id"], name: "index_movie_filming_locations_on_movie_and_location", unique: true
  end

  create_table "movies", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.integer "year", null: false
    t.string "director", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ratings_sum", default: 0, null: false
    t.integer "ratings_count", default: 0, null: false
    t.virtual "average_stars", type: :decimal, precision: 3, scale: 2, as: "\nCASE\n    WHEN (ratings_count = 0) THEN NULL::numeric\n    ELSE round(((ratings_sum)::numeric / (ratings_count)::numeric), 2)\nEND", stored: true
    t.index ["average_stars", "id"], name: "index_movies_on_average_stars", order: { average_stars: "DESC NULLS LAST", id: :desc }
    t.index ["title"], name: "index_movies_on_title", unique: true
    t.check_constraint "ratings_sum >= 0 AND ratings_count >= 0", name: "movies_ratings_non_negative"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "movie_id", null: false
    t.string "reviewer_name", null: false
    t.integer "stars", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id"], name: "index_reviews_on_movie_id"
  end

  add_foreign_key "movie_actors", "actors"
  add_foreign_key "movie_actors", "movies"
  add_foreign_key "movie_filming_locations", "filming_locations"
  add_foreign_key "movie_filming_locations", "movies"
  add_foreign_key "reviews", "movies"
end
