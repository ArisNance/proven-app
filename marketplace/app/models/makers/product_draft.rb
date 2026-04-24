require "uri"

module Makers
  class ProductDraft
    include ActiveModel::Model
    include ActiveModel::Attributes

    MAIN_PRODUCT_CATEGORIES = MakerOnboardingProfile::MAIN_PRODUCT_CATEGORIES

    attr_accessor :shop, :user, :product
    attribute :name, :string
    attribute :description, :string
    attribute :category, :string
    attribute :material, :string
    attribute :price, :string
    attribute :image_url, :string
    attribute :size_values, :string
    attribute :color_values, :string

    validates :shop, :user, :name, :description, :category, :price, presence: true
    validates :name, length: { maximum: 250 }
    validates :description, length: { maximum: 5_000 }
    validates :category, inclusion: { in: MAIN_PRODUCT_CATEGORIES }
    validate :price_is_valid
    validate :image_url_is_valid

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        self.product = create_spree_product!
      end
      true
    rescue StandardError => e
      errors.add(:base, "Could not create product draft: #{e.message}")
      false
    end

    private

    def create_spree_product!
      shipping_category = Spree::ShippingCategory.first_or_create!(name: "Default")
      tax_category = Spree::TaxCategory.first_or_create!(name: "Default")
      store = Spree::Store.default || Spree::Store.first
      price_amount = normalized_price

      spree_product = Spree::Product.new(
        name: name.to_s.strip,
        description: description.to_s.strip,
        slug: generated_slug,
        available_on: Time.current,
        shipping_category: shipping_category,
        tax_category: tax_category,
        status: "draft"
      )

      spree_product.price = price_amount if spree_product.respond_to?(:price=)
      spree_product.public_metadata = build_metadata(price_amount)
      spree_product.save!(validate: false)

      if store.present? && defined?(Spree::ProductsStore)
        Spree::ProductsStore.find_or_create_by!(product_id: spree_product.id, store_id: store.id)
      end

      ProductApproval.find_or_create_by!(product_id: spree_product.id) do |approval|
        approval.state = :pending
        approval.moderation_decision = "pending"
      end

      spree_product
    end

    def build_metadata(price_amount)
      metadata = {
        shop_id: shop.id,
        maker_id: user.id,
        maker_name: user.maker_profile&.display_name.presence || user.email,
        category: category.to_s.strip,
        material: material.to_s.strip.presence || category.to_s.strip,
        image_url: image_url.to_s.strip.presence,
        price_cents: (price_amount * 100).to_i
      }

      variation_payload = {}
      sizes = normalize_variation_values(size_values)
      colors = normalize_variation_values(color_values)
      variation_payload[:size] = sizes if sizes.any?
      variation_payload[:color] = colors if colors.any?
      metadata[:variations] = variation_payload if variation_payload.any?

      metadata.compact
    end

    def normalize_variation_values(raw_values)
      raw_values.to_s.split(",").map(&:strip).reject(&:blank?).uniq
    end

    def generated_slug
      "#{name.to_s.parameterize.presence || "maker-product"}-#{SecureRandom.hex(4)}"
    end

    def normalized_price
      BigDecimal(price.to_s).to_f
    rescue ArgumentError
      0.0
    end

    def price_is_valid
      value = normalized_price
      return if value.positive?

      errors.add(:price, "must be greater than 0")
    end

    def image_url_is_valid
      return if image_url.blank?

      uri = URI.parse(image_url.to_s)
      return if uri.is_a?(URI::HTTP) && uri.host.present?

      errors.add(:image_url, "must be a valid http(s) URL")
    rescue URI::InvalidURIError
      errors.add(:image_url, "must be a valid http(s) URL")
    end
  end
end
