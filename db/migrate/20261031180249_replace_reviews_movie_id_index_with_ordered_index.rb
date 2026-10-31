class ReplaceReviewsMovieIdIndexWithOrderedIndex < ActiveRecord::Migration[8.1]
  def change
    add_index :reviews, [ :movie_id, :created_at, :id ], order: { created_at: :desc, id: :desc },
              name: "index_reviews_on_movie_id_and_newest"
    remove_index :reviews, :movie_id, name: "index_reviews_on_movie_id"
  end
end
