require "rails_helper"
require "ostruct"

RSpec.describe Billing::ListingFees do
  describe ".sync!" do
    let(:maker) { User.create!(email: "maker@example.com", password: "password123", role: :maker) }
    let!(:maker_profile) { MakerProfile.create!(user: maker, display_name: "M", country: "US", preferred_currency: "USD") }
    let(:shop) { Shop.create!(maker: maker, name: "Shop", description: "Handmade goods", state: :pending) }

    it "returns when stripe is not configured" do
      ClimateControl.modify STRIPE_SECRET_KEY: nil do
        expect(described_class.sync!(shop.id)).to be_nil
      end
    end

    it "creates a listing fee subscription when none exists" do
      allow(StripeConnectService).to receive(:ensure_customer_for_shop!).and_return("cus_123")
      allow(StripeConnectService).to receive(:listing_fee_price_id!).and_return("price_123")
      allow(Stripe::Subscription).to receive(:create).and_return(OpenStruct.new(id: "sub_123"))

      ClimateControl.modify STRIPE_SECRET_KEY: "sk_test_123" do
        subscription = described_class.sync!(shop.id)

        expect(subscription.stripe_subscription_id).to eq("sub_123")
        expect(subscription.quantity).to eq(1)
        expect(subscription.unit_amount_cents).to eq(15)
      end
    end

    it "updates an existing stripe subscription" do
      subscription = ListingFeeSubscription.create!(
        shop: shop,
        stripe_subscription_id: "sub_existing",
        status: :active,
        quantity: 1,
        unit_amount_cents: 15
      )

      stripe_item = OpenStruct.new(id: "si_123")
      stripe_subscription = OpenStruct.new(items: OpenStruct.new(data: [stripe_item]))

      allow(StripeConnectService).to receive(:ensure_customer_for_shop!).and_return("cus_123")
      allow(StripeConnectService).to receive(:listing_fee_price_id!).and_return("price_123")
      allow(Stripe::Subscription).to receive(:retrieve).with("sub_existing").and_return(stripe_subscription)
      allow(Stripe::Subscription).to receive(:update).and_return(true)

      ClimateControl.modify STRIPE_SECRET_KEY: "sk_test_123" do
        result = described_class.sync!(shop.id)

        expect(result.id).to eq(subscription.id)
        expect(Stripe::Subscription).to have_received(:update).with(
          "sub_existing",
          hash_including(items: [hash_including(id: "si_123")])
        )
      end
    end
  end
end
