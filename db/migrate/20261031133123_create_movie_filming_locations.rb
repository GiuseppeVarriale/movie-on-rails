class CreateMovieFilmingLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :movie_filming_locations do |t|
      t.references :movie, null: false, foreign_key: true, index: false
      t.references :filming_location, null: false, foreign_key: true

      t.timestamps
    end
    add_index :movie_filming_locations, [ :movie_id, :filming_location_id ],
              unique: true, name: "index_movie_filming_locations_on_movie_and_location"
  end
end
