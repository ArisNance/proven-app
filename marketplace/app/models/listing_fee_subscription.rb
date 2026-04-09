class ListingFeeSubscription < ApplicationRecord
  enum status: { active: 0, paused: 1, canceled: 2 }

  belongs_to :shop

  validates :stripe_subscription_id, presence: true
end
