module Admin
  class MakerApplicationsController < BaseController
    before_action :set_maker_application, only: %i[show update approve reject]

    def index
      @state_filter = params[:state].presence_in(MakerApplication.states.keys)
      scope = MakerApplication.includes(:user, :reviewer, :maker_verification).order(submitted_at: :desc, created_at: :desc)
      @maker_applications = @state_filter.present? ? scope.where(state: @state_filter) : scope
    end

    def show
      @maker_verification = @maker_application.maker_verification || @maker_application.build_maker_verification
    end

    def update
      @maker_verification = @maker_application.maker_verification || @maker_application.build_maker_verification
      @maker_verification.assign_attributes(maker_verification_params)
      @maker_verification.verified_by ||= admin_reviewer
      @maker_verification.verified_on ||= Time.current if @maker_verification.overall_confidence_score.present?

      @maker_application.assign_attributes(maker_application_admin_params) if params[:maker_application].present?

      if @maker_verification.save && @maker_application.save
        @maker_application.update!(state: :in_review, reviewer: admin_reviewer) if @maker_application.submitted?
        redirect_to admin_maker_application_path(@maker_application), notice: "Verification details saved."
      else
        render :show, status: :unprocessable_entity
      end
    end

    def approve
      verification = @maker_application.maker_verification
      if verification.blank? || !verification.passes?
        redirect_to admin_maker_application_path(@maker_application), alert: "Set overall confidence to 4 or 5 before approving."
        return
      end

      ActiveRecord::Base.transaction do
        @maker_application.update!(state: :accepted, reviewer: admin_reviewer, reviewed_at: Time.current)
        verification.update!(verified_by: admin_reviewer, verified_on: Time.current)

        user = @maker_application.user
        user.update!(role: :maker) if user.buyer?
        ensure_maker_profile_for!(user)
      end

      redirect_to admin_maker_application_path(@maker_application), notice: "Maker application approved."
    end

    def reject
      @maker_application.update!(state: :rejected, reviewer: admin_reviewer, reviewed_at: Time.current)
      redirect_to admin_maker_application_path(@maker_application), alert: "Maker application rejected."
    end

    private

    def set_maker_application
      @maker_application = MakerApplication.includes(:user, :reviewer, :maker_verification).find(params[:id])
    end

    def admin_reviewer
      User.admin.first || User.first
    end

    def ensure_maker_profile_for!(user)
      maker_profile = user.maker_profile || user.build_maker_profile
      maker_profile.display_name ||= [@maker_application.first_name, @maker_application.last_name].join(" ").squish
      maker_profile.country ||= default_country_name
      maker_profile.preferred_currency ||= "USD"
      maker_profile.save!(validate: false)
    end

    def default_country_name
      return "United States" unless defined?(Spree::Country)

      Spree::Country.find_by(iso: "US")&.name || Spree::Country.order(:name).first&.name || "United States"
    end

    def maker_application_admin_params
      params.require(:maker_application).permit(:admin_notes)
    end

    def maker_verification_params
      params.require(:maker_verification).permit(
        :identity_status,
        :workspace_status,
        :production_capability_status,
        :product_origin_status,
        :identity_name_given,
        :identity_id_verified,
        :identity_name_match_confidence,
        :identity_notes,
        :workspace_type,
        :workspace_confidence,
        :workspace_notes,
        :production_in_progress_product_seen,
        :production_process_explained,
        :production_materials_observed,
        :production_complexity_level,
        :production_confidence,
        :production_notes,
        :product_origin_matched_to_maker,
        :product_origin_categories_verified,
        :product_origin_inconsistencies_flagged,
        :product_origin_confidence,
        :product_origin_notes,
        :red_flag_stock_like_imagery,
        :red_flag_inconsistent_story,
        :red_flag_no_in_progress_proof,
        :red_flag_unclear_production_chain,
        :maker_type_classification,
        :overall_confidence_score,
        :verification_method,
        :verification_duration_minutes,
        :verified_on,
        :reviewer_notes,
        identity_attachments: [],
        workspace_attachments: [],
        production_attachments: [],
        product_origin_attachments: [],
        reviewer_attachments: []
      )
    end
  end
end

