if ENV["SHOPIFY_API_KEY"].present? && ENV["SHOPIFY_API_SECRET"].present?
  ShopifyAPI::Context.setup(
    api_key: ENV["SHOPIFY_API_KEY"],
    api_secret_key: ENV["SHOPIFY_API_SECRET"],
    scope: ENV.fetch("SHOPIFY_SCOPES", "read_products,write_products"),
    host_name: ENV.fetch("SHOPIFY_HOST", "localhost:3000"),
    is_embedded: false,
    api_version: "2025-10"
  )
else
  Rails.logger.warn("ShopifyAPI context not configured: missing SHOPIFY_API_KEY/SHOPIFY_API_SECRET")
end
