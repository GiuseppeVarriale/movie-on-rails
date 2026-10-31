require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(app, window_size: [ 1280, 900 ], headless: true, process_timeout: 20, timeout: 10)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :cuprite
  end
end
