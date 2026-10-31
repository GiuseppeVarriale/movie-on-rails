class Import::MoviesImporter < Import::CsvImporter
  Row = Data.define(:movie, :actor, :location)

  private

  def kind
    "movies"
  end

  def build_row(csv_row)
    row = Row.new(
      movie: Movie.new(title: csv_row["movie"], description: csv_row["description"],
                       year: csv_row["year"], director: csv_row["director"]),
      actor: Actor.new(name: csv_row["actor"]),
      location: FilmingLocation.new(name: csv_row["filming location"], country: csv_row["country"])
    )

    [ row, validation_errors(*row.to_h.values) ]
  end

  def save(rows)
    movie_ids = save_movies(rows.map(&:movie))
    actor_ids = save_actors(rows.map(&:actor))
    location_ids = save_locations(rows.map(&:location))

    MovieActor.insert_all(
      rows.map { |row| { movie_id: movie_ids.fetch(row.movie.title), actor_id: actor_ids.fetch(row.actor.name.downcase) } }
          .uniq.sort_by(&:values),
      unique_by: %i[movie_id actor_id]
    )
    MovieFilmingLocation.insert_all(
      rows.map { |row| { movie_id: movie_ids.fetch(row.movie.title), filming_location_id: location_ids.fetch(location_key(row.location)) } }
          .uniq.sort_by(&:values),
      unique_by: %i[movie_id filming_location_id]
    )
  end

  def save_movies(movies)
    movies = movies.uniq(&:title).sort_by(&:title)
    Movie.insert_all(movies.map { |movie| movie.slice(:title, :description, :year, :director) }, unique_by: :title)

    Movie.where(title: movies.map(&:title)).pluck(:title, :id).to_h
  end

  def save_actors(actors)
    actors = actors.uniq { |actor| actor.name.downcase }.sort_by { |actor| actor.name.downcase }
    Actor.insert_all(actors.map { |actor| actor.slice(:name) }, unique_by: :name)

    Actor.where(name: actors.map(&:name)).pluck(:name, :id).to_h { |name, id| [ name.downcase, id ] }
  end

  def save_locations(locations)
    locations = locations.uniq { |location| location_key(location) }.sort_by { |location| location_key(location) }
    FilmingLocation.insert_all(locations.map { |location| location.slice(:name, :country) }, unique_by: %i[name country])

    FilmingLocation.where(name: locations.map(&:name))
                   .pluck(:name, :country, :id)
                   .to_h { |name, country, id| [ [ name.downcase, country ], id ] }
  end

  def location_key(location)
    [ location.name.downcase, location.country ]
  end
end
