class Movie < ApplicationRecord
  FIRST_FILM_YEAR = 1888

  RatingTotals = Data.define(:stars, :count)

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

  def self.lock_for_ratings_update!
    order(:id).lock("FOR NO KEY UPDATE").ids
  end

  def self.add_ratings(totals)
    return if totals.empty?

    where(id: totals.keys).lock_for_ratings_update!
    where(id: totals.keys).update_all(
      ratings_sum: arel_table[:ratings_sum] + per_movie(totals, &:stars),
      ratings_count: arel_table[:ratings_count] + per_movie(totals, &:count)
    )
  end

  def self.per_movie(totals)
    totals.each_with_object(Arel::Nodes::Case.new(arel_table[:id])) do |(id, total), expression|
      expression.when(id).then(yield(total))
    end
  end
  private_class_method :per_movie
end
