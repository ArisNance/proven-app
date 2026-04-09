require "rails_helper"

RSpec.describe "Webhook endpoints", type: :request do
  it "accepts shipstation webhook" do
    post "/webhooks/shipstation", params: { event: "SHIP_NOTIFY" }
    expect(response).to have_http_status(:accepted)
  end

  it "fails stripe webhook with invalid signature" do
    post "/webhooks/stripe", params: { id: "evt_1" }
    expect(response).to have_http_status(:bad_request)
  end
end
