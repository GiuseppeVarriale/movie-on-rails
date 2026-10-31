class MovieFilmingLocation < ApplicationRecord
  belongs_to :movie
  belongs_to :filming_location

  validates :filming_location_id, uniqueness: { scope: :movie_id }
end
