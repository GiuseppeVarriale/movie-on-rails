require "rails_helper"

RSpec.describe "Movies", type: :request do
  def count_queries(&)
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    queries
  end

  def create_movie_with_cast
    create(:movie).tap do |movie|
      movie.actors << create_list(:actor, 2)
      movie.filming_locations << create(:filming_location)
    end
  end

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

    it "shows the empty state without movies" do
      get root_path

      expect(response.body).to include("No movies yet")
    end

    it "lists the movies, best rated first" do
      inception, gone = create(:movie, title: "Inception"), create(:movie, title: "Gone in 60 seconds")
      Movie.add_ratings(inception.id => [ 11, 4 ], gone.id => [ 18, 5 ])

      get root_path

      expect(response.body.index("Gone in 60 seconds")).to be < response.body.index("Inception")
    end

    it "accepts another sort" do
      create(:movie, title: "Zodiac")
      create(:movie, title: "Arrival")

      get root_path(sort: "title")

      expect(response.body.index("Arrival")).to be < response.body.index("Zodiac")
    end

    it "ignores an unknown sort" do
      get root_path(sort: "unknown")

      expect(response).to have_http_status(:ok)
    end

    it "paginates the movies" do
      stub_const("MoviesController::PER_PAGE", 2)
      create_list(:movie, 3)

      get root_path(page: 2)

      expect(response.body.scan(/<article id="movie_/).size).to eq(1)
    end

    it "runs the same number of queries whatever the number of movies" do
      create_movie_with_cast
      few = count_queries { get root_path }
      create_movie_with_cast
      create_movie_with_cast

      expect(count_queries { get root_path }).to eq(few)
    end
  end

  describe "GET /movies" do
    it "renders the same page" do
      get movies_path

      expect(response).to have_http_status(:ok)
    end
  end
end
