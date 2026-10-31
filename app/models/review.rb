class Review < ApplicationRecord
  MIN_STARS = 0
  MAX_STARS = 5

  belongs_to :movie

  normalizes :reviewer_name, with: ->(name) { name.squish }

  validates :reviewer_name, presence: true
  validates :stars, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: MIN_STARS,
    less_than_or_equal_to: MAX_STARS
  }
end
