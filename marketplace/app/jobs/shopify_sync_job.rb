class ShopifySyncJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 5

  def perform(user_id, connection_id = nil)
    user = User.find(user_id)
    scope = user.shopify_connections.where(status: %i[active errored])
    scope = scope.where(id: connection_id) if connection_id.present?

    scope.find_each do |connection|
      Shopify::SyncService.new(connection).sync_products!
    end
  end
end
