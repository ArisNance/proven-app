module Shipstation
  class SyncService
    def initialize(payload)
      @payload = payload.is_a?(Hash) ? payload : {}
    end

    def perform
      external_payload = fetch_external_resource
      result = {
        action: @payload["action"],
        resource_type: @payload["resource_type"],
        order_number: extract_order_number(external_payload),
        tracking_number: extract_tracking_number(external_payload)
      }

      shipment_update = update_spree_shipment_tracking(
        order_number: result[:order_number],
        tracking_number: result[:tracking_number]
      )
      result.merge(shipment_update)
    end

    private

    def fetch_external_resource
      resource_url = @payload["resource_url"].to_s
      return @payload if resource_url.blank?
      return @payload if ENV["SHIPSTATION_API_KEY"].blank? || ENV["SHIPSTATION_API_SECRET"].blank?

      response = Shipstation::Client.new.get(resource_url)
      response.is_a?(Hash) ? response : @payload
    rescue StandardError => e
      Rails.logger.warn("ShipStation resource fetch failed: #{e.message}")
      @payload
    end

    def extract_order_number(resource)
      resource["orderNumber"].presence ||
        resource["order_number"].presence ||
        @payload["orderNumber"].presence ||
        @payload["order_number"].presence
    end

    def extract_tracking_number(resource)
      resource["trackingNumber"].presence ||
        resource["tracking_number"].presence ||
        @payload["trackingNumber"].presence ||
        @payload["tracking_number"].presence
    end

    def update_spree_shipment_tracking(order_number:, tracking_number:)
      return { shipment_updated: false, reason: "missing_order_or_tracking" } if order_number.blank? || tracking_number.blank?

      order = Spree::Order.find_by(number: order_number)
      return { shipment_updated: false, reason: "order_not_found" } if order.blank?

      shipment = order.shipments.order(created_at: :desc).first
      return { shipment_updated: false, reason: "shipment_not_found", order_id: order.id } if shipment.blank?

      shipment.update!(tracking: tracking_number)
      { shipment_updated: true, order_id: order.id, shipment_id: shipment.id }
    rescue StandardError => e
      { shipment_updated: false, reason: e.message }
    end
  end
end

