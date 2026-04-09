class ShopApproval < ApplicationRecord
  enum state: { pending: 0, approved: 1, rejected: 2 }

  belongs_to :shop
  belongs_to :reviewer, class_name: "User", optional: true
end
