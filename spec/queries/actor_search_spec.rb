require "rails_helper"

RSpec.describe ActorSearch do
  def names(query)
    described_class.new(query:).results.map { |suggestion| suggestion.actor.name }
  end

  describe "#query" do
    it "squishes the term" do
      expect(described_class.new(query: "  Leo   Di ").query).to eq("Leo Di")
    end

    it "caps the term at 100 characters" do
      expect(described_class.new(query: "a" * 150).query.length).to eq(100)
    end
  end

  describe "#searchable?" do
    it "needs at least 3 letters" do
      expect([ "le", "leo" ].map { |query| described_class.new(query:).searchable? }).to eq([ false, true ])
    end
  end

  describe "#results" do
    before do
      [ "Leonardo Di Caprio", "Cleo Laine", "Ellen Page", "Leo Woodall" ].each { |name| create(:actor, name:) }
    end

    it "suggests nothing below 3 letters" do
      expect(names("le")).to be_empty
    end

    it "matches part of a name, ignoring case" do
      expect(names("LEO")).to contain_exactly("Cleo Laine", "Leo Woodall", "Leonardo Di Caprio")
    end

    it "lists names starting with the term first" do
      expect(names("leo")).to eq([ "Leo Woodall", "Leonardo Di Caprio", "Cleo Laine" ])
    end

    it "treats % and _ literally" do
      expect([ names("%%%"), names("___") ]).to eq([ [], [] ])
    end

    it "returns at most LIMIT suggestions" do
      stub_const("ActorSearch::LIMIT", 2)
      [ "Zed One", "Zed Two", "Zed Three" ].each { |name| create(:actor, name:) }

      expect(names("zed").size).to eq(2)
    end

    it "counts each actor's movies" do
      leo = Actor.find_by!(name: "Leonardo Di Caprio")
      leo.movies << create_list(:movie, 2)

      expect(described_class.new(query: "leonardo").results.sole).to have_attributes(actor: leo, movies_count: 2)
    end

    it "counts zero movies for an actor without movies" do
      expect(described_class.new(query: "ellen").results.sole.movies_count).to eq(0)
    end
  end
end
