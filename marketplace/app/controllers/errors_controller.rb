class ErrorsController < ApplicationController
  layout "application"

  def not_found
    render_error(:not_found, "Not Found")
  end

  def unprocessable
    render_error(:unprocessable_entity, "Unprocessable Entity")
  end

  def internal
    render_error(:internal_server_error, "Internal Server Error")
  end

  private

  def render_error(status, message)
    respond_to do |format|
      format.html { render status: status }
      format.json { render json: { error: message }, status: status }
      format.any { head status }
    end
  end
end
