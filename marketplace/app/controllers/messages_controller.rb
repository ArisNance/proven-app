class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    conversation = current_user.conversations.find(params[:conversation_id])
    message = conversation.messages.build(sender: current_user, body: params.fetch(:body))

    if message.save
      ConversationChannel.broadcast_to(conversation, {
        id: message.id,
        body: message.body,
        sender_id: message.sender_id,
        created_at: message.created_at
      })

      redirect_to conversation_path(conversation), notice: "Message sent"
    else
      redirect_to conversation_path(conversation), alert: message.errors.full_messages.to_sentence
    end
  end
end
