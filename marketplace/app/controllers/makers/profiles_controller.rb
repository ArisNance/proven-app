module Makers
  class ProfilesController < ApplicationController
    def show
      @maker_onboarding_profile = MakerOnboardingProfile.includes(:user, :shop).find_by!(username: params[:username].to_s)
      @shop = @maker_onboarding_profile.shop || @maker_onboarding_profile.user.shops.order(created_at: :asc).first
      @products = Storefront::Catalog.all.select { |product| product.source_shop_id.to_i == @shop&.id.to_i }.first(24)
      @shop_favorite_count = @shop.present? ? @shop.shop_favorites.count : 0
      @favorited_shop = user_signed_in? && @shop.present? && current_user.shop_favorites.exists?(shop_id: @shop.id)
    end
  end
end
