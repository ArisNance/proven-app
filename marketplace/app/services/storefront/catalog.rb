require "ostruct"

module Storefront
  class Catalog
    Product = Struct.new(
      :id,
      :slug,
      :name,
      :price_cents,
      :image_url,
      :maker_name,
      :category,
      :material,
      :description,
      :details,
      :variation_values,
      :source_shop_id,
      :source_maker_id,
      :created_at,
      keyword_init: true
    )

    class << self
      def all
        dynamic_products
      end

      def featured(limit: 6)
        all.first(limit)
      end

      def categories
        all.map(&:category).uniq.sort
      end

      def find(id_or_slug)
        normalized = id_or_slug.to_s
        all.find { |product| product.id == normalized || product.slug == normalized }
      end

      private

      def dynamic_products
        return [] unless defined?(Spree::Product)
        return [] unless ActiveRecord::Base.connection.data_source_exists?("spree_products")

        Spree::Product.where.not(name: [nil, ""]).order(created_at: :desc).limit(1000).map do |product|
          metadata = (product.public_metadata || {}).with_indifferent_access
          shop_id = metadata[:shop_id].presence
          maker_name = metadata[:maker_name].presence || "Proven Maker"
          category = metadata[:category].presence || "Handmade"
          material = metadata[:material].presence || "Curated materials"
          price_cents = metadata[:price_cents].to_i
          price_cents = ((product.respond_to?(:price) ? product.price.to_f : 0.0) * 100).to_i if price_cents.zero?

          Product.new(
            id: "spree-#{product.id}",
            slug: product.slug.presence || "product-#{product.id}",
            name: product.name,
            price_cents: price_cents,
            image_url: metadata[:image_url].presence,
            maker_name: maker_name,
            category: category,
            material: material,
            description: product.description.to_s.truncate(100),
            details: [product.description.to_s, shop_id.present? ? "Shop ##{shop_id}" : nil].compact.join("\n\n"),
            variation_values: extract_variation_values(product, metadata),
            source_shop_id: shop_id,
            source_maker_id: metadata[:maker_id].presence,
            created_at: product.created_at
          )
        end
      rescue StandardError
        []
      end

      def extract_variation_values(product, metadata)
        grouped = Hash.new { |hash, key| hash[key] = { label: nil, values: [] } }

        if product.respond_to?(:variants_including_master)
          product.variants_including_master.each do |variant|
            next unless variant.respond_to?(:option_values)

            variant.option_values.each do |option_value|
              type_name = option_value.option_type&.presentation.presence || option_value.option_type&.name.presence
              value_name = option_value.presentation.presence || option_value.name.presence
              next if type_name.blank? || value_name.blank?

              key = normalize_variation_key(type_name)
              grouped[key][:label] ||= type_name.to_s.strip
              grouped[key][:values] << value_name.to_s.strip
            end
          end
        end

        metadata_variations = metadata[:variations]
        if metadata_variations.is_a?(Hash)
          metadata_variations.each do |type_name, values|
            key = normalize_variation_key(type_name)
            grouped[key][:label] ||= type_name.to_s.strip.titleize
            Array(values).each do |value_name|
              next if value_name.blank?

              grouped[key][:values] << value_name.to_s.strip
            end
          end
        end

        grouped.transform_values do |data|
          {
            label: data[:label].presence || "Variation",
            values: data[:values].map(&:presence).compact.uniq.sort
          }
        end.reject { |_key, data| data[:values].blank? }
      end

      def normalize_variation_key(value)
        normalized = value.to_s.parameterize(separator: "_")
        normalized.presence || "variation"
      end
    end
  end
end
