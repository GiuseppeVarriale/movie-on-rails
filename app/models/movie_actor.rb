# One actor appearing in one movie (join model for the movie <-> actor
# many-to-many relationship).
class MovieActor < ApplicationRecord
  belongs_to :movie
  belongs_to :actor

  validates :actor_id, uniqueness: { scope: :movie_id }
end
