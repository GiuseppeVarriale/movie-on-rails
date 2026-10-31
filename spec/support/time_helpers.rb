# `travel_to` / `freeze_time` for date-dependent specs.
RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end
