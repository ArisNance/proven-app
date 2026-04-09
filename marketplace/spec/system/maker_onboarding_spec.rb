require "rails_helper"

RSpec.describe "Storefront guest experience", type: :system do
  it "renders the handmade guest homepage and featured collection" do
    visit "/"

    expect(page).to have_content("Handmade Retailer")
    expect(page).to have_content("Handmade Selections")
    expect(page).to have_link("Shop handmade")
  end
end
