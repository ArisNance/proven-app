module Makers
  class ProfilesController < ApplicationController
    def show
      @maker_onboarding_profile = MakerOnboardingProfile.includes(:user, :shop).find_by!(username: params[:username].to_s)
      @shop = @maker_onboarding_profile.shop || @maker_onboarding_profile.user.shops.order(created_at: :asc).first
      @products = Storefront::Catalog.all.select { |product| product.source_shop_id.to_i == @shop&.id.to_i }.first(24)
    end
  end
end

