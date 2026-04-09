class ConversationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @conversations = current_user.conversations.includes(:messages, :buyer, :maker).order(updated_at: :desc)
  end

  def show
    @conversation = current_user.conversations.includes(:buyer, :maker).find(params[:id])
    @messages = @conversation.messages.includes(:sender).order(created_at: :asc)
    @counterpart = @conversation.buyer_id == current_user.id ? @conversation.maker : @conversation.buyer
  end

  def create
    conversation = Conversation.find_or_create_by!(buyer: current_user, maker_id: params.fetch(:maker_id))
    redirect_to conversation_path(conversation)
  end
end
