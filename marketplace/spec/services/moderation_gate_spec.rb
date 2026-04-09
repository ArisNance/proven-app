require "rails_helper"

RSpec.describe Moderation::Gate do
  describe ".evaluate" do
    it "returns the contract keys" do
      product = instance_double(Spree::Product, id: 1, name: "Sample", description: "Desc")
      allow(Spree::Product).to receive(:find).with(1).and_return(product)

      result = described_class.evaluate(1)

      expect(result).to include(:listing_id, :duplicate_score, :policy_flags, :decision)
      expect(%w[allow review block]).to include(result[:decision])
    end
  end
end
