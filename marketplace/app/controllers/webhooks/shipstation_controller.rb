module Webhooks
  class ShipstationController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      provided = request.headers["X-Shipstation-Secret"]
      expected = ENV["SHIPSTATION_WEBHOOK_SECRET"]
      if expected.present?
        provided_value = provided.to_s
        valid = provided_value.bytesize == expected.bytesize &&
          ActiveSupport::SecurityUtils.secure_compare(provided_value, expected)
        return head :unauthorized unless valid
      end

      payload = params.to_unsafe_h.except(:controller, :action).to_h.deep_stringify_keys
      ShippingSyncJob.perform_async(payload)
      head :accepted
    end
  end
end
