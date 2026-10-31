class FilmingLocation < ApplicationRecord
  has_many :movie_filming_locations, dependent: :restrict_with_error
  has_many :movies, through: :movie_filming_locations

  normalizes :name, with: ->(name) { name.squish }
  normalizes :country, with: ->(country) { country.strip.upcase }

  validates :name, presence: true, uniqueness: { scope: :country }
  validates :country, presence: true, format: { with: /\A[A-Z]{2}\z/ }
end
