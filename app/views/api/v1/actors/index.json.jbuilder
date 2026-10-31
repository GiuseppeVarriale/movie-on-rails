json.actors @suggestions do |suggestion|
  json.extract! suggestion.actor, :id, :name
  json.movies_count suggestion.movies_count
  json.movies_url api_v1_movies_url(actor_id: suggestion.actor.id)
end

json.meta do
  json.q @search.query
  json.limit ActorSearch::LIMIT
end
