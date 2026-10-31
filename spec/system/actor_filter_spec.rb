require "rails_helper"

RSpec.describe "Actor filter", type: :system do
  before do
    Import::MoviesImporter.call(file_fixture("movies.csv"))
    Import::ReviewsImporter.call(file_fixture("reviews.csv"))
    visit root_path
  end

  def titles
    page.all("article h2").map(&:text)
  end

  it "suggests actors below the field from 3 letters" do
    fill_in "Filter by actor", with: "leo"

    within("[data-autocomplete-target='results']") { expect(page).to have_css("li[role='option']", text: /Leonardo Di Caprio\s+2 movies/) }
  end

  it "suggests nothing for 2 letters" do
    fill_in "Filter by actor", with: "le"

    expect(page).to have_css("[data-autocomplete-target='results']", visible: :hidden)
  end

  it "filters the list when an actor is picked" do
    fill_in "Filter by actor", with: "cage"
    find("li[role='option']", text: "Nicolas Cage").click

    expect(page).to have_text("1 movie with Nicolas Cage")
  end

  it "updates the URL with the picked actor" do
    fill_in "Filter by actor", with: "cage"
    find("li[role='option']", text: "Nicolas Cage").click

    expect(page).to have_current_path(/actor_id=#{Actor.find_by!(name: 'Nicolas Cage').id}/)
  end

  it "highlights the picked actor in the cards" do
    fill_in "Filter by actor", with: "leo"
    find("li[role='option']", text: "Leonardo Di Caprio").click

    expect(page).to have_css("article a[aria-current='true']", text: "Leonardo Di Caprio", count: 2)
  end

  it "picks a suggestion with the keyboard" do
    fill_in "Filter by actor", with: "ellen"
    find("li[role='option']", text: "Ellen Page")
    find_field("Filter by actor").send_keys(:down, :enter)

    expect(page).to have_text("1 movie with Ellen Page")
  end

  it "filters by the typed text when Enter is pressed without picking" do
    fill_in "Filter by actor", with: "ribisi"
    find("li[role='option']", text: "Giovani Ribisi")
    find_field("Filter by actor").send_keys(:escape, :enter)

    expect(page).to have_text(%(2 movies with an actor matching "ribisi"))
  end

  it "clears the filter" do
    fill_in "Filter by actor", with: "cage"
    find("li[role='option']", text: "Nicolas Cage").click
    find("[aria-live='polite']", text: "1 movie with Nicolas Cage")
    click_link "Clear actor filter"

    expect(titles).to eq([ "Gone in 60 seconds", "Inception" ])
  end

  it "filters by clicking an actor in a card" do
    within("article", text: "Inception") { click_link "Ellen Page" }

    expect(page).to have_text("1 movie with Ellen Page")
  end

  describe "several actors matching the same letters" do
    before do
      Movie.find_by!(title: "Inception").actors << [ create(:actor, name: "Someleo Name"), create(:actor, name: "Aleo Smith") ]
      visit root_path
    end

    it "suggests the actor starting with the letters first" do
      fill_in "Filter by actor", with: "leo"

      expect(page.all("li[role='option']", minimum: 3).map { |option| option.text.lines.first.strip })
        .to eq([ "Leonardo Di Caprio", "Aleo Smith", "Someleo Name" ])
    end

    it "lists only the picked actor's movies" do
      fill_in "Filter by actor", with: "leo"
      find("li[role='option']", text: "Someleo Name").click

      expect(page).to have_text("1 movie with Someleo Name")
    end
  end
end
