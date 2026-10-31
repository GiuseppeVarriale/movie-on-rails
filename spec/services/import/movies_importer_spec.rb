require "rails_helper"

RSpec.describe Import::MoviesImporter do
  let(:header) { "Movie,Description,Year,Director,Actor,Filming location,Country\n" }

  describe ".call with the sample file" do
    subject(:import) { described_class.call(file_fixture("movies.csv")) }

    it "creates the movies, actors and locations without duplicates" do
      expect { import }
        .to change(Movie, :count).by(2)
        .and change(Actor, :count).by(5)
        .and change(FilmingLocation, :count).by(3)
    end

    it "links each movie to its cast and locations" do
      import

      expect(Movie.find_by!(title: "Inception")).to have_attributes(
        actors: match_array(Actor.where(name: [ "Leonardo Di Caprio", "Joseph Gordon Levitt", "Ellen Page", "Giovani Ribisi" ])),
        filming_locations: match_array(FilmingLocation.where(name: [ "Los Angeles", "BedfordShire" ]))
      )
    end

    it "creates every link once" do
      expect { import }
        .to change(MovieActor, :count).by(7)
        .and change(MovieFilmingLocation, :count).by(4)
    end

    it "stores the movie attributes" do
      import

      expect(Movie.find_by!(title: "Gone in 60 seconds"))
        .to have_attributes(year: 2000, director: "Dominic Sena", description: start_with("A retired master car thief"))
    end

    it "records a completed import with its counters" do
      expect(import).to have_attributes(
        kind: "movies", status: "completed", rows_processed: 14, rows_failed: 0, failures: [],
        started_at: be_present, finished_at: be_present
      )
    end

    it "records the source file and its checksum" do
      expect(import).to have_attributes(
        source_path: file_fixture("movies.csv").to_s,
        file_checksum: Digest::SHA256.file(file_fixture("movies.csv")).hexdigest
      )
    end

    it "gives the same result in tiny batches (one movie's rows across batches)" do
      described_class.call(file_fixture("movies.csv"), batch_size: 2)

      expect([ Movie.count, Actor.count, FilmingLocation.count, MovieActor.count, MovieFilmingLocation.count ])
        .to eq([ 2, 5, 3, 7, 4 ])
    end
  end

  describe "importing the same file twice" do
    before { described_class.call(file_fixture("movies.csv")) }

    it "refuses the second import" do
      expect { described_class.call(file_fixture("movies.csv")) }
        .to raise_error(described_class::AlreadyImportedError, /already been imported/)
    end

    it "changes nothing" do
      expect { described_class.call(file_fixture("movies.csv")) rescue nil }
        .to not_change(Import, :count)
        .and not_change(MovieActor, :count)
    end
  end

  describe "a file being imported right now" do
    before do
      create(:import, status: :running, file_checksum: Digest::SHA256.file(file_fixture("movies.csv")).hexdigest)
    end

    it "is refused before writing anything" do
      expect { described_class.call(file_fixture("movies.csv")) rescue nil }
        .to not_change(Movie, :count)
        .and not_change(Import, :count)
    end

    it "raises AlreadyImportedError" do
      expect { described_class.call(file_fixture("movies.csv")) }
        .to raise_error(described_class::AlreadyImportedError, /already been imported or is being imported/)
    end
  end

  describe "invalid rows" do
    let(:path) do
      csv_file(header +
        "Inception,Dreams,2010,Christopher Nolan,Leonardo Di Caprio,Los Angeles,US\n" +
        "Old Movie,Too old,1700,Someone,Some Actor,Paris,FR\n" +
        "Inception,Dreams,2010,Christopher Nolan,Ellen Page,BedfordShire,UKX\n" +
        "Gone in 60 seconds,Cars,2000,Dominic Sena,Nicolas Cage,Lone Pine,US\n")
    end

    it "skips them and imports the valid ones" do
      described_class.call(path)

      expect(Movie.pluck(:title)).to contain_exactly("Inception", "Gone in 60 seconds")
    end

    it "reports each one with its line number and errors" do
      import = described_class.call(path)

      expect(import.failures).to contain_exactly(
        { "line" => 3, "errors" => [ "Year must be greater than or equal to 1888" ] },
        { "line" => 4, "errors" => [ "Country is invalid" ] }
      )
    end

    it "counts processed and failed rows" do
      expect(described_class.call(path)).to have_attributes(status: "completed", rows_processed: 4, rows_failed: 2)
    end
  end

  describe "an existing movie" do
    let!(:inception) do
      create(:movie, title: "Inception", description: "Original description", year: 2010, director: "Christopher Nolan")
    end
    let(:path) { csv_file(header + "Inception,Another description,2011,Someone Else,Tom Hardy,Calgary,CA\n") }

    it "keeps its title, description, year and director" do
      described_class.call(path)

      expect(inception.reload).to have_attributes(
        title: "Inception", description: "Original description", year: 2010, director: "Christopher Nolan"
      )
    end

    it "links the new actor and location to it" do
      described_class.call(path)

      expect(inception.reload).to have_attributes(
        actors: [ Actor.find_by!(name: "Tom Hardy") ],
        filming_locations: [ FilmingLocation.find_by!(name: "Calgary", country: "CA") ]
      )
    end
  end

  describe "existing actors and locations in a different case or spacing" do
    let!(:leo) { create(:actor, name: "Leonardo Di Caprio") }
    let!(:los_angeles) { create(:filming_location, name: "Los Angeles", country: "US") }
    let(:path) { csv_file(header + "Inception,Dreams,2010,Christopher Nolan,  LEONARDO di caprio ,los angeles,us\n") }

    it "reuses them instead of creating duplicates" do
      expect { described_class.call(path) }
        .to not_change(Actor, :count)
        .and not_change(FilmingLocation, :count)
    end

    it "links them to the movie" do
      described_class.call(path)

      expect(Movie.find_by!(title: "Inception")).to have_attributes(actors: [ leo ], filming_locations: [ los_angeles ])
    end
  end

  describe "an unexpected error" do
    before { allow(MovieActor).to receive(:insert_all).and_raise(ActiveRecord::StatementInvalid, "boom") }

    it "re-raises it" do
      expect { described_class.call(file_fixture("movies.csv")) }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it "marks the import as failed and rolls back the batch" do
      described_class.call(file_fixture("movies.csv")) rescue nil

      expect([ Import.sole.status, Movie.count ]).to eq([ "failed", 0 ])
    end
  end
end
