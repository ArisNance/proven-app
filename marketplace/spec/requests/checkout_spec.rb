require "rails_helper"
require "ostruct"

RSpec.describe "Checkout", type: :request do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  describe "POST /checkout/:product_id" do
    let(:catalog_product) do
      OpenStruct.new(
        id: "spree-10",
        slug: "sample-product",
        name: "Sample Product",
        description: "A sample listing",
        price_cents: 2_500,
        source_shop_id: nil,
        source_maker_id: nil
      )
    end

    it "redirects to Stripe checkout session URL" do
      allow(Storefront::Catalog).to receive(:find).and_return(catalog_product)
      allow(Payments::CheckoutService).to receive(:create_product_checkout!).and_return(OpenStruct.new(url: "https://checkout.stripe.com/c/pay/cs_test_123"))

      post "/checkout/#{catalog_product.slug}", params: { quantity: 2 }

      expect(response).to redirect_to("https://checkout.stripe.com/c/pay/cs_test_123")
    end

    it "redirects back to listing when checkout setup fails" do
      allow(Storefront::Catalog).to receive(:find).and_return(catalog_product)
      allow(Payments::CheckoutService).to receive(:create_product_checkout!).and_raise(
        Payments::CheckoutService::ConfigurationError,
        "Stripe is not configured"
      )

      post "/checkout/#{catalog_product.slug}", params: { quantity: 1 }

      expect(response).to redirect_to("/products/#{catalog_product.slug}")
    end
  end
end
