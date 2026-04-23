class FeeReconciliationJob
  include Sidekiq::Job
  sidekiq_options queue: :critical, retry: 10

  def perform(event_id)
    event = WebhookEvent.find_by(event_id: event_id, provider: "stripe")
    return unless event

    payload = event.payload.is_a?(Hash) ? event.payload : {}
    event_type = payload["type"].to_s
    object = payload.dig("data", "object") || {}

    case event_type
    when "checkout.session.completed"
      reconcile_checkout_session!(object)
    when "customer.subscription.updated"
      reconcile_subscription_updated!(object)
    when "customer.subscription.deleted"
      reconcile_subscription_deleted!(object)
    when "invoice.payment_failed"
      reconcile_invoice_payment_failed!(object)
    when "invoice.paid"
      reconcile_invoice_paid!(object)
    end

    event.update!(processed_at: Time.current, processing_error: nil)
  rescue StandardError => e
    event&.update!(processing_error: e.message, processed_at: nil)
    raise
  end

  private

  def reconcile_checkout_session!(object)
    metadata = object["metadata"] || {}
    Rails.logger.info(
      "Stripe checkout completed session=#{object['id']} shop_id=#{metadata['shop_id']} product_id=#{metadata['product_id']}"
    )
  end

  def reconcile_subscription_updated!(object)
    subscription_id = object["id"].to_s
    return if subscription_id.blank?

    subscription = ListingFeeSubscription.find_by(stripe_subscription_id: subscription_id)
    return unless subscription

    item = Array(object.dig("items", "data")).first || {}
    quantity = item["quantity"].to_i
    status = normalize_subscription_status(object["status"])

    subscription.update!(
      status: status,
      quantity: quantity.positive? ? quantity : subscription.quantity
    )
  end

  def reconcile_subscription_deleted!(object)
    subscription_id = object["id"].to_s
    return if subscription_id.blank?

    subscription = ListingFeeSubscription.find_by(stripe_subscription_id: subscription_id)
    subscription&.update!(status: :canceled)
  end

  def reconcile_invoice_payment_failed!(object)
    subscription_id = object["subscription"].to_s
    return if subscription_id.blank?

    subscription = ListingFeeSubscription.find_by(stripe_subscription_id: subscription_id)
    subscription&.update!(status: :paused)
  end

  def reconcile_invoice_paid!(object)
    subscription_id = object["subscription"].to_s
    return if subscription_id.blank?

    subscription = ListingFeeSubscription.find_by(stripe_subscription_id: subscription_id)
    subscription&.update!(status: :active)
  end

  def normalize_subscription_status(status)
    case status.to_s
    when "active", "trialing"
      :active
    when "canceled", "unpaid", "incomplete_expired"
      :canceled
    when "past_due", "incomplete"
      :paused
    else
      :paused
    end
  end
end
