class MoviesController < ApplicationController
  PER_PAGE = 12
  REVIEWS_PER_PAGE = 10

  def index
    @search = MovieSearch.new(sort: search_params[:sort], actor_id: search_params[:actor_id], actor: search_params[:actor])
    @pagy, @movies = paginate(@search.results, search_params, limit: PER_PAGE)
  end

  def show
    @movie = Movie.includes(:actors, :filming_locations).find(params.expect(:id))
    @pagy, @reviews = paginate(@movie.reviews.newest_first, pagination_params, limit: REVIEWS_PER_PAGE)
  end

  private

  def search_params
    params.permit(:sort, :actor_id, :actor, :page)
  end

  def pagination_params
    params.permit(:page)
  end
end
