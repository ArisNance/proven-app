class RecommendationCache < ApplicationRecord
  belongs_to :buyer, class_name: "User"

  validates :ranked_product_ids, presence: true

  scope :fresh, -> { where("expires_at > ?", Time.current) }
end
