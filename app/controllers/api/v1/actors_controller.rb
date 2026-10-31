class Api::V1::ActorsController < Api::V1::BaseController
  def index
    @search = ActorSearch.new(query: search_params[:q])
    invalid_parameter!(:q, :min_length, count: ActorSearch::MIN_LENGTH) unless @search.searchable?
    @suggestions = @search.results
  end

  private

  def search_params
    params.permit(:q)
  end
end
