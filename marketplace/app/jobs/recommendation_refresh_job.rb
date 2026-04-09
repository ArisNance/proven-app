class RecommendationRefreshJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 3

  def perform(buyer_id)
    Recommendations::Engine.for_buyer(buyer_id)
  end
end
