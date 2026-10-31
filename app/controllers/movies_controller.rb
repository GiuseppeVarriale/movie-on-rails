class MoviesController < ApplicationController
  PER_PAGE = 12
  REVIEWS_PER_PAGE = 10

  def index
    @search = MovieSearch.new(sort: params[:sort], actor_id: params[:actor_id], actor: params[:actor])
    @pagy, @movies = pagy(:offset, @search.results, limit: PER_PAGE)
  end

  def show
    @movie = Movie.includes(:actors, :filming_locations).find(params[:id])
    @pagy, @reviews = pagy(:offset, @movie.reviews.order(created_at: :desc, id: :desc), limit: REVIEWS_PER_PAGE)
  end
end
