module Users
  class RegistrationsController < Devise::RegistrationsController
    protected

    def after_sign_up_path_for(_resource)
      dashboard_index_path
    end

    def after_inactive_sign_up_path_for(_resource)
      root_path
    end
  end
end
