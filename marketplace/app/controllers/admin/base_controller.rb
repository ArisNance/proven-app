module Admin
  class BaseController < ApplicationController
    before_action :require_admin_session!

    private

    def require_admin_session!
      return if session[:proven_admin_authenticated] == true

      redirect_to admin_login_path, alert: "Sign in with admin credentials to continue."
    end
  end
end
