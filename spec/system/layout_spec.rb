require "rails_helper"

RSpec.describe "Layout", type: :system do
  before { visit root_path }

  it "shows the app name in the header" do
    within("header") { expect(page).to have_link("Movies on Rails", href: root_path) }
  end

  it "shows the main navigation" do
    expect(page).to have_css("nav[aria-label='Main']")
  end

  it "shows the page heading" do
    expect(page).to have_css("h1", text: "Movies")
  end

  it "shows the footer" do
    expect(page).to have_css("footer", text: "a movie review platform built with Ruby on Rails")
  end

  it "applies the brand theme" do
    navy = page.evaluate_script("getComputedStyle(document.querySelector('footer')).backgroundColor")

    expect(navy).to eq("rgb(0, 59, 77)")
  end
end
