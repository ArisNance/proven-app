module Shipstation
  class OrderPayloadBuilder
    def initialize(checkout_order)
      @checkout_order = checkout_order
    end

    def build
      {
        orderNumber: @checkout_order.reference_code,
        orderDate: (@checkout_order.submitted_at || @checkout_order.created_at || Time.current).utc.iso8601,
        orderStatus: "awaiting_shipment",
        customerEmail: @checkout_order.email,
        customerUsername: @checkout_order.email,
        billTo: address_payload,
        shipTo: address_payload,
        amountPaid: cents_to_decimal(@checkout_order.total_cents),
        taxAmount: 0,
        shippingAmount: 0,
        internalNotes: @checkout_order.shipping_notes.to_s,
        items: item_payloads
      }
    end

    private

    def address_payload
      {
        name: [@checkout_order.first_name, @checkout_order.last_name].join(" ").squish,
        company: "",
        street1: @checkout_order.address1,
        street2: @checkout_order.address2.to_s,
        city: @checkout_order.city,
        state: @checkout_order.state,
        postalCode: @checkout_order.postal_code,
        country: @checkout_order.country,
        phone: @checkout_order.phone.to_s
      }
    end

    def item_payloads
      Array(@checkout_order.cart_snapshot).map.with_index do |item, index|
        {
          lineItemKey: "line-#{index + 1}",
          sku: item["product_slug"].to_s,
          name: item["name"].to_s,
          quantity: item["quantity"].to_i,
          unitPrice: cents_to_decimal(item["unit_price_cents"].to_i)
        }
      end
    end

    def cents_to_decimal(cents)
      (cents.to_i / 100.0).round(2)
    end
  end
end
