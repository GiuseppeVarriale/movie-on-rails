require "rails_helper"

RSpec.describe "Movie list", type: :system do
  before do
    Import::MoviesImporter.call(file_fixture("movies.csv"))
    Import::ReviewsImporter.call(file_fixture("reviews.csv"))
  end

  it "lists the movies with the best rated first" do
    visit root_path

    expect(page.all("article h2").map(&:text)).to eq([ "Gone in 60 seconds", "Inception" ])
  end

  it "shows each movie's details" do
    visit root_path

    within("article", text: "Inception") do
      expect(page).to have_text("2010").and have_text("Directed by Christopher Nolan")
        .and have_text("2.75").and have_text("4 reviews").and have_text("BedfordShire, UK")
    end
  end

  it "shows the cast as chips" do
    visit root_path

    within("article", text: "Inception") do
      expect(page.all("li").map(&:text)).to eq([ "Ellen Page", "Giovani Ribisi", "Joseph Gordon Levitt", "Leonardo Di Caprio" ])
    end
  end

  it "describes the rating for screen readers" do
    visit root_path

    expect(page).to have_css("[role='img'][aria-label='Rated 3.60 out of 5']")
  end

  it "sorts by title" do
    visit root_path
    click_link "Title"

    expect(page).to have_css("a[aria-current='true']", text: "Title")
  end
end
