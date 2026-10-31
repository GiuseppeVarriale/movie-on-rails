class Api::V1::BaseController < ActionController::API
  include AbstractController::Translation
  include Paginated

  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  class InvalidParameter < StandardError; end

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from InvalidParameter, with: :render_invalid_parameter

  private

  def paginate(collection, permitted_params)
    super(collection, permitted_params.slice(:page, :per_page),
          limit: DEFAULT_PER_PAGE, client_limit: MAX_PER_PAGE, limit_key: "per_page")
  end

  def invalid_parameter!(name, reason, **)
    raise InvalidParameter, t("api.errors.invalid_parameter.#{reason}", parameter: name, **)
  end

  def render_not_found(error)
    render_error :not_found, :not_found, t("api.errors.not_found", resource: error.model.constantize.model_name.human)
  end

  def render_invalid_parameter(error)
    render_error :bad_request, :invalid_parameter, error.message
  end

  def render_error(status, code, message)
    render json: { error: { code:, message: } }, status:
  end
end
