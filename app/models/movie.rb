class Movie < ApplicationRecord
  # "Roundhay Garden Scene" (Louis Le Prince, 1888), the oldest surviving film.
  FIRST_FILM_YEAR = 1888

  has_many :movie_actors, dependent: :destroy
  has_many :actors, through: :movie_actors
  has_many :movie_filming_locations, dependent: :destroy
  has_many :filming_locations, through: :movie_filming_locations
  has_many :reviews, dependent: :destroy

  normalizes :title, :director, with: ->(value) { value.squish }

  validates :title, presence: true, uniqueness: true
  validates :description, :director, presence: true
  validates :year, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: FIRST_FILM_YEAR,
    less_than_or_equal_to: ->(_movie) { Date.current.year }
  }
end
