class ShipstationOrderPushJob
  include Sidekiq::Job
  sidekiq_options queue: :default, retry: 5

  def perform(checkout_order_id)
    order = CheckoutOrder.find_by(id: checkout_order_id)
    return if order.blank?

    payload = Shipstation::OrderPayloadBuilder.new(order).build
    order.update!(shipstation_payload: payload)

    return if ENV["SHIPSTATION_API_KEY"].blank? || ENV["SHIPSTATION_API_SECRET"].blank?

    response = Shipstation::Client.new.post("/orders/createorder", body: payload)
    response_hash = response.is_a?(Hash) ? response : {}

    order.update!(
      status: :shipstation_submitted,
      shipstation_submitted_at: Time.current,
      shipstation_order_id: response_hash["orderId"].to_s.presence,
      shipstation_order_number: response_hash["orderNumber"].to_s.presence,
      shipstation_payload: payload.merge("response" => response_hash),
      shipstation_error: nil
    )
  rescue StandardError => e
    order&.update!(status: :shipstation_failed, shipstation_error: e.message)
    raise
  end
end
