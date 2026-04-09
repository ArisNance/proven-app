class ProductApproval < ApplicationRecord
  enum state: { pending: 0, approved: 1, rejected: 2 }

  belongs_to :product, class_name: "Spree::Product"
  belongs_to :reviewer, class_name: "User", optional: true

  validates :moderation_decision, inclusion: { in: %w[pending allow review block] }
end
