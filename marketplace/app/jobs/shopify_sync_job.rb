class ShopifySyncJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 5

  def perform(user_id)
    user = User.find(user_id)
    Rails.logger.info("Starting Shopify sync for user=#{user.id}")
  end
end
