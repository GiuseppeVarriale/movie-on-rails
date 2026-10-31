require "rails_helper"

RSpec.describe Actor, type: :model do
  subject(:actor) { build(:actor) }

  describe "factory" do
    it { is_expected.to be_valid }
  end

  describe "associations" do
    it { is_expected.to have_many(:movie_actors).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:movies).through(:movie_actors) }

    it "lists every movie the actor appears in" do
      actor = create(:actor)
      gone_in_60_seconds, inception = create_list(:movie, 2)
      actor.movies << [ gone_in_60_seconds, inception ]

      expect(actor.reload.movies).to contain_exactly(gone_in_60_seconds, inception)
    end
  end

  describe "#destroy" do
    context "when the actor appears in a movie" do
      let!(:movie_actor) { create(:movie_actor) }
      let(:actor) { movie_actor.actor }

      it "is not allowed" do
        expect(actor.destroy).to be(false)
      end

      it "explains why" do
        actor.destroy

        expect(actor.errors[:base]).to include(/dependent movie actors exist/)
      end

      it "keeps the actor and their cast links" do
        expect { actor.destroy }
          .to not_change(described_class, :count)
          .and not_change(MovieActor, :count)
      end
    end

    context "when the actor appears in no movie" do
      it "is allowed" do
        actor = create(:actor)

        expect { actor.destroy }.to change(described_class, :count).by(-1)
      end
    end
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
    describe "in the import context" do
      before { create(:actor, name: "Leonardo Di Caprio") }

      it "skips the name uniqueness check (the database enforces it on insert)" do
        actor.name = "leonardo di caprio"

        expect(actor.valid?(:import)).to be(true)
      end

      it "still requires a name" do
        actor.name = ""

        expect(actor.valid?(:import)).to be(false)
      end
    end

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

  describe "search scopes" do
    before { [ "Leonardo Di Caprio", "Cleo Laine", "Ellen Page" ].each { |name| create(:actor, name:) } }

    describe ".name_contains" do
      it "keeps actors whose name contains the term, ignoring case" do
        expect(described_class.name_contains("LEO").pluck(:name)).to contain_exactly("Leonardo Di Caprio", "Cleo Laine")
      end

      it "treats % and _ literally" do
        expect(described_class.name_contains("%").count).to eq(0)
      end
    end

    describe ".order_by_prefix_match" do
      it "puts names starting with the term first" do
        expect(described_class.order_by_prefix_match("leo").order(:name).first.name).to eq("Leonardo Di Caprio")
      end

      it "only orders, without removing anyone" do
        expect(described_class.order_by_prefix_match("leo").count).to eq(3)
      end
    end
  end

  describe "normalization" do
    it "squishes the name" do
      expect(described_class.new(name: "  Leonardo   Di Caprio ").name).to eq("Leonardo Di Caprio")
    end
  end
end
