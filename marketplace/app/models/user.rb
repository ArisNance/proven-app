class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2]

  enum role: { buyer: 0, maker: 1, admin: 2 }, _default: :buyer

  has_one :maker_profile, dependent: :destroy
  has_one :buyer_profile, dependent: :destroy
  has_many :shops, foreign_key: :maker_id, dependent: :destroy
  has_many :messages, foreign_key: :sender_id, dependent: :destroy
  has_many :buyer_conversations, class_name: "Conversation", foreign_key: :buyer_id, dependent: :destroy
  has_many :maker_conversations, class_name: "Conversation", foreign_key: :maker_id, dependent: :destroy

  def conversations
    Conversation.where("buyer_id = :id OR maker_id = :id", id: id)
  end

  def self.from_google_oauth(auth)
    user = find_or_initialize_by(email: auth.info.email)
    user.password = Devise.friendly_token.first(20) if user.new_record?
    user.save!
    user
  end
end
