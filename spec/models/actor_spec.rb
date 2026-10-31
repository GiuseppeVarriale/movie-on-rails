require "rails_helper"

RSpec.describe Actor, type: :model do
  subject(:actor) { build(:actor) }

  describe "factory" do
    it { is_expected.to be_valid }
  end

  describe "database" do
    it { is_expected.to have_db_column(:name).of_type(:citext).with_options(null: false) }
    it { is_expected.to have_db_index(:name).unique }

    it "rejects a NULL name even when validations are skipped" do
      actor.name = nil

      expect { actor.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "rejects the same name in a different case even when validations are skipped" do
      create(:actor, name: "Leonardo Di Caprio")
      actor.name = "LEONARDO DI CAPRIO"

      expect { actor.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    # citext makes the uniqueness check case-insensitive; covered explicitly below
    it { is_expected.to validate_uniqueness_of(:name).ignoring_case_sensitivity }

    it "rejects the same name in a different case" do
      create(:actor, name: "Leonardo Di Caprio")
      actor.name = "leonardo di caprio"

      expect(actor).not_to be_valid
    end
  end

  describe "case-insensitive lookups" do
    before { create(:actor, name: "Leonardo Di Caprio") }

    it "finds an actor regardless of case" do
      expect(described_class.find_by(name: "leonardo DI caprio")).to be_present
    end

    it "keeps the original casing" do
      expect(described_class.find_by(name: "leonardo di caprio").name).to eq("Leonardo Di Caprio")
    end

    it "matches lists of names regardless of case" do
      expect(described_class.where(name: [ "LEONARDO DI CAPRIO", "Nobody" ]).count).to eq(1)
    end
  end

  describe "bulk insert (used by the CSV import)" do
    it "skips actors that already exist, regardless of case" do
      create(:actor, name: "Leonardo Di Caprio")

      expect {
        described_class.insert_all([ { name: "leonardo di caprio" }, { name: "Nicolas Cage" } ], unique_by: :name)
      }.to change(described_class, :count).by(1)
    end

    it "keeps the casing of the actor that was stored first" do
      create(:actor, name: "Leonardo Di Caprio")

      described_class.insert_all([ { name: "LEONARDO DI CAPRIO" } ], unique_by: :name)

      expect(described_class.pluck(:name)).to eq([ "Leonardo Di Caprio" ])
    end
  end

  describe "normalization" do
    it "squishes the name" do
      expect(described_class.new(name: "  Leonardo   Di Caprio ").name).to eq("Leonardo Di Caprio")
    end
  end
end
