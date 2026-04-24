module Makers
  class ShopsController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_maker_ready!, only: %i[new create]
    before_action :set_shop, only: %i[show connect_billing sync_billing]

    def index
      @state_filter = params[:state].presence_in(Shop.states.keys)
      scope = current_user.shops.includes(:shop_approval, :listing_fee_subscriptions).order(created_at: :desc)
      @shops = @state_filter.present? ? scope.where(state: @state_filter) : scope
    end

    def show
      @approval = @shop.shop_approval
      @listing_fee_subscription = @shop.listing_fee_subscriptions.order(created_at: :desc).first
      @stripe_configured = ENV["STRIPE_SECRET_KEY"].present?
    end

    def connect_billing
      return redirect_to makers_shop_path(@shop), alert: "Stripe is not configured yet." if ENV["STRIPE_SECRET_KEY"].blank?
      return redirect_to makers_shop_path(@shop), alert: "Shop must be approved before connecting Stripe billing." unless @shop.approved?

      maker_profile = ensure_maker_profile_for_billing!
      account_id = StripeConnectService.create_or_fetch_account!(maker_profile)
      onboarding_url = StripeConnectService.onboarding_link(
        account_id,
        refresh_path: makers_shop_path(@shop),
        return_path: makers_shop_path(@shop)
      )

      redirect_to onboarding_url, allow_other_host: true
    rescue Stripe::StripeError => e
      redirect_to makers_shop_path(@shop), alert: "Could not open Stripe onboarding: #{e.message}"
    end

    def sync_billing
      return redirect_to makers_shop_path(@shop), alert: "Stripe is not configured yet." if ENV["STRIPE_SECRET_KEY"].blank?
      return redirect_to makers_shop_path(@shop), alert: "Shop must be approved before syncing billing." unless @shop.approved?

      StripeConnectService.ensure_customer_for_shop!(@shop)
      Billing::ListingFees.sync!(@shop.id)
      redirect_to makers_shop_path(@shop), notice: "Billing profile synced. You can now proceed with product uploads."
    rescue Stripe::StripeError, StandardError => e
      redirect_to makers_shop_path(@shop), alert: "Billing sync failed: #{e.message}"
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

    def set_shop
      @shop = current_user.shops.includes(:shop_approval, :listing_fee_subscriptions).find(params[:id])
    end

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

    def ensure_maker_profile_for_billing!
      maker_profile = current_user.maker_profile || current_user.build_maker_profile
      maker_profile.display_name = current_user.maker_onboarding_profile&.dba_business_name.presence ||
        current_user.email.to_s.split("@").first.to_s.titleize if maker_profile.display_name.blank?
      maker_profile.country ||= default_country_name
      maker_profile.preferred_currency ||= "USD"
      maker_profile.save!(validate: false)
      maker_profile
    end

    def default_country_name
      return "United States" unless defined?(Spree::Country)

      Spree::Country.find_by(iso: "US")&.name || Spree::Country.order(:name).first&.name || "United States"
    end
  end
end
