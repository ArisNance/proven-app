module Payments
  class CheckoutService
    class ConfigurationError < StandardError; end

    APPLICATION_FEE_BPS = 1_000

    class << self
      def create_product_checkout!(product:, quantity:, buyer_email: nil)
        raise ConfigurationError, "Stripe is not configured" if ENV["STRIPE_SECRET_KEY"].blank?

        qty = quantity.to_i
        qty = 1 if qty <= 0
        qty = 25 if qty > 25

        amount_cents = product.price_cents.to_i
        raise ConfigurationError, "Product must have a positive price" if amount_cents <= 0

        line_item = {
          quantity: qty,
          price_data: {
            currency: currency_for(product),
            unit_amount: amount_cents,
            product_data: {
              name: product.name.to_s,
              description: product.description.to_s.truncate(180)
            }
          }
        }

        session_params = {
          mode: "payment",
          line_items: [line_item],
          success_url: success_url,
          cancel_url: cancel_url(product),
          customer_email: buyer_email,
          metadata: checkout_metadata(product, qty),
          allow_promotion_codes: true
        }.compact

        payment_intent_data = build_connect_payment_intent_data(product, amount_cents, qty)
        session_params[:payment_intent_data] = payment_intent_data if payment_intent_data.present?

        Stripe::Checkout::Session.create(session_params)
      end

      private

      def currency_for(product)
        preferred_currency = Shop.find_by(id: product.source_shop_id)&.maker&.maker_profile&.preferred_currency
        preferred_currency.to_s.downcase.presence || "usd"
      end

      def success_url
        "#{app_host}/checkout/success?session_id={CHECKOUT_SESSION_ID}"
      end

      def cancel_url(product)
        slug_or_id = product.slug.presence || product.id
        "#{app_host}/products/#{slug_or_id}?checkout=canceled"
      end

      def app_host
        ENV.fetch("APP_HOST", "http://localhost:3000")
      end

      def checkout_metadata(product, quantity)
        {
          source: "proven_marketplace",
          product_id: product.id.to_s,
          product_slug: product.slug.to_s,
          shop_id: product.source_shop_id.to_s,
          maker_id: product.source_maker_id.to_s,
          quantity: quantity.to_s
        }
      end

      def build_connect_payment_intent_data(product, amount_cents, quantity)
        shop = Shop.find_by(id: product.source_shop_id)
        account_id = shop&.maker&.maker_profile&.stripe_account_id
        return {} if account_id.blank?

        total_cents = amount_cents * quantity
        fee_cents = ((total_cents * application_fee_bps) / 10_000.0).round

        {
          transfer_data: {
            destination: account_id
          },
          application_fee_amount: fee_cents
        }
      end

      def application_fee_bps
        configured = ENV.fetch("STRIPE_APPLICATION_FEE_BPS", APPLICATION_FEE_BPS).to_i
        configured.positive? ? configured : APPLICATION_FEE_BPS
      end
    end
  end
end

