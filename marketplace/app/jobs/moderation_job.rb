class ModerationJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 5

  def perform(listing_id)
    result = Moderation::Gate.evaluate(listing_id)
    ProductApproval.create!(
      product_id: listing_id,
      moderation_decision: result[:decision],
      duplicate_score: result[:duplicate_score],
      policy_flags: result[:policy_flags],
      state: :pending
    )
  end
end
