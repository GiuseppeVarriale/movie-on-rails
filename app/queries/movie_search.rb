class MovieSearch
  SORTS = {
    "rating" => [ Movie.arel_table[:average_stars].desc.nulls_last, { id: :desc } ],
    "title" => [ { title: :asc } ],
    "newest" => [ { year: :desc }, { title: :asc } ]
  }.freeze
  DEFAULT_SORT = "rating"

  attr_reader :sort, :actor_id, :actor

  def initialize(sort: nil, actor_id: nil, actor: nil)
    @sort = SORTS.key?(sort) ? sort : DEFAULT_SORT
    @actor_id = Integer(actor_id, exception: false)
    @actor = searchable_actor_text(actor) unless @actor_id
  end

  def results
    scope = Movie.order(*SORTS.fetch(sort)).includes(:actors, :filming_locations)
    filtered_by_actor? ? scope.where(id: actor_movie_ids) : scope
  end

  def filtered_by_actor?
    actor_id.present? || actor.present?
  end

  def selected_actor
    return @selected_actor if defined?(@selected_actor)

    @selected_actor = actor_id && Actor.find_by(id: actor_id)
  end

  def params
    { sort: (sort unless sort == DEFAULT_SORT), actor_id:, actor: }.compact
  end

  private

  def searchable_actor_text(text)
    search = ActorSearch.new(query: text)
    search.query if search.searchable?
  end

  def actor_movie_ids
    movie_actors = actor_id ? MovieActor.where(actor_id:) : MovieActor.where(actor: Actor.name_contains(actor))
    movie_actors.select(:movie_id)
  end
end
