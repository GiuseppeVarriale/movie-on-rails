require "rails_helper"

RSpec.describe Import::Dispatcher do
  let(:movies_csv) { file_fixture("movies.csv").to_s }
  let(:reviews_csv) { file_fixture("reviews.csv").to_s }

  describe ".call" do
    it "imports every file with the importer matching its headers" do
      described_class.call([ movies_csv, reviews_csv ])

      expect([ Movie.count, Review.count ]).to eq([ 2, 9 ])
    end

    it "imports movies before reviews whatever the order given" do
      results = described_class.call([ reviews_csv, movies_csv ])

      expect(results.map(&:kind)).to eq(%w[movies reviews])
    end

    it "lets the reviews find the movies imported in the same run" do
      results = described_class.call([ reviews_csv, movies_csv ])

      expect(results.last.import).to have_attributes(status: "completed", rows_failed: 0)
    end

    it "returns one result per file with its import" do
      results = described_class.call([ movies_csv ])

      expect(results.sole).to have_attributes(path: movies_csv, kind: "movies", import: Import.sole, skipped?: false)
    end
  end

  describe "a file already imported" do
    before { described_class.call([ movies_csv ]) }

    it "is skipped" do
      expect(described_class.call([ movies_csv ]).sole).to be_skipped
    end

    it "doesn't stop the other files" do
      expect { described_class.call([ movies_csv, reviews_csv ]) }.to change(Review, :count).by(9)
    end
  end

  describe "a file that can't be imported" do
    it "aborts on a missing file before importing anything" do
      expect { described_class.call([ movies_csv, "missing.csv" ]) rescue nil }.not_to change(Import, :count)
    end

    it "explains which file is missing" do
      expect { described_class.call([ "missing.csv" ]) }
        .to raise_error(described_class::FileNotFoundError, "missing.csv doesn't exist")
    end

    it "aborts on unknown headers before importing anything" do
      unknown = csv_file("Title,Rating\n")

      expect { described_class.call([ movies_csv, unknown ]) rescue nil }.not_to change(Import, :count)
    end

    it "raises the unknown format error" do
      expect { described_class.call([ csv_file("Title,Rating\n") ]) }
        .to raise_error(Import::KindDetector::UnknownFormatError)
    end
  end

  describe "IMPORTERS" do
    it "has an importer for every Import kind" do
      expect(described_class::IMPORTERS.keys).to match_array(Import.kinds.keys)
    end
  end
end
