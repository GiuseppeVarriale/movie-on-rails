require "rails_helper"

RSpec.describe Import::KindDetector do
  describe ".call" do
    context "with the sample files" do
      it "detects the movies CSV" do
        expect(described_class.call(file_fixture("movies.csv"))).to eq("movies")
      end

      it "detects the reviews CSV" do
        expect(described_class.call(file_fixture("reviews.csv"))).to eq("reviews")
      end
    end

    context "with header variations" do
      it "ignores a UTF-8 BOM" do
        path = csv_file("﻿Movie,User,Stars,Review\n")

        expect(described_class.call(path)).to eq("reviews")
      end

      it "ignores letter case and surrounding whitespace" do
        path = csv_file(" movie , USER,Stars ,  review\n")

        expect(described_class.call(path)).to eq("reviews")
      end

      it "ignores column order" do
        path = csv_file("Country,Filming location,Actor,Director,Year,Description,Movie\n")

        expect(described_class.call(path)).to eq("movies")
      end

      it "reads only the header line" do
        path = csv_file("Movie,User,Stars,Review\nnot,\"a valid\n")

        expect(described_class.call(path)).to eq("reviews")
      end
    end

    context "with an unknown format" do
      it "raises when the headers match no kind" do
        path = csv_file("Title,Rating\n")

        expect { described_class.call(path) }
          .to raise_error(described_class::UnknownFormatError, /unrecognized headers \(title, rating\)/)
      end

      it "raises when a column is missing" do
        path = csv_file("Movie,User,Stars\n")

        expect { described_class.call(path) }.to raise_error(described_class::UnknownFormatError)
      end

      it "raises when there is an extra column" do
        path = csv_file("Movie,User,Stars,Review,Date\n")

        expect { described_class.call(path) }.to raise_error(described_class::UnknownFormatError)
      end

      it "lists the expected formats in the message" do
        path = csv_file("Title\n")

        expect { described_class.call(path) }
          .to raise_error(described_class::UnknownFormatError, /Expected movies \(.+\); reviews \(movie, user, stars, review\)/)
      end

      it "raises when the header line isn't valid CSV" do
        path = csv_file("source \"https://rubygems.org\"\n")

        expect { described_class.call(path) }
          .to raise_error(described_class::UnknownFormatError, /is not a valid CSV file/)
      end

      it "raises when the file is empty" do
        path = csv_file("")

        expect { described_class.call(path) }.to raise_error(described_class::UnknownFormatError, /is empty/)
      end
    end
  end

  describe "HEADERS" do
    it "covers exactly the Import kinds" do
      expect(described_class::HEADERS.keys).to match_array(Import.kinds.keys)
    end
  end
end
