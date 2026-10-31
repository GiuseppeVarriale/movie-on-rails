require "sidekiq/web"

Sidekiq::Web.use Rack::Auth::Basic, "Sidekiq" do |username, password|
  expected_username = ENV.fetch("SIDEKIQ_USERNAME", "")
  expected_password = ENV.fetch("SIDEKIQ_PASSWORD", "")

  username_matches = ActiveSupport::SecurityUtils.secure_compare(username, expected_username)
  password_matches = ActiveSupport::SecurityUtils.secure_compare(password, expected_password)

  expected_username.present? && expected_password.present? && username_matches && password_matches
end
