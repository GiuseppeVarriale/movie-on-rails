class ActorsController < ApplicationController
  def index
    @search = ActorSearch.new(query: search_params[:q])
    @suggestions = @search.results

    expires_in 1.minute, public: true
    render layout: false
  end

  private

  def search_params
    params.permit(:q)
  end
end
