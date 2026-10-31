require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MovieOnRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Generators create RSpec specs and FactoryBot factories (never Minitest).
    # Every generated spec must be completed with real examples before committing.
    config.generators do |g|
      g.test_framework :rspec,
                       fixtures: true,          # handled by fixture_replacement below
                       view_specs: false,       # views are covered by request/system specs
                       helper_specs: false,
                       routing_specs: false,
                       controller_specs: false, # request specs instead (RSpec/Rails recommendation)
                       request_specs: true
      g.fixture_replacement :factory_bot, dir: "spec/factories"
      g.system_tests nil                        # system specs are written by hand
      g.helper false
    end
  end
end
