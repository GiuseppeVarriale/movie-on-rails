require "rails_helper"

RSpec.describe Movie, type: :model do
  subject(:movie) { build(:movie) }

  describe "factory" do
    it { is_expected.to be_valid }
  end

  describe "associations" do
    it { is_expected.to have_many(:movie_actors).dependent(:destroy) }
    it { is_expected.to have_many(:actors).through(:movie_actors) }

    it "lists its cast" do
      movie = create(:movie)
      cage, ribisi = create_list(:actor, 2)
      movie.actors << [ cage, ribisi ]

      expect(movie.reload.actors).to contain_exactly(cage, ribisi)
    end

    it "removes its cast links but keeps the actors when destroyed" do
      movie_actor = create(:movie_actor)

      expect { movie_actor.movie.destroy }
        .to change(MovieActor, :count).by(-1)
        .and not_change(Actor, :count)
    end

    it { is_expected.to have_many(:movie_filming_locations).dependent(:destroy) }
    it { is_expected.to have_many(:filming_locations).through(:movie_filming_locations) }

    it "lists its filming locations" do
      movie = create(:movie)
      los_angeles, bedfordshire = create_list(:filming_location, 2)
      movie.filming_locations << [ los_angeles, bedfordshire ]

      expect(movie.reload.filming_locations).to contain_exactly(los_angeles, bedfordshire)
    end

    it "removes its location links but keeps the locations when destroyed" do
      movie_filming_location = create(:movie_filming_location)

      expect { movie_filming_location.movie.destroy }
        .to change(MovieFilmingLocation, :count).by(-1)
        .and not_change(FilmingLocation, :count)
    end

    it { is_expected.to have_many(:reviews).dependent(:destroy) }

    it "lists its reviews" do
      movie = create(:movie)
      reviews = create_list(:review, 2, movie:)

      expect(movie.reload.reviews).to match_array(reviews)
    end

    it "deletes its reviews when destroyed" do
      movie = create(:movie)
      create_list(:review, 2, movie:)

      expect { movie.destroy }.to change(Review, :count).by(-2)
    end
  end

  describe "ratings" do
    let(:movie) { create(:movie) }

    it { is_expected.to have_db_column(:ratings_sum).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:ratings_count).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:average_stars).of_type(:decimal).with_options(precision: 3, scale: 2) }
    it { is_expected.to have_db_index([ :average_stars, :id ]) }

    it "has no average without reviews" do
      expect(movie.average_stars).to be_nil
    end

    it "computes the average in the database from the counters" do
      described_class.update_counters(movie.id, ratings_sum: 18, ratings_count: 5)

      expect(movie.reload.average_stars).to eq(BigDecimal("3.6"))
    end

    it "rounds the average to two decimals" do
      described_class.update_counters(movie.id, ratings_sum: 11, ratings_count: 3)

      expect(movie.reload.average_stars).to eq(BigDecimal("3.67"))
    end

    it "rejects negative counters" do
      described_class.update_counters(movie.id, ratings_sum: 2, ratings_count: 1)

      expect { described_class.update_counters(movie.id, ratings_count: -2) }
        .to raise_error(ActiveRecord::StatementInvalid, /movies_ratings_non_negative/)
    end

    describe ".lock_for_ratings_update!" do
      def sql_of(&)
        statements = []
        ActiveSupport::Notifications.subscribed(->(*, payload) { statements << payload[:sql] }, "sql.active_record", &)
        statements.grep(/FOR NO KEY UPDATE/)
      end

      it "locks the movies in id order without blocking review inserts" do
        expect(sql_of { described_class.where(id: [ 2, 1 ]).lock_for_ratings_update! }.sole)
          .to include('WHERE "movies"."id" IN ($1, $2) ORDER BY "movies"."id" ASC FOR NO KEY UPDATE')
      end

      it "returns the locked ids" do
        movies = create_list(:movie, 2)

        expect(described_class.where(id: movies.map(&:id)).lock_for_ratings_update!).to eq(movies.map(&:id).sort)
      end
    end

    describe ".add_ratings" do
      let!(:other) { create(:movie) }
      let(:totals) do
        { movie.id => Movie::RatingTotals.new(stars: 7, count: 2), other.id => Movie::RatingTotals.new(stars: 5, count: 1) }
      end

      it "adds each movie's totals to its counters" do
        described_class.update_counters(movie.id, ratings_sum: 4, ratings_count: 1)

        described_class.add_ratings(totals)

        expect([ movie.reload, other.reload ].map { |m| [ m.ratings_sum, m.ratings_count, m.average_stars ] })
          .to eq([ [ 11, 3, BigDecimal("3.67") ], [ 5, 1, BigDecimal("5") ] ])
      end

      it "does nothing without totals" do
        expect { described_class.add_ratings({}) }.not_to(change { movie.reload.ratings_count })
      end
    end

    it "sorts by average with the index, best rated first" do
      worse, better, unrated = create_list(:movie, 3)
      described_class.update_counters(worse.id, ratings_sum: 11, ratings_count: 4)
      described_class.update_counters(better.id, ratings_sum: 18, ratings_count: 5)

      expect(described_class.order(Arel.sql("average_stars DESC NULLS LAST"), id: :desc)).to eq([ better, worse, unrated ])
    end
  end

  describe "database" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:year).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:director).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_index(:title).unique }
    it { is_expected.to have_db_index([ :year, :title ]) }

    it "rejects a NULL title even when validations are skipped" do
      movie.title = nil

      expect { movie.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a NULL description even when validations are skipped" do
      movie.description = nil

      expect { movie.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a NULL year even when validations are skipped" do
      movie.year = nil

      expect { movie.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a NULL director even when validations are skipped" do
      movie.director = nil

      expect { movie.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a duplicate title even when validations are skipped" do
      create(:movie, title: "Inception")
      movie.title = "Inception"

      expect { movie.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "validations" do
    describe "in the import context" do
      before { create(:movie, title: "Inception") }

      it "skips the title uniqueness check (the database enforces it on insert)" do
        movie.title = "Inception"

        expect(movie.valid?(:import)).to be(true)
      end

      it "still applies the other rules" do
        movie.assign_attributes(title: "Inception", year: 1700)

        expect(movie.valid?(:import)).to be(false)
      end
    end

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_uniqueness_of(:title) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:year) }
    it { is_expected.to validate_presence_of(:director) }

    it do
      expect(movie).to validate_numericality_of(:year)
        .only_integer
        .is_greater_than_or_equal_to(Movie::FIRST_FILM_YEAR)
        .is_less_than_or_equal_to(Date.current.year)
    end

    describe "year range" do
      around { |example| travel_to(Date.new(2026, 10, 31)) { example.run } }

      it "accepts the year of the first film ever recorded (1888)" do
        movie.year = 1888

        expect(movie).to be_valid
      end

      it "rejects years before the first film ever recorded" do
        movie.year = 1887

        expect(movie).not_to be_valid
      end

      it "accepts the current year" do
        movie.year = 2026

        expect(movie).to be_valid
      end

      it "rejects future years" do
        movie.year = 2027

        expect(movie).not_to be_valid
      end
    end

    it "uses the current date, so next year becomes valid once it arrives" do
      movie.year = 2027

      travel_to(Date.new(2027, 1, 1)) { expect(movie).to be_valid }
    end
  end

  describe "normalization" do
    it "squishes the title" do
      expect(described_class.new(title: "  Gone in   60 seconds ").title).to eq("Gone in 60 seconds")
    end

    it "squishes the director" do
      expect(described_class.new(director: " Dominic   Sena ").director).to eq("Dominic Sena")
    end
  end
end
