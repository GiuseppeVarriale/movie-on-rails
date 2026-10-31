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

    it "breaks ties between movies of the same year by title" do
      tenet = create(:movie, title: "Tenet", year: 2010)

      expect(described_class.new(sort: "newest").results.where(year: 2010)).to eq([ inception, tenet ])
    end

    it "reads every sort from an index instead of sorting in memory" do
      ActiveRecord::Base.connection.execute("SET LOCAL enable_seqscan = off")

      plans = MovieSearch::SORTS.keys.index_with { |sort| described_class.new(sort:).results.limit(12).explain.inspect }

      expect(plans.transform_values { |plan| plan.include?("Index Scan") && plan.exclude?("Sort") })
        .to eq("rating" => true, "title" => true, "newest" => true)
    end

    it "preloads actors and filming locations" do
      results = described_class.new.results.to_a

      expect(results).to all(satisfy { |movie| movie.association(:actors).loaded? && movie.association(:filming_locations).loaded? })
    end
  end

  describe "actor filter" do
    let!(:leo) { create(:actor, name: "Leonardo Di Caprio") }
    let!(:ribisi) { create(:actor, name: "Giovani Ribisi") }

    before do
      gone_in_60_seconds.actors << [ leo, ribisi ]
      inception.actors << leo
    end

    it "lists the movies of the actor given by id" do
      expect(described_class.new(actor_id: ribisi.id.to_s).results).to eq([ gone_in_60_seconds ])
    end

    it "keeps the rating order while filtering" do
      expect(described_class.new(actor_id: leo.id).results).to eq([ gone_in_60_seconds, inception ])
    end

    it "lists each movie once even when several of its actors match the text" do
      gone_in_60_seconds.actors << create(:actor, name: "Leonard Nimoy")

      expect(described_class.new(actor: "leonar").results.to_a).to eq([ gone_in_60_seconds, inception ])
    end

    it "filters by part of an actor's name, ignoring case" do
      expect(described_class.new(actor: "RIBISI").results).to eq([ gone_in_60_seconds ])
    end

    it "ignores a text shorter than 3 letters" do
      expect(described_class.new(actor: "ri")).not_to be_filtered_by_actor
    end

    it "ignores a non-numeric id" do
      expect(described_class.new(actor_id: "abc")).not_to be_filtered_by_actor
    end

    it "prefers the id when both are given" do
      expect(described_class.new(actor_id: ribisi.id, actor: "leonardo").results).to eq([ gone_in_60_seconds ])
    end

    it "exposes the selected actor" do
      expect(described_class.new(actor_id: leo.id).selected_actor).to eq(leo)
    end

    it "builds params that keep the filter and a non-default sort" do
      expect(described_class.new(sort: "title", actor_id: leo.id).params).to eq(sort: "title", actor_id: leo.id)
    end
  end

  describe "partial actor filter matching anywhere in the name" do
    let!(:leonardo) { create(:actor, name: "Leonardo de Caprio") }
    let!(:someleo) { create(:actor, name: "Someleo Name") }

    before do
      inception.actors << leonardo
      unrated.actors << someleo
    end

    it "lists the movies of every actor whose name contains the text" do
      expect(described_class.new(actor: "leo").results).to contain_exactly(inception, unrated)
    end

    it "lists only the picked actor's movies when filtering by id" do
      expect(described_class.new(actor_id: someleo.id).results).to eq([ unrated ])
    end
  end
end
