class ActorSearch
  MIN_LENGTH = 3
  MAX_LENGTH = 100
  LIMIT = 10

  Suggestion = Data.define(:actor, :movies_count)

  attr_reader :query

  def initialize(query:)
    @query = query.to_s.squish.first(MAX_LENGTH)
  end

  def searchable?
    query.length >= MIN_LENGTH
  end

  def results
    return [] unless searchable?

    actors = Actor.name_contains(query).order_by_prefix_match(query).order(:name).limit(LIMIT).to_a
    movies_counts = MovieActor.where(actor: actors).group(:actor_id).count

    actors.map { |actor| Suggestion.new(actor:, movies_count: movies_counts.fetch(actor.id, 0)) }
  end
end
