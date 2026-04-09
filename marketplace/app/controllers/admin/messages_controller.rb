module Admin
  class MessagesController < BaseController
    def index
      @messages = Message.includes(:sender, :conversation).order(created_at: :desc).limit(500)
    end

    def show
      @message = Message.includes(:sender, :conversation).find(params[:id])
    end

    def destroy
      message = Message.find(params[:id])
      message.destroy!
      redirect_to admin_messages_path, notice: "Message removed."
    rescue StandardError => e
      redirect_to admin_messages_path, alert: "Could not delete message: #{e.message}"
    end
  end
end
