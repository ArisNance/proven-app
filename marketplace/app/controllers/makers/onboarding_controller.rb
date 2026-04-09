module Makers
  class OnboardingController < ApplicationController
    before_action :authenticate_user!

    def show
      @maker_profile = current_user.maker_profile || current_user.build_maker_profile(preferred_currency: "USD")
      @stripe_onboarding_url = stripe_onboarding_url_for(@maker_profile)
    end

    def create
      @maker_profile = current_user.maker_profile || current_user.build_maker_profile
      @maker_profile.assign_attributes(maker_profile_params)

      if @maker_profile.save
        create_connect_account_if_possible(@maker_profile)
        redirect_to new_makers_shop_path, notice: "Profile saved. Continue with your shop setup."
      else
        @stripe_onboarding_url = stripe_onboarding_url_for(@maker_profile)
        render :show, status: :unprocessable_entity
      end
    end

    private

    def maker_profile_params
      params.require(:maker_profile).permit(:display_name, :bio, :country, :preferred_currency)
    end

    def create_connect_account_if_possible(profile)
      return if ENV["STRIPE_SECRET_KEY"].blank?

      StripeConnectService.create_or_fetch_account!(profile)
    rescue Stripe::StripeError => e
      Rails.logger.error("Stripe Connect onboarding setup failed for maker_profile #{profile.id}: #{e.message}")
      flash[:alert] = "Profile saved, but payout onboarding is currently unavailable. You can retry from the shop pages."
    end

    def stripe_onboarding_url_for(profile)
      return if profile.blank? || profile.stripe_account_id.blank? || ENV["STRIPE_SECRET_KEY"].blank?

      StripeConnectService.onboarding_link(profile.stripe_account_id)
    rescue Stripe::StripeError => e
      Rails.logger.warn("Stripe onboarding link failed for maker_profile #{profile.id}: #{e.message}")
      nil
    end
  end
end
