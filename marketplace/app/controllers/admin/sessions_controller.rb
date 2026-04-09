module Admin
  class SessionsController < ApplicationController
    ADMIN_USERNAME = "Proven_admin".freeze
    ADMIN_PASSWORD = "ProVen0nly10!".freeze

    def new
      return unless session[:proven_admin_authenticated] == true

      redirect_to admin_root_path, notice: "You are already signed in to admin."
    end

    def create
      if params[:username].to_s == ADMIN_USERNAME && params[:password].to_s == ADMIN_PASSWORD
        session[:proven_admin_authenticated] = true
        redirect_to admin_root_path, notice: "Welcome to the Proven admin panel."
      else
        flash.now[:alert] = "Invalid admin username or password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      session.delete(:proven_admin_authenticated)
      redirect_to admin_login_path, notice: "You have been signed out from admin."
    end
  end
end
