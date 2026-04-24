module Storefront
  class Cart
    CartItem = Struct.new(
      :product_slug,
      :product,
      :quantity,
      :unit_price_cents,
      :line_total_cents,
      keyword_init: true
    )

    SESSION_KEY = "storefront_cart_items".freeze
    MAX_QUANTITY = 25

    def initialize(session:)
      @session = session
      @session[SESSION_KEY] ||= []
    end

    def add_product(product, quantity: 1)
      slug = normalize_slug(product)
      qty = normalize_quantity(quantity)
      return if slug.blank?

      entries = raw_entries
      existing = entries.find { |entry| entry["product_slug"] == slug }

      if existing
        existing["quantity"] = normalize_quantity(existing["quantity"].to_i + qty)
      else
        entries << { "product_slug" => slug, "quantity" => qty }
      end

      persist!(entries)
    end

    def update_quantity(product_slug, quantity)
      slug = product_slug.to_s
      entries = raw_entries
      entry = entries.find { |item| item["product_slug"] == slug }
      return unless entry

      qty = quantity.to_i
      if qty <= 0
        entries.reject! { |item| item["product_slug"] == slug }
      else
        entry["quantity"] = normalize_quantity(qty)
      end

      persist!(entries)
    end

    def remove(product_slug)
      slug = product_slug.to_s
      entries = raw_entries.reject { |entry| entry["product_slug"] == slug }
      persist!(entries)
    end

    def clear!
      @session[SESSION_KEY] = []
    end

    def item_count
      items.sum(&:quantity)
    end

    def subtotal_cents
      items.sum(&:line_total_cents)
    end

    def items
      raw_entries.filter_map do |entry|
        slug = entry["product_slug"].to_s
        qty = normalize_quantity(entry["quantity"])
        product = Storefront::Catalog.find(slug)
        next if product.blank?

        price_cents = product.price_cents.to_i
        CartItem.new(
          product_slug: slug,
          product: product,
          quantity: qty,
          unit_price_cents: price_cents,
          line_total_cents: price_cents * qty
        )
      end
    end

    def snapshot
      items.map do |item|
        {
          "product_slug" => item.product_slug,
          "name" => item.product.name,
          "quantity" => item.quantity,
          "unit_price_cents" => item.unit_price_cents,
          "line_total_cents" => item.line_total_cents,
          "source_shop_id" => item.product.source_shop_id.to_s,
          "source_maker_id" => item.product.source_maker_id.to_s
        }
      end
    end

    private

    def raw_entries
      Array(@session[SESSION_KEY]).map do |entry|
        normalized = entry.is_a?(Hash) ? entry.stringify_keys : {}
        {
          "product_slug" => normalized["product_slug"].to_s,
          "quantity" => normalize_quantity(normalized["quantity"])
        }
      end
    end

    def persist!(entries)
      @session[SESSION_KEY] = entries
    end

    def normalize_slug(product)
      product.slug.presence || product.id.to_s
    end

    def normalize_quantity(value)
      qty = value.to_i
      qty = 1 if qty <= 0
      qty > MAX_QUANTITY ? MAX_QUANTITY : qty
    end
  end
end
