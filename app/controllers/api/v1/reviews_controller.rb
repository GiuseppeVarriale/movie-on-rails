class Api::V1::ReviewsController < Api::V1::BaseController
  before_action :set_movie

  def index
    @pagy, @reviews = paginate(@movie.reviews.newest_first, pagination_params)
  end

  private

  def set_movie
    @movie = Movie.find(params.expect(:movie_id))
  end

  def pagination_params
    params.permit(:page, :per_page)
  end
end
