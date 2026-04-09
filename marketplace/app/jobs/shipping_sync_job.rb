class ShippingSyncJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 5

  def perform(payload)
    Rails.logger.info("ShipStation payload received: #{payload.to_json}")
  end
end
