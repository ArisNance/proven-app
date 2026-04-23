module Makers
  class ProfileOnboardingController < ApplicationController
    before_action :authenticate_user!
    before_action :set_maker_application
    before_action :ensure_profile_onboarding_eligibility!

    def show
      @maker_onboarding_profile = current_user.maker_onboarding_profile || current_user.build_maker_onboarding_profile(default_profile_attributes)
    end

    def create
      @maker_onboarding_profile = current_user.maker_onboarding_profile || current_user.build_maker_onboarding_profile(default_profile_attributes)
      @maker_onboarding_profile.assign_attributes(maker_onboarding_profile_params)
      @maker_onboarding_profile.maker_application ||= @maker_application
      @maker_onboarding_profile.state = :completed

      if @maker_onboarding_profile.save
        ActiveRecord::Base.transaction do
          ensure_user_is_maker!
          ensure_maker_profile_record!
          shop = ensure_shop_record!
          @maker_onboarding_profile.update!(shop: shop)
        end

        redirect_to dashboard_index_path, notice: "Maker onboarding complete. Your shop profile is now active."
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def set_maker_application
      @maker_application = current_user.maker_application
    end

    def ensure_profile_onboarding_eligibility!
      return if current_user.maker?
      return if @maker_application&.accepted?

      redirect_to makers_onboarding_path, alert: "Submit and pass maker verification before onboarding your shop profile."
    end

    def default_profile_attributes
      {
        legal_first_name: @maker_application&.first_name,
        legal_last_name: @maker_application&.last_name,
        legal_business_name: @maker_application&.business_name || [@maker_application&.first_name, @maker_application&.last_name].compact.join(" "),
        dba_business_name: @maker_application&.business_name,
        username: suggested_username,
        main_product_category: MakerOnboardingProfile::MAIN_PRODUCT_CATEGORIES.first,
        lead_time_for_fulfillment: MakerOnboardingProfile::LEAD_TIME_OPTIONS.first,
        shipping_policy: "Please describe your shipping method, carriers, and handling expectations.",
        privacy_policy: "Please describe how buyer data is handled and protected.",
        returns_accepted: false,
        exchanges_accepted: false,
        refunds_accepted: false,
        cancellations_accepted: false
      }
    end

    def suggested_username
      base = [
        @maker_application&.business_name.presence,
        current_user.email.to_s.split("@").first
      ].compact.first.to_s.parameterize(separator: "_")

      return base if base.present?

      "maker_#{current_user.id}"
    end

    def ensure_user_is_maker!
      return if current_user.maker?

      current_user.update!(role: :maker)
    end

    def ensure_maker_profile_record!
      maker_profile = current_user.maker_profile || current_user.build_maker_profile
      maker_profile.display_name = [@maker_onboarding_profile.legal_first_name, @maker_onboarding_profile.legal_last_name].join(" ").squish
      maker_profile.bio = @maker_onboarding_profile.what_do_you_make_and_started.presence || @maker_application&.what_do_you_make
      maker_profile.country ||= default_country_name
      maker_profile.preferred_currency ||= "USD"
      maker_profile.save!(validate: false)
    end

    def default_country_name
      return "United States" unless defined?(Spree::Country)

      Spree::Country.find_by(iso: "US")&.name || Spree::Country.order(:name).first&.name || "United States"
    end

    def ensure_shop_record!
      shop = current_user.shops.order(created_at: :asc).first || current_user.shops.build(state: :pending)
      shop.name = @maker_onboarding_profile.dba_business_name
      shop.username = @maker_onboarding_profile.username
      shop.description = @maker_onboarding_profile.what_do_you_make_and_started.presence ||
        @maker_application&.what_do_you_make.presence ||
        "Independent maker shop on Proven."
      shop.save!
      ShopApproval.find_or_create_by!(shop: shop) { |approval| approval.state = :pending }
      shop
    end

    def maker_onboarding_profile_params
      params.require(:maker_onboarding_profile).permit(
        :legal_first_name,
        :legal_last_name,
        :legal_business_name,
        :tax_identifier,
        :dba_business_name,
        :username,
        :year_started,
        :main_product_category,
        :what_do_you_make_and_started,
        :what_inspires_your_work,
        :favorite_part_of_process,
        :favorite_product_to_make,
        :what_you_listen_to,
        :what_makes_work_different,
        :time_to_create_one_piece,
        :workspace_typical_day,
        :what_people_should_know,
        :what_to_watch_in_process,
        :lead_time_for_fulfillment,
        :shipping_policy,
        :returns_accepted,
        :exchanges_accepted,
        :refunds_accepted,
        :additional_policy_information,
        :cancellations_accepted,
        :cancellation_timeframe,
        :privacy_policy,
        :maker_faq
      )
    end
  end
end

