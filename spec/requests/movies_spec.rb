require "rails_helper"

RSpec.describe "Movies", type: :request do
  describe "GET /" do
    it "renders the movies page" do
      get root_path

      expect(response).to have_http_status(:ok)
    end

    it "uses the page title with the app name" do
      get root_path

      expect(response.body).to include("<title>Movies · Movies on Rails</title>")
    end

    it "loads the brand font" do
      get root_path

      expect(response.body).to include("fonts.googleapis.com/css2?family=Manrope")
    end
  end

  describe "GET /movies" do
    it "renders the same page" do
      get movies_path

      expect(response).to have_http_status(:ok)
    end
  end
end
