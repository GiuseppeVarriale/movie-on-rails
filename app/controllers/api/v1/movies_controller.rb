class Api::V1::MoviesController < Api::V1::BaseController
  before_action :set_movie, only: :show

  def index
    @search = MovieSearch.new(sort: search_params[:sort], actor_id: search_params[:actor_id], actor: search_params[:actor])
    validate_search!
    @pagy, @movies = paginate(@search.results, search_params.slice(:page, :per_page))
  end

  def show
  end

  private

  def set_movie
    @movie = Movie.includes(:actors, :filming_locations).find(params.expect(:id))
  end

  def search_params
    params.permit(:sort, :actor_id, :actor, :page, :per_page)
  end

  def validate_search!
    if search_params[:sort] && search_params[:sort] != @search.sort
      invalid_parameter!(:sort, :one_of, values: MovieSearch::SORTS.keys.join(", "))
    end
    invalid_parameter!(:actor_id, :positive_integer) if search_params[:actor_id] && !@search.actor_id&.positive?
    if search_params[:actor] && !@search.actor_id && !@search.actor
      invalid_parameter!(:actor, :min_length, count: ActorSearch::MIN_LENGTH)
    end
  end
end
