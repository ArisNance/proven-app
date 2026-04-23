require "rails_helper"

RSpec.describe ShopifyOauthService do
  describe ".normalize_shop_domain" do
    it "normalizes a short Shopify domain" do
      expect(described_class.normalize_shop_domain("example-store")).to eq("example-store.myshopify.com")
    end

    it "normalizes a full URL into a shop domain" do
      expect(described_class.normalize_shop_domain("https://example-store.myshopify.com/admin")).to eq("example-store.myshopify.com")
    end

    it "raises for blank value" do
      expect { described_class.normalize_shop_domain("  ") }.to raise_error(ShopifyOauthService::InvalidOauth)
    end
  end
end

