require "rails_helper"

RSpec.describe Movie::RatingsRecalculator, :without_transaction do
  self.use_transactional_tests = false

  let(:header) { "Movie,User,Stars,Review\n" }
  let(:files) do
    Array.new(3) do |file|
      rows = Array.new(600) { |row| "Movie #{(row * 7 + file) % 50},Reviewer,#{(row + file) % 6},Text\n" }
      csv_file(header + rows.join)
    end
  end

  before { 50.times { |index| create(:movie, title: "Movie #{index}") } }


  def run_alongside_imports
    importing = Concurrent::AtomicFixnum.new(files.size)
    in_parallel(files.size + 1) do |index|
      index.zero? ? recalculate_while(importing) : import_and_count_down(files[index - 1], importing)
    end
  end

  def recalculate_while(importing)
    described_class.call while importing.value.positive?
  end

  def import_and_count_down(file, importing)
    Import::ReviewsImporter.call(file, batch_size: 10)
  ensure
    importing.decrement
  end

  it "runs alongside review imports without deadlocks and keeps exact totals" do
    run_alongside_imports

    real = Review.group(:movie_id).pluck(:movie_id, Arel.sql("SUM(stars)"), Arel.sql("COUNT(*)")).to_h { |id, sum, count| [ id, [ sum, count ] ] }
    expect(Movie.pluck(:id, :ratings_sum, :ratings_count).to_h { |id, sum, count| [ id, [ sum, count ] ] }).to eq(real)
  end
end
