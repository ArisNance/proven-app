class ProductFavoritesController < ApplicationController
  before_action :authenticate_user!

  def create
    product = Storefront::Catalog.find(params[:id].to_s)
    return redirect_back(fallback_location: products_path, alert: "Product not found.") if product.blank?

    current_user.product_favorites.find_or_create_by!(product_slug: product.slug)
    redirect_back fallback_location: product_path(product.slug), notice: "Product saved to favorites."
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: product_path(product.slug), alert: "Could not save favorite: #{e.message}"
  end

  def destroy
    product = Storefront::Catalog.find(params[:id].to_s)
    slugs = [params[:id].to_s, product&.slug].compact
    current_user.product_favorites.where(product_slug: slugs).delete_all

    fallback = product.present? ? product_path(product.slug) : products_path
    redirect_back fallback_location: fallback, notice: "Product removed from favorites."
  end
end
