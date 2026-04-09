class FlaggedItem < ApplicationRecord
  enum state: { open: 0, resolved: 1 }

  belongs_to :product, class_name: "Spree::Product"

  validates :reason, presence: true
end
