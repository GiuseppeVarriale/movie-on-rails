json.reviews @reviews, partial: "api/v1/reviews/review", as: :review

json.meta do
  json.movie_id @movie.id
  json.pagination { json.partial! "api/v1/shared/pagination", pagy: @pagy }
end
