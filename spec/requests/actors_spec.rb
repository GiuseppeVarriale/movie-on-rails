require "rails_helper"

RSpec.describe "Actors", type: :request do
  let!(:leo) { create(:actor, name: "Leonardo Di Caprio") }

  before { leo.movies << create_list(:movie, 2) }

  describe "GET /actors" do
    it "suggests matching actors as options, without the layout" do
      get actors_path(q: "leo")

      expect(response.body).to include(%(data-autocomplete-value="#{leo.id}" data-autocomplete-label="Leonardo Di Caprio"))
        .and include(%(role="option"))
        .and not_include("<html")
    end

    it "shows each actor's movie count" do
      get actors_path(q: "LEO")

      expect(response.body).to include("2 movies")
    end

    it "says when nothing matches" do
      get actors_path(q: "xyz")

      expect(response.body).to include("No actors found")
    end

    it "suggests nothing below 3 letters" do
      get actors_path(q: "le")

      expect(response.body).not_to include("<li")
    end

    it "drops a list as q" do
      get actors_path(q: [ "leo" ])

      expect(response.body).not_to include("<li")
    end

    it "escapes actor names" do
      create(:actor, name: "<script>alert(1)</script>")

      get actors_path(q: "script")

      expect(response.body).to include("&lt;script&gt;").and not_include("<script>alert(1)</script>")
    end

    it "lets the browser cache the answer for a minute" do
      get actors_path(q: "leo")

      expect(response.headers["Cache-Control"]).to include("max-age=60", "public")
    end
  end
end
