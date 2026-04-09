class ErrorsController < ApplicationController
  layout "application"

  def not_found
    render status: :not_found
  end

  def unprocessable
    render status: :unprocessable_entity
  end

  def internal
    render status: :internal_server_error
  end
end
