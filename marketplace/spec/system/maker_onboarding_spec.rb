require "rails_helper"

RSpec.describe "Storefront guest experience", type: :system do
  it "renders the handmade guest homepage and featured collection" do
    visit "/"

    expect(page).to have_content("EVERY ITEM. EVERY MAKER. VERIFIED.")
    expect(page).to have_content("Proven Marketplace.")
    expect(page).to have_link("Shop collection")
  end
end
