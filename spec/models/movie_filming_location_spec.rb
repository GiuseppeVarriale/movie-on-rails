require "rails_helper"

RSpec.describe MovieFilmingLocation, type: :model do
  subject(:movie_filming_location) { build(:movie_filming_location) }

  describe "factory" do
    it { is_expected.to be_valid }
  end

  describe "associations" do
    it { is_expected.to belong_to(:movie) }
    it { is_expected.to belong_to(:filming_location) }
  end

  describe "database" do
    it { is_expected.to have_db_column(:movie_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:filming_location_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_index([ :movie_id, :filming_location_id ]).unique }
    it { is_expected.to have_db_index(:filming_location_id) }

    it "rejects the same location twice in a movie even when validations are skipped" do
      existing = create(:movie_filming_location)
      duplicate = build(:movie_filming_location, movie: existing.movie, filming_location: existing.filming_location)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects a movie that doesn't exist even when validations are skipped" do
      movie_filming_location.movie_id = 0

      expect { movie_filming_location.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "rejects a location that doesn't exist even when validations are skipped" do
      movie_filming_location.filming_location_id = 0

      expect { movie_filming_location.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:filming_location_id).scoped_to(:movie_id) }

    it "allows the same location in different movies" do
      existing = create(:movie_filming_location)
      movie_filming_location.filming_location = existing.filming_location

      expect(movie_filming_location).to be_valid
    end
  end

  describe "bulk insert" do
    let!(:existing) { create(:movie_filming_location) }
    let!(:new_location) { create(:filming_location) }
    let(:rows) do
      [
        { movie_id: existing.movie_id, filming_location_id: existing.filming_location_id },
        { movie_id: existing.movie_id, filming_location_id: new_location.id }
      ]
    end

    it "skips pairs that already exist" do
      expect { described_class.insert_all(rows, unique_by: [ :movie_id, :filming_location_id ]) }
        .to change(described_class, :count).from(1).to(2)
    end
  end
end
