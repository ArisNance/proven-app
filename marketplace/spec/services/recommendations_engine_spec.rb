require "rails_helper"

RSpec.describe Recommendations::Engine do
  describe ".for_buyer" do
    it "returns ranked product ids payload" do
      buyer = User.create!(email: "buyer@example.com", password: "password123", role: :buyer)
      allow(Spree::Product).to receive_message_chain(:limit, :pluck).and_return([1, 2, 3])

      result = described_class.for_buyer(buyer.id)
      expect(result[:ranked_product_ids]).to eq([1, 2, 3])
    end
  end
end
