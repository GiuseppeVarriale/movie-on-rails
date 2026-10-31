class MoviesController < ApplicationController
  PER_PAGE = 12

  def index
    @search = MovieSearch.new(sort: params[:sort])
    @pagy, @movies = pagy(:offset, @search.results, limit: PER_PAGE)
  end
end
