module Webhooks
  class ShipstationController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      provided = request.headers["X-Shipstation-Secret"]
      expected = ENV["SHIPSTATION_WEBHOOK_SECRET"]
      return head :unauthorized if expected.present? && !ActiveSupport::SecurityUtils.secure_compare(provided.to_s, expected)

      ShippingSyncJob.perform_async(params.to_unsafe_h)
      head :accepted
    end
  end
end
