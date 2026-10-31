require "rails_helper"

RSpec.describe MovieActor, type: :model do
  subject(:movie_actor) { build(:movie_actor) }

  describe "factory" do
    it { is_expected.to be_valid }
  end

  describe "associations" do
    it { is_expected.to belong_to(:movie) }
    it { is_expected.to belong_to(:actor) }
  end

  describe "database" do
    it { is_expected.to have_db_column(:movie_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_column(:actor_id).of_type(:integer).with_options(null: false) }
    it { is_expected.to have_db_index([ :movie_id, :actor_id ]).unique }
    it { is_expected.to have_db_index(:actor_id) }

    it "rejects the same actor twice in a movie even when validations are skipped" do
      existing = create(:movie_actor)
      duplicate = build(:movie_actor, movie: existing.movie, actor: existing.actor)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects a movie that doesn't exist even when validations are skipped" do
      movie_actor.movie_id = 0

      expect { movie_actor.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "rejects an actor that doesn't exist even when validations are skipped" do
      movie_actor.actor_id = 0

      expect { movie_actor.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:actor_id).scoped_to(:movie_id) }

    it "allows the same actor in different movies" do
      existing = create(:movie_actor)
      movie_actor.actor = existing.actor

      expect(movie_actor).to be_valid
    end
  end

  describe "bulk insert" do
    let!(:existing) { create(:movie_actor) }
    let!(:new_actor) { create(:actor) }
    let(:rows) do
      [
        { movie_id: existing.movie_id, actor_id: existing.actor_id },
        { movie_id: existing.movie_id, actor_id: new_actor.id }
      ]
    end

    it "skips pairs that already exist" do
      expect { described_class.insert_all(rows, unique_by: [ :movie_id, :actor_id ]) }
        .to change(described_class, :count).from(1).to(2)
    end
  end
end
