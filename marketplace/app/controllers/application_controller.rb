class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private

  def forbidden
    redirect_to(user_signed_in? ? dashboard_index_path : root_path, alert: "You do not have permission to access that page.")
  end
end
