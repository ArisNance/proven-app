class Shop < ApplicationRecord
  enum state: { pending: 0, approved: 1, rejected: 2, suspended: 3 }

  belongs_to :maker, class_name: "User"
  has_one :shop_approval, dependent: :destroy
  has_one :maker_onboarding_profile, dependent: :nullify
  has_many :listing_fee_subscriptions, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true, length: { maximum: 2_500 }
  validates :username, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :username, format: { with: /\A[a-z0-9_]+\z/, message: "can only include lowercase letters, numbers, and underscores" }, allow_blank: true
end
