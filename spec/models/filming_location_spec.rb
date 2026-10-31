require "rails_helper"

RSpec.describe FilmingLocation, type: :model do
  subject(:location) { build(:filming_location) }

  describe "factory" do
    it { is_expected.to be_valid }
  end

  describe "associations" do
    it { is_expected.to have_many(:movie_filming_locations).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:movies).through(:movie_filming_locations) }

    it "lists every movie filmed there" do
      location = create(:filming_location)
      gone_in_60_seconds, inception = create_list(:movie, 2)
      location.movies << [ gone_in_60_seconds, inception ]

      expect(location.reload.movies).to contain_exactly(gone_in_60_seconds, inception)
    end
  end

  describe "#destroy" do
    context "when the location is used by a movie" do
      let!(:movie_filming_location) { create(:movie_filming_location) }
      let(:location) { movie_filming_location.filming_location }

      it "is not allowed" do
        expect(location.destroy).to be(false)
      end

      it "explains why" do
        location.destroy

        expect(location.errors[:base]).to include(/dependent movie filming locations exist/)
      end

      it "keeps the location and its movie links" do
        expect { location.destroy }
          .to not_change(described_class, :count)
          .and not_change(MovieFilmingLocation, :count)
      end
    end

    context "when the location is used by no movie" do
      it "is allowed" do
        location = create(:filming_location)

        expect { location.destroy }.to change(described_class, :count).by(-1)
      end
    end
  end

  describe "database" do
    it { is_expected.to have_db_column(:name).of_type(:citext).with_options(null: false) }
    it { is_expected.to have_db_column(:country).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_index([ :name, :country ]).unique }

    it "rejects a NULL name even when validations are skipped" do
      location.name = nil

      expect { location.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a NULL country even when validations are skipped" do
      location.country = nil

      expect { location.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects the same name and country in a different case even when validations are skipped" do
      create(:filming_location, name: "New York", country: "US")
      location.assign_attributes(name: "NEW YORK", country: "US")

      expect { location.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "validations" do
    describe "in the import context" do
      before { create(:filming_location, name: "Los Angeles", country: "US") }

      it "skips the name/country uniqueness check (the database enforces it on insert)" do
        location.assign_attributes(name: "los angeles", country: "US")

        expect(location.valid?(:import)).to be(true)
      end

      it "still checks the country format" do
        location.assign_attributes(name: "los angeles", country: "USA")

        expect(location.valid?(:import)).to be(false)
      end
    end

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:country).ignoring_case_sensitivity }

    it { is_expected.to allow_values("US", "UK", "us").for(:country) }
    it { is_expected.not_to allow_values("USA", "U", "1A", "U$").for(:country) }

    it "rejects the same name in a different case within the same country" do
      create(:filming_location, name: "New York", country: "US")
      location.assign_attributes(name: "new york", country: "us")

      expect(location).not_to be_valid
    end

    it "allows the same name in different countries" do
      create(:filming_location, name: "Paris", country: "FR")
      location.assign_attributes(name: "Paris", country: "US")

      expect(location).to be_valid
    end
  end

  describe "find_or_create_by!" do
    let!(:new_york) { create(:filming_location, name: "New York", country: "US") }

    it "finds the existing location regardless of case and spacing" do
      expect(described_class.find_or_create_by!(name: " new   YORK ", country: " us ")).to eq(new_york)
    end

    it "doesn't create a duplicate" do
      expect { described_class.find_or_create_by!(name: "new york", country: "us") }
        .not_to change(described_class, :count)
    end

    it "keeps the original casing" do
      expect(described_class.find_or_create_by!(name: "NEW YORK", country: "US").name).to eq("New York")
    end
  end

  describe "bulk insert" do
    before { create(:filming_location, name: "Los Angeles", country: "US") }

    it "skips locations that already exist, regardless of case" do
      rows = [ { name: "los angeles", country: "US" }, { name: "BedfordShire", country: "UK" } ]

      expect { described_class.insert_all(rows, unique_by: [ :name, :country ]) }
        .to change(described_class, :count).by(1)
    end
  end

  describe "normalization" do
    it "squishes the name" do
      expect(described_class.new(name: "  Los   Angeles ").name).to eq("Los Angeles")
    end

    it "upcases and strips the country" do
      expect(described_class.new(country: " us ").country).to eq("US")
    end
  end
end
