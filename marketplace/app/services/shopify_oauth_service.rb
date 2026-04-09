class ShopifyOauthService
  def self.authorization_url(shop_domain)
    query = {
      client_id: ENV.fetch("SHOPIFY_API_KEY"),
      scope: ENV.fetch("SHOPIFY_SCOPES"),
      redirect_uri: "#{ENV.fetch('APP_HOST')}/shopify/oauth/callback",
      state: SecureRandom.hex(16)
    }.to_query

    "https://#{shop_domain}/admin/oauth/authorize?#{query}"
  end

  def self.exchange!(params)
    # Placeholder for token exchange and shop record persistence.
    raise "Missing code" if params["code"].blank?

    true
  end
end
