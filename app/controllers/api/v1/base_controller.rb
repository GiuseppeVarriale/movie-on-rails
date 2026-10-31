class Api::V1::BaseController < ActionController::API
  include AbstractController::Translation
  include Pagy::Method

  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  class InvalidParameter < StandardError; end

  rescue_from InvalidParameter, with: :render_invalid_parameter

  private

  def paginate(collection, pagination_params)
    pagy(:offset, collection, limit: DEFAULT_PER_PAGE, client_limit: MAX_PER_PAGE, limit_key: "per_page",
         request: { base_url: request.base_url, path: request.path, params: pagination_params.to_h })
  end

  def invalid_parameter!(name, reason, **)
    raise InvalidParameter, t("api.errors.invalid_parameter.#{reason}", parameter: name, **)
  end

  def render_invalid_parameter(error)
    render_error :bad_request, :invalid_parameter, error.message
  end

  def render_error(status, code, message)
    render json: { error: { code:, message: } }, status:
  end
end
