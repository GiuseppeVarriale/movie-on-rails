require "rails_helper"
require "rake"

RSpec.describe "ratings rake tasks", type: :task do
  before { Rails.application.load_tasks if Rake::Task.tasks.empty? }

  describe "ratings:recalculate" do
    subject(:run_task) do
      Rake::Task["ratings:recalculate"].reenable
      Rake::Task["ratings:recalculate"].invoke
    end

    let!(:movie) { create(:movie) }

    before do
      create(:review, movie:, stars: 4)
      movie.update_columns(ratings_sum: 0, ratings_count: 0)
    end

    it "recalculates the ratings and says how many movies" do
      expect { run_task }.to output("Recalculated the ratings of 1 movie\n").to_stdout
    end

    it "fixes the counters" do
      expect { run_task }.to output.to_stdout.and change { movie.reload.average_stars }.from(nil).to(BigDecimal("4"))
    end
  end
end
