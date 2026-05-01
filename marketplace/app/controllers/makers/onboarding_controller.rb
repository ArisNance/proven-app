module Makers
  class OnboardingController < ApplicationController
    before_action :authenticate_user!

    def show
      @maker_application = current_user.maker_application || current_user.build_maker_application
      @maker_application.email ||= current_user.email
    end

    def create
      @maker_application = current_user.maker_application || current_user.build_maker_application
      @maker_application.assign_attributes(maker_application_params)
      @maker_application.state = next_application_state(@maker_application)
      @maker_application.submitted_at ||= Time.current

      if @maker_application.save
        confirmation_email_sent = true
        if @maker_application.saved_change_to_state? && @maker_application.state == "submitted"
          confirmation_email_sent = MakerApplicationLifecycleEmailService.application_received!(@maker_application)
        end

        if @maker_application.accepted?
          redirect_to makers_profile_onboarding_path, notice: "Application accepted. Complete your onboarding profile."
        else
          flash[:alert] = "Your application was submitted, but we could not send the confirmation email right now." unless confirmation_email_sent
          redirect_to dashboard_index_path, notice: "Your maker application has been submitted for review."
        end
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def maker_application_params
      params.require(:maker_application).permit(
        :first_name,
        :last_name,
        :email,
        :business_name,
        :business_url,
        :what_do_you_make,
        :how_long_making
      )
    end

    def next_application_state(application)
      return :accepted if application.accepted?
      return :in_review if application.in_review?

      :submitted
    end
  end
end
