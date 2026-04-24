require "rails_helper"

RSpec.describe Shop, type: :model do
  it "is invalid without name" do
    maker = User.create!(email: "m2@example.com", password: "password123", role: :maker)
    shop = described_class.new(maker: maker)

    expect(shop).not_to be_valid
  end

  it "enforces one shop per maker" do
    maker = User.create!(email: "maker-single-shop@example.com", password: "password123", role: :maker)
    described_class.create!(maker: maker, name: "First", description: "First shop description")

    duplicate = described_class.new(maker: maker, name: "Second", description: "Second shop description")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:maker_id]).to include("can only have one shop on Proven")
  end
end
