class ActorsController < ApplicationController
  def index
    @search = ActorSearch.new(query: params[:q])
    @suggestions = @search.results

    expires_in 1.minute, public: true
    render layout: false
  end
end
