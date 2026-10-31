require "rails_helper"

RSpec.describe MoviesHelper, type: :helper do
  let(:movie) { create(:movie) }

  describe "#filming_location_label" do
    it "shows the country in parentheses" do
      location = build(:filming_location, name: "Los Angeles", country: "US")

      expect(helper.filming_location_label(location)).to eq("Los Angeles (US)")
    end
  end

  describe "#card_actors" do
    it "shows every actor when there are few" do
      movie.actors << create_list(:actor, 2)

      expect(helper.card_actors(movie)).to eq([ movie.actors.sort_by(&:name), 0 ])
    end

    it "shows the first 4 alphabetically and counts the rest" do
      movie.actors << %w[Eve Bob Dan Ann Cal Fay].map { |name| create(:actor, name:) }

      shown, hidden = helper.card_actors(movie)
      expect([ shown.map(&:name), hidden ]).to eq([ %w[Ann Bob Cal Dan], 2 ])
    end
  end

  describe "#card_locations" do
    it "shows the first 3 alphabetically and counts the rest" do
      movie.filming_locations << %w[Rome Oslo Lima Kyiv Bern].map { |name| create(:filming_location, name:) }

      shown, hidden = helper.card_locations(movie)
      expect([ shown.map(&:name), hidden ]).to eq([ %w[Bern Kyiv Lima], 2 ])
    end
  end
end
