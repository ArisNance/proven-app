module Admin
  class BaseController < ApplicationController
    before_action :require_admin_session!

    private

    def require_admin_session!
      authenticated = session[:proven_admin_authenticated] == true
      seeded_login = session[:proven_admin_seeded_login].to_s == Admin::SessionsController::ADMIN_USERNAME
      return if authenticated && seeded_login

      session.delete(:proven_admin_authenticated)
      session.delete(:proven_admin_seeded_login)
      redirect_to admin_login_path, alert: "Sign in with admin credentials to continue."
    end
  end
end
