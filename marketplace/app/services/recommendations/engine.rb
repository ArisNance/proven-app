module Recommendations
  class Engine
    TTL = 6.hours

    def self.for_buyer(buyer_id)
      buyer = User.find(buyer_id)
      cached = RecommendationCache.fresh.find_by(buyer: buyer)
      return cached.payload if cached

      product_ids = Spree::Product.limit(24).pluck(:id)
      payload = {
        buyer_id: buyer.id,
        ranked_product_ids: product_ids,
        rationale: "metadata_similarity_and_recent_engagement"
      }

      RecommendationCache.create!(
        buyer: buyer,
        ranked_product_ids: product_ids,
        payload: payload,
        expires_at: TTL.from_now
      )

      payload
    end
  end
end
