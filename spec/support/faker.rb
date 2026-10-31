# Faker draws from the RSpec seed, so `bin/rspec --seed 1234` repeats the same data
RSpec.configure do |config|
  config.before(:suite) { Faker::Config.random = Random.new(config.seed) }
end
