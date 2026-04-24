class ShopFavorite < ApplicationRecord
  belongs_to :user
  belongs_to :shop

  validates :shop_id, uniqueness: { scope: :user_id }
end
