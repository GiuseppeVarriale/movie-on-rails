require "rails_helper"

RSpec.describe Movie::RatingsRecalculator do
  let!(:inception) { create(:movie) }
  let!(:unreviewed) { create(:movie) }

  before do
    [ 4, 2, 3, 2 ].each { |stars| create(:review, movie: inception, stars:) }
    Movie.update_all(ratings_sum: 5, ratings_count: 1)
  end

  it "rebuilds each movie's counters from its reviews" do
    described_class.call

    expect(inception.reload).to have_attributes(ratings_sum: 11, ratings_count: 4, average_stars: BigDecimal("2.75"))
  end

  it "resets the counters of a movie without reviews" do
    described_class.call

    expect(unreviewed.reload).to have_attributes(ratings_sum: 0, ratings_count: 0, average_stars: nil)
  end

  it "returns the number of movies recalculated" do
    expect(described_class.call).to eq(2)
  end

  it "runs a single update for all movies" do
    updates = []
    callback = ->(*, payload) { updates << payload[:sql] if payload[:sql].start_with?("UPDATE") }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { described_class.call }

    expect(updates.size).to eq(1)
  end
end
