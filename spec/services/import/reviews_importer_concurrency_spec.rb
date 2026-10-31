require "rails_helper"

RSpec.describe Import::ReviewsImporter, :without_transaction do
  self.use_transactional_tests = false

  let(:header) { "Movie,User,Stars,Review\n" }
  let!(:inception) { create(:movie, title: "Inception") }

  def import_unless_already_imported(path)
    described_class.call(path)
  rescue Import::CsvImporter::AlreadyImportedError
    nil
  end

  it "keeps exact movie ratings when different review files are imported at the same time" do
    files = Array.new(4) { |index| csv_file(header + "Inception,Reviewer #{index},#{index + 1},Text\n" * 25) }

    in_parallel(4) { |index| described_class.call(files[index], batch_size: 5) }

    expect(inception.reload).to have_attributes(ratings_count: 100, ratings_sum: (1 + 2 + 3 + 4) * 25)
  end

  it "imports the reviews of a file only once when it is imported twice at the same time" do
    create(:movie, title: "Gone in 60 seconds")

    in_parallel(2) { import_unless_already_imported(file_fixture("reviews.csv")) }

    expect([ Review.count, Import.completed.count ]).to eq([ 9, 1 ])
  end
end
