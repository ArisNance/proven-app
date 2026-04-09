require "rails_helper"

RSpec.describe Shop, type: :model do
  it "is invalid without name" do
    maker = User.create!(email: "m2@example.com", password: "password123", role: :maker)
    shop = described_class.new(maker: maker)

    expect(shop).not_to be_valid
  end
end
