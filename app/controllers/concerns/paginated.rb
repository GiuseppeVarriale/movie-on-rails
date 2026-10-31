module Paginated
  extend ActiveSupport::Concern

  include Pagy::Method

  private

  def paginate(collection, permitted_params, **)
    pagy(:offset, collection, request: { base_url: request.base_url, path: request.path, params: permitted_params.to_h }, **)
  end
end
