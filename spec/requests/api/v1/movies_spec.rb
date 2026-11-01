require "swagger_helper"

RSpec.describe "API v1 movies", type: :request do
  let(:leo) { create(:actor, name: "Leonardo Di Caprio") }
  let(:inception) do
    create(:movie, title: "Inception", year: 2010, director: "Christopher Nolan").tap do |movie|
      movie.actors << [ leo, create(:actor, name: "Elliot Page") ]
      movie.filming_locations << create(:filming_location, name: "Paris", country: "FR")
    end
  end
  let(:gone) do
    create(:movie, title: "Gone in 60 seconds", year: 2000, director: "Dominic Sena").tap do |movie|
      movie.actors << [ leo, create(:actor, name: "Nicolas Cage") ]
    end
  end
  let(:zodiac) { create(:movie, title: "Zodiac", year: 2007, director: "David Fincher") }

  before do
    Movie.add_ratings(
      inception.id => Movie::RatingTotals.new(stars: 9, count: 2),
      gone.id => Movie::RatingTotals.new(stars: 7, count: 2)
    )
    zodiac
  end

  def titles
    response.parsed_body["movies"].pluck("title")
  end

  def titles_for(params)
    get api_v1_movies_path(params)
    titles
  end

  def inception_json
    {
      "id" => inception.id, "title" => "Inception", "year" => 2010, "director" => "Christopher Nolan",
      "description" => inception.description, "average_stars" => 4.5, "reviews_count" => 2,
      "actors" => [ { "id" => inception.actors.find_by!(name: "Elliot Page").id, "name" => "Elliot Page" },
                    { "id" => leo.id, "name" => "Leonardo Di Caprio" } ],
      "filming_locations" => [ { "id" => inception.filming_locations.first.id, "name" => "Paris", "country" => "FR" } ],
      "url" => api_v1_movie_url(inception), "reviews_url" => api_v1_movie_reviews_url(inception)
    }
  end

  path "/api/v1/movies" do
    get "List movies" do
      tags "Movies"
      description "Same list, sorting and actor filter as the movies page."
      produces "application/json"
      parameter name: :sort, in: :query, required: false,
                schema: { type: :string, enum: MovieSearch::SORTS.keys, default: MovieSearch::DEFAULT_SORT },
                description: "rating: best rated first (unrated last); title: A–Z; newest: by year, newest first"
      parameter name: :actor_id, in: :query, required: false, schema: { type: :integer, minimum: 1 },
                description: "Only movies with this actor (see /api/v1/actors). Takes precedence over actor"
      parameter name: :actor, in: :query, required: false, schema: { type: :string, minLength: ActorSearch::MIN_LENGTH },
                description: "Only movies with an actor whose name contains this text"
      parameter name: :page, in: :query, required: false, schema: { type: :integer, minimum: 1, default: 1 }
      parameter name: :per_page, in: :query, required: false,
                schema: { type: :integer, minimum: 1, maximum: Api::V1::BaseController::MAX_PER_PAGE,
                          default: Api::V1::BaseController::DEFAULT_PER_PAGE }

      response 200, "Movies" do
        schema type: :object,
               properties: {
                 movies: { type: :array, items: { "$ref" => "#/components/schemas/movie" } },
                 meta: {
                   type: :object,
                   properties: {
                     pagination: { "$ref" => "#/components/schemas/pagination" },
                     filters: {
                       type: :object,
                       description: "The filters actually applied",
                       properties: {
                         sort: { type: :string, example: "rating" },
                         actor_id: { type: :integer, nullable: true },
                         actor: { type: :string, nullable: true, example: "leo" }
                       }
                     }
                   }
                 }
               }
        let(:actor_id) { leo.id }

        run_test! do
          expect(titles).to eq([ "Inception", "Gone in 60 seconds" ])
        end
      end

      response 400, "Invalid parameter" do
        schema "$ref" => "#/components/schemas/error"
        example "application/json", :unknown_sort,
                { error: { code: "invalid_parameter", message: "sort must be one of: rating, title, newest" } }
        example "application/json", :invalid_actor_id,
                { error: { code: "invalid_parameter", message: "actor_id must be a positive integer" } }
        example "application/json", :short_actor,
                { error: { code: "invalid_parameter", message: "actor must have at least 3 characters" } }
        let(:sort) { "popularity" }

        run_test! do
          expect(response.parsed_body.dig("error", "message")).to eq("sort must be one of: rating, title, newest")
        end
      end
    end
  end

  path "/api/v1/movies/{id}" do
    parameter name: :id, in: :path, schema: { type: :integer }

    get "Show a movie" do
      tags "Movies"
      produces "application/json"

      response 200, "Movie" do
        schema type: :object, properties: { movie: { "$ref" => "#/components/schemas/movie" } }
        let(:id) { inception.id }

        run_test! do
          expect(response.parsed_body["movie"]).to include("title" => "Inception", "average_stars" => 4.5, "reviews_count" => 2)
        end
      end

      response 404, "Movie not found" do
        schema "$ref" => "#/components/schemas/error"
        example "application/json", :movie_not_found, { error: { code: "not_found", message: "Movie not found" } }
        let(:id) { 0 }

        run_test!
      end
    end
  end

  describe "GET /api/v1/movies" do
    it "sorts the best rated first by default, unrated last" do
      get api_v1_movies_path

      expect(titles).to eq([ "Inception", "Gone in 60 seconds", "Zodiac" ])
    end

    it "sorts by title or newest" do
      get api_v1_movies_path(sort: "title")
      by_title = titles
      get api_v1_movies_path(sort: "newest")

      expect([ by_title, titles ]).to eq([ [ "Gone in 60 seconds", "Inception", "Zodiac" ], [ "Inception", "Zodiac", "Gone in 60 seconds" ] ])
    end

    it "returns each movie with its details" do
      get api_v1_movies_path

      expect(response.parsed_body["movies"].first).to eq(inception_json)
    end

    it "returns null as the average of an unrated movie" do
      get api_v1_movies_path(sort: "title")

      expect(response.parsed_body["movies"].last).to include("title" => "Zodiac", "average_stars" => nil, "reviews_count" => 0)
    end

    it "filters by part of an actor's name, in any case" do
      get api_v1_movies_path(actor: "  CAGE ")

      expect([ titles, response.parsed_body.dig("meta", "filters") ])
        .to eq([ [ "Gone in 60 seconds" ], { "sort" => "rating", "actor_id" => nil, "actor" => "CAGE" } ])
    end

    it "prefers actor_id over actor" do
      get api_v1_movies_path(actor_id: leo.id, actor: "cage")

      expect([ titles, response.parsed_body.dig("meta", "filters", "actor") ]).to eq([ [ "Inception", "Gone in 60 seconds" ], nil ])
    end

    it "returns an empty list for an actor without movies" do
      get api_v1_movies_path(actor_id: create(:actor).id)

      expect([ response.status, titles ]).to eq([ 200, [] ])
    end

    it "filters by the actor_id alone" do
      get api_v1_movies_path(actor_id: inception.actors.find_by!(name: "Elliot Page").id)

      expect(titles).to eq([ "Inception" ])
    end

    it "matches the text anywhere in an actor's name" do
      zodiac.actors << create(:actor, name: "Cleo Smith")

      get api_v1_movies_path(actor: "leo")

      expect(titles).to eq([ "Inception", "Gone in 60 seconds", "Zodiac" ])
    end

    it "lists a movie once when several of its actors match" do
      inception.actors << create(:actor, name: "Leonard Nimoy")

      get api_v1_movies_path(actor: "leo")

      expect([ titles, response.parsed_body.dig("meta", "pagination", "count") ]).to eq([ [ "Inception", "Gone in 60 seconds" ], 2 ])
    end

    it "returns an empty list when no actor matches the text" do
      get api_v1_movies_path(actor: "xyz")

      expect([ response.status, titles ]).to eq([ 200, [] ])
    end

    it "returns an empty list for an unknown actor_id" do
      get api_v1_movies_path(actor_id: Actor.maximum(:id).to_i + 1)

      expect([ response.status, titles ]).to eq([ 200, [] ])
    end

    it "takes % and _ in the text literally" do
      zodiac.actors << create(:actor, name: "Mark_Ruffalo 100%")

      matches = %w[k_r a_k %%%].map { |text| titles_for(actor: text) }

      expect(matches).to eq([ [ "Zodiac" ], [], [] ])
    end

    it "combines the actor filter with each sort" do
      orders = MovieSearch::SORTS.keys.index_with { |sort| titles_for(actor: "leo", sort:) }

      expect(orders).to eq("rating" => [ "Inception", "Gone in 60 seconds" ], "title" => [ "Gone in 60 seconds", "Inception" ],
                           "newest" => [ "Inception", "Gone in 60 seconds" ])
    end

    it "breaks ties in the newest sort by title" do
      create(:movie, title: "Alien", year: 2010)

      get api_v1_movies_path(sort: "newest")

      expect(titles).to eq([ "Alien", "Inception", "Zodiac", "Gone in 60 seconds" ])
    end

    it "paginates the filtered movies" do
      get api_v1_movies_path(actor: "leo", sort: "title", per_page: 1, page: 2)

      expect([ titles, response.parsed_body.dig("meta", "pagination").slice("count", "pages") ])
        .to eq([ [ "Inception" ], { "count" => 2, "pages" => 2 } ])
    end

    it "lists the same movies in the same order as the movies page" do
      create_list(:movie, 3)
      get movies_path(sort: "newest", actor: "leo")
      page_titles = Nokogiri::HTML(response.body).css("article h2").map { |title| title.text.squish }

      get api_v1_movies_path(sort: "newest", actor: "leo")

      expect(titles).to eq(page_titles).and eq([ "Inception", "Gone in 60 seconds" ])
    end

    it "paginates with page and per_page" do
      get api_v1_movies_path(page: 2, per_page: 2)

      expect([ titles, response.parsed_body.dig("meta", "pagination") ]).to eq(
        [ [ "Zodiac" ], { "page" => 2, "per_page" => 2, "pages" => 2, "count" => 3, "next_page" => nil, "prev_page" => 1 } ]
      )
    end

    it "uses 20 per page by default and at most 100" do
      stub_const("Api::V1::BaseController::MAX_PER_PAGE", 2)
      get api_v1_movies_path
      default = response.parsed_body.dig("meta", "pagination", "per_page")
      get api_v1_movies_path(per_page: 50)

      expect([ default, response.parsed_body.dig("meta", "pagination", "per_page"), titles.size ]).to eq([ 20, 2, 2 ])
    end

    it "returns an empty page after the last one" do
      get api_v1_movies_path(page: 9)

      expect([ response.status, titles ]).to eq([ 200, [] ])
    end

    it "runs the same number of queries whatever the number of movies and cast" do
      few = count_queries { get api_v1_movies_path }
      create_list(:movie, 3) { |movie| movie.actors << create_list(:actor, 2) }

      expect(count_queries { get api_v1_movies_path }).to eq(few)
    end

    it "rejects an unknown sort, an invalid actor_id and a short actor" do
      statuses = [ { sort: "" }, { actor_id: "abc" }, { actor_id: "-1" }, { actor: "le" } ].map do |params|
        get api_v1_movies_path(params)
        [ response.status, response.parsed_body.dig("error", "code") ]
      end

      expect(statuses.uniq).to eq([ [ 400, "invalid_parameter" ] ])
    end

    it "drops lists and hashes, which aren't permitted, and shows the filters applied" do
      get api_v1_movies_path(actor: [ "cage" ], per_page: { size: 1 })

      expect([ titles.size, response.parsed_body["meta"] ]).to eq([ 3, {
        "pagination" => { "page" => 1, "per_page" => 20, "pages" => 1, "count" => 3, "next_page" => nil, "prev_page" => nil },
        "filters" => { "sort" => "rating", "actor_id" => nil, "actor" => nil }
      } ])
    end

    it "ignores unknown parameters" do
      get api_v1_movies_path(order: "id; DROP TABLE movies")

      expect([ response.status, titles ]).to eq([ 200, [ "Inception", "Gone in 60 seconds", "Zodiac" ] ])
    end

    it "explains what is wrong" do
      get api_v1_movies_path(actor: "le")

      expect(response.parsed_body).to eq("error" => { "code" => "invalid_parameter", "message" => "actor must have at least 3 characters" })
    end

    it "only answers JSON" do
      get "/api/v1/movies.xml"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/movies/:id" do
    it "lists the whole cast by name" do
      inception.actors << create(:actor, name: "Tom Hardy")

      get api_v1_movie_path(inception)

      expect(response.parsed_body.dig("movie", "actors").pluck("name")).to eq([ "Elliot Page", "Leonardo Di Caprio", "Tom Hardy" ])
    end

    it "returns 404 with a JSON error for an unknown movie" do
      get api_v1_movie_path("abc")

      expect([ response.status, response.parsed_body ])
        .to eq([ 404, { "error" => { "code" => "not_found", "message" => "Movie not found" } } ])
    end
  end
end
