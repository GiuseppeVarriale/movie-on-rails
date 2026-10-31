require "csv"

class Import::MoviesImporter
  class AlreadyImportedError < StandardError; end

  BATCH_SIZE = 1_000
  MAX_FAILURES = 1_000

  Row = Data.define(:movie, :actor, :location)

  def self.call(path, batch_size: BATCH_SIZE)
    new(path, batch_size:).call
  end

  def initialize(path, batch_size: BATCH_SIZE)
    @path = path.to_s
    @batch_size = batch_size
  end

  def call
    @import = start_import

    each_batch { |lines| import_batch(lines) }

    import.update!(status: :completed, finished_at: Time.current)
    import
  rescue StandardError
    import&.update_columns(status: "failed", finished_at: Time.current) if import&.persisted?
    raise
  end

  private

  attr_reader :path, :batch_size, :import

  def start_import
    checksum = Digest::SHA256.file(path).hexdigest
    raise AlreadyImportedError, I18n.t("imports.errors.already_imported", path:) if Import.completed.exists?(file_checksum: checksum)

    Import.create!(kind: :movies, source_path: path, file_checksum: checksum, status: :running, started_at: Time.current)
  end

  def each_batch(&)
    CSV.foreach(path, headers: true, encoding: "bom|utf-8", header_converters: ->(header) { header.to_s.squish.downcase })
       .with_index(2)
       .each_slice(batch_size, &)
  end

  def import_batch(lines)
    failures = []
    rows = lines.filter_map { |csv_row, line| build_row(csv_row, line, failures) }

    ApplicationRecord.transaction { save(rows) } if rows.any?

    import.update!(
      rows_processed: import.rows_processed + lines.size,
      rows_failed: import.rows_failed + failures.size,
      failures: (import.failures + failures).first(MAX_FAILURES)
    )
  end

  def build_row(csv_row, line, failures)
    row = Row.new(
      movie: Movie.new(title: csv_row["movie"], description: csv_row["description"],
                       year: csv_row["year"], director: csv_row["director"]),
      actor: Actor.new(name: csv_row["actor"]),
      location: FilmingLocation.new(name: csv_row["filming location"], country: csv_row["country"])
    )
    errors = row.to_h.values.reject { |record| record.valid?(:import) }.flat_map { |record| record.errors.full_messages }
    return row if errors.empty?

    failures << { "line" => line, "errors" => errors }
    nil
  end

  def save(rows)
    movie_ids = save_movies(rows.map(&:movie))
    actor_ids = save_actors(rows.map(&:actor))
    location_ids = save_locations(rows.map(&:location))

    MovieActor.insert_all(
      rows.map { |row| { movie_id: movie_ids.fetch(row.movie.title), actor_id: actor_ids.fetch(row.actor.name.downcase) } }.uniq,
      unique_by: %i[movie_id actor_id]
    )
    MovieFilmingLocation.insert_all(
      rows.map { |row| { movie_id: movie_ids.fetch(row.movie.title), filming_location_id: location_ids.fetch(location_key(row.location)) } }.uniq,
      unique_by: %i[movie_id filming_location_id]
    )
  end

  def save_movies(movies)
    movies = movies.uniq(&:title)
    Movie.insert_all(movies.map { |movie| movie.slice(:title, :description, :year, :director) }, unique_by: :title)

    Movie.where(title: movies.map(&:title)).pluck(:title, :id).to_h
  end

  def save_actors(actors)
    actors = actors.uniq { |actor| actor.name.downcase }
    Actor.insert_all(actors.map { |actor| actor.slice(:name) }, unique_by: :name)

    Actor.where(name: actors.map(&:name)).pluck(:name, :id).to_h { |name, id| [ name.downcase, id ] }
  end

  def save_locations(locations)
    locations = locations.uniq { |location| location_key(location) }
    FilmingLocation.insert_all(locations.map { |location| location.slice(:name, :country) }, unique_by: %i[name country])

    FilmingLocation.where(name: locations.map(&:name))
                   .pluck(:name, :country, :id)
                   .to_h { |name, country, id| [ [ name.downcase, country ], id ] }
  end

  def location_key(location)
    [ location.name.downcase, location.country ]
  end
end
