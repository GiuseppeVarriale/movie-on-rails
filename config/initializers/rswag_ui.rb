Rswag::Ui.configure do |c|
  # Swagger UI at /api-docs, reading the file served by rswag-api
  c.openapi_endpoint "/api-docs/v1/swagger.yaml", "Movies on Rails API v1"
end
