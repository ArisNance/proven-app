module Makers
  class ShopsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_maker_ready!, only: %i[new create]

    def index
      @state_filter = params[:state].presence_in(Shop.states.keys)
      scope = current_user.shops.includes(:shop_approval, :listing_fee_subscriptions).order(created_at: :desc)
      @shops = @state_filter.present? ? scope.where(state: @state_filter) : scope
    end

    def show
      @shop = current_user.shops.includes(:shop_approval, :listing_fee_subscriptions).find(params[:id])
      @approval = @shop.shop_approval
      @listing_fee_subscription = @shop.listing_fee_subscriptions.order(created_at: :desc).first
    end

    def new
      @shop = current_user.shops.build
    end

    def create
      @shop = current_user.shops.build(shop_params)
      @shop.state = :pending

      if @shop.save
        ShopApproval.find_or_create_by!(shop: @shop) { |approval| approval.state = :pending }
        setup_billing_for(@shop)
        redirect_to makers_shop_path(@shop), notice: "Shop submitted for approval"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def shop_params
      params.require(:shop).permit(:name, :description)
    end

    def ensure_maker_ready!
      return if current_user.maker_onboarding_profile&.completed?
      return if current_user.maker? && current_user.maker_profile.present?

      if current_user.maker_application&.accepted? || current_user.maker?
        redirect_to makers_profile_onboarding_path, alert: "Finish maker profile onboarding before creating a shop."
      else
        redirect_to makers_onboarding_path, alert: "Submit your maker application before creating a shop."
      end
    end

    def setup_billing_for(shop)
      return if ENV["STRIPE_SECRET_KEY"].blank?

      StripeConnectService.ensure_customer_for_shop!(shop)
      Billing::ListingFees.sync!(shop.id)
    rescue Stripe::StripeError, StandardError => e
      Rails.logger.error("Billing setup failed for shop #{shop.id}: #{e.message}")
      flash[:alert] = "Shop submitted, but billing setup could not finish. Reopen this shop later to retry."
    end
  end
end
