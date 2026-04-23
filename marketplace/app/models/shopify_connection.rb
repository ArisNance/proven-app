class ShopifyConnection < ApplicationRecord
  enum status: { active: 0, disconnected: 1, errored: 2 }

  belongs_to :user

  validates :shop_domain, :access_token, presence: true
  validates :shop_domain, uniqueness: true

  before_validation :normalize_shop_domain

  private

  def normalize_shop_domain
    normalized = shop_domain.to_s.strip.downcase
    normalized = normalized.delete_prefix("https://")
    normalized = normalized.delete_prefix("http://")
    normalized = normalized.split("/").first.to_s
    normalized = "#{normalized}.myshopify.com" if normalized.present? && !normalized.end_with?(".myshopify.com")
    self.shop_domain = normalized
  end
end

