require "openssl"

class ShopifyOauthService
  class InvalidOauth < StandardError; end

  def self.authorization_url(shop_domain, state:)
    normalized_shop = normalize_shop_domain(shop_domain)

    query = {
      client_id: ENV.fetch("SHOPIFY_API_KEY"),
      scope: ENV.fetch("SHOPIFY_SCOPES"),
      redirect_uri: "#{ENV.fetch('APP_HOST')}/shopify/oauth/callback",
      state: state
    }.to_query

    "https://#{normalized_shop}/admin/oauth/authorize?#{query}"
  end

  def self.exchange!(params, expected_state:, user_id:)
    validate_state!(params, expected_state)
    validate_hmac!(params)

    code = params["code"].to_s
    raise InvalidOauth, "Missing code" if code.blank?

    shop_domain = normalize_shop_domain(params["shop"])
    response = HTTParty.post(
      "https://#{shop_domain}/admin/oauth/access_token",
      headers: { "Content-Type" => "application/json" },
      body: {
        client_id: ENV.fetch("SHOPIFY_API_KEY"),
        client_secret: ENV.fetch("SHOPIFY_API_SECRET"),
        code: code
      }.to_json
    )

    body = response.parsed_response.is_a?(Hash) ? response.parsed_response : {}
    access_token = body["access_token"].to_s
    raise InvalidOauth, "Shopify token exchange failed: #{response.body}" if !response.success? || access_token.blank?

    user = User.find(user_id)
    connection = ShopifyConnection.find_or_initialize_by(shop_domain: shop_domain)
    connection.user = user
    connection.access_token = access_token
    connection.scopes = body["scope"].to_s
    connection.status = :active
    connection.installed_at ||= Time.current
    connection.last_sync_status = "connected"
    connection.last_sync_error = nil
    connection.save!

    connection
  end

  def self.normalize_shop_domain(shop_domain)
    normalized = shop_domain.to_s.strip.downcase
    normalized = normalized.delete_prefix("https://")
    normalized = normalized.delete_prefix("http://")
    normalized = normalized.split("/").first.to_s
    normalized = "#{normalized}.myshopify.com" if normalized.present? && !normalized.end_with?(".myshopify.com")
    raise InvalidOauth, "Invalid Shopify shop domain" if normalized.blank?

    normalized
  end

  def self.validate_state!(params, expected_state)
    actual_state = params["state"].to_s
    raise InvalidOauth, "Invalid OAuth state" if expected_state.blank? || actual_state.blank?
    state_match = actual_state.bytesize == expected_state.bytesize &&
      ActiveSupport::SecurityUtils.secure_compare(actual_state, expected_state)
    raise InvalidOauth, "State mismatch" unless state_match
  end

  def self.validate_hmac!(params)
    provided_hmac = params["hmac"].to_s
    raise InvalidOauth, "Missing Shopify HMAC" if provided_hmac.blank?

    serialized = params
      .except("hmac", "signature", "controller", "action")
      .sort
      .map { |key, value| "#{key}=#{value}" }
      .join("&")

    digest = OpenSSL::HMAC.hexdigest("sha256", ENV.fetch("SHOPIFY_API_SECRET"), serialized)
    valid_hmac = provided_hmac.bytesize == digest.bytesize &&
      ActiveSupport::SecurityUtils.secure_compare(provided_hmac, digest)
    raise InvalidOauth, "Invalid Shopify HMAC" unless valid_hmac
  end
end
