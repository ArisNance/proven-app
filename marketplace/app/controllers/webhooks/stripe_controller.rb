module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      signature = request.env["HTTP_STRIPE_SIGNATURE"]

      event = Stripe::Webhook.construct_event(payload, signature, ENV.fetch("STRIPE_WEBHOOK_SECRET"))
      return head :ok if WebhookEvent.exists?(provider: "stripe", event_id: event.id)

      WebhookEvent.create!(provider: "stripe", event_id: event.id, payload: event.to_hash)
      FeeReconciliationJob.perform_async(event.id)

      head :ok
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      render json: { error: e.message }, status: :bad_request
    end
  end
end
