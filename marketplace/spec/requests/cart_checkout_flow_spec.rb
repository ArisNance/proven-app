require "rails_helper"
require "ostruct"

RSpec.describe "Cart and custom checkout flow", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  let(:product) do
    OpenStruct.new(
      id: "spree-33",
      slug: "woven-basket",
      name: "Woven Basket",
      description: "Handmade woven basket",
      price_cents: 4_800,
      image_url: nil,
      maker_name: "Maker Studio",
      source_shop_id: nil,
      source_maker_id: nil
    )
  end

  before do
    allow(Storefront::Catalog).to receive(:find) do |id_or_slug|
      [product.slug, product.id.to_s].include?(id_or_slug.to_s) ? product : nil
    end
  end

  it "adds to bag and renders storefront cart" do
    post "/checkout/#{product.slug}", params: { quantity: 2, checkout_action: "add_to_bag" }
    expect(response).to redirect_to(storefront_cart_path)

    get storefront_cart_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Woven Basket")
  end

  it "routes buy now to branded checkout form" do
    post "/checkout/#{product.slug}", params: { quantity: 1, checkout_action: "buy_now" }
    expect(response).to redirect_to(checkout_path)

    get checkout_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Shipping Address")
  end

  it "submits checkout form and creates checkout order" do
    allow(ShipstationOrderPushJob).to receive(:perform_async)

    post "/checkout/#{product.slug}", params: { quantity: 1, checkout_action: "buy_now" }
    expect(response).to redirect_to(checkout_path)

    post checkout_place_order_path, params: {
      checkout_form: {
        email: "buyer@example.com",
        first_name: "Ada",
        last_name: "Lovelace",
        phone: "5551234567",
        address1: "123 Market St",
        address2: "Unit 4",
        city: "San Francisco",
        state: "CA",
        postal_code: "94105",
        country: "US",
        shipping_notes: "Leave with front desk"
      }
    }

    order = CheckoutOrder.order(:created_at).last
    expect(order).to be_present
    expect(order.total_cents).to eq(4_800)
    expect(response).to redirect_to(checkout_success_path(reference: order.reference_code))
    expect(ShipstationOrderPushJob).to have_received(:perform_async).with(order.id)
  end
end
