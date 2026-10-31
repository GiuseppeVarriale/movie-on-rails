require "rails_helper"
require "rake"

RSpec.describe "import rake tasks", type: :task do
  before { Rails.application.load_tasks if Rake::Task.tasks.empty? }

  def run_task(name, files: nil)
    Rake::Task[name].reenable
    original = ENV["FILES"]
    ENV["FILES"] = files
    Rake::Task[name].invoke
  ensure
    ENV["FILES"] = original
  end

  describe "import:csv" do
    let(:files) { "#{file_fixture('reviews.csv')} #{file_fixture('movies.csv')}" }

    it "imports the files given in FILES" do
      expect { run_task("import:csv", files:) }.to output(/movies .*completed, 14 rows.*\n.*reviews .*completed, 9 rows/).to_stdout
    end

    it "creates the records" do
      expect { run_task("import:csv", files:) }
        .to output.to_stdout
        .and change(Movie, :count).by(2)
        .and change(Review, :count).by(9)
    end

    it "prints the usage without FILES" do
      expect { run_task("import:csv") }
        .to raise_error(SystemExit)
        .and output(/Usage: bin\/rails import:csv FILES=/).to_stderr
    end

    it "aborts with the error of an unrecognized file" do
      expect { run_task("import:csv", files: csv_file("Title,Rating\n")) }
        .to raise_error(SystemExit)
        .and output(/unrecognized headers/).to_stderr
    end
  end

  describe "import:status" do
    it "lists the latest imports" do
      create(:import, :completed, source_path: "movies.csv")

      expect { run_task("import:status") }.to output(/movies movies.csv: completed/).to_stdout
    end
  end
end
