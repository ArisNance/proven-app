module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      signature = request.env["HTTP_STRIPE_SIGNATURE"]
      event = parse_event(payload: payload, signature: signature)
      event_id = event["id"].to_s
      return render json: { error: "Missing Stripe event id" }, status: :bad_request if event_id.blank?
      return head :ok if WebhookEvent.exists?(provider: "stripe", event_id: event_id)

      WebhookEvent.create!(
        provider: "stripe",
        event_id: event_id,
        event_type: event["type"].to_s,
        payload: event
      )
      FeeReconciliationJob.perform_async(event_id)

      head :ok
    rescue JSON::ParserError, Stripe::SignatureVerificationError, Stripe::StripeError => e
      render json: { error: e.message }, status: :bad_request
    end

    private

    def parse_event(payload:, signature:)
      webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"].to_s
      return JSON.parse(payload) if webhook_secret.blank?

      Stripe::Webhook.construct_event(payload, signature, webhook_secret).to_hash
    end
  end
end
