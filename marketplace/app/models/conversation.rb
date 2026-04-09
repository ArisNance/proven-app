class Conversation < ApplicationRecord
  belongs_to :buyer, class_name: "User"
  belongs_to :maker, class_name: "User"
  has_many :messages, dependent: :destroy

  validates :buyer_id, uniqueness: { scope: :maker_id }
end
