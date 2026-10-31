require "rails_helper"

RSpec.describe Review, type: :model do
  subject(:review) { build(:review) }

  describe "factory" do
    it { is_expected.to be_valid }
  end

  describe "associations" do
    it { is_expected.to belong_to(:movie) }
  end

  describe "database" do
    it { is_expected.to have_db_column(:movie_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:reviewer_name).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:stars).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:body).of_type(:text).with_options(null: true) }
    it { is_expected.to have_db_index([ :movie_id, :created_at, :id ]) }

    it "rejects a NULL reviewer name even when validations are skipped" do
      review.reviewer_name = nil

      expect { review.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects NULL stars even when validations are skipped" do
      review.stars = nil

      expect { review.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects a movie that doesn't exist even when validations are skipped" do
      review.movie_id = 0

      expect { review.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:reviewer_name) }
    it { is_expected.to validate_presence_of(:stars) }
    it { is_expected.not_to validate_presence_of(:body) }

    it do
      expect(review).to validate_numericality_of(:stars)
        .only_integer
        .is_greater_than_or_equal_to(Review::MIN_STARS)
        .is_less_than_or_equal_to(Review::MAX_STARS)
    end

    it { is_expected.to allow_values(0, 5).for(:stars) }
    it { is_expected.not_to allow_values(-1, 6, 2.5).for(:stars) }

    it "keeps the body exactly as given" do
      review.body = "Empty"

      expect(review.tap(&:save!).reload.body).to eq("Empty")
    end

    it "allows two reviews with the same reviewer name on the same movie (homonyms)" do
      existing = create(:review, reviewer_name: "Sam Pedro")
      review.assign_attributes(movie: existing.movie, reviewer_name: "Sam Pedro")

      expect(review).to be_valid
    end
  end

  describe "normalization" do
    it "squishes the reviewer name" do
      expect(described_class.new(reviewer_name: "  Sam   Pedro ").reviewer_name).to eq("Sam Pedro")
    end
  end
end
