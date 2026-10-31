require "rails_helper"

RSpec.describe Import::ReviewsImporter do
  let(:header) { "Movie,User,Stars,Review\n" }

  let!(:gone_in_60_seconds) { create(:movie, title: "Gone in 60 seconds") }
  let!(:inception) { create(:movie, title: "Inception") }

  def count_queries(&)
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name].in?(%w[SCHEMA TRANSACTION]) }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    queries
  end

  describe ".call with the sample file" do
    subject(:import) { described_class.call(file_fixture("reviews.csv")) }

    let(:inception_reviews) do
      [
        [ "Mack Boe", 4, "Ok movie" ],
        [ "Peter Troll", 2, "The best ever!" ],
        [ "Rik van der Kroon", 3, "Really good!" ],
        [ "Sam Pedro", 2, "Empty" ]
      ]
    end

    it "creates every review" do
      expect { import }.to change(Review, :count).by(9)
    end

    it "attaches the reviews to their movies" do
      import

      expect([ gone_in_60_seconds.reviews.count, inception.reviews.count ]).to eq([ 5, 4 ])
    end

    it "stores reviewer, stars and text as given" do
      import

      expect(inception.reviews.order(:id).pluck(:reviewer_name, :stars, :body)).to eq(inception_reviews)
    end

    it "records a completed import" do
      expect(import).to have_attributes(kind: "reviews", status: "completed", rows_processed: 9, rows_failed: 0)
    end

    it "gives the same result in tiny batches" do
      expect { described_class.call(file_fixture("reviews.csv"), batch_size: 2) }.to change(Review, :count).by(9)
    end
  end

  describe "importing the same file twice" do
    before { described_class.call(file_fixture("reviews.csv")) }

    it "refuses the second import without duplicating reviews" do
      expect { described_class.call(file_fixture("reviews.csv")) rescue nil }.not_to change(Review, :count)
    end

    it "raises AlreadyImportedError" do
      expect { described_class.call(file_fixture("reviews.csv")) }
        .to raise_error(described_class::AlreadyImportedError)
    end
  end

  describe "invalid rows" do
    let(:path) do
      csv_file(header +
        "Inception,Sam Pedro,4,Good\n" +
        "The Matrix,Neo,5,Whoa\n" +
        "Inception,Low,-1,Bad\n" +
        "Inception,High,6,Too good\n" +
        "Inception,Text,abc,Huh\n" +
        "Inception,Half,4.5,Almost\n" +
        "Inception,,3,No name\n")
    end

    let(:expected_failures) do
      [
        { "line" => 3, "errors" => [ "Movie \"The Matrix\" not found" ] },
        { "line" => 4, "errors" => [ "Stars must be greater than or equal to 0" ] },
        { "line" => 5, "errors" => [ "Stars must be less than or equal to 5" ] },
        { "line" => 6, "errors" => [ "Stars is not a number" ] },
        { "line" => 7, "errors" => [ "Stars must be an integer" ] },
        { "line" => 8, "errors" => [ "Reviewer name can't be blank" ] }
      ]
    end

    it "imports only the valid ones" do
      expect { described_class.call(path) }.to change(Review, :count).by(1)
    end


    it "reports each one with its line number and errors" do
      expect(described_class.call(path).failures).to match_array(expected_failures)
    end

    it "counts processed and failed rows" do
      expect(described_class.call(path)).to have_attributes(status: "completed", rows_processed: 7, rows_failed: 6)
    end
  end

  describe "rules" do
    it "accepts 0 stars and an empty text" do
      path = csv_file(header + "Inception,Sam Pedro,0,\n")

      expect { described_class.call(path) }.to change { inception.reviews.where(stars: 0, body: nil).count }.by(1)
    end

    it "allows the same reviewer name twice on a movie" do
      path = csv_file(header + "Inception,Sam Pedro,4,First\nInception,Sam Pedro,2,Second\n")

      expect { described_class.call(path) }.to change(Review, :count).by(2)
    end

    it "matches the movie title regardless of surrounding spaces" do
      path = csv_file(header + "  Inception  ,Sam Pedro,4,Good\n")

      expect { described_class.call(path) }.to change(inception.reviews, :count).by(1)
    end
  end

  describe "movie ratings" do
    it "adds the imported reviews to each movie's ratings" do
      described_class.call(file_fixture("reviews.csv"))

      expect([ gone_in_60_seconds.reload, inception.reload ].map { |movie| [ movie.ratings_sum, movie.ratings_count ] })
        .to eq([ [ 18, 5 ], [ 11, 4 ] ])
    end

    it "gives the sample movies their averages" do
      described_class.call(file_fixture("reviews.csv"))

      expect([ gone_in_60_seconds.reload.average_stars, inception.reload.average_stars ])
        .to eq([ BigDecimal("3.6"), BigDecimal("2.75") ])
    end

    it "gives the same averages in tiny batches" do
      described_class.call(file_fixture("reviews.csv"), batch_size: 2)

      expect(inception.reload.average_stars).to eq(BigDecimal("2.75"))
    end

    it "adds to ratings the movie already had" do
      Movie.update_counters(inception.id, ratings_sum: 5, ratings_count: 1)

      described_class.call(csv_file(header + "Inception,Sam Pedro,1,Bad\n"))

      expect(inception.reload).to have_attributes(ratings_sum: 6, ratings_count: 2, average_stars: BigDecimal("3"))
    end

    it "ignores rows that failed" do
      described_class.call(csv_file(header + "Inception,Sam Pedro,4,Good\nInception,Bad,9,Nope\n"))

      expect(inception.reload).to have_attributes(ratings_sum: 4, ratings_count: 1)
    end
  end

  describe "performance" do
    let(:small) { csv_file(header + ("Inception,Sam Pedro,4,Good\n" * 5)) }
    let(:large) { csv_file(header + ("Inception,Sam Pedro,4,Good\n" * 50)) }

    it "runs the same number of queries whatever the number of rows in a batch" do
      expect(count_queries { described_class.call(large) }).to eq(count_queries { described_class.call(small) })
    end
  end
end
