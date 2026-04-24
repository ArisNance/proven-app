class ShopFavoritesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_shop

  def create
    current_user.shop_favorites.find_or_create_by!(shop: @shop)
    redirect_back fallback_location: fallback_location_for(@shop), notice: "Shop saved to favorites."
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: fallback_location_for(@shop), alert: "Could not save favorite: #{e.message}"
  end

  def destroy
    current_user.shop_favorites.where(shop: @shop).delete_all
    redirect_back fallback_location: fallback_location_for(@shop), notice: "Shop removed from favorites."
  end

  private

  def set_shop
    @shop = Shop.find(params[:id])
  end

  def fallback_location_for(shop)
    if shop.username.present?
      makers_public_profile_path(username: shop.username)
    else
      products_path
    end
  end
end
