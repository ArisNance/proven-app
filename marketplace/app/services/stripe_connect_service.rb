class StripeConnectService
  LISTING_FEE_PRODUCT_NAME = "Proven Listing Fee".freeze

  def self.create_or_fetch_account!(maker_profile)
    return maker_profile.stripe_account_id if maker_profile.stripe_account_id.present?

    account = Stripe::Account.create(
      {
        type: "express",
        email: maker_profile.user.email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true }
        },
        business_type: "individual"
      }
    )

    maker_profile.update!(stripe_account_id: account.id)
    account.id
  end

  def self.onboarding_link(account_id)
    app_host = ENV.fetch("APP_HOST", "http://localhost:3000")

    Stripe::AccountLink.create(
      account: account_id,
      refresh_url: "#{app_host}/makers/onboarding",
      return_url: "#{app_host}/makers/shops",
      type: "account_onboarding"
    ).url
  end

  def self.ensure_customer_for_shop!(shop)
    return shop.stripe_customer_id if shop.stripe_customer_id.present?

    customer = Stripe::Customer.create(
      {
        email: shop.maker.email,
        name: shop.name,
        metadata: {
          maker_id: shop.maker_id,
          shop_id: shop.id
        }
      }
    )

    shop.update!(stripe_customer_id: customer.id)
    customer.id
  end

  def self.listing_fee_price_id!(currency: "usd", unit_amount_cents: Billing::ListingFees::LISTING_FEE_CENTS)
    normalized_currency = currency.to_s.downcase
    lookup_key = "proven_listing_fee_#{normalized_currency}_#{unit_amount_cents}"

    existing_price = Stripe::Price.list(lookup_keys: [lookup_key], limit: 1).data.first
    return existing_price.id if existing_price.present?

    product = Stripe::Product.create(
      {
        name: LISTING_FEE_PRODUCT_NAME,
        metadata: { kind: "listing_fee" }
      }
    )

    Stripe::Price.create(
      {
        product: product.id,
        currency: normalized_currency,
        unit_amount: unit_amount_cents,
        recurring: { interval: "month" },
        lookup_key: lookup_key,
        transfer_lookup_key: true,
        metadata: { kind: "listing_fee" }
      }
    ).id
  end
end
