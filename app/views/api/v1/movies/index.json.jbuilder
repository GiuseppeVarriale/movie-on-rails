json.movies @movies, partial: "api/v1/movies/movie", as: :movie

json.meta do
  json.pagination { json.partial! "api/v1/shared/pagination", pagy: @pagy }
  json.filters do
    json.sort @search.sort
    json.actor_id @search.actor_id
    json.actor @search.actor
  end
end
