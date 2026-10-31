require "rails_helper"

RSpec.describe Import::MoviesImporter, :without_transaction do
  self.use_transactional_tests = false

  let(:header) { "Movie,Description,Year,Director,Actor,Filming location,Country\n" }

  def rows(round)
    (1..100).flat_map do |movie|
      (1..5).map { |actor| "R#{round} Movie #{movie},Plot,2000,Director,R#{round} Actor #{(movie + actor) % 30},City #{actor},US\n" }
    end
  end

  def files(round)
    [ rows(round), rows(round).reverse, rows(round).shuffle(random: Random.new(1)), rows(round).shuffle(random: Random.new(2)) ]
      .map { |file_rows| csv_file(header + file_rows.join) }
  end

  def import_in_parallel(round)
    round_files = files(round)
    in_parallel(round_files.size) do |index|
      described_class.call(round_files[index], batch_size: 250)
    rescue ActiveRecord::Deadlocked
      nil
    end
  end

  it "imports files sharing movies, actors and locations at the same time without deadlocks" do
    5.times { |round| import_in_parallel(round) }

    expect(Import.group(:status).count).to eq("completed" => 20)
  end

  it "ends with every movie, actor and link exactly once" do
    import_in_parallel(0)

    expect([ Movie.count, Actor.count, MovieActor.count ]).to eq([ 100, 30, 500 ])
  end
end
