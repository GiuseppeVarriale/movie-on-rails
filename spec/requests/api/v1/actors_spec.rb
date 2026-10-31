require "swagger_helper"

RSpec.describe "API v1 actors", type: :request do
  let!(:leo) { create(:actor, name: "Leonardo Di Caprio") }

  before do
    leo.movies << create_list(:movie, 2)
    create(:actor, name: "Cleo Smith")
  end

  def names
    response.parsed_body["actors"].pluck("name")
  end

  path "/api/v1/actors" do
    get "Search actors" do
      tags "Actors"
      description "Actors whose name contains `q` (any case), names starting with it first, " \
                  "at most #{ActorSearch::LIMIT}. Use an actor's id to filter /api/v1/movies."
      produces "application/json"
      parameter name: :q, in: :query, required: true, schema: { type: :string, minLength: ActorSearch::MIN_LENGTH }

      response 200, "Actors" do
        schema type: :object,
               properties: {
                 actors: { type: :array, items: { "$ref" => "#/components/schemas/actor" } },
                 meta: { type: :object, properties: { q: { type: :string, example: "leo" }, limit: { type: :integer, example: 10 } } }
               }
        let(:q) { "leo" }

        run_test! do
          expect(names).to eq([ "Leonardo Di Caprio", "Cleo Smith" ])
        end
      end

      response 400, "Missing or too short q" do
        schema "$ref" => "#/components/schemas/error"
        example "application/json", :short_q, { error: { code: "invalid_parameter", message: "q must have at least 3 characters" } }
        let(:q) { "le" }

        run_test!
      end
    end
  end

  describe "GET /api/v1/actors" do
    it "returns each actor's movie count and a link to their movies" do
      get api_v1_actors_path(q: "LEONARDO")

      expect(response.parsed_body["actors"]).to eq([
        { "id" => leo.id, "name" => "Leonardo Di Caprio", "movies_count" => 2, "movies_url" => api_v1_movies_url(actor_id: leo.id) }
      ])
    end

    it "lists names starting with q first, then by name" do
      create(:actor, name: "Leopold Stokowski")

      get api_v1_actors_path(q: "leo")

      expect(names).to eq([ "Leonardo Di Caprio", "Leopold Stokowski", "Cleo Smith" ])
    end

    it "returns at most #{ActorSearch::LIMIT} actors" do
      create_list(:actor, ActorSearch::LIMIT) { |actor, i| actor.update!(name: "Leon #{i}") }

      get api_v1_actors_path(q: "leo")

      expect(names.size).to eq(ActorSearch::LIMIT)
    end

    it "takes % and _ in q literally" do
      get api_v1_actors_path(q: "%%%")

      expect(names).to eq([])
    end

    it "returns an empty list when nothing matches" do
      get api_v1_actors_path(q: "xyz")

      expect([ response.status, names ]).to eq([ 200, [] ])
    end

    it "requires q" do
      get api_v1_actors_path

      expect(response.parsed_body).to eq("error" => { "code" => "invalid_parameter", "message" => "q must have at least 3 characters" })
    end

    it "drops a list as q, which isn't permitted" do
      get api_v1_actors_path(q: [ "leo" ])

      expect([ response.status, response.parsed_body.dig("error", "message") ]).to eq([ 400, "q must have at least 3 characters" ])
    end

    it "lists the same actors as the autocomplete" do
      get actors_path(q: "leo")
      suggestions = Nokogiri::HTML(response.body).css("[data-autocomplete-label]").map { |option| option["data-autocomplete-label"] }

      get api_v1_actors_path(q: "leo")

      expect(names).to eq(suggestions)
    end
  end
end
