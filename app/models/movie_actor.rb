class MovieActor < ApplicationRecord
  belongs_to :movie
  belongs_to :actor

  validates :actor_id, uniqueness: { scope: :movie_id }
end
