require "rails_helper"
require "ostruct"

RSpec.describe StripeConnectService do
  describe ".create_or_fetch_account!" do
    it "persists stripe account id even when maker profile is otherwise invalid" do
      user = User.create!(email: "stripe-maker@example.com", password: "password123", role: :maker)
      maker_profile = user.build_maker_profile(
        display_name: "Maker",
        country: "United States",
        preferred_currency: "USD"
      )
      maker_profile.save!(validate: false)

      allow(Stripe::Account).to receive(:create).and_return(OpenStruct.new(id: "acct_test_123"))

      account_id = described_class.create_or_fetch_account!(maker_profile)

      expect(account_id).to eq("acct_test_123")
      expect(maker_profile.reload.stripe_account_id).to eq("acct_test_123")
    end

    it "returns existing account id without creating a new stripe account" do
      user = User.create!(email: "stripe-maker-2@example.com", password: "password123", role: :maker)
      maker_profile = user.create_maker_profile!(
        display_name: "Maker 2",
        country: "United States",
        preferred_currency: "USD",
        stripe_account_id: "acct_existing"
      )

      allow(Stripe::Account).to receive(:create)

      account_id = described_class.create_or_fetch_account!(maker_profile)

      expect(account_id).to eq("acct_existing")
      expect(Stripe::Account).not_to have_received(:create)
    end
  end
end
