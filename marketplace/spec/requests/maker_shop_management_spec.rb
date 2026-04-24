require "rails_helper"

RSpec.describe "Maker shop management", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  let(:password) { "password123" }
  let(:maker) { User.create!(email: "maker-shop-management@example.com", password: password, role: :maker) }

  before do
    maker.create_maker_profile!(
      display_name: "Maker Manager",
      country: "United States",
      preferred_currency: "USD",
      bio: "Handmade goods"
    )

    post user_session_path, params: { user: { email: maker.email, password: password } }
  end

  it "prevents creating a second shop" do
    existing_shop = Shop.create!(maker: maker, name: "Primary Shop", description: "Existing shop", state: :pending)

    get new_makers_shop_path
    expect(response).to redirect_to(makers_shop_path(existing_shop))

    expect do
      post makers_shops_path, params: { shop: { name: "Duplicate Shop", description: "Should not save" } }
    end.not_to change(Shop, :count)
  end

  it "provides approved-shop product upload flow and creates draft product records" do
    shop = Shop.create!(maker: maker, name: "Approved Shop", description: "Ready to upload", state: :approved)
    ShopApproval.create!(shop: shop, state: :approved)

    get new_makers_shop_product_path(shop)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Upload a Product")

    expect do
      post makers_shop_products_path(shop), params: {
        makers_product_draft: {
          name: "Clay Mug",
          description: "Wheel-thrown mug with satin glaze.",
          category: "Ceramics",
          material: "Stoneware",
          price: "42.00",
          image_url: "https://example.com/mug.jpg",
          size_values: "8oz, 12oz",
          color_values: "Sage, Oat"
        }
      }
    end.to change(Spree::Product, :count).by(1).and change(ProductApproval, :count).by(1)

    expect(response).to redirect_to(makers_shop_products_path(shop))
  end
end
