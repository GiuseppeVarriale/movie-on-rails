require "rails_helper"

RSpec.describe Import, type: :model do
  subject(:import) { build(:import) }

  let(:checksum) { Faker::Crypto.sha256 }

  describe "factory" do
    it { is_expected.to be_valid }
    it { expect(build(:import, :completed)).to be_valid }
  end

  describe "database" do
    it { is_expected.to have_db_column(:kind).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:status).of_type(:string).with_options(null: false, default: "pending") }
    it { is_expected.to have_db_column(:source_path).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:file_checksum).of_type(:string).with_options(null: false) }
    it { is_expected.to have_db_column(:rows_processed).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:rows_failed).of_type(:integer).with_options(null: false, default: 0) }
    it { is_expected.to have_db_column(:failures).of_type(:jsonb).with_options(null: false, default: []) }
    it { is_expected.to have_db_index(:file_checksum).unique }

    it "rejects a second completed import of the same file even when validations are skipped" do
      create(:import, :completed, file_checksum: checksum)
      import.assign_attributes(status: :completed, file_checksum: checksum)

      expect { import.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "accepts the same file again when the earlier import didn't complete" do
      create(:import, status: :failed, file_checksum: checksum)
      import.assign_attributes(status: :completed, file_checksum: checksum)

      expect { import.save(validate: false) }.not_to raise_error
    end
  end

  describe "enums" do
    it do
      expect(import).to define_enum_for(:kind)
        .with_values(movies: "movies", reviews: "reviews")
        .backed_by_column_of_type(:string)
    end

    it do
      expect(import).to define_enum_for(:status)
        .with_values(pending: "pending", running: "running", completed: "completed", failed: "failed")
        .backed_by_column_of_type(:string)
        .with_default(:pending)
    end

    it { is_expected.not_to allow_value("other").for(:kind) }
    it { is_expected.not_to allow_value("other").for(:status) }
  end

  describe "defaults" do
    subject(:import) { described_class.new }

    it { is_expected.to be_pending }
    it { expect(import.rows_processed).to eq(0) }
    it { expect(import.rows_failed).to eq(0) }
    it { expect(import.failures).to eq([]) }
  end

  describe "validations" do
    it { is_expected.not_to allow_value(nil).for(:kind) }
    it { is_expected.to validate_presence_of(:source_path) }
    it { is_expected.to validate_presence_of(:file_checksum) }
    it { is_expected.to validate_numericality_of(:rows_processed).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:rows_failed).only_integer.is_greater_than_or_equal_to(0) }

    it { is_expected.to allow_value(Faker::Crypto.sha256).for(:file_checksum) }
    it { is_expected.not_to allow_values("abc", "z" * 64, Faker::Crypto.md5).for(:file_checksum) }

    describe "a file can be completed only once" do
      before { create(:import, :completed, file_checksum: checksum) }

      it "rejects a second completed import of the same file" do
        import.assign_attributes(status: :completed, file_checksum: checksum)

        expect(import).not_to be_valid
      end

      it "allows a new pending import of the same file" do
        import.file_checksum = checksum

        expect(import).to be_valid
      end
    end

    it "allows completing a file whose earlier import failed" do
      create(:import, status: :failed, file_checksum: checksum)
      import.assign_attributes(status: :completed, file_checksum: checksum)

      expect(import).to be_valid
    end
  end
end
