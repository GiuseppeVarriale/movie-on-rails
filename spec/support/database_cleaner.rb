RSpec.configure do |config|
  config.after(:each, :without_transaction) do
    DatabaseCleaner.clean_with(:deletion)
  end
end
