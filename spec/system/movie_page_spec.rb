require "rails_helper"

RSpec.describe "Movie page", type: :system do
  before do
    Import::MoviesImporter.call(file_fixture("movies.csv"))
    Import::ReviewsImporter.call(file_fixture("reviews.csv"))
    visit root_path
    click_link "Inception"
  end

  it "opens from the movie list" do
    expect(page).to have_css("h1", text: "Inception").and have_text("A thief who steals corporate secrets")
  end

  it "shows the rating, the full cast and the filming locations" do
    expect(page).to have_css("[aria-label='Rated 2.75 out of 5']")
      .and have_link("Joseph Gordon Levitt").and have_text("BedfordShire (UK)")
  end

  it "lists the reviews below with their stars" do
    within("section", text: "4 reviews") do
      expect(page).to have_css("li[id^='review_']", count: 4).and have_css("[aria-label='Rated 4 out of 5']")
    end
  end

  it "filters the list by an actor from the cast" do
    click_link "Ellen Page"

    expect(page).to have_text("1 movie with Ellen Page")
  end

  it "goes back to all movies" do
    click_link "← All movies"

    expect(page).to have_css("article h2", count: 2)
  end
end
