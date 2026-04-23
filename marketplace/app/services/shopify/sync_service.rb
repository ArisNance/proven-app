module Shopify
  class SyncService
    DEFAULT_API_VERSION = ENV.fetch("SHOPIFY_SYNC_API_VERSION", "2025-10")

    def initialize(connection)
      @connection = connection
    end

    def sync_products!
      response = HTTParty.get(
        api_url("/products.json"),
        headers: request_headers,
        query: { limit: 50, status: "active" }
      )

      unless response.success?
        mark_error!("Shopify sync failed: #{response.code} #{response.body}")
        return { imported: 0, updated: 0 }
      end

      body = response.parsed_response.is_a?(Hash) ? response.parsed_response : {}
      products = Array(body["products"])

      imported = 0
      updated = 0

      products.each do |shopify_product|
        result = upsert_spree_product(shopify_product)
        imported += 1 if result == :imported
        updated += 1 if result == :updated
      end

      @connection.update!(
        status: :active,
        last_synced_at: Time.current,
        last_sync_status: "ok",
        last_sync_error: nil
      )

      { imported: imported, updated: updated }
    rescue StandardError => e
      mark_error!(e.message)
      raise
    end

    private

    def upsert_spree_product(shopify_product)
      shipping_category = Spree::ShippingCategory.first_or_create!(name: "Default")
      tax_category = Spree::TaxCategory.first_or_create!(name: "Default")
      store = Spree::Store.default || Spree::Store.first

      shopify_id = shopify_product["id"].to_s
      metadata_query = { shopify_product_id: shopify_id, source: "shopify" }.to_json
      spree_product = Spree::Product.where("public_metadata @> ?", metadata_query).first
      status = spree_product.present? ? :updated : :imported
      spree_product ||= Spree::Product.new

      price = first_variant_price(shopify_product)
      metadata = (spree_product.public_metadata || {}).merge(
        source: "shopify",
        shopify_product_id: shopify_id,
        shopify_shop_domain: @connection.shop_domain,
        shop_id: find_shop_id_for_user,
        maker_id: @connection.user_id,
        maker_name: @connection.user.maker_profile&.display_name || @connection.user.email,
        category: product_type(shopify_product),
        material: product_type(shopify_product),
        image_url: primary_image_url(shopify_product),
        price_cents: (price * 100).to_i,
        variations: option_values(shopify_product)
      )

      spree_product.assign_attributes(
        name: shopify_product["title"].to_s.truncate(250),
        description: shopify_product["body_html"].to_s.gsub(/<[^>]*>/, " ").squish.presence || "Imported from Shopify",
        slug: spree_product.slug.presence || "shopify-#{@connection.shop_domain.parameterize}-#{shopify_id}",
        available_on: Time.current,
        shipping_category: shipping_category,
        tax_category: tax_category,
        status: spree_product.status.presence || "draft",
        public_metadata: metadata
      )
      spree_product.price = price if spree_product.respond_to?(:price=)
      spree_product.save!(validate: false)

      if store.present? && defined?(Spree::ProductsStore)
        Spree::ProductsStore.find_or_create_by!(product_id: spree_product.id, store_id: store.id)
      end

      ProductApproval.find_or_create_by!(product_id: spree_product.id) do |approval|
        approval.state = :pending
        approval.moderation_decision = "pending"
      end

      status
    end

    def find_shop_id_for_user
      @connection.user.shops.order(created_at: :asc).limit(1).pick(:id)
    end

    def product_type(shopify_product)
      shopify_product["product_type"].to_s.presence || "Imported"
    end

    def first_variant_price(shopify_product)
      variants = Array(shopify_product["variants"])
      variant_price = variants.first.to_h["price"].to_f
      variant_price.positive? ? variant_price : 1.0
    end

    def primary_image_url(shopify_product)
      image = shopify_product["image"]
      return image["src"] if image.is_a?(Hash) && image["src"].present?

      first_image = Array(shopify_product["images"]).first
      first_image.is_a?(Hash) ? first_image["src"] : nil
    end

    def option_values(shopify_product)
      options = Array(shopify_product["options"])
      options.each_with_object({}) do |option, memo|
        name = option["name"].to_s
        values = Array(option["values"]).map(&:to_s).reject(&:blank?)
        next if name.blank? || values.empty?

        key = name.parameterize(separator: "_")
        memo[key] = values
      end
    end

    def api_url(path)
      "https://#{@connection.shop_domain}/admin/api/#{DEFAULT_API_VERSION}#{path}"
    end

    def request_headers
      {
        "X-Shopify-Access-Token" => @connection.access_token,
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    end

    def mark_error!(message)
      @connection.update!(
        status: :errored,
        last_sync_status: "error",
        last_sync_error: message
      )
    end
  end
end
