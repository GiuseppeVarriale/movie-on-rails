require "rails_helper"

RSpec.describe MovieSearch do
  let!(:inception) { create(:movie, title: "Inception", year: 2010) }
  let!(:gone_in_60_seconds) { create(:movie, title: "Gone in 60 seconds", year: 2000) }
  let!(:unrated) { create(:movie, title: "Arrival", year: 2016) }

  before do
    Movie.add_ratings(inception.id => [ 11, 4 ], gone_in_60_seconds.id => [ 18, 5 ])
  end

  describe "#sort" do
    it "defaults to rating" do
      expect(described_class.new.sort).to eq("rating")
    end

    it "accepts a known sort" do
      expect(described_class.new(sort: "title").sort).to eq("title")
    end

    it "falls back to rating for an unknown sort" do
      expect(described_class.new(sort: "id; DROP TABLE movies").sort).to eq("rating")
    end
  end

  describe "#results" do
    it "lists the best rated first and unrated movies last" do
      expect(described_class.new.results).to eq([ gone_in_60_seconds, inception, unrated ])
    end

    it "sorts by title" do
      expect(described_class.new(sort: "title").results).to eq([ unrated, gone_in_60_seconds, inception ])
    end

    it "sorts the newest first" do
      expect(described_class.new(sort: "newest").results).to eq([ unrated, inception, gone_in_60_seconds ])
    end

    it "preloads actors and filming locations" do
      results = described_class.new.results.to_a

      expect(results).to all(satisfy { |movie| movie.association(:actors).loaded? && movie.association(:filming_locations).loaded? })
    end
  end
end
