require "rails_helper"

RSpec.describe Import::ConsoleReport do
  def result_for(import, path: "movies.csv", kind: "movies")
    Import::Dispatcher::Result.new(path:, kind:, import:)
  end

  describe ".for_results" do
    it "summarizes a completed import" do
      import = create(:import, :completed, source_path: "movies.csv", rows_processed: 14)

      expect(described_class.for_results([ result_for(import) ]))
        .to eq([ "movies movies.csv: completed, 14 rows, 0 failed" ])
    end

    it "lists failures with their line numbers" do
      failures = [ { "line" => 3, "errors" => [ "Year must be greater than or equal to 1888", "Title can't be blank" ] } ]
      import = create(:import, :completed, source_path: "movies.csv", rows_processed: 2, rows_failed: 1, failures:)

      expect(described_class.for_results([ result_for(import) ]).last)
        .to eq("  line 3: Year must be greater than or equal to 1888 and Title can't be blank")
    end

    it "shows the first failures and counts the rest" do
      failures = (2..8).map { |line| { "line" => line, "errors" => [ "Stars is not a number" ] } }
      import = create(:import, :completed, source_path: "reviews.csv", rows_processed: 7, rows_failed: 7, failures:)

      expect(described_class.for_results([ result_for(import) ]).last(2))
        .to eq([ "  line 6: Stars is not a number", "  ... and 2 more failed rows" ])
    end

    it "reports a skipped file" do
      expect(described_class.for_results([ result_for(nil, path: "reviews.csv", kind: "reviews") ]))
        .to eq([ "reviews reviews.csv: skipped (already imported or being imported)" ])
    end
  end

  describe ".for_imports" do
    it "lists each import with its id and date" do
      import = travel_to(Time.zone.local(2026, 10, 31, 15, 33)) { create(:import, :completed, source_path: "movies.csv") }

      expect(described_class.for_imports([ import ]))
        .to eq([ "##{import.id} 31 Oct 15:33 movies movies.csv: completed, 0 rows, 0 failed" ])
    end

    it "says when there are no imports" do
      expect(described_class.for_imports([])).to eq([ "No imports yet" ])
    end
  end
end
