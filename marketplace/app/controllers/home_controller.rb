class HomeController < ApplicationController
  def index
    catalog = Storefront::Catalog.all
    @featured_products = catalog.first(8)
    @featured_shops = Shop.includes(maker: :maker_profile).order(created_at: :desc).limit(12)
    @products_by_shop = catalog.group_by { |product| product.source_shop_id.to_i }
    @category_tiles = catalog.group_by(&:category).map do |name, products|
      {
        name: name,
        count: products.count,
        image_url: products.first&.image_url
      }
    end.sort_by { |tile| -tile[:count] }.first(8)
    @shop_by_category = @category_tiles.first(6)
    @top_search_terms = catalog.flat_map do |product|
      [product.category, product.material, product.name.to_s.split.first(2).join(" ")]
    end.compact.map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(18)
    @gift_guides = @category_tiles.first(3).map do |tile|
      {
        title: "#{tile[:name]} finds under $100",
        body: "Top-rated picks in #{tile[:name]} from verified independent makers.",
        image_url: tile[:image_url],
        path: products_path(category: tile[:name])
      }
    end
    @verified_makers_count = MakerProfile.count
    @products_reviewed_count = ProductApproval.count
  end
end
