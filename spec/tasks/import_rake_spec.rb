require "rails_helper"
require "rake"

RSpec.describe "import rake tasks", type: :task do
  before { Rails.application.load_tasks if Rake::Task.tasks.empty? }

  def run_task(name, files: nil, inline: nil)
    Rake::Task[name].reenable
    original = ENV.to_h.slice("FILES", "INLINE")
    ENV["FILES"] = files
    ENV["INLINE"] = inline
    Rake::Task[name].invoke
  ensure
    ENV["FILES"] = original["FILES"]
    ENV["INLINE"] = original["INLINE"]
  end

  describe "import:csv" do
    let(:files) { "#{file_fixture('reviews.csv')} #{file_fixture('movies.csv')}" }
    let(:absolute_paths) { [ file_fixture("reviews.csv"), file_fixture("movies.csv") ].map { |path| File.expand_path(path) } }

    context "without INLINE" do
      it "enqueues one import job with the absolute paths" do
        expect { run_task("import:csv", files:) }
          .to output(/Import queued \(job .+\)/).to_stdout
          .and have_enqueued_job(ImportFilesJob).with(absolute_paths).on_queue("imports")
      end

      it "doesn't import right away" do
        expect { run_task("import:csv", files:) }.to output.to_stdout.and not_change(Movie, :count)
      end

      it "enqueues nothing when a file can't be imported" do
        expect { run_task("import:csv", files: csv_file("Title,Rating\n")) }
          .to raise_error(SystemExit)
          .and output.to_stderr
          .and not_have_enqueued_job(ImportFilesJob)
      end
    end

    context "with INLINE=1" do
      it "imports the files right away and prints the report" do
        expect { run_task("import:csv", files:, inline: "1") }
          .to output(/movies .*completed, 14 rows.*\n.*reviews .*completed, 9 rows/).to_stdout
      end

      it "creates the records" do
        expect { run_task("import:csv", files:, inline: "1") }
          .to output.to_stdout
          .and change(Movie, :count).by(2)
          .and change(Review, :count).by(9)
      end
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
