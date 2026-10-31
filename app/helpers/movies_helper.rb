module MoviesHelper
  CARD_ACTORS_LIMIT = 4
  CARD_LOCATIONS_LIMIT = 3

  def filming_location_label(location)
    t("movies.movie.location", name: location.name, country: location.country)
  end

  def card_actors(movie)
    shown_and_hidden(movie.actors.sort_by(&:name), CARD_ACTORS_LIMIT)
  end

  def card_locations(movie)
    shown_and_hidden(movie.filming_locations.sort_by(&:name), CARD_LOCATIONS_LIMIT)
  end

  private

  def shown_and_hidden(items, limit)
    [ items.first(limit), [ items.size - limit, 0 ].max ]
  end
end
