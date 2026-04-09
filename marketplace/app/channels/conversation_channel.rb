class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find(params[:conversation_id])
    return reject unless allowed?(conversation)

    stream_for conversation
  end

  private

  def allowed?(conversation)
    [conversation.buyer_id, conversation.maker_id].include?(current_user.id)
  end
end
