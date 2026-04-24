class ProductsController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @category = params[:category].to_s.strip
    @sort = params[:sort].to_s.presence_in(%w[featured newest price_asc price_desc]) || "featured"
    @variation_filters = normalized_variation_filters
    @size_filters = normalized_array_param(:size)
    @price_filters = normalized_array_param(:price)

    all_products = Storefront::Catalog.all
    scoped_products = all_products
    scoped_products = scoped_products.select { |product| product.category == @category } if @category.present?

    if @query.present?
      q = @query.downcase
      scoped_products = scoped_products.select do |product|
        [product.name, product.maker_name, product.material, product.description].compact.join(" ").downcase.include?(q)
      end
    end

    groups = variation_groups_for(scoped_products)
    @size_group = groups.find { |group| group[:key] == "size" } || { key: "size", label: "Size", values: [] }
    @variation_groups = groups.reject { |group| group[:key] == "size" }
    @price_groups = price_groups_for(scoped_products)

    @products = scoped_products.select do |product|
      product_matches_variation_filters?(product, @variation_filters) &&
        product_matches_size_filters?(product, @size_filters) &&
        product_matches_price_filters?(product, @price_filters)
    end
    @products = sort_products(@products, @sort)

    @categories = all_products.map(&:category).uniq.sort
    @category_counts = all_products.group_by(&:category).transform_values(&:count)
    @products_total = all_products.count
  end

  def show
    @product = Storefront::Catalog.find(params[:id])
    if @product.present?
      @related_products = Storefront::Catalog.all.select { |item| item.category == @product.category && item.slug != @product.slug }.first(4)
      @maker_shop = Shop.find_by(id: @product.source_shop_id)
      @maker_profile = @maker_shop&.maker&.maker_profile
      @maker_onboarding_profile = @maker_shop&.maker&.maker_onboarding_profile
      @favorite_count = ProductFavorite.where(product_slug: @product.slug).count
      @shop_favorite_count = @maker_shop.present? ? @maker_shop.shop_favorites.count : 0
      if user_signed_in?
        @favorited_product = current_user.product_favorites.exists?(product_slug: @product.slug)
        @favorited_shop = @maker_shop.present? && current_user.shop_favorites.exists?(shop_id: @maker_shop.id)
      end
      return
    end

    redirect_to products_path, alert: "Product not found."
  end

  private

  def normalized_variation_filters
    raw = params[:variation]
    return {} unless raw.respond_to?(:to_h) || raw.respond_to?(:to_unsafe_h)

    source = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h

    source.each_with_object({}) do |(key, values), normalized|
      selected_values = Array(values).map(&:to_s).map(&:strip).reject(&:blank?)
      normalized[key.to_s] = selected_values if selected_values.any?
    end
  end

  def normalized_array_param(key)
    Array(params[key]).map(&:to_s).map(&:strip).reject(&:blank?)
  end

  def variation_groups_for(products)
    groups = Hash.new { |hash, key| hash[key] = { label: key.to_s.humanize, counts: Hash.new(0) } }

    products.each do |product|
      next unless product.respond_to?(:variation_values) && product.variation_values.is_a?(Hash)

      product.variation_values.each do |key, data|
        values = Array(data[:values]).map(&:to_s).map(&:strip).reject(&:blank?)
        next if values.empty?

        label = data[:label].to_s.strip.presence || key.to_s.humanize
        groups[key][:label] = label
        values.each { |value| groups[key][:counts][value] += 1 }
      end
    end

    groups.map do |key, data|
      {
        key: key,
        label: data[:label],
        values: data[:counts].sort_by { |value, count| [-count, value] }.map { |value, count| { value: value, count: count } }
      }
    end.sort_by { |group| group[:label] }
  end

  def price_groups_for(products)
    price_ranges.map do |range|
      count = products.count { |product| price_in_range?(product.price_cents.to_i, range) }
      range.merge(count: count)
    end
  end

  def product_matches_variation_filters?(product, variation_filters)
    return true if variation_filters.blank?
    return false unless product.respond_to?(:variation_values) && product.variation_values.is_a?(Hash)

    variation_filters.all? do |key, selected_values|
      product_values = Array(product.variation_values.dig(key, :values)).map(&:to_s).map(&:downcase)
      selected_values.map(&:downcase).any? { |selected| product_values.include?(selected) }
    end
  end

  def product_matches_size_filters?(product, size_filters)
    return true if size_filters.blank?
    return false unless product.respond_to?(:variation_values) && product.variation_values.is_a?(Hash)

    product_sizes = Array(product.variation_values.dig("size", :values)).map(&:to_s).map(&:downcase)
    return false if product_sizes.blank?

    size_filters.map(&:downcase).any? { |selected| product_sizes.include?(selected) }
  end

  def product_matches_price_filters?(product, price_filters)
    return true if price_filters.blank?

    price_cents = product.price_cents.to_i
    selected_ranges = price_ranges.index_by { |group| group[:key] }
    price_filters.any? do |key|
      range = selected_ranges[key.to_s]
      range.present? && price_in_range?(price_cents, range)
    end
  end

  def price_ranges
    @price_ranges ||= [
      { key: "under_25", label: "Under $25", min_cents: 0, max_cents: 2_499 },
      { key: "25_75", label: "$25 to $75", min_cents: 2_500, max_cents: 7_500 },
      { key: "75_150", label: "$75 to $150", min_cents: 7_501, max_cents: 15_000 },
      { key: "150_plus", label: "$150+", min_cents: 15_001, max_cents: nil }
    ]
  end

  def price_in_range?(price_cents, range)
    min_ok = price_cents >= range[:min_cents].to_i
    max_ok = range[:max_cents].nil? || price_cents <= range[:max_cents].to_i
    min_ok && max_ok
  end

  def sort_products(products, sort)
    case sort
    when "newest"
      products.sort_by { |product| product.respond_to?(:created_at) && product.created_at.present? ? -product.created_at.to_i : 0 }
    when "price_asc"
      products.sort_by { |product| product.price_cents.to_i }
    when "price_desc"
      products.sort_by { |product| -product.price_cents.to_i }
    else
      products
    end
  end
end
