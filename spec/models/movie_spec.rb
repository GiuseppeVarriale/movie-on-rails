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
  end

  describe "database" do
    it { is_expected.to have_db_column(:title).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:description).of_type(:text).with_options(null: false) }
    it { is_expected.to have_db_column(:year).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:director).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_index(:title).unique }

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
