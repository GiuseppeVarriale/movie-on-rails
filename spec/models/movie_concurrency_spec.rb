require "rails_helper"

RSpec.describe Movie, :without_transaction, type: :model do
  self.use_transactional_tests = false

  let!(:movie) { create(:movie) }

  it "keeps exact rating totals when many reviews are counted at the same time" do
    in_parallel(5) { 20.times { described_class.update_counters(movie.id, ratings_sum: 3, ratings_count: 1) } }

    expect(movie.reload).to have_attributes(ratings_sum: 300, ratings_count: 100, average_stars: BigDecimal("3"))
  end
end
