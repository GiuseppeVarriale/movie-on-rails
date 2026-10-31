module QueryCounter
  def count_queries(&)
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    queries
  end
end

RSpec.configure { |config| config.include QueryCounter, type: :request }
