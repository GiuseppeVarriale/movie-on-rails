class Movie < ApplicationRecord
  # "Roundhay Garden Scene" (Louis Le Prince, 1888), the oldest surviving film.
  FIRST_FILM_YEAR = 1888

  has_many :movie_actors, dependent: :destroy
  has_many :actors, through: :movie_actors
  has_many :movie_filming_locations, dependent: :destroy
  has_many :filming_locations, through: :movie_filming_locations
  has_many :reviews, dependent: :destroy

  normalizes :title, :director, with: ->(value) { value.squish }

  validates :title, presence: true, uniqueness: { on: %i[create update] }
  validates :description, :director, presence: true
  validates :year, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: FIRST_FILM_YEAR,
    less_than_or_equal_to: ->(_movie) { Date.current.year }
  }

  def self.add_ratings(totals)
    return if totals.empty?

    where(id: totals.keys).order(:id).lock("FOR NO KEY UPDATE").ids
    values = totals.map { |id, (stars, reviews)| sanitize_sql_array([ "(?, ?, ?)", id, stars, reviews ]) }.join(", ")

    connection.exec_update(<<~SQL.squish)
      UPDATE movies
      SET ratings_sum = movies.ratings_sum + totals.stars,
          ratings_count = movies.ratings_count + totals.reviews
      FROM (VALUES #{values}) AS totals(movie_id, stars, reviews)
      WHERE movies.id = totals.movie_id
    SQL
  end
end
