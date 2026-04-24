class ProductFavorite < ApplicationRecord
  belongs_to :user

  validates :product_slug, presence: true
  validates :product_slug, uniqueness: { scope: :user_id }

  def product
    Storefront::Catalog.find(product_slug)
  end
end
