class AddRatingsToMovies < ActiveRecord::Migration[8.1]
  def change
    add_column :movies, :ratings_sum, :bigint, null: false, default: 0
    add_column :movies, :ratings_count, :integer, null: false, default: 0
    add_column :movies, :average_stars, :virtual, type: :decimal, precision: 3, scale: 2, stored: true,
               as: "CASE WHEN ratings_count = 0 THEN NULL ELSE ROUND(ratings_sum::numeric / ratings_count, 2) END"

    add_check_constraint :movies, "ratings_sum >= 0 AND ratings_count >= 0", name: "movies_ratings_non_negative"
    add_index :movies, [ :average_stars, :id ], order: { average_stars: "DESC NULLS LAST", id: :desc },
              name: "index_movies_on_average_stars"
  end
end
