require "digest"

class ShippingSyncJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 5

  def perform(payload)
    normalized_payload = payload.is_a?(Hash) ? payload : {}
    event_id = build_event_id(normalized_payload)

    return if WebhookEvent.exists?(provider: "shipstation", event_id: event_id)

    event = create_event!(event_id: event_id, payload: normalized_payload)
    return unless event

    result = Shipstation::SyncService.new(normalized_payload).perform
    event.update!(
      payload: event.payload.merge("processing_result" => result),
      processed_at: Time.current,
      processing_error: nil
    )
  rescue StandardError => e
    event&.update!(processing_error: e.message, processed_at: nil)
    raise
  end

  private

  def create_event!(event_id:, payload:)
    WebhookEvent.create!(
      provider: "shipstation",
      event_id: event_id,
      event_type: payload["action"].to_s,
      payload: payload
    )
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def build_event_id(payload)
    stable_input = [
      payload["resource_url"],
      payload["resource_type"],
      payload["action"],
      payload["occurred_at"],
      payload.to_json
    ].compact.join("|")

    Digest::SHA256.hexdigest(stable_input)
  end
end
