# Use `create(:movie)` instead of `FactoryBot.create(:movie)` in specs.
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
