json.extract! movie, :id, :title, :year, :director, :description
json.average_stars movie.average_stars&.to_f
json.reviews_count movie.ratings_count
json.actors movie.actors.sort_by(&:name), :id, :name
json.filming_locations movie.filming_locations.sort_by(&:name), :id, :name, :country
json.url api_v1_movie_url(movie)
json.reviews_url api_v1_movie_reviews_url(movie)
