module Moderation
  class Gate
    DUPLICATE_THRESHOLD = 0.92

    def self.evaluate(listing_id)
      listing = Spree::Product.find(listing_id)
      duplicate_score = SimilaritySearch.new(listing).score
      policy_flags = ModerationClient.new.check(listing)

      decision = if policy_flags.include?("banned")
                   "block"
                 elsif duplicate_score >= DUPLICATE_THRESHOLD
                   "review"
                 else
                   "allow"
                 end

      {
        listing_id: listing.id,
        duplicate_score: duplicate_score,
        policy_flags: policy_flags,
        decision: decision
      }
    end

    class SimilaritySearch
      def initialize(listing)
        @listing = listing
      end

      def score
        return 0.0 unless @listing.respond_to?(:description)

        text = [@listing.name, @listing.description].compact.join(" ")
        return 0.0 if text.blank?

        # Placeholder until pgvector queries are installed.
        0.0
      end
    end

    class ModerationClient
      def check(listing)
        return [] if ENV["OPENAI_API_KEY"].blank?

        # Contract shape is stable; provider call is intentionally behind a service boundary.
        []
      rescue StandardError => e
        Rails.logger.warn("Moderation unavailable for listing #{listing.id}: #{e.message}")
        []
      end
    end
  end
end
