class Actor < ApplicationRecord
  # `name` is a citext column: comparisons ignore case ("leonardo di caprio"
  # finds "Leonardo Di Caprio") while the original casing is kept.
  has_many :movie_actors, dependent: :restrict_with_error
  has_many :movies, through: :movie_actors

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, uniqueness: true
end
