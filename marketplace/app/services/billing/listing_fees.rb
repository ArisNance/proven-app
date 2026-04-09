module Billing
  class ListingFees
    LISTING_FEE_CENTS = 15

    def self.sync!(shop_id)
      shop = Shop.find(shop_id)
      return if ENV["STRIPE_SECRET_KEY"].blank?

      customer_id = StripeConnectService.ensure_customer_for_shop!(shop)
      quantity = active_listing_count(shop)
      currency = shop.maker.maker_profile&.preferred_currency.to_s.downcase.presence || "usd"
      price_id = StripeConnectService.listing_fee_price_id!(currency: currency, unit_amount_cents: LISTING_FEE_CENTS)

      subscription_record = ListingFeeSubscription.find_or_initialize_by(shop: shop)

      if updatable_subscription?(subscription_record)
        updated_subscription = update_existing_subscription!(subscription_record.stripe_subscription_id, quantity)

        unless updated_subscription
          stripe_subscription_id = create_subscription!(customer_id: customer_id, price_id: price_id, quantity: quantity)
          subscription_record.stripe_subscription_id = stripe_subscription_id
        end
      else
        stripe_subscription_id = create_subscription!(customer_id: customer_id, price_id: price_id, quantity: quantity)
        subscription_record.stripe_subscription_id = stripe_subscription_id
      end

      subscription_record.status = :active
      subscription_record.quantity = quantity
      subscription_record.unit_amount_cents = LISTING_FEE_CENTS
      subscription_record.save!
      subscription_record
    end

    def self.active_listing_count(shop)
      return 1 unless shop.respond_to?(:products)

      count = shop.products.respond_to?(:active) ? shop.products.active.count : shop.products.count
      count.positive? ? count : 1
    end

    def self.updatable_subscription?(record)
      record.persisted? && record.stripe_subscription_id.present? && !record.stripe_subscription_id.start_with?("pending_create_")
    end

    def self.update_existing_subscription!(subscription_id, quantity)
      stripe_subscription = Stripe::Subscription.retrieve(subscription_id)
      subscription_item = stripe_subscription.items.data.first

      Stripe::Subscription.update(
        subscription_id,
        {
          items: [{ id: subscription_item.id, quantity: quantity }],
          proration_behavior: "create_prorations"
        }
      )
    rescue Stripe::InvalidRequestError
      nil
    end

    def self.create_subscription!(customer_id:, price_id:, quantity:)
      Stripe::Subscription.create(
        {
          customer: customer_id,
          items: [{ price: price_id, quantity: quantity }],
          collection_method: "charge_automatically",
          metadata: { billing_type: "listing_fee" }
        }
      ).id
    end
  end
end
