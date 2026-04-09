class BuyerProfile < ApplicationRecord
  belongs_to :user

  validates :preference_tags, length: { maximum: 1000 }, allow_blank: true
end
