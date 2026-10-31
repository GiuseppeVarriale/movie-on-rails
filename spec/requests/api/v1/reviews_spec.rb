require "swagger_helper"

RSpec.describe "API v1 reviews", type: :request do
  let!(:movie) { create(:movie, title: "Inception") }

  def reviewers
    response.parsed_body["reviews"].pluck("reviewer_name")
  end

  path "/api/v1/movies/{movie_id}/reviews" do
    parameter name: :movie_id, in: :path, schema: { type: :integer }

    get "List a movie's reviews" do
      tags "Reviews"
      description "Newest first."
      produces "application/json"
      parameter name: :page, in: :query, required: false, schema: { type: :integer, minimum: 1, default: 1 }
      parameter name: :per_page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: Api::V1::BaseController::MAX_PER_PAGE,
                          default: Api::V1::BaseController::DEFAULT_PER_PAGE }

      response 200, "Reviews" do
        schema type: :object,
               properties: {
                 reviews: { type: :array, items: { "$ref" => "#/components/schemas/review" } },
                 meta: {
                   type: :object,
                   properties: { movie_id: { type: :integer }, pagination: { "$ref" => "#/components/schemas/pagination" } }
                 }
               }
        let(:movie_id) { movie.id }

        before do
          create(:review, movie:, reviewer_name: "Suzan Something", stars: 4, body: "Mind-bending", created_at: 2.days.ago)
          create(:review, movie:, reviewer_name: "Axel Ontheway", stars: 5, body: nil, created_at: 1.day.ago)
        end

        run_test! do
          expect(reviewers).to eq([ "Axel Ontheway", "Suzan Something" ])
        end
      end

      response 404, "Movie not found" do
        schema "$ref" => "#/components/schemas/error"
        let(:movie_id) { 0 }

        run_test!
      end
    end
  end

  describe "GET /api/v1/movies/:movie_id/reviews" do
    it "returns each review with its details" do
      review = create(:review, movie:, reviewer_name: "Suzan Something", stars: 0, body: "Empty")

      get api_v1_movie_reviews_path(movie)

      expect(response.parsed_body["reviews"]).to eq([ review.slice(:id, :reviewer_name, :stars, :body, :created_at).as_json ])
    end

    it "lists only the movie's reviews" do
      create(:review, movie:, reviewer_name: "Mine")
      create(:review, reviewer_name: "Other movie")

      get api_v1_movie_reviews_path(movie)

      expect(reviewers).to eq([ "Mine" ])
    end

    it "breaks ties between reviews created together by id, newest first" do
      first, second = create_list(:review, 2, movie:, created_at: 1.day.ago)

      get api_v1_movie_reviews_path(movie)

      expect(response.parsed_body["reviews"].pluck("id")).to eq([ second.id, first.id ])
    end

    it "paginates the reviews" do
      create_list(:review, 3, movie:)

      get api_v1_movie_reviews_path(movie, page: 2, per_page: 2)

      expect([ reviewers.size, response.parsed_body.dig("meta", "pagination", "pages") ]).to eq([ 1, 2 ])
    end

    it "drops a list as page, which isn't permitted" do
      create_list(:review, 3, movie:)

      get api_v1_movie_reviews_path(movie, page: [ 2 ], per_page: 2)

      expect([ reviewers.size, response.parsed_body.dig("meta", "pagination", "page") ]).to eq([ 2, 1 ])
    end

    it "returns an empty list without reviews" do
      get api_v1_movie_reviews_path(movie)

      expect([ response.status, reviewers ]).to eq([ 200, [] ])
    end

    it "runs the same number of queries whatever the number of reviews" do
      few = count_queries { get api_v1_movie_reviews_path(movie) }
      create_list(:review, 3, movie:)

      expect(count_queries { get api_v1_movie_reviews_path(movie) }).to eq(few)
    end
  end
end
