require "rails_helper"

RSpec.describe ImportFilesJob, type: :job do
  let(:paths) { [ file_fixture("reviews.csv").to_s, file_fixture("movies.csv").to_s ] }

  describe ".perform_later" do
    it "enqueues the job on the imports queue with the paths" do
      expect { described_class.perform_later(paths) }
        .to have_enqueued_job(described_class).with(paths).on_queue("imports")
    end
  end

  describe "#perform" do
    it "imports every file, movies before reviews" do
      expect { perform_enqueued_jobs { described_class.perform_later(paths) } }
        .to change(Movie, :count).by(2)
        .and change(Review, :count).by(9)
    end

    it "logs the import report" do
      allow(Rails.logger).to receive(:info).and_call_original

      described_class.perform_now(paths)

      expect(Rails.logger).to have_received(:info).with(/reviews .*reviews\.csv: completed, 9 rows, 0 failed/)
    end
  end

  describe "retries" do
    it "is not retried automatically, so a partly imported file is never imported twice" do
      expect(described_class.get_sidekiq_options).to include("retry" => false)
    end
  end
end
