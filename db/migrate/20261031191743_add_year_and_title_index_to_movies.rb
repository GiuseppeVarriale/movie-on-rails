class AddYearAndTitleIndexToMovies < ActiveRecord::Migration[8.1]
  def change
    add_index :movies, [ :year, :title ], order: { year: :desc }, name: "index_movies_on_newest"
  end
end
