class Actor < ApplicationRecord
  # `name` is a citext column: comparisons ignore case ("leonardo di caprio"
  # finds "Leonardo Di Caprio") while the original casing is kept.
  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, uniqueness: true
end
