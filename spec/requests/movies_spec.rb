require "rails_helper"

RSpec.describe "Movies", type: :request do
  def count_queries(&)
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    queries
  end

  def add_cast_and_reviews(movie, count)
    movie.actors << create_list(:actor, count)
    create_list(:review, count, movie:)
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

  describe "GET / with an actor filter" do
    let!(:leo) { create(:actor, name: "Leonardo Di Caprio") }
    let!(:inception) { create(:movie, title: "Inception") }

    before do
      inception.actors << leo
      create(:movie, title: "Zodiac")
    end

    it "lists only the actor's movies" do
      get root_path(actor_id: leo.id)

      expect(response.body).to include("Inception").and not_include("Zodiac")
    end

    it "summarizes the filter" do
      get root_path(actor_id: leo.id)

      expect(response.body).to include("1 movie with Leonardo Di Caprio")
    end

    it "fills the field with the actor's name" do
      get root_path(actor_id: leo.id)

      expect(response.body).to match(/<input value="Leonardo Di Caprio"[^>]*name="actor"/)
    end

    it "filters by part of a name" do
      get root_path(actor: "caprio")

      expect(response.body).to include(%(1 movie with an actor matching &quot;caprio&quot;))
    end

    it "keeps the filter in the sort links" do
      get root_path(actor_id: leo.id)

      expect(response.body).to include(%(href="/movies?actor_id=#{leo.id}&amp;sort=title"))
    end

    it "shows an empty state when the actor has no movies" do
      get root_path(actor: "nobody")

      expect(response.body).to include("No movies with this actor").and include("Show all movies")
    end
  end

  describe "GET /movies/:id" do
    let(:movie) { create(:movie, title: "Inception", description: "Dream heist.", director: "Christopher Nolan") }

    it "shows the movie's details" do
      get movie_path(movie)

      expect(response.body).to include("Inception").and include("Dream heist.").and include("Directed by Christopher Nolan")
    end

    it "uses the movie title as the page title" do
      get movie_path(movie)

      expect(response.body).to include("<title>Inception · Movies on Rails</title>")
    end

    it "lists the reviews newest first" do
      create(:review, movie:, reviewer_name: "Older", created_at: 2.days.ago)
      create(:review, movie:, reviewer_name: "Newer", created_at: 1.day.ago)

      get movie_path(movie)

      expect(response.body.index("Newer")).to be < response.body.index("Older")
    end

    it "keeps the review text as given and notes a review without text" do
      create(:review, movie:, body: "Empty")
      create(:review, movie:, body: nil)

      get movie_path(movie)

      expect(response.body).to include("Empty").and include("No comment")
    end

    it "paginates the reviews" do
      stub_const("MoviesController::REVIEWS_PER_PAGE", 2)
      create_list(:review, 3, movie:)

      get movie_path(movie, page: 2)

      expect(response.body.scan(/<li id="review_/).size).to eq(1)
    end

    it "shows an empty state without reviews" do
      get movie_path(movie)

      expect(response.body).to include("No reviews yet")
    end

    it "runs the same number of queries whatever the number of reviews and cast" do
      add_cast_and_reviews(movie, 1)
      few = count_queries { get movie_path(movie) }
      add_cast_and_reviews(movie, 4)

      expect(count_queries { get movie_path(movie) }).to eq(few)
    end

    it "returns 404 for an unknown movie" do
      get movie_path(id: 0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /movies" do
    it "renders the same page" do
      get movies_path

      expect(response).to have_http_status(:ok)
    end
  end
end
