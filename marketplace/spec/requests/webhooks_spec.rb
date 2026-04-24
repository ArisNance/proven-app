require "rails_helper"

RSpec.describe "Webhook endpoints", type: :request do
  it "accepts shipstation webhook" do
    headers = {}
    webhook_secret = ENV["SHIPSTATION_WEBHOOK_SECRET"].to_s
    headers["X-Shipstation-Secret"] = webhook_secret if webhook_secret.present?

    post "/webhooks/shipstation", params: { event: "SHIP_NOTIFY" }, headers: headers
    expect(response).to have_http_status(:accepted)
  end

  it "fails stripe webhook with invalid signature" do
    post "/webhooks/stripe", params: { id: "evt_1" }
    expect(response).to have_http_status(:bad_request)
  end
end
