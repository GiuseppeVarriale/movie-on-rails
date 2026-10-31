class Actor < ApplicationRecord
  has_many :movie_actors, dependent: :restrict_with_error
  has_many :movies, through: :movie_actors

  scope :name_contains, ->(term) { where("name::text ILIKE ?", "%#{sanitize_sql_like(term)}%") }
  scope :order_by_prefix_match, ->(term) {
    order(sanitize_sql_for_order([ Arel.sql("name::text ILIKE ? DESC"), "#{sanitize_sql_like(term)}%" ]))
  }

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, uniqueness: { on: %i[create update] }
end
