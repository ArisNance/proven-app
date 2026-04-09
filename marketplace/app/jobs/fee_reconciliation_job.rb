class FeeReconciliationJob
  include Sidekiq::Job
  sidekiq_options queue: :critical, retry: 10

  def perform(event_id)
    event = WebhookEvent.find_by(event_id: event_id, provider: "stripe")
    return unless event

    Rails.logger.info("Reconciling Stripe event #{event.event_id}")
  end
end
