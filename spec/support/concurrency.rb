module Concurrency
  def in_parallel(count)
    barrier = Concurrent::CyclicBarrier.new(count)
    Array.new(count) do |index|
      Thread.new do
        barrier.wait
        Rails.application.executor.wrap { yield index }
      end
    end.each(&:join)
  end
end

RSpec.configure do |config|
  config.include Concurrency, :without_transaction
end
